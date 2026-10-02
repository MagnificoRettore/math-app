import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/auth_validators.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/profile_avatar.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'school_picker_screen.dart';
import 'welcome_screen.dart';

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
              fontSize: 20,
              fontWeight: FontWeight.w700,
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
            style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('profile-guest-login'),
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: c.accent,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Accedi'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('profile-guest-register'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegistrationScreen())),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: c.border),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text('Registrati', style: TextStyle(color: c.textPrimary)),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onCreate,
            child: Text(
              'Scopri come ospite',
              style: TextStyle(
                fontSize: 15,
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
            ProfileAvatar(
              user: preview,
              size: 68,
              color: levelColor,
              plateColor: levelColor.withValues(alpha: 0.14),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${preview.accountId}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _AuthChip(
              label: user.authMethod == AuthMethod.google ? 'Google' : 'Email',
              icon: user.authMethod == AuthMethod.google
                  ? Icons.g_mobiledata
                  : Icons.alternate_email,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    level == null ? Icons.help_outline : _iconFor(level.icon),
                    size: 16,
                    color: levelColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    level?.title ?? 'Scuola non impostata',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: levelColor,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _field(
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
                const SizedBox(height: 12),
                _field(
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
                const SizedBox(height: 12),
                _ReadOnlyField(label: 'Email', value: user.email),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ProfileAvatar(
                      user: preview,
                      size: 44,
                      color: levelColor,
                      plateColor: levelColor.withValues(alpha: 0.14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _avatarId.isEmpty
                            ? 'Foto profilo: iniziali'
                            : 'Foto profilo: ${_avatarId.replaceAll('_rounded', '')}',
                        style: TextStyle(fontSize: 14, color: c.textSecondary),
                      ),
                    ),
                    TextButton(
                      key: const Key('profile-change-avatar'),
                      onPressed: _saving ? null : _pickAvatar,
                      child: const Text('Cambia foto'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('profile-save'),
                  onPressed: _saving || !_dirty ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: c.accent,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salva modifiche'),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(fontSize: 12, color: c.textSecondary),
        filled: true,
        fillColor: c.background,
        labelStyle: TextStyle(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
      ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              AvatarPicker(
                value: _avatarId,
                onChanged: (value) => Navigator.of(context).pop(value),
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
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

  IconData _iconFor(String name) {
    switch (name) {
      case 'school':
        return Icons.school_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
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
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Identifica l’account, non si modifica',
        helperStyle: TextStyle(fontSize: 12, color: c.textSecondary),
        filled: true,
        fillColor: c.background,
        labelStyle: TextStyle(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
      ),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, color: c.textSecondary),
      ),
    );
  }
}

class _AuthChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AuthChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.accent,
            ),
          ),
        ],
      ),
    );
  }
}
