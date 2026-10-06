// Genera l'icona dell'app per Android, iOS e macOS: la «π» gialla con il
// gradino `yellowDeep` su `headerBand`, la stessa di `web/icons`.
//
//   flutter test tool/generate_app_icons_test.dart
//
// - Android: `mipmap-*/ic_launcher.png` (quadrato arrotondato) e, per le
//   versioni con icone adattive, `ic_launcher_foreground.png` (la sola «π»
//   nella zona sicura) con il colore di fondo in `values/ic_launcher_background.xml`.
// - iOS: quadrati a piena pagina e **senza canale alpha** (l'App Store rifiuta
//   le icone con trasparenza); il sistema arrotonda gli angoli.
// - macOS: quadrato arrotondato con alpha.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_colors.dart';

/// La «π» in coordinate 512×512, come nell'icona web: barra e due gambe.
const _glyph = [
  ui.Rect.fromLTRB(158, 185, 354, 211),
  ui.Rect.fromLTRB(190, 185, 221, 362),
  ui.Rect.fromLTRB(291, 185, 322, 362),
];

/// Quanto scende il gradino sotto la «π».
const _depth = 25.0;

/// Disegna l'icona in un quadrato di lato [size].
///
/// [rounded] arrotonda gli angoli del fondo; [background] lo disegna;
/// [scale] ingrandisce o rimpicciolisce la «π» attorno al centro.
void _paint(
  ui.Canvas canvas,
  double size, {
  required bool background,
  bool rounded = false,
  double scale = 1,
}) {
  final palette = AppPalette.light;
  final k = size / 512;
  if (background) {
    final paint = ui.Paint()..color = palette.headerBand;
    if (rounded) {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(0, 0, size, size),
          ui.Radius.circular(size * 0.2),
        ),
        paint,
      );
    } else {
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, size, size), paint);
    }
  }
  canvas.save();
  canvas.translate(size / 2, size / 2);
  canvas.scale(scale * k);
  canvas.translate(-256, -256);
  final deep = ui.Paint()..color = palette.yellowDeep;
  final face = ui.Paint()..color = palette.yellow;
  for (final r in _glyph) {
    canvas.drawRect(r.shift(const ui.Offset(0, _depth)), deep);
  }
  for (final r in _glyph) {
    canvas.drawRect(r, face);
  }
  canvas.restore();
}

Future<ui.Image> _render(
  int size, {
  required bool background,
  bool rounded = false,
  double scale = 1,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  _paint(
    canvas,
    size.toDouble(),
    background: background,
    rounded: rounded,
    scale: scale,
  );
  return recorder.endRecording().toImage(size, size);
}

/// PNG con alpha, dall'encoder di Flutter.
Future<Uint8List> _pngRgba(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// PNG **senza** alpha (RGB, 8 bit): scritto a mano perché l'encoder di
/// Flutter dà sempre RGBA, e per iOS un canale alpha, anche tutto opaco, è un
/// motivo di rifiuto.
Future<Uint8List> _pngRgb(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final w = image.width, h = image.height;
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // filtro «nessuno»
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      raw
        ..addByte(rgba[i])
        ..addByte(rgba[i + 1])
        ..addByte(rgba[i + 2]);
    }
  }
  final out = BytesBuilder()
    ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
    ..add(
      _chunk(
        'IHDR',
        (ByteData(13)
              ..setUint32(0, w)
              ..setUint32(4, h)
              ..setUint8(8, 8)
              ..setUint8(9, 2))
            .buffer
            .asUint8List(),
      ),
    )
    ..add(_chunk('IDAT', Uint8List.fromList(zlib.encode(raw.toBytes()))))
    ..add(_chunk('IEND', Uint8List(0)));
  return out.toBytes();
}

Uint8List _chunk(String type, Uint8List body) {
  final typeBytes = type.codeUnits;
  final crcInput = Uint8List.fromList([...typeBytes, ...body]);
  final out = ByteData(12 + body.length);
  out.setUint32(0, body.length);
  for (var i = 0; i < 4; i++) {
    out.setUint8(4 + i, typeBytes[i]);
  }
  for (var i = 0; i < body.length; i++) {
    out.setUint8(8 + i, body[i]);
  }
  out.setUint32(8 + body.length, _crc32(crcInput));
  return out.buffer.asUint8List();
}

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(Uint8List data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

void _write(String path, Uint8List bytes) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('icone di Android, iOS e macOS', (tester) async {
    await tester.runAsync(() async {
      // Android: lato in px per densità, 48 dp per il quadrato arrotondato e
      // 108 dp per il livello adattivo.
      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final entry in densities.entries) {
        final legacy = await _render(
          (48 * entry.value).round(),
          background: true,
          rounded: true,
        );
        _write(
          'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
          await _pngRgba(legacy),
        );
        final foreground = await _render(
          (108 * entry.value).round(),
          background: false,
          scale: 1.2,
        );
        _write(
          'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_foreground.png',
          await _pngRgba(foreground),
        );
      }
      _write(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
        Uint8List.fromList(
          '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
              .codeUnits,
        ),
      );
      _write(
        'android/app/src/main/res/values/ic_launcher_background.xml',
        Uint8List.fromList(
          '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#2B1A6B</color>
</resources>
'''
              .codeUnits,
        ),
      );

      // iOS: i lati in px dei file che `Contents.json` già elenca.
      const ios = {
        '20x20@1x': 20,
        '20x20@2x': 40,
        '20x20@3x': 60,
        '29x29@1x': 29,
        '29x29@2x': 58,
        '29x29@3x': 87,
        '40x40@1x': 40,
        '40x40@2x': 80,
        '40x40@3x': 120,
        '60x60@2x': 120,
        '60x60@3x': 180,
        '76x76@1x': 76,
        '76x76@2x': 152,
        '83.5x83.5@2x': 167,
        '1024x1024@1x': 1024,
      };
      for (final entry in ios.entries) {
        final image = await _render(entry.value, background: true);
        _write(
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-${entry.key}.png',
          await _pngRgb(image),
        );
      }

      // macOS: quadrato arrotondato, con alpha.
      for (final size in const [16, 32, 64, 128, 256, 512, 1024]) {
        final image = await _render(size, background: true, rounded: true);
        _write(
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
          await _pngRgba(image),
        );
      }
    });
  });
}
