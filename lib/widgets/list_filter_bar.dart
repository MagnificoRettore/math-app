import 'package:flutter/material.dart';

import '../haptics.dart';
import '../models/course.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'press_tracker.dart';
import 'search_overlay.dart';
import 'year_tile.dart';

/// Quali voci mostrano Lezioni ed Esercizi: tutte, o solo quelle iniziate e
/// non ancora finite.
enum ListFilter { all, inProgress }

/// La riga in cima a Lezioni ed Esercizi: il menu dell'anno e i filtri.
///
/// Filtri e lente stanno sempre insieme: se lo spazio non basta (schermi
/// stretti, testo grande) le pillole si rimpiccioliscono, invece di scorrere o
/// andare a capo.
class ListFilterBar extends StatelessWidget {
  final List<Course> courses;
  final int selectedIndex;
  final ValueChanged<int> onYear;
  final ListFilter filter;
  final ValueChanged<ListFilter> onFilter;

  const ListFilterBar({
    super.key,
    required this.courses,
    required this.selectedIndex,
    required this.onYear,
    required this.filter,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    // La ricerca sta fissa a destra; le pillole si riducono nello spazio che
    // resta se non ci stanno (schermi stretti, testo grande).
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    YearDropdown(
                      courses: courses,
                      selectedIndex: selectedIndex,
                      onSelected: onYear,
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      key: const Key('filter-all'),
                      label: 'Tutti',
                      selected: filter == ListFilter.all,
                      onTap: () => onFilter(ListFilter.all),
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      key: const Key('filter-in-progress'),
                      label: 'In corso',
                      selected: filter == ListFilter.inProgress,
                      onTap: () => onFilter(ListFilter.inProgress),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const SearchPill(),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// L'anno scelto, con un menu per cambiarlo. Bianco col bordo indaco, per non
/// confondersi con i filtri, che sono gialli quando attivi.
class YearDropdown extends StatelessWidget {
  final List<Course> courses;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const YearDropdown({
    super.key,
    required this.courses,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final current = courses[selectedIndex.clamp(0, courses.length - 1)];
    return PopupMenuButton<int>(
      key: const Key('year-dropdown'),
      tooltip: 'Cambia anno',
      position: PopupMenuPosition.under,
      // Un po' staccato dal menu: attaccato sembrerebbe in linea con i filtri.
      offset: const Offset(0, 8),
      onOpened: AppHaptics.selectionClick,
      onSelected: (index) {
        AppHaptics.selectionClick();
        onSelected(index);
      },
      // Il foglio del menu nello stile delle card: fondo bianco, bordo lilla da
      // 3, angoli da 20 e l'ombra fine; le voci sono pillole come i filtri.
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: c.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border, width: 3),
      ),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      constraints: const BoxConstraints(minWidth: 168),
      itemBuilder: (_) => [
        for (final (index, course) in courses.indexed)
          PopupMenuItem<int>(
            key: Key('year-option-${course.id}'),
            value: index,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: _YearOption(
              label: yearLabel(course),
              selected: course == current,
            ),
          ),
      ],
      child: _Pill(
        selected: false,
        borderColor: c.accent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(yearLabel(current), style: _pillStyle(c)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 20, color: c.textPrimary),
          ],
        ),
      ),
    );
  }
}

/// Un filtro: giallo con il bordo scuro quando è attivo, bianco col bordo
/// lilla altrimenti, come gli altri controlli scelti.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selected) return;
          AppHaptics.selectionClick();
          onTap();
        },
        child: _Pill(
          selected: selected,
          child: Text(label, style: _pillStyle(c)),
        ),
      ),
    );
  }
}

TextStyle _pillStyle(AppPalette c) => TextStyle(
  fontFamily: AppText.bodyFont,
  fontSize: AppText.bodyMedium,
  fontWeight: FontWeight.w500,
  color: c.textPrimary,
);

/// La pillola dei controlli della barra, sollevata da un gradino pieno come i
/// bottoni (`AppButton`): premuta scende di tutto il gradino e il gradino va a
/// zero, al rilascio torna su. Il filtro attivo resta giù, come un interruttore
/// premuto. Il tocco si legge con un `Listener`, che non toglie niente ai
/// gesti del figlio (il menu dell'anno ha il suo).
class _Pill extends StatefulWidget {
  /// Altezza del gradino sotto la faccia.
  static const double depth = 4;

  final bool selected;
  final Color? borderColor;
  final Widget child;

  const _Pill({required this.selected, required this.child, this.borderColor});

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _pressed = false;

  // Resta giù almeno un istante anche per un tocco rapido (`PressTracker`).
  late final PressTracker _press = PressTracker(
    (value) => setState(() => _pressed = value),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    _press.hold = AppMotion.duration(context, AppMotion.fast);
    final down = widget.selected || _pressed;
    final border =
        widget.borderColor ?? (widget.selected ? c.yellowDeep : c.border);
    return Listener(
      onPointerDown: (_) => _press.down(),
      onPointerUp: (_) => _press.up(),
      onPointerCancel: (_) => _press.up(),
      child: Padding(
        // Lo spazio del gradino: l'altezza totale non cambia mai.
        padding: const EdgeInsets.only(bottom: _Pill.depth),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          curve: AppMotion.standard,
          transform: Matrix4.translationValues(0, down ? _Pill.depth : 0, 0),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.selected ? c.yellow : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 2),
            boxShadow: [
              BoxShadow(
                color: border,
                offset: Offset(0, down ? 0 : _Pill.depth),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// La ricerca, con il suo pulsante come gli altri controlli della barra. Apre
/// `showSearchOverlay` con il `context` del pulsante, che dà il punto da cui
/// l'overlay si espande.
class SearchPill extends StatelessWidget {
  const SearchPill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Cerca',
      onTap: () => showSearchOverlay(context),
      child: Tooltip(
        message: 'Cerca',
        // Il `Builder` dà il contesto del solo pulsante: è il suo centro, non
        // quello della barra, l'origine dell'espansione.
        child: Builder(
          builder: (buttonContext) => GestureDetector(
            key: const Key('header-search'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selectionClick();
              showSearchOverlay(buttonContext);
            },
            child: _Pill(
              selected: false,
              child: Icon(Icons.search_rounded, size: 22, color: c.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una voce del menu dell'anno: la scelta è gialla col bordo oro, le altre
/// sono trasparenti. Niente spunta: lo dice l'evidenziazione.
class _YearOption extends StatelessWidget {
  final String label;
  final bool selected;

  const _YearOption({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selected ? c.yellow : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? c.yellowDeep : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(label, style: _pillStyle(c)),
    );
  }
}
