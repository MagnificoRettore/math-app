import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'scientific_calculator.dart';

/// Altezza della toolbar compatta: quella di un bottone da 44 più il suo
/// gradino, così sta alla pari con i bottoni accanto («Completa la lezione»).
/// Il FAB collassato è `M3EToolbarTokens.fabMedium`, cioè 80, e si scala fin
/// qui (da espanso scende a `fabBaseline`, 56).
const double kToolsBarHeight = 49;

/// La toolbar degli strumenti, la stessa delle lezioni e degli esercizi: il FAB
/// compatto con la pila che si apre in alto.
///
/// Sta in una `Positioned` con `width: M3EToolbarTokens.fabMedium`, mai in una
/// `Row`: `M3EToolbar` riserva in layout l'altezza della pila anche da
/// collassato (136px, di cui 80 di FAB) pur clip-paintandola a zero, e con
/// larghezza illimitata il suo layout verticale va in `Infinity`. La scala parte
/// dal basso a sinistra, così il FAB dipinto è a filo del margine e ha lo
/// stesso spigolo inferiore dei bottoni, e la pila si rivela in alto.
///
/// Indaco come la barra di avanzamento della lezione: il FAB prende i colori da
/// `AppTheme.lessonToolbar` (dal `Theme` di Flutter non gli arriverebbero), il
/// pannello espanso quelli qui sotto.
class AppToolsBar extends StatelessWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onCalculator;

  /// La chiave del `M3EToolbar` (nei test si cerca da lì).
  final Key toolbarKey;

  const AppToolsBar({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onCalculator,
    this.toolbarKey = const ValueKey('tools_toolbar'),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Transform.scale(
      alignment: Alignment.bottomLeft,
      scale: kToolsBarHeight / M3EToolbarTokens.fabMedium,
      child: M3ETheme(
        data: AppTheme.lessonToolbar,
        child: M3EToolbar(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          key: toolbarKey,
          axis: Axis.vertical,
          fabPosition: M3EToolbarFabPosition.bottom,
          expanded: expanded,
          onExpandedChanged: onExpandedChanged,
          fabExpandIcon: const Icon(M3EIcons.handyman_rounded),
          fabCollapseIcon: const Icon(M3EIcons.close_rounded),
          actions: [
            M3EToolbarAction(
              icon: M3EIcons.calculate_rounded,
              tooltip: 'Calcolatrice',
              onPressed: onCalculator,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mette la toolbar degli strumenti, ferma in basso a sinistra, sopra [child],
/// con la calcolatrice che si apre a tutto schermo sopra di lei. Per le pagine
/// degli esercizi; la lezione ha i suoi bottoni e usa [AppToolsBar] da sé.
class ToolsOverlay extends StatefulWidget {
  final Widget child;

  const ToolsOverlay({super.key, required this.child});

  @override
  State<ToolsOverlay> createState() => _ToolsOverlayState();
}

class _ToolsOverlayState extends State<ToolsOverlay> {
  bool _expanded = false;
  bool _calcOpen = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          left: 20,
          bottom: 16 + bottomInset,
          width: M3EToolbarTokens.fabMedium,
          child: AppToolsBar(
            expanded: _expanded,
            onExpandedChanged: (value) => setState(() => _expanded = value),
            onCalculator: () => setState(() => _calcOpen = true),
          ),
        ),
        if (_calcOpen)
          Positioned.fill(
            child: ScientificCalculatorSheet(
              onClose: () => setState(() => _calcOpen = false),
            ),
          ),
      ],
    );
  }
}
