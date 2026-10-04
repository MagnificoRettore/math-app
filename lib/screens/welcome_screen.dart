import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/google_button.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'school_picker_screen.dart';
import '../widgets/app_button.dart';

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
                fontFamily: AppText.headingFont,
                fontSize: AppText.hero,
                fontWeight: FontWeight.w600,
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
            AppButton(
              label: 'Registrati con email',
              expand: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
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

/// La testata di «Creazione profilo» del design: indaco con il bordo in basso
/// ondulato, una tessera gialla con l'icona e il titolo bianco.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipPath(
      key: const Key('welcome-hero'),
      clipper: const _WaveBottom(),
      child: Container(
        color: c.headerBand,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.yellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.calculate_outlined,
                size: 30,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Math App\nStudia con noi',
                style: TextStyle(
                  fontFamily: AppText.headingFont,
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w600,
                  color: c.onHeaderBand,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il bordo inferiore ondulato della testata del design: lo stesso tracciato
/// della tavola (390×232), scalato sulla misura del riquadro, con gli angoli
/// in alto arrotondati come le card.
class _WaveBottom extends CustomClipper<Path> {
  const _WaveBottom();

  @override
  Path getClip(Size size) {
    double x(double v) => v / 390 * size.width;
    double y(double v) => v / 232 * size.height;
    const r = 22.0;
    return Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, y(170))
      ..cubicTo(x(340), y(200), x(330), y(150), x(285), y(180))
      ..cubicTo(x(245), y(206), x(230), y(232), x(195), y(232))
      ..cubicTo(x(160), y(232), x(145), y(206), x(105), y(180))
      ..cubicTo(x(60), y(150), x(50), y(200), 0, y(170))
      ..close();
  }

  @override
  bool shouldReclip(_WaveBottom oldClipper) => false;
}
