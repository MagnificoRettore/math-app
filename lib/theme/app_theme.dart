import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../theme/app_text.dart';
import 'app_colors.dart';
import 'chart_palette.dart';

class AppTheme {
  /// La base dei campi dei form: bordo da 3 lilla, indaco col fuoco, rosso
  /// nell'errore, raggio 14 e fondo bianco, come nel design. Non è
  /// l'`inputDecorationTheme` perché i campi del dialog di Google restano
  /// sottolineati; ogni campo aggiunge etichetta e icone con `copyWith`.
  static InputDecoration fieldDecoration(AppPalette c) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 3),
    );
    return InputDecoration(
      filled: true,
      fillColor: c.surface,
      labelStyle: TextStyle(color: c.textSecondary),
      floatingLabelStyle: TextStyle(
        color: c.accent,
        fontWeight: FontWeight.w800,
      ),
      helperStyle: TextStyle(fontSize: AppText.caption, color: c.textSecondary),
      border: border(c.border),
      enabledBorder: border(c.border),
      focusedBorder: border(c.accent),
      errorBorder: border(c.hard),
      focusedErrorBorder: border(c.hard),
    );
  }

  /// Il tema della toolbar delle lezioni: FAB e pannello indaco con le icone
  /// bianche, come la barra di avanzamento della lezione.
  ///
  /// È un tema di `material_3_expressive` e non un `ThemeData`: il pacchetto
  /// legge i colori dal `Theme` di `material_ui`, non da quello di Flutter,
  /// quindi senza questo la toolbar resta sul lilla di default di Material 3.
  /// Lo schema nasce dall'indaco dell'app e cambia solo i colori del FAB.
  static final M3EThemeData lessonToolbar = M3EThemeData(
    colorScheme: M3EColorScheme.fromSeed(AppPalette.light.accent).copyWith(
      primaryContainer: AppPalette.light.accent,
      onPrimaryContainer: AppPalette.light.onHeaderBand,
    ),
  );

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
