// TEMPORANEO: sonda di frame timing per il toggle del tema. Da eliminare.
import 'dart:ui' show FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

const bool kPerfProbe = bool.fromEnvironment('PERF_PROBE');
const bool kPerfTrack = bool.fromEnvironment('PERF_TRACK');

class PerfProbe {
  PerfProbe._();

  static bool attivo = false;
  static bool _installato = false;
  static int _conteggio = 0;
  static final List<double> _build = [];
  static final List<double> _raster = [];

  static void install() {
    if (_installato) return;
    _installato = true;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      if (!attivo) {
        _build.clear();
        _raster.clear();
        _conteggio = 0;
        return;
      }
      for (final t in timings) {
        final build = t.buildDuration.inMicroseconds / 1000.0;
        final raster = t.rasterDuration.inMicroseconds / 1000.0;
        _build.add(build);
        _raster.add(raster);
        _conteggio++;
        final wait =
            (t.timestampInMicroseconds(FramePhase.buildStart) -
                t.timestampInMicroseconds(FramePhase.vsyncStart)) /
            1000.0;
        debugPrint(
          'PERF frame=$_conteggio attesa=${wait.toStringAsFixed(1)} '
          'build=${build.toStringAsFixed(1)} raster=${raster.toStringAsFixed(1)} '
          'tot=${((t.timestampInMicroseconds(FramePhase.rasterFinish) - t.timestampInMicroseconds(FramePhase.vsyncStart)) / 1000.0).toStringAsFixed(1)}',
        );
      }
    });
  }

  static void aziona() {
    if (!kPerfProbe) return;
    install();
    attivo = true;
    _build.clear();
    _raster.clear();
    _conteggio = 0;
  }

  static void spegni() {
    if (!kPerfProbe) return;
    attivo = false;
    if (_build.isEmpty) {
      debugPrint('PERF nessun frame catturato');
      return;
    }
    _build.sort();
    _raster.sort();
    double med(List<double> v) => v[v.length ~/ 2];
    debugPrint(
      'PERF totale frame=${_build.length} '
      'build mediana=${med(_build).toStringAsFixed(1)} max=${_build.last.toStringAsFixed(1)} '
      'raster mediana=${med(_raster).toStringAsFixed(1)} max=${_raster.last.toStringAsFixed(1)}',
    );
  }
}
