import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'profile_avatar.dart';

/// Griglia degli avatar proposti.
///
/// Il valore è il **nome** del simbolo; la stringa vuota significa iniziali.
///
/// La scelta si anima subito al tocco, anche se chi usa il picker chiude il
/// foglio: per questo il picker tiene da sé l'avatar scelto, invece di
/// aspettare che il valore torni dal chiamante. L'avatar scelto cresce con un
/// piccolo rimbalzo ([AppMotion.bounce], [AppMotion.slow]) e il bordo indaco
/// con i due anelli compare in [AppMotion.medium].
class AvatarPicker extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const AvatarPicker({super.key, required this.value, required this.onChanged});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  static const double _tile = 52;

  late String _selected = widget.value.trim();

  @override
  void didUpdateWidget(AvatarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _selected = widget.value.trim();
  }

  void _pick(String name) {
    setState(() => _selected = name);
    widget.onChanged(name);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < avatarOptions.length; i++)
          _Option(
            key: ValueKey('avatar-option-${avatarOptions[i]}'),
            name: avatarOptions[i],
            index: i,
            selected: avatarOptions[i] == _selected,
            size: _tile,
            onTap: () => _pick(avatarOptions[i]),
          ),
      ],
    );
  }
}

/// Di quanto cresce l'avatar scelto.
const double _kSelectedScale = 1.08;

class _Option extends StatelessWidget {
  final String name;
  final int index;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _Option({
    super.key,
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
      child: AnimatedScale(
        scale: selected ? _kSelectedScale : 1,
        duration: AppMotion.duration(context, AppMotion.slow),
        curve: AppMotion.bounce,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.medium),
            curve: AppMotion.standard,
            width: size,
            height: size,
            // Scelto: bordo indaco, poi un anello bianco e uno giallo intorno,
            // come l'avatar scelto nel design. Da non scelto gli anelli ci
            // sono, trasparenti e senza spessore, così crescono invece di
            // comparire di colpo.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: plates[index % plates.length],
              border: Border.all(
                color: selected ? c.accent : c.accent.withValues(alpha: 0),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? c.surface : c.surface.withValues(alpha: 0),
                  spreadRadius: selected ? 4 : 0,
                ),
                BoxShadow(
                  color: selected ? c.yellow : c.yellow.withValues(alpha: 0),
                  spreadRadius: selected ? 7 : 0,
                ),
              ],
            ),
            child: Icon(
              avatarIcon(name),
              size: size * 0.44,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
