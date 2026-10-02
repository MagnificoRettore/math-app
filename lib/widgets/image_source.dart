import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Immagine di un riquadro: asset bundled oppure URL, con placeholder
/// uniforme quando il file manca o non è ancora caricato.
///
/// Di default occupa tutta la larghezza disponibile entro una banda fissa
/// (200px, `BoxFit.cover`): è il modo delle tracce degli esercizi, che non
/// hanno un contenitore in cui allineare. Con [naturalSize] prende invece la
/// dimensione naturale, limitata a [maxHeight] e alla larghezza offerta dal
/// genitore: tocca al chiamante posizionarla.
class ImageSource extends StatelessWidget {
  static const double maxHeight = 240;
  static const double _placeholderWidth = 240;
  static const double _placeholderHeight = 180;

  final String source;
  final bool naturalSize;

  const ImageSource({
    super.key,
    required this.source,
    this.naturalSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isUrl = source.startsWith('http://') || source.startsWith('https://');
    final fit = naturalSize ? BoxFit.contain : BoxFit.cover;

    Widget placeholder() => Container(
      height: naturalSize ? _placeholderHeight : null,
      width: naturalSize ? _placeholderWidth : double.infinity,
      color: c.accentSoft,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 44, color: c.textSecondary),
    );

    final image = isUrl
        ? Image.network(
            source,
            fit: fit,
            errorBuilder: (_, _, _) => placeholder(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder(),
          )
        : Image.asset(
            source,
            fit: fit,
            errorBuilder: (_, _, _) => placeholder(),
          );

    if (naturalSize) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxHeight),
            child: image,
          ),
        ],
      );
    }

    return ClipRect(child: SizedBox(height: 200, child: image));
  }
}
