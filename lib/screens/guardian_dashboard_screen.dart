import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sheshield/services/guardian_service.dart';
import 'package:sheshield/ui/sheshield_background.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key, required this.token});
  final String token;
  @override State<GuardianDashboardScreen> createState() => _GuardianDashboardState();
}

class _GuardianDashboardState extends State<GuardianDashboardScreen> with SingleTickerProviderStateMixin {
  late Future<GuardianStatus> future;
  Timer? timer;
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
  @override void initState() { super.initState(); future = GuardianService().status(widget.token); timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh()); }
  void refresh() { final next = GuardianService().status(widget.token); if (mounted) setState(() { future = next; }); }
  @override void dispose() { timer?.cancel(); pulse.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guardian Live'), actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<GuardianStatus>(future: future, builder: (_, snapshot) {
      if (!snapshot.hasData) return snapshot.hasError ? _ErrorView(message: '${snapshot.error}', retry: refresh) : const Center(child: CircularProgressIndicator());
      final value = snapshot.data!;
      final emergency = value.emergencyStatus == 'ACTIVE' || value.emergencyStatus == 'ACCEPTED';
      final hasMap = value.latitude != null && value.longitude != null;
      final accent = emergency ? const Color(0xFFFF315E) : const Color(0xFF13B981);
      return RefreshIndicator(onRefresh: () async => refresh(), child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
        TweenAnimationBuilder<double>(tween: Tween(begin: .85, end: 1), duration: const Duration(milliseconds: 800), curve: Curves.elasticOut, builder: (_, scale, child) => Transform.scale(scale: scale, child: child), child: Container(
          padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: emergency ? const [Color(0xFFFF315E), Color(0xFF9B1447), Color(0xFF5B1239)] : const [Color(0xFF14B985), Color(0xFF168EA0), Color(0xFF4E5DD5)]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 28, offset: const Offset(0, 12))]),
          child: Column(children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (_, child) => Transform.scale(
                scale: 1 + pulse.value * .09,
                child: Container(width: 94, height: 94, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .18), border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2)), child: child),
              ),
              child: Icon(emergency ? Icons.emergency_rounded : Icons.shield_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 15), Text(emergency ? 'EMERGENCY ACTIVE' : 'STUDENT IS SAFE', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: .5)), const SizedBox(height: 7), Text(value.studentName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(value.studentEmail, style: TextStyle(color: Colors.white.withValues(alpha: .82))) ]),
        )),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _Stat(icon: Icons.sos, color: const Color(0xFFFF4778), label: 'Status', value: value.emergencyStatus),
          _Stat(icon: Icons.battery_charging_full, color: const Color(0xFF25A66A), label: 'Battery', value: value.battery == null ? '--' : '${value.battery}%'),
          _Stat(icon: Icons.schedule, color: SheShieldColors.violet, label: 'SOS Time', value: value.sosTime == null ? 'None' : _time(value.sosTime!)),
          _Stat(icon: Icons.update, color: SheShieldColors.teal, label: 'Updated', value: value.lastUpdated == null ? '--' : _time(value.lastUpdated!)),
        ]),
        const SizedBox(height: 18),
        if (hasMap) Container(height: 390, decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: SheShieldColors.violet.withValues(alpha: .20), blurRadius: 24, offset: const Offset(0, 10))]), child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Stack(children: [
          FlutterMap(options: MapOptions(initialCenter: LatLng(value.latitude!, value.longitude!), initialZoom: 16), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.sheshield'), MarkerLayer(markers: [Marker(point: LatLng(value.latitude!, value.longitude!), width: 76, height: 76, child: AnimatedBuilder(animation: pulse, builder: (_, child) => Transform.scale(scale: .9 + pulse.value * .18, child: child), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .18)), child: Icon(Icons.person_pin_circle, color: accent, size: 55))))]), RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')])]),
          Positioned(left: 14, top: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.location_on, color: SheShieldColors.rose), SizedBox(width: 7), Text('Live student location', style: TextStyle(fontWeight: FontWeight.bold))]))),
        ]))),
      ]));
    }),
  );
  String _time(DateTime time) { final t = time.toLocal(); return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'; }
}

class _Stat extends StatelessWidget { const _Stat({required this.icon, required this.color, required this.label, required this.value}); final IconData icon; final Color color; final String label, value; @override Widget build(BuildContext context) => Container(width: (MediaQuery.sizeOf(context).width - 48) / 2, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .82), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: color.withValues(alpha: .12), blurRadius: 16, offset: const Offset(0, 6))]), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))]))])); }
class _ErrorView extends StatelessWidget { const _ErrorView({required this.message, required this.retry}); final String message; final VoidCallback retry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 70, color: SheShieldColors.rose), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 15), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try Again'))]))); }
