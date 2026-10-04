import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text.dart';
import '../widgets/app_card.dart';
import '../widgets/google_button.dart';
import '../widgets/password_field.dart';
import 'registration_screen.dart';
import 'school_picker_screen.dart';
import '../widgets/app_button.dart';

/// Pagina di accesso.
///
/// Card centrale con i campi, il pulsante primario, il separatore e il
/// pulsante Google sotto: tutto in una colonna, perché l'app è solo portrait e
/// due colonne su schermi stretti si leggono male.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
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
              'Bentornato',
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.hero,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accedi col tuo ID account o con la tua email.',
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _identifierController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.username],
                      decoration: AppTheme.fieldDecoration(c).copyWith(
                        labelText: 'Email o ID account',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: c.textSecondary,
                        ),
                      ),
                      validator: (value) => (value?.trim() ?? '').isEmpty
                          ? 'Scrivi il tuo ID account o la tua email'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _passwordController,
                      label: 'Password',
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Scrivi la password'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorLine(message: _error!),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Accedi',
                      onPressed: _submit,
                      busy: _busy,
                      expand: true,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : _forgotPassword,
                        child: Text(
                          'Password dimenticata?',
                          style: TextStyle(
                            fontSize: AppText.bodyMedium,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OrSeparator(label: 'Oppure accedi con'),
            const SizedBox(height: 12),
            GoogleButton(
              label: 'Accedi con Google',
              onTap: _continueWithGoogle,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    color: c.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Non hai un account? '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: _busy ? null : _openRegistration,
                        child: Text(
                          'Registrati',
                          style: TextStyle(
                            fontSize: AppText.bodyLarge,
                            fontWeight: FontWeight.w600,
                            color: c.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Continua come ospite',
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await AuthStore.instance.signIn(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (result != SignInResult.success) {
      setState(() {
        _busy = false;
        _error = result.message;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _continueWithGoogle() async {
    final user = await signInWithGoogleDemo(context);
    if (user == null || !mounted) return;
    if (user.schoolLevelId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SchoolPickerScreen(onboarding: true),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _openRegistration() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
  }

  /// Non c'è server e non c'è email: il recupero è impossibile, e dirlo è
  /// meglio di un form che non manda niente.
  void _forgotPassword() {
    final c = AppColors.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password dimenticata'),
        content: Text(
          'Il profilo è salvato solo su questo dispositivo, quindi non c\'è '
          'un server a cui chiedere una nuova password.\n\n'
          'Se ricordi l\'ID account e la password, accedi. Altrimenti puoi '
          'tornare indietro e creare un account nuovo.',
          style: TextStyle(
            fontSize: AppText.bodyMedium,
            color: c.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }
}

/// Riga d'errore sotto i campi: il colore viene dalla palette, mai da una
/// costante scritta a mano.
class _ErrorLine extends StatelessWidget {
  final String message;

  const _ErrorLine({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: c.hard),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: AppText.label,
              color: c.hard,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
