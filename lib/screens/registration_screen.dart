import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../data/auth_store.dart';
import '../data/auth_validators.dart';
import '../data/content_repository.dart';
import '../haptics.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/password_field.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/school_level_tile.dart';
import '../widgets/year_tile.dart';
import '../widgets/shake.dart';
import '../widgets/strength_meter.dart';
import '../widgets/wave_clipper.dart';

/// Creazione del profilo in quattro passi, come «Creazione profilo» del
/// design: chi sei (avatar e nome), l'account (email, ID, password, termini),
/// la scuola e, per medie e superiori, l'anno. All'università l'anno non c'è e
/// i passi sono tre.
///
/// La testata indaco ha solo la freccia e il titolo del passo, al centro, che
/// cambia in dissolvenza; il passo nuovo entra con una dissolvenza e uno
/// scorrimento (avanti da destra, indietro da sinistra). Col movimento ridotto
/// il passo cambia e basta.
///
/// Gli errori dei campi compaiono solo dopo un «Continua» a vuoto, non mentre
/// si scrive; da lì in poi il passo li aggiorna a ogni modifica. Al passo
/// della scuola e dell'anno «Continua» resta spento finché non si sceglie.
/// Il back di sistema, dal secondo passo in poi, torna al passo prima invece
/// di uscire.
///
/// A profilo creato la schermata diventa un riepilogo animato dei dati scelti;
/// da lì «Inizia» torna alla radice.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _titles = [
    'Chi sei?',
    'Il tuo account',
    'La tua scuola',
    'Il tuo anno',
  ];

  /// Di quanto, in frazione della larghezza, il passo nuovo entra di lato.
  static const double _slide = 0.08;

  final _whoForm = GlobalKey<FormState>();
  final _accountForm = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _accountIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _shakes = FieldShakes();
  String _avatarId = '';
  String _schoolId = '';
  String _courseId = '';
  bool _avatarOpen = false;
  bool _termsAccepted = false;
  bool _busy = false;
  bool _done = false;
  int _step = 0;

  /// I passi con un «Continua» già fallito: lì gli errori si aggiornano
  /// mentre si scrive.
  final Set<int> _failed = {};

  /// Il verso dell'ultimo cambio di passo: avanti il passo nuovo entra da
  /// destra, indietro da sinistra.
  bool _forward = true;

  /// Finché l'utente non scrive a mano nell'ID account, il campo segue
  /// l'email: il suggerimento è buono e nessuno lo scrive da solo.
  bool _accountIdTouched = false;

  Level? get _level => ContentRepository.instance.levelById(_schoolId);

  /// Medie e superiori chiedono l'anno; l'università no.
  bool get _needsYear {
    final level = _level;
    return level != null &&
        level.id != 'university' &&
        level.courses.isNotEmpty;
  }

  int get _stepCount => _needsYear ? 4 : 3;
  bool get _last => _step == _stepCount - 1;

  /// «Continua» è spento finché la scuola o l'anno non sono scelti.
  bool get _canContinue => switch (_step) {
    2 => _schoolId.isNotEmpty,
    3 => _courseId.isNotEmpty,
    _ => true,
  };

  AutovalidateMode get _mode => _failed.contains(_step)
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _accountIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step > _step;
      _step = step;
    });
  }

  void _continue() {
    if (_busy) return;
    if (_step == 0 && !(_whoForm.currentState?.validate() ?? false)) {
      setState(() {
        _failed.add(0);
        _shakes.shakeEmpty([_nameController]);
      });
      return;
    }
    if (_step == 1) {
      if (!(_accountForm.currentState?.validate() ?? false)) {
        setState(() {
          _failed.add(1);
          _shakes.shakeEmpty([
            _emailController,
            _accountIdController,
            _passwordController,
            _confirmController,
          ]);
        });
        return;
      }
      if (!_termsAccepted) {
        _tell('Accetta i Termini e la Privacy Policy per continuare.');
        return;
      }
    }
    if (_last) {
      _submit();
    } else {
      _go(_step + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_done) return _doneView(c);
    Widget content = KeyedSubtree(
      key: ValueKey('registration-step-$_step'),
      child: switch (_step) {
        0 => _whoStep(c),
        1 => _accountStep(c),
        2 => _schoolStep(),
        _ => _yearStep(),
      },
    );
    if (!AppMotion.reduced(context)) {
      content = content
          .animate(key: ValueKey(_step))
          .fadeIn(duration: AppMotion.slow, curve: AppMotion.standard)
          .slideX(
            begin: _forward ? _slide : -_slide,
            end: 0,
            duration: AppMotion.slow,
            curve: AppMotion.standard,
          );
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_step - 1);
      },
      child: Scaffold(
        body: Column(
          children: [
            _StepHeader(title: _titles[_step]),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                children: [content],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      AppButton(
                        key: const Key('registration-back'),
                        label: 'Indietro',
                        variant: AppButtonVariant.outline,
                        onPressed: _busy ? null : () => _go(_step - 1),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AppButton(
                        key: const Key('registration-next'),
                        label: _last ? 'Crea il mio profilo' : 'Continua',
                        expand: true,
                        busy: _busy,
                        onPressed: _canContinue ? _continue : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar al centro e sotto il nome. Il tocco sull'avatar apre, subito
  /// sopra, il rettangolo con tutti quelli disponibili.
  Widget _whoStep(AppPalette c) {
    return Form(
      key: _whoForm,
      autovalidateMode: _mode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: AppMotion.duration(context, AppMotion.medium),
            curve: AppMotion.standard,
            alignment: Alignment.bottomCenter,
            child: _avatarOpen
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      key: const Key('registration-avatar-panel'),
                      child: Center(
                        child: AvatarPicker(
                          value: _avatarId,
                          onChanged: _pickAvatar,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Center(
            child: _AvatarButton(
              avatarId: _avatarId,
              name: _nameController.text,
              open: _avatarOpen,
              onTap: () => setState(() => _avatarOpen = !_avatarOpen),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tocca per scegliere l\'avatar',
              style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          ShakeWidget(
            trigger: _shakes.of(_nameController),
            child: _field(
              controller: _nameController,
              label: 'Come ti chiami?',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Inserisci il tuo nome';
                if (v.length < 2) {
                  return 'Il nome deve avere almeno 2 caratteri';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Il profilo è salvato solo su questo dispositivo.',
              style: TextStyle(
                fontSize: AppText.caption,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// La scelta si vede un attimo, poi il rettangolo si chiude (subito col
  /// movimento ridotto), come il foglio dell'avatar nel profilo.
  Future<void> _pickAvatar(String value) async {
    setState(() => _avatarId = value);
    await Future<void>.delayed(AppMotion.duration(context, AppMotion.slow));
    if (mounted) setState(() => _avatarOpen = false);
  }

  Widget _accountStep(AppPalette c) {
    return AppCard(
      child: Form(
        key: _accountForm,
        autovalidateMode: _mode,
        child: Column(
          children: [
            ShakeWidget(
              trigger: _shakes.of(_emailController),
              child: _field(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: (value) {
                  if (_accountIdTouched) return;
                  final suggested = AuthValidators.accountIdFromEmail(
                    value.trim(),
                  );
                  if (suggested == 'studente') return;
                  _accountIdController.text = suggested;
                },
                validator: (value) => AuthValidators.emailError(
                  value,
                  taken: AuthStore.instance.emailsInUse(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShakeWidget(
              trigger: _shakes.of(_accountIdController),
              child: _field(
                controller: _accountIdController,
                label: 'ID account',
                autocorrect: false,
                helperText: 'Come ti trovano gli altri: 3-20 caratteri',
                prefixIcon: Icons.tag,
                onChanged: (_) => _accountIdTouched = true,
                validator: (value) => AuthValidators.accountIdError(
                  value,
                  taken: AuthStore.instance.accountIdsInUse(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShakeWidget(
              trigger: _shakes.of(_passwordController),
              child: PasswordField(
                controller: _passwordController,
                label: 'Password',
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                validator: AuthValidators.passwordError,
              ),
            ),
            const SizedBox(height: 8),
            StrengthMeter(password: _passwordController.text),
            const SizedBox(height: 12),
            ShakeWidget(
              trigger: _shakes.of(_confirmController),
              child: PasswordField(
                controller: _confirmController,
                label: 'Conferma password',
                textInputAction: TextInputAction.done,
                validator: (value) => AuthValidators.confirmError(
                  value,
                  _passwordController.text,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _TermsRow(
              accepted: _termsAccepted,
              onChanged: (value) => setState(() => _termsAccepted = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _schoolStep() {
    return Column(
      children: [
        for (final level in ContentRepository.instance.levels)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SchoolLevelTile(
              level: level,
              selected: _schoolId == level.id,
              onTap: () => setState(() {
                // L'anno vale dentro la sua scuola.
                if (_schoolId != level.id) _courseId = '';
                _schoolId = level.id;
              }),
            ),
          ),
      ],
    );
  }

  Widget _yearStep() {
    return Column(
      children: [
        for (final course in _level?.courses ?? const <Course>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: YearTile(
              course: course,
              selected: _courseId == course.id,
              onTap: () => setState(() => _courseId = course.id),
            ),
          ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autocorrect = true,
    List<String>? autofillHints,
    ValueChanged<String>? onChanged,
    String? helperText,
    IconData? prefixIcon,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      autofillHints: autofillHints,
      onChanged: onChanged,
      validator: validator,
      decoration: AppTheme.fieldDecoration(c).copyWith(
        labelText: label,
        helperText: helperText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: c.textSecondary),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await AuthStore.instance.registerManual(
        name: _nameController.text,
        email: _emailController.text,
        accountId: _accountIdController.text,
        password: _passwordController.text,
        schoolLevelId: _schoolId,
        courseId: _needsYear ? _courseId : '',
        avatarId: _avatarId,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _tell(error.message);
      return;
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    AppHaptics.mediumImpact();
    setState(() {
      _busy = false;
      _done = true;
    });
  }

  /// La Home è la radice: il profilo è completo, scuola compresa.
  void _finish() => Navigator.of(context).popUntil((route) => route.isFirst);

  /// Il riepilogo dei dati scelti: l'avatar rimbalza in scena e le righe
  /// entrano una dopo l'altra. Col movimento ridotto è già tutto lì.
  Widget _doneView(AppPalette c) {
    final level = _level;
    final course = level?.courses.where((x) => x.id == _courseId).firstOrNull;
    final rows = <(IconData, String, String)>[
      (Icons.person_outline, 'Nome', _nameController.text.trim()),
      (Icons.tag, 'ID account', _accountIdController.text.trim()),
      if (level != null) (Icons.school_outlined, 'Scuola', level.title),
      if (course != null && _needsYear)
        (Icons.event_outlined, 'Anno', yearLabel(course)),
    ];

    Widget enter(int index, Widget child) {
      if (AppMotion.reduced(context)) return child;
      final delay = AppMotion.stagger * (index + 3);
      return child
          .animate()
          .fadeIn(
            delay: delay,
            duration: AppMotion.slow,
            curve: AppMotion.standard,
          )
          .slideY(
            delay: delay,
            begin: 0.2,
            end: 0,
            duration: AppMotion.slow,
            curve: AppMotion.standard,
          );
    }

    Widget avatar = _AvatarCircle(
      key: const Key('registration-done-avatar'),
      avatarId: _avatarId,
      name: _nameController.text,
      size: 120,
    );
    Widget title = Text(
      'Profilo creato!',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppText.headingFont,
        fontSize: AppText.display,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    );
    if (!AppMotion.reduced(context)) {
      avatar = avatar
          .animate()
          .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: AppMotion.slow * 2,
            curve: AppMotion.bounce,
          )
          .fadeIn(duration: AppMotion.slow);
      title = title.animate().fadeIn(
        delay: AppMotion.stagger * 2,
        duration: AppMotion.slow,
        curve: AppMotion.standard,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  children: [
                    Center(child: avatar),
                    const SizedBox(height: 24),
                    title,
                    const SizedBox(height: 24),
                    for (final (i, row) in rows.indexed)
                      enter(
                        i,
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SummaryRow(
                            icon: row.$1,
                            label: row.$2,
                            value: row.$3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: AppButton(
                  key: const Key('registration-done'),
                  label: 'Inizia',
                  expand: true,
                  onPressed: _finish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tell(String message) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.hard,
        ),
      );
  }
}

/// Checkbox dei Termini e della Privacy: il testo apre il foglio con le
/// condizioni, la spunta è ciò che il form pretende.
class _TermsRow extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;

  const _TermsRow({required this.accepted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          key: const Key('terms-checkbox'),
          value: accepted,
          onChanged: (value) => onChanged(value ?? false),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: GestureDetector(
            key: const Key('terms-open'),
            onTap: () => _showTerms(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: AppText.label,
                    color: c.textSecondary,
                    height: 1.35,
                  ),
                  children: [
                    const TextSpan(text: 'Accetto i '),
                    TextSpan(
                      text: 'Termini e Condizioni',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                    const TextSpan(text: ' e la '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Testo segnaposto: le condizioni reali le scrive chi è titolare del
  /// prodotto, non il codice.
  static void _showTerms(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Termini e Condizioni, Privacy Policy',
              style: TextStyle(
                fontSize: AppText.titleMedium,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _placeholder,
              style: TextStyle(
                fontSize: AppText.bodyMedium,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _placeholder =
      'Testo segnaposto. Qui vanno i Termini e le Condizioni e la Privacy '
      'Policy reali del servizio, con titolare del trattamento, base '
      'giuridica, dati raccolti, tempi di conservazione e recapiti.\n\n'
      'Nel frattempo è utile sapere che cosa fa l\'app: il profilo (nome, '
      'email, ID account, avatar) e i tuoi progressi di studio sono salvati '
      'solo su questo dispositivo, in memoria locale. Non viene inviato niente '
      'a server o a terzi e la password non viene conservata in chiaro: ne '
      'resta solo una derivata crittografica.';
}

/// L'avatar scelto, o le iniziali del nome, o la persona se non c'è niente.
class _AvatarCircle extends StatelessWidget {
  final String avatarId;
  final String name;
  final double size;

  const _AvatarCircle({
    super.key,
    required this.avatarId,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final trimmed = name.trim();
    Widget content;
    if (avatarId.isNotEmpty) {
      content = Icon(
        avatarIcon(avatarId),
        size: size * 0.44,
        color: c.textPrimary,
      );
    } else if (trimmed.isNotEmpty) {
      content = Text(
        initialsOf(trimmed),
        style: TextStyle(
          fontFamily: AppText.headingFont,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      );
    } else {
      content = Icon(
        Symbols.person_rounded,
        size: size * 0.44,
        color: c.textPrimary,
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.yellow,
        border: Border.all(color: c.accent, width: 4),
      ),
      child: content,
    );
  }
}

/// L'avatar grande al centro del primo passo, con la matita che dice che si
/// tocca.
class _AvatarButton extends StatelessWidget {
  final String avatarId;
  final String name;
  final bool open;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.avatarId,
    required this.name,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      expanded: open,
      label: 'Scegli il tuo avatar',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: const Key('registration-avatar'),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarCircle(avatarId: avatarId, name: name, size: 112),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                  border: Border.all(color: c.surface, width: 3),
                ),
                child: Icon(
                  open ? Icons.close_rounded : Icons.edit_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una riga del riepilogo: icona, etichetta e valore scelto.
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: c.accent),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppText.titleSmall,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spento nei test che aspettano `pumpAndSettle`: un'animazione che si ripete
/// per sempre non si esaurisce mai.
@visibleForTesting
bool registrationWaveEnabled = true;

/// La testata indaco di «Creazione profilo»: il bordo in basso ondulato, la
/// freccia per uscire e il titolo del passo al centro, che cambia in
/// dissolvenza.
///
/// Il bordo ondeggia piano (`WaveBottomClipper.phase`): si rifà solo il
/// tracciato del ritaglio, il contenuto sta in un `RepaintBoundary` e non si
/// ridisegna. Col movimento ridotto il bordo sta fermo.
class _StepHeader extends StatefulWidget {
  final String title;

  const _StepHeader({required this.title});

  @override
  State<_StepHeader> createState() => _StepHeaderState();
}

class _StepHeaderState extends State<_StepHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final WaveBottomClipper _clipper = WaveBottomClipper(phase: _wave);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context) || !registrationWaveEnabled) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final c = AppColors.of(context);
    return ClipPath(
      key: const Key('registration-header'),
      clipper: _clipper,
      child: RepaintBoundary(
        child: Container(
          width: double.infinity,
          color: c.headerBand,
          padding: const EdgeInsets.only(bottom: 52),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(color: c.onHeaderBand),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: AppMotion.duration(context, AppMotion.medium),
                    switchInCurve: AppMotion.standard,
                    switchOutCurve: AppMotion.standard,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.center,
                      children: [...previous, ?current],
                    ),
                    child: Semantics(
                      key: ValueKey(title),
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppText.headingFont,
                          fontSize: AppText.display,
                          fontWeight: FontWeight.w600,
                          color: c.onHeaderBand,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
