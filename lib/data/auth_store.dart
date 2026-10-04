import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_account.dart';
import '../models/user_profile.dart';
import 'auth_validators.dart';
import 'password_hasher.dart';

/// Esito di un tentativo di accesso. I messaggi sono quelli mostrati a
/// schermo: [unknownAccount] e [wrongPassword] stanno separati perché il
/// login deve poter rispondere «password sbagliata» a chi l'ha sbagliata.
enum SignInResult {
  success,
  unknownAccount,
  wrongPassword,
  googleOnly,
  noPassword,
  emptyIdentifier;

  String get message => switch (this) {
    SignInResult.success => 'Accesso effettuato',
    SignInResult.unknownAccount =>
      'Nessun account con questo ID o questa email',
    SignInResult.wrongPassword => 'Password errata',
    SignInResult.googleOnly => 'Questo account usa Google: accedi con Google',
    SignInResult.noPassword => 'Questo profilo è stato creato prima delle password: crea un account nuovo',
    SignInResult.emptyIdentifier => 'Scrivi il tuo ID account o la tua email',
  };
}

/// Errore di scrittura su un account: email o ID account già presi.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Sessione e account del dispositivo.
///
/// Il profilo in uso è la **sessione** (`user_profile_v1`), gli account sono
/// l'elenco delle credenziali (`accounts_v1`): uscire cancella la sessione e
/// lascia gli account, così si rientra con la password.
///
/// Non c'è server: [accounts_v1] è un elenco di utenti su questo dispositivo e
/// «unico» significa unico qui. Vedi `password_hasher.dart` su cosa comporta.
class AuthStore extends ChangeNotifier {
  static final AuthStore instance = AuthStore._();
  AuthStore._();

  /// Sessione: il profilo mostrato a schermo.
  static const _key = 'user_profile_v1';

  /// Elenco degli account del dispositivo.
  static const _accountsKey = 'accounts_v1';

  UserProfile? _currentUser;
  List<LocalAccount> _accounts = const [];
  bool _loaded = false;
  Object? _loadError;

  UserProfile? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  /// Account salvati sul dispositivo. In sola lettura: per scrivere ci passa
  /// `registerManual` e `updateProfile`, che controllano anche le unicità.
  List<LocalAccount> get accounts => List.unmodifiable(_accounts);

  /// ID degli altri account, quello in uso escluso: serve alla validazione
  /// mentre si modifica il profilo.
  List<String> accountIdsInUse({String? exceptAccountId}) => [
    for (final account in _accounts)
      if (account.profile.accountId != exceptAccountId)
        account.profile.accountId,
  ];

  List<String> emailsInUse({String? exceptAccountId}) => [
    for (final account in _accounts)
      if (account.profile.accountId != exceptAccountId) account.profile.email,
  ];

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _currentUser = _withAccountId(
          UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      }
      _accounts = _readAccounts(prefs);
      if (_needsLegacyAccount(prefs)) {
        _accounts = _withLegacyAccount(_accounts, _currentUser);
        await _persistAccounts(prefs);
      }
      _loaded = true;
      notifyListeners();
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _currentUser = null;
    _accounts = const [];
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _currentUser = null;
    _accounts = const [];
    _loadError = null;
    await load();
  }

  /// Registrazione manuale. `accountId` è opzionale: se manca viene derivato
  /// dall'email. Email e ID account devono essere liberi, altrimenti
  /// [AuthException] con il messaggio da mostrare.
  ///
  /// La forza della password la controlla il form: lo store riceve input solo
  /// dall'app, quindi la validazione qui sarebbe un doppio controllo.
  Future<UserProfile> registerManual({
    required String name,
    required String email,
    required String password,
    String? accountId,
    String schoolLevelId = '',
    String avatarId = '',
  }) async {
    final mail = email.trim();
    final handle = _resolveAccountId(accountId, mail);
    _requireFree(mail, handle);

    final profile = UserProfile(
      name: name.trim(),
      email: mail,
      accountId: handle,
      authMethod: AuthMethod.manual,
      schoolLevelId: schoolLevelId,
      avatarId: avatarId,
      createdAt: DateTime.now(),
    );
    final salt = PasswordHasher.createSalt();
    final account = LocalAccount(
      profile: profile,
      passwordHash: PasswordHasher.hash(password, salt),
      passwordSalt: salt,
    );

    _accounts = [..._accounts, account];
    _currentUser = profile;
    notifyListeners();
    await _persistAll();
    return profile;
  }

  /// Registrazione col dialog dimostrativo di Google: nessuna password, il
  /// profilo è quello che il dialog chiede.
  Future<UserProfile> signUpWithGoogle({
    required String name,
    required String email,
    String? photoUrl,
    String schoolLevelId = '',
  }) async {
    final mail = email.trim();
    final existing = _findByEmail(mail);
    if (existing != null) {
      _currentUser = existing.profile;
      notifyListeners();
      await _persistSession();
      return existing.profile;
    }

    final handle = _freeAccountIdFrom(mail);
    final profile = UserProfile(
      name: name.trim(),
      email: mail,
      accountId: handle,
      authMethod: AuthMethod.google,
      photoUrl: photoUrl,
      schoolLevelId: schoolLevelId,
      createdAt: DateTime.now(),
    );
    _accounts = [
      ..._accounts,
      LocalAccount(profile: profile, passwordHash: '', passwordSalt: ''),
    ];
    _currentUser = profile;
    notifyListeners();
    await _persistAll();
    return profile;
  }

  /// Accesso con ID account o email. `identifier` accetta i due: è il campo
  /// che nel login sta scritto «Email o ID account».
  Future<SignInResult> signIn({
    required String identifier,
    required String password,
  }) async {
    final needle = identifier.trim();
    if (needle.isEmpty) return SignInResult.emptyIdentifier;

    final account = _findByHandleOrEmail(needle);
    if (account == null) return SignInResult.unknownAccount;
    if (!account.hasPassword) {
      return account.profile.authMethod == AuthMethod.google
          ? SignInResult.googleOnly
          : SignInResult.noPassword;
    }
    if (!PasswordHasher.verify(
      password,
      account.passwordSalt,
      account.passwordHash,
    )) {
      return SignInResult.wrongPassword;
    }

    _currentUser = account.profile;
    notifyListeners();
    await _persistSession();
    return SignInResult.success;
  }

  Future<void> updateSchool(String schoolLevelId) async {
    final user = _currentUser;
    if (user == null) return;
    _replaceSessionProfile(user.copyWith(schoolLevelId: schoolLevelId));
    await _persistAll();
  }

  /// Aggiorna i campi modificabili del profilo in uso. L'handle non può essere
  /// quello di un altro account, altrimenti [AuthException].
  Future<UserProfile?> updateProfile({
    String? name,
    String? accountId,
    String? avatarId,
  }) async {
    final user = _currentUser;
    if (user == null) return null;

    final handle = accountId?.trim();
    if (handle != null && handle != user.accountId) {
      _requireFree(user.email, handle, exceptAccountId: user.accountId);
    }

    _replaceSessionProfile(
      user.copyWith(name: name, accountId: handle, avatarId: avatarId),
    );
    await _persistAll();
    return _currentUser;
  }

  /// Mette il nuovo profilo nella sessione e nell'account da cui è venuto:
  /// senza il secondo passaggio l'elenco degli account resterebbe indietro e
  /// il rientro dal login riporterebbe i valori vecchi.
  void _replaceSessionProfile(UserProfile updated) {
    final previous = _currentUser!;
    _currentUser = updated;
    _accounts = [
      for (final account in _accounts)
        if (account.profile.accountId == previous.accountId)
          account.copyWith(profile: updated)
        else
          account,
    ];
    notifyListeners();
  }

  /// Chiude la sessione e tiene l'account: si rientra con la password.
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  List<LocalAccount> _readAccounts(SharedPreferences prefs) {
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            LocalAccount.fromJson(_withAccountIdProfile(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _withAccountIdProfile(Map<String, dynamic> json) {
    final profile = json['profile'];
    if (profile is! Map<String, dynamic>) return json;
    return {
      ...json,
      'profile': _withAccountId(UserProfile.fromJson(profile)).toJson(),
    };
  }

  /// Un profilo senza `accountId` è un profilo scritto prima che l'handle
  /// esistesse: glielo diamo dall'email così l'elenco degli account resta
  /// coerente senza perdere le sessioni già aperte.
  UserProfile _withAccountId(UserProfile profile) {
    if (profile.accountId.isNotEmpty) return profile;
    return profile.copyWith(accountId: _freeAccountIdFrom(profile.email));
  }

  /// Un profilo salvato prima di `accounts_v1` diventa un account senza
  /// credenziale: si può usare l'app, ma per rientrare serve registrarsi.
  bool _needsLegacyAccount(SharedPreferences prefs) {
    if (prefs.getString(_accountsKey) != null) return false;
    if (_currentUser == null) return false;
    final mail = _currentUser!.email.trim();
    return !_accounts.any((account) => account.profile.email == mail);
  }

  List<LocalAccount> _withLegacyAccount(
    List<LocalAccount> accounts,
    UserProfile? user,
  ) {
    if (user == null) return accounts;
    return [
      ...accounts,
      LocalAccount(profile: user, passwordHash: '', passwordSalt: ''),
    ];
  }

  String _resolveAccountId(String? accountId, String email) {
    final given = accountId?.trim() ?? '';
    if (given.isNotEmpty) return given;
    return _freeAccountIdFrom(email);
  }

  /// Handle libero a partire dall'email: quello ricavato, o il primo con un
  /// suffisso se qualcuno lo ha già preso.
  String _freeAccountIdFrom(String email) {
    final base = AuthValidators.accountIdFromEmail(email);
    if (!_isTaken(base, null)) return base;
    for (var suffix = 2; suffix < 100; suffix++) {
      final candidate =
          '${base.substring(0, base.length > 16 ? 16 : base.length)}'
          '$suffix';
      if (!_isTaken(candidate, null)) return candidate;
    }
    return base;
  }

  void _requireFree(String email, String accountId, {String? exceptAccountId}) {
    if (_isTaken(email, exceptAccountId, byEmail: true)) {
      throw const AuthException('Questa email è già presente');
    }
    if (_isTaken(accountId, exceptAccountId)) {
      throw const AuthException('Questo ID account è già in uso');
    }
  }

  bool _isTaken(String value, String? exceptAccountId, {bool byEmail = false}) {
    final needle = value.toLowerCase();
    return _accounts.any((account) {
      if (account.profile.accountId == exceptAccountId) return false;
      final candidate = byEmail
          ? account.profile.email
          : account.profile.accountId;
      return candidate.toLowerCase() == needle;
    });
  }

  LocalAccount? _findByEmail(String email) {
    final needle = email.toLowerCase();
    for (final account in _accounts) {
      if (account.profile.email.toLowerCase() == needle) return account;
    }
    return null;
  }

  LocalAccount? _findByHandleOrEmail(String identifier) {
    final needle = identifier.toLowerCase();
    for (final account in _accounts) {
      if (account.profile.accountId.toLowerCase() == needle ||
          account.profile.email.toLowerCase() == needle) {
        return account;
      }
    }
    return null;
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _persistSession(prefs);
    await _persistAccounts(prefs);
  }

  Future<void> _persistSession([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final user = _currentUser;
    if (user == null) return;
    await p.setString(_key, jsonEncode(user.toJson()));
  }

  Future<void> _persistAccounts([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _accountsKey,
      jsonEncode([for (final account in _accounts) account.toJson()]),
    );
  }
}
