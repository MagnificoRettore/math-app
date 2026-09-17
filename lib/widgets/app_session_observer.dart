import 'dart:async';

import 'package:flutter/material.dart';

import '../data/study_store.dart';

class AppSessionObserver extends StatefulWidget {
  final Widget child;

  const AppSessionObserver({super.key, required this.child});

  @override
  State<AppSessionObserver> createState() => _AppSessionObserverState();
}

class _AppSessionObserverState extends State<AppSessionObserver>
    with WidgetsBindingObserver {
  static const _tick = Duration(minutes: 1);

  DateTime? _sessionSince;
  Timer? _timer;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCounting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _flushTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_inForeground) {
        _inForeground = true;
        _startCounting();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_inForeground) {
        _inForeground = false;
        _timer?.cancel();
        _timer = null;
        _flushTime();
      }
    }
  }

  void _startCounting() {
    _sessionSince ??= DateTime.now();
    _timer ??= Timer.periodic(_tick, (_) => _flushTime());
  }

  Future<void> _flushTime() async {
    final since = _sessionSince;
    if (since == null) return;
    _sessionSince = DateTime.now();
    final minutes = DateTime.now().difference(since).inMinutes;
    if (minutes <= 0) return;
    final goalReached = await StudyStore.instance.addMinutes(minutes);
    if (goalReached && mounted && _inForeground) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Obiettivo di oggi raggiunto: 10 minuti!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
