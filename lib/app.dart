import 'package:flutter/material.dart';

import '_perf_probe.dart';
import 'data/settings_store.dart';
import 'screens/customization_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_session_observer.dart';
import 'widgets/dismiss_keyboard.dart';

final GlobalKey<NavigatorState> _perfNav = GlobalKey<NavigatorState>();

Future<void> perfPushCustomization() async {
  _perfNav.currentState?.push(
    MaterialPageRoute(builder: (_) => const CustomizationScreen()),
  );
}

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final themeMode = SettingsStore.instance.themeMode;
        return MaterialApp(
          navigatorKey: kPerfProbe ? _perfNav : null,
          title: 'Matematica',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          themeAnimationStyle: AppTheme.transitionStyle,
          builder: (context, child) =>
              DismissKeyboard(child: AppSessionObserver(child: child!)),
          home: const SplashScreen(),
        );
      },
    );
  }
}
