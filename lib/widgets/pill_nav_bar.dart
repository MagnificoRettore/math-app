import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
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

  const PillNavOverlay({super.key, required this.selected, required this.child});

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

  late int _selected;
  bool _navigating = false;
  bool _navigationDone = false;

  bool _dragging = false;
  double? _dragLeft;
  int? _activeIndex;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected.index;
  }

  @override
  void didUpdateWidget(covariant PillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected.index;
      _navigating = false;
      _navigationDone = false;
      _dragging = false;
      _dragLeft = null;
      _activeIndex = null;
    }
  }

  /// Seleziona la sezione al tocco: l'indicatore scivola sulla nuova
  /// posizione, poi (a fine snap) la pagina viene caricata sotto la pillola.
  void _commit(int index) {
    if (_navigating || index == _selected) return;
    HapticFeedback.selectionClick();
    _navigating = true;
    setState(() => _selected = index);
  }

  void _onSnapComplete() {
    if (!_navigating || _navigationDone || !mounted) return;
    _performNavigation(_selected);
  }

  /// Esegue la navigazione esattamente una volta per selezione, anche se
  /// viene invocata sia dal rilascio del drag sia dal termine dello snap.
  void _performNavigation(int index) {
    if (_navigationDone) return;
    _navigationDone = true;
    _navigating = true;

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
      // Scelta annullata: l'indicatore torna sulla sezione della schermata.
      setState(() {
        _navigating = false;
        _navigationDone = false;
        _selected = widget.selected.index;
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

    final fillTop = c.surface.withValues(alpha: isDark ? 0.92 : 0.9);
    final fillBottom = c.surface.withValues(alpha: isDark ? 0.6 : 0.55);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [fillTop, fillBottom],
                      ),
                      border: Border.all(
                        color: c.border.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.38, 1],
                          colors: [
                            c.textPrimary.withValues(alpha: 0.05),
                            c.textPrimary.withValues(alpha: 0.01),
                            Colors.transparent,
                          ],
                        ),
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
                      final segWidth =
                          (constraints.maxWidth / _itemCount).clamp(
                            1.0,
                            double.infinity,
                          );
                      final maxLeft = constraints.maxWidth - segWidth;

                      double clampLeft(double left) =>
                          left.clamp(0.0, maxLeft);
                      int segmentAt(double x) =>
                          (x / segWidth).floor().clamp(0, _itemCount - 1);
                      double indicatorLeft(int index) => index * segWidth;

                      final draggingFrom = _dragLeft ?? indicatorLeft(_selected);
                      final activeIndex = _activeIndex ?? _selected;
                      final snapDuration =
                          (!_dragging && !reduceMotion)
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
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragLeft = clampLeft(
                              (_dragLeft ?? indicatorLeft(_selected)) +
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
                              segmentAt(indicatorLeft(_selected) + segWidth / 2);
                          if (releasedIndex == _selected) {
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
                          // è stato mostrato durante il trascinamento).
                          HapticFeedback.selectionClick();
                          _navigating = true;
                          setState(() {
                            _dragging = false;
                            _dragLeft = null;
                            _activeIndex = null;
                            _selected = releasedIndex;
                          });
                          _performNavigation(_selected);
                        },
                        onHorizontalDragCancel: () {
                          setState(() {
                            _dragging = false;
                            _dragLeft = null;
                            _activeIndex = null;
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.surface.withValues(alpha: 0.98),
            c.surface.withValues(alpha: 0.82),
          ],
        ),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
        return Icons.home_outlined;
      case PillTab.lessons:
        return Icons.menu_book_outlined;
      case PillTab.exercises:
        return Icons.calculate_outlined;
      case PillTab.profile:
        return Icons.person_outline;
    }
  }

  IconData get _filledIcon {
    switch (tab) {
      case PillTab.home:
        return Icons.home;
      case PillTab.lessons:
        return Icons.menu_book;
      case PillTab.exercises:
        return Icons.calculate;
      case PillTab.profile:
        return Icons.person;
    }
  }
}