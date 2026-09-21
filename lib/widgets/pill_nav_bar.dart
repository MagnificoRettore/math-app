import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../models/level.dart';
import '../screens/course_screen.dart';
import '../screens/lesson_list_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import 'school_choice_sheet.dart';

enum PillTab { home, lessons, exercises, profile }

const _pillLabels = {
  PillTab.home: 'HOME',
  PillTab.lessons: 'LEZIONI',
  PillTab.exercises: 'ESERCIZI',
  PillTab.profile: 'PROFILO',
};

/// Spazio riservato sotto il contenuto per la pillola in overlay.
const double kPillBottomReserve = 96;

/// Transizione sobria per il cambio sezione: la pagina nuova sfuma sopra
/// quella attuale, così la pillola resta visivamente in sovraimpressione
/// mentre il contenuto cambia sotto di essa.
Route<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

/// Inquadra il body a schermo intero con la pillola in overlay in basso:
/// il contenuto scorre sotto la barra in vetro (effetto Liquid Glass).
class PillNavOverlay extends StatelessWidget {
  final PillTab selected;
  final Widget child;

  const PillNavOverlay({
    super.key,
    required this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: kPillBottomReserve),
            child: child,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PillNavBar(selected: selected),
        ),
      ],
    );
  }
}

class PillNavBar extends StatefulWidget {
  final PillTab selected;

  const PillNavBar({super.key, required this.selected});

  @override
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar> {
  static const _itemCount = 4;

  // La sezione selezionata è derivata da [PillNavBar.selected]: la barra
  // riflette sempre la schermata corrente, quindi l'indicatore non può
  // rimanere "bloccato" su una vecchia sezione quando la schermata torna
  // visibile dopo un pop.
  //
  // Queste variabili sono transitorie: valgono solo durante una singola
  // interazione (un tap in attesa dello snap o un drag in corso).
  bool _dragging = false;
  double? _dragLeft;
  int? _activeIndex;
  int? _pendingTabIndex;

  int get _selectedIndex => widget.selected.index;

  @override
  void didUpdateWidget(covariant PillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _dragging = false;
      _dragLeft = null;
      _activeIndex = null;
      _pendingTabIndex = null;
    }
  }

  /// Seleziona la sezione al tocco: l'indicatore scivola sulla nuova
  /// posizione, poi (a fine snap) la pagina viene caricata sotto la pillola.
  void _commit(int index) {
    if (_pendingTabIndex != null || index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _pendingTabIndex = index);
  }

  void _onSnapComplete() {
    if (!mounted) return;
    final pending = _pendingTabIndex;
    if (pending == null) return;
    setState(() => _pendingTabIndex = null);
    _performNavigation(pending);
  }

  /// Esegue la navigazione esattamente una volta per interazione: per il tap
  /// parte dallo snap completato (`_onSnapComplete`), per il drag dal rilascio.
  void _performNavigation(int index) {
    final tab = PillTab.values[index];
    final navigator = Navigator.of(context);

    if (tab == PillTab.home) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    if (tab == PillTab.profile) {
      navigator.popUntil((route) => route.isFirst);
      navigator.push(_fadeRoute(const ProfileScreen()));
      return;
    }

    final user = AuthStore.instance.currentUser;
    final levelId = (user?.schoolLevelId ?? '').isNotEmpty
        ? user!.schoolLevelId
        : null;
    final level = levelId == null
        ? null
        : ContentRepository.instance.levelById(levelId);
    if (level != null) {
      navigator.popUntil((route) => route.isFirst);
      navigator.push(_fadeRoute(_screenFor(tab, level)));
      return;
    }

    unawaited(_openSchoolChoice(tab));
  }

  Future<void> _openSchoolChoice(PillTab tab) async {
    final destination = tab == PillTab.lessons
        ? SchoolChoiceDestination.lessons
        : SchoolChoiceDestination.exercises;

    final chosen = await showSchoolChoiceSheet(
      context,
      destination: destination,
    );
    if (!mounted) return;
    if (chosen == null) {
      // Scelta annullata: la pillola torna sulla sezione della schermata.
      setState(() {
        _dragging = false;
        _dragLeft = null;
        _activeIndex = null;
      });
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(_fadeRoute(_screenFor(tab, chosen)));
  }

  Widget _screenFor(PillTab tab, Level level) {
    if (tab == PillTab.lessons) {
      return LessonListScreen(levelId: level.id, showPill: true);
    }
    return CourseScreen(level: level, showPill: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // ―― Liquid Glass ――――――――――――――――――――――――――――――――――――――
    // Tinta del vetro: semi-trasparente e più spessa in alto, così la
    // sfocatura del contenuto sottostante resta ben visibile.
    final glassTop = c.surface.withValues(alpha: isDark ? 0.25 : 0.18);
    final glassBottom = c.surface.withValues(alpha: isDark ? 0.12 : 0.08);
    // Riflessi di luce: più marcati in chiaro, soffusi in scuro.
    final rim = isDark ? 0.35 : 0.6;
    final glare = isDark ? 0.12 : 0.2;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            // Ombra di profondità molto morbida: stacca la pillola dallo sfondo.
            BoxShadow(
              color: c.shadow,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            // Ombra di contatto più corta per "ancorare" il vetro.
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          // Un unico BackdropFilter ristretto al "buco" della pillola: sfoca in
          // tempo reale ciò che scorre sotto, con sigma moderato per non pesare
          // sul framerate.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [
                // 1) Corpo di vetro: gradiente verticale semi-trasparente.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [glassTop, glassBottom],
                      ),
                    ),
                  ),
                ),
                // 2) Tinta "liquida": leggera sfumatura d'accento che simula
                //    lo spessore e la rifrazione del vetro.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.25, 1],
                        colors: [
                          c.accent.withValues(alpha: 0.05),
                          c.accent.withValues(alpha: 0.015),
                        ],
                      ),
                    ),
                  ),
                ),
                // 3) Bordo esterno sottile e nitido.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.14 : 0.55,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // 4) Riflesso superiore: linea di luce sul bordo alto.
                Positioned(
                  left: 4,
                  right: 4,
                  top: 0,
                  height: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: rim),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 5) Riflessi laterali: bordi verticali del vetro.
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  width: 12,
                  child: _EdgeGlare(alpha: glare),
                ),
                Positioned(
                  right: 0,
                  top: 8,
                  bottom: 8,
                  width: 12,
                  child: _EdgeGlare(alpha: glare, flip: true),
                ),
                // 6) Bagliore diagonale: rifrazione "liquida" sulla superficie.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0, 0.45, 1],
                          colors: [
                            Colors.white.withValues(alpha: glare),
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: glare * 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 7) Ombra interna al fondo: spessore percepito del vetro.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                          Colors.black.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final segWidth = (constraints.maxWidth / _itemCount)
                          .clamp(1.0, double.infinity);
                      final maxLeft = constraints.maxWidth - segWidth;

                      double clampLeft(double left) => left.clamp(0.0, maxLeft);
                      int segmentAt(double x) =>
                          (x / segWidth).floor().clamp(0, _itemCount - 1);
                      double indicatorLeft(int index) => index * segWidth;

                      final draggingFrom =
                          _dragLeft ??
                          indicatorLeft(_pendingTabIndex ?? _selectedIndex);
                      final activeIndex =
                          _activeIndex ?? _pendingTabIndex ?? _selectedIndex;
                      final snapDuration = (!_dragging && !reduceMotion)
                          ? const Duration(milliseconds: 260)
                          : Duration.zero;
                      final snapCurve = Curves.easeOutCubic;

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: (details) {
                          final x = details.localPosition.dx;
                          setState(() {
                            _dragging = true;
                            _dragLeft = clampLeft(x - segWidth / 2);
                            _activeIndex = segmentAt(x);
                            _pendingTabIndex = null;
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragLeft = clampLeft(
                              (_dragLeft ?? indicatorLeft(_selectedIndex)) +
                                  details.delta.dx,
                            );
                            final index = segmentAt(_dragLeft! + segWidth / 2);
                            if (index != _activeIndex) {
                              HapticFeedback.selectionClick();
                              _activeIndex = index;
                            }
                          });
                        },
                        onHorizontalDragEnd: (_) {
                          final releasedIndex =
                              _activeIndex ??
                              segmentAt(
                                indicatorLeft(_selectedIndex) + segWidth / 2,
                              );
                          if (releasedIndex == _selectedIndex) {
                            // Rilascio sulla sezione attuale: niente navigazione,
                            // l'indicatore torna centrato sul segmento.
                            setState(() {
                              _dragging = false;
                              _dragLeft = null;
                              _activeIndex = null;
                            });
                            return;
                          }
                          // Al rilascio avviene la selezione: l'indicatore è già
                          // sul segmento, quindi si naviga subito (il movimento
                          // è stato mostrato durante il trascinamento). Tutto lo
                          // stato transitorio viene azzerato qui, così quando la
                          // schermata tornerà visibile l'evidenziazione e
                          // l'indicatore saranno di nuovo sulla sezione corrente.
                          HapticFeedback.selectionClick();
                          setState(() {
                            _dragging = false;
                            _dragLeft = null;
                            _activeIndex = null;
                          });
                          _performNavigation(releasedIndex);
                        },
                        onHorizontalDragCancel: () {
                          setState(() {
                            _dragging = false;
                            _dragLeft = null;
                            _activeIndex = null;
                            _pendingTabIndex = null;
                          });
                        },
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              key: const ValueKey('pill-indicator'),
                              duration: snapDuration,
                              curve: snapCurve,
                              onEnd: _onSnapComplete,
                              left: clampLeft(draggingFrom) + 3,
                              top: 0,
                              bottom: 0,
                              width: segWidth - 6,
                              child: _GlassIndicator(),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < _itemCount; i++)
                                  Expanded(
                                    child: _PillButton(
                                      tab: PillTab.values[i],
                                      active: i == activeIndex,
                                      onTap: () => _commit(i),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIndicator extends StatelessWidget {
  const _GlassIndicator();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Capsula di vetro "accesa": traslucida ma ben visibile, con un
          // riflesso di luce sul bordo alto come il vetro liquido.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.07),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.45),
                  ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 16,
            constraints: const BoxConstraints(maxWidth: double.infinity),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.5 : 0.7),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Riflesso verticale lungo un bordo laterale del vetro:
/// un gradiente orizzontale che sfuma verso il centro.
class _EdgeGlare extends StatelessWidget {
  final double alpha;
  final bool flip;

  const _EdgeGlare({required this.alpha, this.flip = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: flip ? Alignment.centerRight : Alignment.centerLeft,
          end: flip ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final PillTab tab;
  final bool active;
  final VoidCallback onTap;

  const _PillButton({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? _filledIcon : _outlinedIcon,
                size: 20,
                color: active ? c.accent : c.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? c.accent : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label => _pillLabels[tab] ?? tab.name.toUpperCase();

  IconData get _outlinedIcon {
    switch (tab) {
      case PillTab.home:
        return Symbols.home_rounded;
      case PillTab.lessons:
        return Symbols.book_2_rounded;
      case PillTab.exercises:
        return Icons.calculate_outlined;
      case PillTab.profile:
        return Icons.person_outline;
    }
  }

  IconData get _filledIcon {
    switch (tab) {
      case PillTab.home:
        return Symbols.home_rounded;
      case PillTab.lessons:
        return Symbols.book_2_rounded;
      case PillTab.exercises:
        return Icons.calculate;
      case PillTab.profile:
        return Icons.person;
    }
  }
}
