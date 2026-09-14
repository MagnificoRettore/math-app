import 'package:flutter/material.dart';

import 'data/settings_store.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_session_observer.dart';

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final themeMode = SettingsStore.instance.themeMode;
        return MaterialApp(
          title: 'Matematica',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          builder: (context, child) => AppSessionObserver(child: child!),
          home: const SplashScreen(),
        );
      },
    );
  }
}