import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'app_colors.dart';
import 'chart_palette.dart';

class AppTheme {
  /// Durata e curva del passaggio fra tema chiaro e tema scuro.
  ///
  /// Flutter di default anima il tema con 200ms lineari, che si leggono come un
  /// lampo. Qui il passaggio dura 200ms con `easeOutCubic`: parte subito e
  /// arriva dolce, senza la coda lunga di `easeInOutCubicEmphasized`, che a
  /// fine passaggio sembrava bloccarsi mentre l'icona era già ferma. Sono i 320ms
  /// dell'animazione sole/luna (`ThemeToggle._transition`) meno i 40ms di
  /// ritardo, così i colori arrivano 80ms **prima** dell'icona: due viaggi che
  /// finiscono insieme si leggono come un unico scatto.
  static const AnimationStyle transitionStyle = AnimationStyle(
    duration: Duration(milliseconds: 200),
    reverseDuration: Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
  );

  static final ThemeData light = _build(Brightness.light, AppPalette.light);
  static final ThemeData dark = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final dark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: palette.accent,
            brightness: brightness,
            surface: palette.surface,
          ).copyWith(
            // `fromSeed` ricava il primary dalla **tonalità 40** del seme,
            // quindi dall'indaco di marca esce un grigio-viola: il primary si
            // dichiara, e dal seme resta tutta la scala intorno (secondary,
            // surface, surfaceContainer). Il terziario è il rosa scuro delle
            // sezioni «da ripassare», e come il primary non viene dal seme:
            // `AppPalette.danger` ne resta l'unica sorgente.
            primary: palette.accent,
            onPrimary: dark ? palette.accentSoft : Colors.white,
            primaryContainer: palette.accentSoft,
            onPrimaryContainer: palette.textPrimary,
            tertiary: palette.danger,
            onTertiary: Colors.white,
            tertiaryContainer: palette.danger.withValues(
              alpha: dark ? 0.22 : 0.12,
            ),
          ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: AppText.headline,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.accentSoft,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: AppText.micro, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 0.8,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: palette.accent,
        labelColor: palette.textPrimary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppText.bodyLarge,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: AppText.bodyLarge),
      ),
      extensions: [palette, ChartPalette.of(palette)],
    );
  }
}
