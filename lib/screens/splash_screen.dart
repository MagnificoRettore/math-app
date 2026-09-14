import 'dart:async';

import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../data/search_index.dart';
import '../data/settings_store.dart';
import '../data/study_store.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF007AFF),
              Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 24),
                        const Text(
                          'Math App',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esercizi e lezioni di matematica',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
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
                              color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildRetry() {
    return Column(
      children: [
        const Text(
          'Non è stato possibile caricare i contenuti.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF007AFF),
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
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.calculate_outlined,
        size: 56,
        color: Color(0xFF007AFF),
      ),
    );
  }
}