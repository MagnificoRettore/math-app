import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_session_observer.dart';
import 'widgets/dismiss_keyboard.dart';

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matematica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          DismissKeyboard(child: AppSessionObserver(child: child!)),
      home: const SplashScreen(),
    );
  }
}
