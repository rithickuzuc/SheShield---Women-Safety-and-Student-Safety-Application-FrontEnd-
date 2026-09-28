import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeSosService {
  ShakeSosService({required this.onTripleShake});

  final Future<void> Function() onTripleShake;
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<DateTime> _shakes = [];
  DateTime? _lastShake;
  DateTime? _lastTrigger;

  void start() {
    _subscription ??= userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onMotion, onError: (_) {});
  }

  void _onMotion(UserAccelerometerEvent event) {
    final force = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (force < 16) return;
    final now = DateTime.now();
    if (_lastShake != null && now.difference(_lastShake!).inMilliseconds < 450) {
      return;
    }
    _lastShake = now;
    _shakes.removeWhere((time) => now.difference(time) > const Duration(seconds: 5));
    _shakes.add(now);
    if (_shakes.length < 3) return;
    _shakes.clear();
    if (_lastTrigger != null && now.difference(_lastTrigger!) < const Duration(seconds: 30)) {
      return;
    }
    _lastTrigger = now;
    onTripleShake();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
