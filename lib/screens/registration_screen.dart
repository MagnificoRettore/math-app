import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/auth_validators.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/google_button.dart';
import '../widgets/password_field.dart';
import '../widgets/strength_meter.dart';
import 'school_picker_screen.dart';

/// Creazione account.
///
/// Subito dopo si sceglie la scuola, come prima: è il livello che decide
/// lezioni, esercizi e consigli.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _accountIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _termsAccepted = false;
  bool _busy = false;

  /// Finché l'utente non scrive a mano nell'ID account, il campo segue
  /// l'email: il suggerimento è buono e nessuno lo scrive da solo.
  bool _accountIdTouched = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _accountIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Crea il tuo profilo',
              style: TextStyle(
                fontSize: AppText.hero,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subito dopo sceglierai la tua scuola per ricevere consigli su '
              'misura.',
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  _field(
                    controller: _nameController,
                    label: 'Nome e cognome',
                    textCapitalization: TextCapitalization.words,
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
                  const SizedBox(height: 12),
                  _field(
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
                  const SizedBox(height: 12),
                  PasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() {}),
                    validator: AuthValidators.passwordError,
                  ),
                  const SizedBox(height: 8),
                  StrengthMeter(password: _passwordController.text),
                  const SizedBox(height: 12),
                  PasswordField(
                    controller: _confirmController,
                    label: 'Conferma password',
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => AuthValidators.confirmError(
                      value,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _TermsRow(
                    accepted: _termsAccepted,
                    onChanged: (value) =>
                        setState(() => _termsAccepted = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: c.accent,
                textStyle: const TextStyle(
                  fontSize: AppText.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crea account'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: c.border, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Oppure registrati con',
                    style: TextStyle(
                      fontSize: AppText.label,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: c.border, height: 1)),
              ],
            ),
            const SizedBox(height: 12),
            GoogleButton(
              label: 'Registrati con Google',
              onTap: _continueWithGoogle,
            ),
            const SizedBox(height: 8),
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
      ),
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
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(
          fontSize: AppText.caption,
          color: c.textSecondary,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: c.textSecondary),
        filled: true,
        fillColor: c.surface,
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

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_termsAccepted) {
      _tell('Accetta i Termini e la Privacy Policy per continuare.');
      return;
    }
    setState(() => _busy = true);

    try {
      await AuthStore.instance.registerManual(
        name: _nameController.text,
        email: _emailController.text,
        accountId: _accountIdController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _tell(error.message);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SchoolPickerScreen(onboarding: true),
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    final user = await signInWithGoogleDemo(context);
    if (user == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SchoolPickerScreen(onboarding: true),
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
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                    const TextSpan(text: ' e la '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w700,
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
