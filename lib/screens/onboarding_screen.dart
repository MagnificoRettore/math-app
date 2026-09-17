import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static List<({IconData icon, Color color, String title, String body})>
  _slides(AppPalette c) => [
    (
      icon: Icons.calculate_outlined,
      color: c.accent,
      title: 'Esercizi risolti passo passo',
      body:
          'Ogni esercizio mostra le formule chiave, i suggerimenti e la '
          'soluzione completa per imparare davvero.',
    ),
    (
      icon: Icons.school_outlined,
      color: c.indigo,
      title: 'Studia per la tua scuola',
      body:
          'Scegli Scuola Media, Superiore o Università: ricevi lezioni ed '
          'esercizi consigliati su misura per te.',
    ),
    (
      icon: Icons.local_fire_department,
      color: c.medium,
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
    final slides = _slides(AppColors.of(context));
    if (_page >= slides.length - 1) {
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
    final slides = _slides(c);
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
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
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
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: c.accent,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(isLast ? 'Inizia' : 'Avanti'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(
    ({IconData icon, Color color, String title, String body}) slide,
  ) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(slide.icon, color: slide.color, size: 60),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
