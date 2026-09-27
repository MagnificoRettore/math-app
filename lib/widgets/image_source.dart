import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Immagine di un riquadro: asset bundled oppure URL, con placeholder
/// uniforme quando il file manca o non è ancora caricato.
class ImageSource extends StatelessWidget {
  final String source;
  final String caption;

  const ImageSource({super.key, required this.source, this.caption = ''});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isUrl = source.startsWith('http://') || source.startsWith('https://');
    const fit = BoxFit.cover;
    final placeholder = Container(
      height: 180,
      width: double.infinity,
      color: c.accentSoft,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 44, color: c.textSecondary),
    );
    final image = isUrl
        ? Image.network(
            source,
            fit: fit,
            errorBuilder: (_, _, _) => placeholder,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
          )
        : Image.asset(source, fit: fit, errorBuilder: (_, _, _) => placeholder);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(child: SizedBox(height: 200, child: image)),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ),
      ],
    );
  }
}
