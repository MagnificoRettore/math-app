import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/auth_validators.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../theme/app_text.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/shake.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'school_picker_screen.dart';
import 'welcome_screen.dart';
import '../widgets/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AuthStore.instance,
          builder: (context, _) {
            final user = AuthStore.instance.currentUser;
            if (user == null) {
              return _GuestProfile(onCreate: () => _openWelcome(context));
            }
            return _ProfileContent(user: user);
          },
        ),
      ),
    );
  }

  void _openWelcome(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
}

class _GuestProfile extends StatelessWidget {
  final VoidCallback onCreate;

  const _GuestProfile({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, size: 44, color: c.accent),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Nessun profilo',
            style: TextStyle(
              fontFamily: AppText.headingFont,
              fontSize: AppText.titleLarge,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Accedi per ritrovare i tuoi progressi, oppure crea un profilo per '
            'ricevere lezioni ed esercizi consigliati per la tua scuola.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppText.bodyMedium,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          key: const Key('profile-guest-login'),
          label: 'Accedi',
          expand: true,
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
        const SizedBox(height: 12),
        AppButton(
          key: const Key('profile-guest-register'),
          label: 'Registrati',
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegistrationScreen())),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onCreate,
            child: Text(
              'Scopri come ospite',
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Profilo dell'utente connesso: intestazione, modifica dei campi, scuola e
/// uscita.
///
/// I campi si salvano con «Salva modifiche» e non a ogni lettera: lo store
/// scrive in memoria locale e una scrittura per keystroke non serve a niente.
class _ProfileContent extends StatefulWidget {
  final UserProfile user;

  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _accountIdController;
  final _shakes = FieldShakes();
  late String _avatarId;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _accountIdController = TextEditingController(text: widget.user.accountId);
    _avatarId = widget.user.avatarId;
  }

  @override
  void didUpdateWidget(covariant _ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Finché l'utente non ha toccato niente, il campo segue il profilo: dopo
    // un salvataggio o un cambio di scuola non deve perdere quello che ha
    // scritto.
    if (_dirty) return;
    _nameController.text = widget.user.name;
    _accountIdController.text = widget.user.accountId;
    _avatarId = widget.user.avatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = widget.user;
    final level = ContentRepository.instance.levelById(user.schoolLevelId);
    final levelColor = level == null ? c.accent : _colorFor(c, level.icon);
    final preview = user.copyWith(
      name: _nameController.text.trim().isEmpty
          ? user.name
          : _nameController.text.trim(),
      accountId: _accountIdController.text.trim(),
      avatarId: _avatarId,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Cambia foto profilo',
              child: GestureDetector(
                key: const Key('profile-change-avatar'),
                behavior: HitTestBehavior.opaque,
                onTap: _saving ? null : _pickAvatar,
                child: ProfileAvatar(
                  user: preview,
                  size: 68,
                  color: levelColor,
                  plateColor: levelColor.withValues(alpha: 0.14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppText.headingFont,
                      fontSize: AppText.title,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${preview.accountId}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppText.bodyMedium,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppText.bodyMedium,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Modifica profilo',
                  style: TextStyle(
                    fontSize: AppText.titleSmall,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ShakeWidget(
                  trigger: _shakes.of(_nameController),
                  child: _field(
                    controller: _nameController,
                    label: 'Nome e cognome',
                    onChanged: _markDirty,
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
                const SizedBox(height: 12),
                ShakeWidget(
                  trigger: _shakes.of(_accountIdController),
                  child: _field(
                    controller: _accountIdController,
                    label: 'ID account',
                    autocorrect: false,
                    helperText: 'Come ti trovano gli altri: 3-20 caratteri',
                    onChanged: _markDirty,
                    validator: (value) => AuthValidators.accountIdError(
                      value,
                      taken: AuthStore.instance.accountIdsInUse(
                        exceptAccountId: widget.user.accountId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(label: 'Email', value: user.email),
                const SizedBox(height: 16),
                AppButton(
                  key: const Key('profile-save'),
                  label: 'Salva modifiche',
                  onPressed: _dirty ? _save : null,
                  busy: _saving,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SchoolPickerScreen(initialLevelId: user.schoolLevelId),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: c.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cambia la tua scuola',
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: c.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => _signOut(context),
          color: c.surface,
          child: Row(
            children: [
              Icon(Icons.logout, color: c.hard),
              const SizedBox(width: 12),
              Text(
                'Esci',
                style: TextStyle(
                  fontSize: AppText.bodyLarge,
                  fontWeight: FontWeight.w500,
                  color: c.hard,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _markDirty(String _) {
    if (!_dirty) setState(() => _dirty = true);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    ValueChanged<String>? onChanged,
    bool autocorrect = true,
    String? helperText,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      autocorrect: autocorrect,
      onChanged: onChanged,
      validator: validator,
      decoration: AppTheme.fieldDecoration(c)
          .copyWith(labelText: label, helperText: helperText),
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scegli la foto profilo',
                style: TextStyle(
                  fontSize: AppText.titleMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Il foglio si chiude dopo il rimbalzo della scelta, altrimenti
              // l'animazione non si vedrebbe; subito col movimento ridotto.
              AvatarPicker(
                value: _avatarId,
                onChanged: (value) async {
                  final navigator = Navigator.of(context);
                  await Future<void>.delayed(
                    AppMotion.duration(context, AppMotion.slow),
                  );
                  if (navigator.mounted) navigator.pop(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _avatarId = picked;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(
        () => _shakes.shakeEmpty([_nameController, _accountIdController]),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthStore.instance.updateProfile(
        name: _nameController.text,
        accountId: _accountIdController.text,
        avatarId: _avatarId,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _tell(error.message, error: true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    _tell('Modifiche salvate');
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthStore.instance.signOut();
    // La scuola in visita era di quest'utente: chi entra dopo deve trovare la
    // propria, non quella che il precedente stava sfogliando.
    BrowseStore.instance.reset();
  }

  void _tell(String message, {bool error = false}) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? c.hard : null,
        ),
      );
  }

  Color _colorFor(AppPalette c, String name) {
    switch (name) {
      case 'school':
        return c.accent;
      case 'account_balance':
        return c.purple;
      case 'menu_book':
        return c.teal;
      default:
        return c.accent;
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InputDecorator(
      decoration: AppTheme.fieldDecoration(c).copyWith(
        labelText: label,
        helperText: 'Identifica l’account, non si modifica',
      ),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: AppText.bodyLarge, color: c.textSecondary),
      ),
    );
  }
}
