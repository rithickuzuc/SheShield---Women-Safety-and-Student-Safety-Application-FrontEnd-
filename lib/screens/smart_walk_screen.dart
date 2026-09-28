import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sheshield/models/login_response.dart';
import 'package:sheshield/services/emergency_service.dart';
import 'package:sheshield/services/location_service.dart';

class SmartWalkScreen extends StatefulWidget {
  const SmartWalkScreen({super.key, required this.user});
  final LoginResponse user;
  @override State<SmartWalkScreen> createState() => _SmartWalkScreenState();
}

class _SmartWalkScreenState extends State<SmartWalkScreen> {
  final map = MapController();
  StreamSubscription<Position>? locationSub;
  StreamSubscription<UserAccelerometerEvent>? motionSub;
  final path = <LatLng>[];
  Position? current;
  DateTime? lastMovedAt, runningSince, lastFallCheck;
  LatLng? movementAnchor;
  String status = 'Preparing Smart Walk…';
  bool active = false, checking = false, sosActive = false;
  Timer? stopTimer;

  @override void initState() { super.initState(); start(); }
  Future<void> start() async {
    try {
      final first = await LocationService().getCurrentPosition();
      if (!mounted) return;
      updatePosition(first);
      locationSub = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3)).listen(updatePosition);
      motionSub = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(checkMotion);
      stopTimer = Timer.periodic(const Duration(seconds: 10), (_) => checkLongStop());
      setState(() { active = true; status = 'Smart Walk monitoring active'; });
    } catch (e) { if (mounted) setState(() => status = '$e'); }
  }
  void updatePosition(Position p) {
    final point = LatLng(p.latitude, p.longitude), now = DateTime.now();
    current = p; path.add(point); if (path.length > 800) path.removeAt(0);
    if (movementAnchor == null || const Distance().as(LengthUnit.Meter, movementAnchor!, point) >= 10) { movementAnchor = point; lastMovedAt = now; }
    if (p.speed >= 4.0) { runningSince ??= now; if (now.difference(runningSince!) >= const Duration(seconds: 6)) safetyCheck('Unusual continuous running detected'); }
    else { runningSince = null; }
    if (mounted) { setState(() {}); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) map.move(point, max(map.camera.zoom, 16)); }); }
  }
  void checkMotion(UserAccelerometerEvent e) {
    final force = sqrt(e.x * e.x + e.y * e.y + e.z * e.z), now = DateTime.now();
    if (force > 22 && (lastFallCheck == null || now.difference(lastFallCheck!) > const Duration(seconds: 30))) { lastFallCheck = now; safetyCheck('Possible fall detected'); }
  }
  void checkLongStop() { final stopped = lastMovedAt; if (active && stopped != null && DateTime.now().difference(stopped) >= const Duration(minutes: 2)) safetyCheck('Unusually long stop detected'); }
  Future<void> safetyCheck(String reason) async {
    if (!mounted || checking || sosActive) return; checking = true; var seconds = 15; Timer? timer;
    final send = await showDialog<bool>(context: context, barrierDismissible: false, builder: (dialog) => StatefulBuilder(builder: (_, update) { timer ??= Timer.periodic(const Duration(seconds: 1), (t) { seconds--; if (seconds <= 0) { t.cancel(); if (dialog.mounted) { Navigator.pop(dialog, true); } } else if (dialog.mounted) { update(() {}); } }); return AlertDialog(icon: const Icon(Icons.health_and_safety, color: Colors.red, size: 48), title: const Text('Are you safe?'), content: Text('$reason.\n\nSOS activates in $seconds seconds.'), actions: [FilledButton.tonal(onPressed: () { timer?.cancel(); Navigator.pop(dialog, false); }, child: const Text("I'm Safe")), FilledButton(onPressed: () { timer?.cancel(); Navigator.pop(dialog, true); }, child: const Text('Send SOS Now'))]); }));
    timer?.cancel(); checking = false; lastMovedAt = DateTime.now(); if (send == true) await sendSos(reason);
  }
  Future<void> sendSos(String reason) async { final p = current; if (p == null || sosActive) return; setState(() => sosActive = true); try { final alert = await EmergencyService().triggerSos(userId: widget.user.userId, latitude: p.latitude, longitude: p.longitude); if (mounted) { setState(() => status = 'Emergency Active • SOS #${alert.emergencyId}'); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Smart Walk SOS activated: $reason'), backgroundColor: Colors.red)); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
  Future<void> stop() async { active = false; stopTimer?.cancel(); await locationSub?.cancel(); await motionSub?.cancel(); if (mounted) Navigator.pop(context); }
  @override void dispose() { active = false; stopTimer?.cancel(); locationSub?.cancel(); motionSub?.cancel(); map.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final point = current == null ? const LatLng(11.0168, 76.9558) : LatLng(current!.latitude, current!.longitude); return Scaffold(appBar: AppBar(title: const Text('Smart Walk Mode'), actions: [TextButton.icon(onPressed: stop, icon: const Icon(Icons.stop_circle), label: const Text('Stop'))]), body: Column(children: [Container(width: double.infinity, padding: const EdgeInsets.all(14), color: sosActive ? Colors.red.shade100 : Colors.green.shade100, child: Column(children: [Text(status, style: const TextStyle(fontWeight: FontWeight.bold)), if (current != null) Text('Speed: ${(current!.speed * 3.6).clamp(0, 999).toStringAsFixed(1)} km/h • GPS accuracy: ${current!.accuracy.toStringAsFixed(0)} m')])), Expanded(child: FlutterMap(mapController: map, options: MapOptions(initialCenter: point, initialZoom: 16), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.sheshield'), if (path.length > 1) PolylineLayer(polylines: [Polyline(points: path, strokeWidth: 6, color: const Color(0xFF8E3A62))]), MarkerLayer(markers: [Marker(point: point, width: 62, height: 62, child: const Icon(Icons.directions_walk, color: Color(0xFF8E3A62), size: 48))]), RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')])])), Padding(padding: const EdgeInsets.all(14), child: OutlinedButton.icon(onPressed: () => safetyCheck('Manual safety check'), icon: const Icon(Icons.health_and_safety), label: const Text('Test Safety Check')))])); }
}
