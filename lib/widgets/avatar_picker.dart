import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'profile_avatar.dart';

/// Griglia degli avatar proposti, più il pulsante per tornare alle iniziali.
///
/// Il valore è il **nome** del simbolo; la stringa vuota significa iniziali,
/// ed è quello che fa «Rimuovi foto».
class AvatarPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const AvatarPicker({super.key, required this.value, required this.onChanged});

  static const double _tile = 52;

  @override
  Widget build(BuildContext context) {
    final selected = value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < avatarOptions.length; i++)
              _Option(
                name: avatarOptions[i],
                index: i,
                selected: avatarOptions[i] == selected,
                size: _tile,
                onTap: () => onChanged(avatarOptions[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String name;
  final int index;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _Option({
    required this.name,
    required this.index,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // I cerchi colorati del design, a turno: giallo, turchese, arancio, lilla.
    final plates = [c.yellow, c.iconPalette[2], c.orange, c.accentSoft];
    return Semantics(
      selected: selected,
      button: true,
      label: 'Avatar $name',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          // Scelto: bordo indaco, poi un anello bianco e uno giallo intorno,
          // come l'avatar scelto nel design.
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: plates[index % plates.length],
            border: Border.all(
              color: selected ? c.accent : Colors.transparent,
              width: 4,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(color: c.surface, spreadRadius: 4),
                    BoxShadow(color: c.yellow, spreadRadius: 7),
                  ]
                : null,
          ),
          child: Icon(
            avatarIcon(name),
            size: size * 0.44,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}
