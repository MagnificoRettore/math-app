import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'home_screen.dart';
import '../widgets/app_button.dart';
import '../widgets/illustration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  /// Una illustrazione del design per slide: il laptop per gli esercizi,
  /// l'albero per la scuola, il razzo per la serie.
  static const List<({AppIllustration illustration, String title, String body})>
  _slides = [
    (
      illustration: AppIllustration.lezione,
      title: 'Esercizi risolti passo passo',
      body:
          'Ogni esercizio mostra le formule chiave, i suggerimenti e la '
          'soluzione completa per imparare davvero.',
    ),
    (
      illustration: AppIllustration.albero,
      title: 'Studia per la tua scuola',
      body:
          'Scegli Scuola Media, Superiore o Università: ricevi lezioni ed '
          'esercizi consigliati su misura per te.',
    ),
    (
      illustration: AppIllustration.razzo,
      title: 'Costruisci una serie',
      body:
          'Allenati ogni giorno: raggiungi gli obiettivi di 5 esercizi e '
          '10 minuti e mantieni viva la tua serie.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SettingsStore.instance.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _skip() async {
    await _finish();
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const slides = _slides;
    final isLast = _page >= slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      isLast ? '' : 'Salta',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.bodyMedium,
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? c.accent : c.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [for (final slide in slides) _buildSlide(slide)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppButton(
                label: isLast ? 'Inizia' : 'Avanti',
                onPressed: _next,
                expand: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(
    ({AppIllustration illustration, String title, String body}) slide,
  ) {
    final c = AppColors.of(context);
    // Scorre se lo schermo è basso: l'illustrazione da sola è alta 264.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IllustrationView(slide.illustration, width: 220),
            const SizedBox(height: 28),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.headline,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              slide.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
