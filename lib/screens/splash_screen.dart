import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../data/search_index.dart';
import '../data/settings_store.dart';
import '../data/study_store.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _loading = true;
  bool _failed = false;
  bool _started = false;

  rive.File? _riveFile;
  rive.RiveWidgetController? _riveController;

  @override
  void initState() {
    super.initState();
    _loadSplashRive();
    _init();
  }

  @override
  void dispose() {
    _riveController?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  bool get _riveEnabled {
    final binding = WidgetsBinding.instance;
    return !binding.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }

  Future<void> _loadSplashRive() async {
    if (!_riveEnabled) return;
    try {
      final file = await rive.File.asset(
        'assets/rive/rewards.riv',
        riveFactory: rive.Factory.flutter,
      );
      if (!mounted || file == null) return;
      setState(() {
        _riveFile = file;
        _riveController = rive.RiveWidgetController(file);
      });
    } catch (_) {
      // Fallback: resta l'icona statica.
    }
  }

  Future<void> _init() async {
    if (_started) return;
    _started = true;
    setState(() {
      _loading = true;
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

    SearchIndex.instance.build(
      ContentRepository.instance.levels,
      lessons: LessonRepository.instance.lessons,
    );

    if (!mounted) return;

    if (ContentRepository.instance.loadError != null ||
        LessonRepository.instance.loadError != null ||
        ProgressStore.instance.loadError != null ||
        AuthStore.instance.loadError != null ||
        SettingsStore.instance.loadError != null) {
      setState(() {
        _loading = false;
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 24),
                        Text(
                          'Math App',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: c.onSplash,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esercizi e lezioni di matematica',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.onSplash.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_failed)
                          _buildRetry()
                        else
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: c.onSplash.withValues(alpha: 0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
        );
      },
      child: _Logo(controller: _riveController),
    );
  }

  Widget _buildRetry() {
    final c = AppColors.of(context);
    return Column(
      children: [
        Text(
          'Non è stato possibile caricare i contenuti.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.onSplash),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: c.onSplash,
            foregroundColor: c.splashTop,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _loading ? null : _retry,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text(
            'Riprova',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final rive.RiveWidgetController? controller;

  const _Logo({this.controller});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final riveController = controller;
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: c.onSplash,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: riveController == null
            ? Icon(Icons.calculate_outlined, size: 56, color: c.splashTop)
            : Padding(
                padding: const EdgeInsets.all(8),
                child: rive.RiveWidget(
                  controller: riveController,
                  fit: rive.Fit.contain,
                ),
              ),
      ),
    );
  }
}
