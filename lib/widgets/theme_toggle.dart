import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/settings_store.dart';
import '../haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';

/// Card «Tema scuro» con l'animazione sole/luna.
///
/// L'animazione parte sul tap e il tema cambia 50ms dopo, così l'icona è già in
/// viaggio quando i colori cominciano a interpolare (`AppTheme.transitionStyle`).
class ThemeToggle extends StatefulWidget {
  const ThemeToggle({super.key});

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
        /// Due controller: [_controller] per gli idle e [_drive] per il viaggio del
        /// tratto. `SingleTickerProviderStateMixin` ne ammette uno solo.
        with
        TickerProviderStateMixin {
  static const _asset = 'assets/animations/toggle.json';
  static const _dayIdle = 'Day Idle';
  static const _nightIdle = 'Night Idle';
  static const _toNight = 'Day to Night';
  static const _toDay = 'Night to Day';
  static const _idleLoops = 3;

  /// Durata del tratto sole/luna del cambio tema.
  ///
  /// I marker durano 1000ms («Day to Night») e 1333ms («Night to Day»): senza
  /// un override ogni direzione avrebbe una velocità diversa, e diversa da
  /// quella dei colori. Fissare 320ms rende le due uguali e le accorcia.
  static const _transition = Duration(milliseconds: 320);

  /// Quanto l'icona parte prima del tema. Con i colori a 200ms
  /// (`AppTheme.transitionStyle`) i due viaggi finiscono **separati**: i colori
  /// a 240ms, l'icona a 320ms.
  static const _themeChangeDelay = Duration(milliseconds: 40);

  /// Curva del tratto: l'icona parte subito e frena, mentre il tempo della
  /// composizione resterebbe lineare (`animateTo` non ha curva) e si fermerebbe
  /// di colpo.
  static const _curve = Curves.easeOutCubic;

  /// Il tempo della composizione, usato dagli idle.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  /// Il viaggio del tratto, da 0 a 1. Sta separato da [_controller] perché la
  /// curva si applichi **allo span del marker** e non a tutto l'intervallo 0..1
  /// della composizione: un `CurvedAnimation` sul controller di prima
  /// sposterebbe l'idle fuori dai suoi marker (`easeOutCubic(0.19)` non è più
  /// il frame 0.19) e la fine del tratto cadrebbe su 0.78 invece che sul
  /// marker, con la luna ferma a metà.
  late final AnimationController _drive = AnimationController(
    vsync: this,
    duration: _transition,
  );

  /// La curva del tratto, creata una volta sola: ogni `CurvedAnimation` si
  /// registra come listener di [_drive], e una nuova a ogni tap si sommerebbe
  /// alle precedenti senza essere mai liberata.
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _drive,
    curve: _curve,
  );

  /// Quello che `Lottie` legge: il tempo della composizione quando è fermo, il
  /// viaggio del tratto quando sta cambiando tema.
  late Animation<double> _frame;

  LottieComposition? _composition;
  bool _animating = false;

  bool get _isDark => SettingsStore.instance.themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _frame = _controller;
    _load();
  }

  @override
  void dispose() {
    _curved.dispose();
    _drive.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final composition = await AssetLottie(_asset).load();
    if (!mounted) return;
    setState(() {
      _composition = composition;
      _controller.duration = composition.duration;
    });
    _playIdle();
  }

  Marker? _marker(String name) => _composition?.getMarker(name);

  void _playIdle() {
    final idle = _marker(_isDark ? _nightIdle : _dayIdle);
    if (idle == null) return;
    _controller.repeat(min: idle.start, max: idle.end, count: _idleLoops);
  }

  void _onToggle() {
    if (_animating) return;
    AppHaptics.selectionClick();
    final next = _isDark ? ThemeMode.light : ThemeMode.dark;
    final transition = _marker(next == ThemeMode.dark ? _toNight : _toDay);
    if (transition == null) {
      unawaited(SettingsStore.instance.setThemeMode(next));
      return;
    }
    _animating = true;
    setState(() {
      _frame = Tween<double>(
        begin: _controller.value,
        end: transition.end,
      ).animate(_curved);
    });
    _drive.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _frame = _controller);
      _animating = false;
      _playIdle();
    });
    // Il tema segue l'avvio dell'icona invece di precederlo. Il timer non va
    // cancellato in `dispose`: scrive sullo store e non tocca il widget, quindi
    // un cambio tema richiesto e poi schermata chiusa deve comunque valere.
    Timer(_themeChangeDelay, () {
      unawaited(SettingsStore.instance.setThemeMode(next));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final isDark = _isDark;
        final composition = _composition;
        return AppCard(
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, color: c.medium),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tema scuro',
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (composition == null)
                Switch(
                  value: isDark,
                  activeThumbColor: c.accent,
                  onChanged: (_) => _onToggle(),
                )
              else
                Semantics(
                  label: 'Tema scuro',
                  button: true,
                  toggled: isDark,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onToggle,
                    child: RepaintBoundary(
                      child: SizedBox(
                        key: const Key('theme-toggle-animation'),
                        width: 88,
                        height: 48,
                        child: Lottie(
                          composition: composition,
                          controller: _frame,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
