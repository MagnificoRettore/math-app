import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text.dart';
import '../widgets/google_button.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'school_picker_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: c.background, actions: const []),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _WelcomeHero(),
            const SizedBox(height: 28),
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
              'Raccontaci quale scuola frequenti e ti proponiamo le lezioni '
              'guidate e gli esercizi più adatti a te.',
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GoogleButton(
              label: 'Continua con Google',
              onTap: () {
                return _continueWithGoogle(context);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
              style: AppTheme.wideButton,
              child: const Text('Registrati con email'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text(
                  'Hai già un account? Accedi',
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Il tuo profilo è salvato solo su questo dispositivo.',
                textAlign: TextAlign.center,
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

  Future<void> _continueWithGoogle(BuildContext context) async {
    final user = await signInWithGoogleDemo(context);
    if (user == null || !context.mounted) return;
    if (user.schoolLevelId.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SchoolPickerScreen(onboarding: true),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007AFF), Color(0xFF5C6BC0)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              size: 30,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Math App\nStudia con noi',
              style: TextStyle(
                fontSize: AppText.title,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
