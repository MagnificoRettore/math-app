import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class ExerciseToolsBar extends StatelessWidget {
  const ExerciseToolsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return M3EToolbar(
      colorStyle: M3EToolbarColorStyle.standard,
      axis: Axis.horizontal,
      expanded: true,
      activeIndex: null,
      fabExpandIcon: null,
      alignment: Alignment.bottomLeft,
      actions: const <M3EToolbarItem>[
        M3EToolbarAction(
          icon: M3EIcons.calculate,
          tooltip: 'Calcolatrice',
          onPressed: _noop,
        ),
        M3EToolbarAction(
          icon: M3EIcons.functions,
          tooltip: 'Funzioni',
          onPressed: _noop,
        ),
      ],
    );
  }
}

void _noop() {}