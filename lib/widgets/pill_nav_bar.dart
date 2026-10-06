import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import '../haptics.dart';
import '../theme/app_colors.dart';

enum PillTab { lessons, home, exercises }

const _labels = {
  PillTab.lessons: 'Lezioni',
  PillTab.home: 'Home',
  PillTab.exercises: 'Esercizi',
};

/// Altezza della barra: la fascia indaco ([_kBandHeight]) più i 20 px di cui
/// il bottone Home sporge sopra di lei.
const double kPillBottomReserve = 92;

/// La fascia indaco, alta quanto i bottoni laterali.
const double _kBandHeight = 72;

/// Il cerchio di Home, bordo crema compreso, e il suo gradino.
const double _kHomeSize = 70;
const double _kHomeStep = 5;

/// Il rientro delle tre colonne dai bordi, che avvicina i lati a Home.
const double _kSideInset = 28;

/// La barra di navigazione del design: una fascia indaco a tutta larghezza
/// con gli angoli in alto smussati a 28, Lezioni ed Esercizi ai lati (icona,
/// nome e un trattino giallo sotto quella scelta) e Home al centro, un cerchio
/// che sporge sopra la fascia con il bordo crema e il gradino pieno dei
/// bottoni: giallo quando si è in Home, bianco altrimenti.
class PillNavBar extends StatelessWidget {
  final PillTab selected;

  /// Chiamata col tab toccato. La barra non naviga: la `HomeScreen` sposta le
  /// pagine, header e barra restano fermi.
  final ValueChanged<PillTab> onSelect;

  const PillNavBar({super.key, required this.selected, required this.onSelect});

  void _select(PillTab tab) {
    if (tab == selected) return;
    AppHaptics.selectionClick();
    onSelect(tab);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    final current = selected;

    return SizedBox(
      height: kPillBottomReserve + systemBottom,
      child: Stack(
        // Il gradino di Home esce di poco sopra la barra.
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _kBandHeight + systemBottom,
            child: DecoratedBox(
              key: const ValueKey('pill-surface'),
              decoration: BoxDecoration(
                color: c.headerBand,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: systemBottom,
            height: kPillBottomReserve,
            // Le tre colonne non arrivano ai bordi: Lezioni ed Esercizi stanno
            // più vicine a Home che a un terzo esatto dello schermo.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kSideInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final tab in PillTab.values)
                    Expanded(
                      child: tab == PillTab.home
                          ? _HomeButton(
                              active: current == tab,
                              onTap: () => _select(tab),
                            )
                          : _SideButton(
                              tab: tab,
                              active: current == tab,
                              onTap: () => _select(tab),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le icone del design, a tratto: un libro aperto e un foglio con la spunta e
/// la matita. `{c}` è il colore del tratto.
const _icons = {
  PillTab.lessons:
      '<svg viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.4" '
      'stroke-linejoin="round"><path d="M12 6 C9 4 5 4 3 5 V19 C5 18 9 18 12 '
      '20 C15 18 19 18 21 19 V5 C19 4 15 4 12 6 Z M12 6 V20"/></svg>',
  PillTab.home:
      '<svg viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.6" '
      'stroke-linejoin="round"><path d="M4 11 L12 4 L20 11 V20 H14 V14 H10 V20 '
      'H4 Z"/></svg>',
  PillTab.exercises:
      '<svg viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.4" '
      'stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" '
      'width="13" height="18" rx="2"/><path d="M7.5 12 l2.5 2.5 4-5"/><path '
      'd="M19 8 L21 10 L15 16 L13 16 L13 14 Z"/></svg>',
};

Widget _icon(PillTab tab, Color color, double size) {
  final hex = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return SvgPicture.string(
    _icons[tab]!.replaceAll('{c}', '#$hex'),
    width: size,
    height: size,
  );
}

/// Il nome della sezione sotto l'icona: Outfit 600 da 14.
Widget _label(PillTab tab, Color color) => Text(
  _labels[tab]!,
  // Una riga sola: con le colonne rientrate, su un telefono stretto e il
  // testo ingrandito «Esercizi» andrebbe a capo e sforerebbe la fascia.
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: AppText.headingFont,
    fontSize: AppText.bodyLarge,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: color,
  ),
);

/// Lezioni o Esercizi: icona, nome e il trattino giallo sotto quella scelta,
/// sulla fascia indaco. Giallo la scelta, lilla le altre.
class _SideButton extends StatelessWidget {
  final PillTab tab;
  final bool active;
  final VoidCallback onTap;

  const _SideButton({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = active ? c.yellow : c.border;
    return Semantics(
      button: true,
      selected: active,
      label: _labels[tab],
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: ValueKey('pill-${tab.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _kBandHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _icon(tab, color, 28),
              const SizedBox(height: 4),
              _label(tab, color),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.medium),
                curve: AppMotion.standard,
                width: 22,
                height: 4,
                decoration: BoxDecoration(
                  color: active ? c.yellow : c.yellow.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home: il cerchio da 70 che sporge sopra la fascia, con il bordo crema da 6
/// e il gradino pieno da 5 dei bottoni. Giallo su oro quando si è in Home,
/// bianco su lilla altrimenti; il nome sotto, sulla fascia.
class _HomeButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _HomeButton({required this.active, required this.onTap});

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _pressed = false;

  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final active = widget.active;
    return Semantics(
      button: true,
      selected: active,
      label: _labels[PillTab.home],
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        key: const ValueKey('pill-home'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        // Cerchio, nome e il margine sotto superano di poco l'altezza della
        // barra: come nel design, il cerchio sporge in alto invece di
        // schiacciarsi.
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          maxHeight: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premuto, come `AppButton`: il cerchio scende di tutto il
                // gradino e il gradino va a zero; al rilascio torna su. La
                // discesa è una traslazione, così il nome sotto non si muove.
                AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.fast),
                  curve: AppMotion.standard,
                  width: _kHomeSize,
                  height: _kHomeSize,
                  alignment: Alignment.center,
                  transform: Matrix4.translationValues(
                    0,
                    _pressed ? _kHomeStep : 0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? c.yellow : c.surface,
                    border: Border.all(color: c.background, width: 6),
                    // Il gradino pieno dei bottoni, non un'ombra sfumata.
                    boxShadow: [
                      BoxShadow(
                        color: active ? c.yellowDeep : c.borderDeep,
                        offset: Offset(0, _pressed ? 0 : _kHomeStep),
                      ),
                    ],
                  ),
                  child: _icon(PillTab.home, c.textPrimary, 30),
                ),
                const SizedBox(height: 4),
                _label(PillTab.home, active ? c.yellow : c.border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
