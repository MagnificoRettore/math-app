import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../data/search_index.dart';
import '../data/settings_store.dart';
import '../data/study_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../widgets/app_button.dart';
import '../widgets/illustration.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (_started) return;
    _started = true;
    setState(() {
      _failed = false;
    });

    final loadFuture = Future.wait([
      ContentRepository.instance.load(),
      LessonRepository.instance.load(),
      ProgressStore.instance.load(),
      AuthStore.instance.load(),
      SettingsStore.instance.load(),
      StudyStore.instance.load(),
    ]);
    final minSplash = Future<void>.delayed(const Duration(seconds: 2));
    await Future.wait([loadFuture, minSplash]);

    SearchIndex.instance.build(ContentRepository.instance.levels);

    if (!mounted) return;

    if (ContentRepository.instance.loadError != null ||
        LessonRepository.instance.loadError != null ||
        ProgressStore.instance.loadError != null ||
        AuthStore.instance.loadError != null ||
        SettingsStore.instance.loadError != null) {
      setState(() {
        _failed = true;
      });
      return;
    }

    _started = false;
    _goNext();
  }

  void _retry() {
    _started = false;
    _init();
  }

  void _goNext() {
    final destination = SettingsStore.instance.onboardingSeen
        ? const HomeScreen()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.splashTop, c.splashBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IllustrationView(AppIllustration.idea, width: 200),
                const SizedBox(height: 24),
                Text(
                  'Math App',
                  style: TextStyle(
                    fontFamily: AppText.headingFont,
                    fontSize: AppText.display,
                    fontWeight: FontWeight.w600,
                    color: c.onSplash,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_failed) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Non è stato possibile caricare i contenuti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppText.bodyMedium,
                      color: c.onSplash,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sul fondo indaco il bottone è giallo: l'indaco sparirebbe.
                  AppButton(
                    label: 'Riprova',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.secondary,
                    onPressed: _retry,
                  ),
                ] else
                  const SizedBox(height: 32),
                if (!_failed) ...[
                  const SizedBox(height: 24),
                  Lottie.asset(
                    'assets/animations/splash_loading.json',
                    // Piccolo: sopra c'è l'illustrazione, e insieme devono
                    // stare anche su un telefono basso.
                    width: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
