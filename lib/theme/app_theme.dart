import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'app_colors.dart';
import 'chart_palette.dart';

class AppTheme {
  /// Il bottone principale a tutta riga delle schermate di accesso, profilo e
  /// onboarding. Non è il `filledButtonTheme`: `Size.fromHeight` allarga a
  /// tutta riga, e «Completa la lezione», «Riprendi» o il dialog di Google non
  /// lo sono. Il colore è il `primary` del tema, cioè `accent`.
  static final ButtonStyle wideButton = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    // La famiglia va scritta: un `textStyle` del bottone sostituisce quello
    // del tema e non eredita il font.
    textStyle: const TextStyle(
      fontFamily: AppText.headingFont,
      fontSize: AppText.titleSmall,
      fontWeight: FontWeight.w600,
    ),
  );

  /// La base dei campi dei form: riquadro a 14, bordo e testi del tema. Non è
  /// l'`inputDecorationTheme` perché i campi del dialog di Google restano
  /// sottolineati; ogni campo aggiunge etichetta e icone con `copyWith`.
  static InputDecoration fieldDecoration(AppPalette c, {required Color fill}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.border),
    );
    return InputDecoration(
      filled: true,
      fillColor: fill,
      labelStyle: TextStyle(color: c.textSecondary),
      helperStyle: TextStyle(fontSize: AppText.caption, color: c.textSecondary),
      border: border,
      enabledBorder: border,
    );
  }

  /// Il tema dell'app, uno solo e chiaro come il design.
  static final ThemeData light = _build(AppPalette.light);

  static ThemeData _build(AppPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppText.bodyFont,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: palette.accent,
            surface: palette.surface,
          ).copyWith(
            // `fromSeed` ricava il primary dalla **tonalità 40** del seme,
            // quindi dall'indaco del design uscirebbe un altro viola: il
            // primary si dichiara, e dal seme resta la scala intorno. Il
            // secondario è il giallo del design, con l'inchiostro sopra; il
            // terziario il rosa scuro delle sezioni «da ripassare».
            primary: palette.accent,
            onPrimary: Colors.white,
            primaryContainer: palette.accentSoft,
            onPrimaryContainer: palette.textPrimary,
            secondary: palette.yellow,
            onSecondary: palette.textPrimary,
            tertiary: palette.danger,
            onTertiary: Colors.white,
            tertiaryContainer: palette.danger.withValues(alpha: 0.12),
          ),
    );

    // Titoli in Fredoka, il resto in Nunito: `fontFamily` del tema vale per
    // tutti gli stili, quindi i titoli si rimettono a mano.
    TextStyle? heading(TextStyle? style) =>
        style?.copyWith(fontFamily: AppText.headingFont);
    final textTheme = base.textTheme
        .copyWith(
          displayLarge: heading(base.textTheme.displayLarge),
          displayMedium: heading(base.textTheme.displayMedium),
          displaySmall: heading(base.textTheme.displaySmall),
          headlineLarge: heading(base.textTheme.headlineLarge),
          headlineMedium: heading(base.textTheme.headlineMedium),
          headlineSmall: heading(base.textTheme.headlineSmall),
          titleLarge: heading(base.textTheme.titleLarge),
          labelLarge: heading(base.textTheme.labelLarge),
        )
        .apply(
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        );

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppText.headingFont,
          color: palette.textPrimary,
          fontSize: AppText.headline,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.accentSoft,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: AppText.micro, fontWeight: FontWeight.w700),
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
        contentTextStyle: const TextStyle(
          fontFamily: AppText.bodyFont,
          color: Colors.white,
        ),
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
          fontWeight: FontWeight.w700,
          fontSize: AppText.bodyLarge,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: AppText.bodyLarge),
      ),
      extensions: [palette, ChartPalette.of(palette)],
    );
  }
}
