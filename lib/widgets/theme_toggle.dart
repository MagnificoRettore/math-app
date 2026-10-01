import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../data/settings_store.dart';
import '../haptics.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

/// Card «Tema scuro» con l'animazione sole/luna.
///
/// Cambia tema all'inizio dell'animazione, non a metà, e la transizione dei
/// colori la segue per gli stessi 2s (`AppTheme.transitionStyle`).
class ThemeToggle extends StatefulWidget {
  const ThemeToggle({super.key});

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/animations/toggle.json';
  static const _dayIdle = 'Day Idle';
  static const _nightIdle = 'Night Idle';
  static const _toNight = 'Day to Night';
  static const _toDay = 'Night to Day';
  static const _idleLoops = 3;

  /// Durata del tratto sole/luna del cambio tema.
  ///
  /// I marker durano 1000ms («Day to Night») e 1333ms («Night to Day»): senza
  /// un override ogni direzione avrebbe una velocità diversa. Fissare 2s rende
  /// le due uguali e allinea i colori, che viaggiano per
  /// `AppTheme.transitionStyle`.
  static const _transition = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  LottieComposition? _composition;
  bool _animating = false;

  bool get _isDark => SettingsStore.instance.themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
    unawaited(SettingsStore.instance.setThemeMode(next));
    final transition = _marker(next == ThemeMode.dark ? _toNight : _toDay);
    if (transition == null) return;
    _animating = true;
    _controller.animateTo(transition.end, duration: _transition).whenComplete(
      () {
        if (!mounted) return;
        _animating = false;
        _playIdle();
      },
    );
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
                    fontSize: 15,
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
                    child: SizedBox(
                      key: const Key('theme-toggle-animation'),
                      width: 88,
                      height: 48,
                      child: Lottie(
                        composition: composition,
                        controller: _controller,
                        fit: BoxFit.contain,
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
