import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_text.dart';
import 'package:math_app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('la scala dei caratteri', () {
    test('la gerarchia va dal più piccolo al più grande', () {
      // Se uno slot viene spostato sotto un altro la scala smette di dire
      // quale ruolo è più importante, e i titoli finiscono più piccoli del
      // corpo. Il test non dice quanto: dice solo l'ordine.
      expect(AppText.micro, lessThan(AppText.caption));
      expect(AppText.caption, lessThan(AppText.labelSmall));
      expect(AppText.labelSmall, lessThan(AppText.label));
      expect(AppText.label, lessThan(AppText.bodySmall));
      expect(AppText.bodySmall, lessThan(AppText.bodyMedium));
      expect(AppText.bodyMedium, lessThan(AppText.bodyLarge));
      expect(AppText.bodyLarge, lessThan(AppText.titleSmall));
      expect(AppText.titleSmall, lessThan(AppText.titleMedium));
      expect(AppText.titleMedium, lessThan(AppText.titleLarge));
      expect(AppText.titleLarge, lessThan(AppText.title));
      expect(AppText.title, lessThan(AppText.headline));
      expect(AppText.headline, lessThan(AppText.hero));
      expect(AppText.hero, lessThan(AppText.display));
    });

    test('il documento delle lezioni sta dentro la scala della UI', () {
      expect(AppText.docBody, greaterThan(AppText.bodyMedium));
      expect(AppText.docBody, lessThan(AppText.titleMedium));
      expect(AppText.docHeading, greaterThan(AppText.docBody));
      expect(AppText.docTitle, greaterThan(AppText.docHeading));
    });

    test('il titolo delle AppBar è `headline`, in Fredoka', () {
      final style = AppTheme.light.appBarTheme.titleTextStyle;
      expect(style?.fontSize, AppText.headline);
      expect(style?.fontFamily, AppText.headingFont);
    });

    test('il testo è in Nunito e i titoli in Fredoka', () {
      final text = AppTheme.light.textTheme;
      expect(text.bodyMedium?.fontFamily, AppText.bodyFont);
      expect(text.titleLarge?.fontFamily, AppText.headingFont);
      expect(text.labelLarge?.fontFamily, AppText.headingFont);
    });
  });
}
