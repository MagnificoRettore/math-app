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
    final c = AppColors.of(context);
    final selected = value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final name in avatarOptions)
              _Option(
                name: name,
                selected: name == selected,
                size: _tile,
                onTap: () => onChanged(name),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => onChanged(''),
          icon: const Icon(Icons.person_off_outlined, size: 18),
          label: const Text('Rimuovi foto, torna alle iniziali'),
          style: TextButton.styleFrom(
            foregroundColor: c.textSecondary,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String name;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _Option({
    required this.name,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? c.accentSoft : c.surface,
            border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(
            avatarIcon(name),
            size: size * 0.44,
            color: selected ? c.accent : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
