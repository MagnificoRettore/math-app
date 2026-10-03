import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import '_perf_probe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MathApp());
  debugPrint('PERF build avviato probe=$kPerfProbe track=$kPerfTrack');
  if (kPerfProbe) {
    Future<void>.delayed(const Duration(seconds: 4), () {
      unawaited(perfPushCustomization());
    });
  }
}
