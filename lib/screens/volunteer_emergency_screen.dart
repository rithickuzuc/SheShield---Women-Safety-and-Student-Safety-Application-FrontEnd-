import 'package:flutter/material.dart';
import 'package:sheshield/models/emergency_details.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/map_launcher_service.dart';
import 'package:sheshield/services/volunteer_emergency_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerEmergencyScreen extends StatefulWidget {
  const VolunteerEmergencyScreen({super.key, required this.emergencyId});
  final int emergencyId;
  @override State<VolunteerEmergencyScreen> createState() => _VolunteerEmergencyScreenState();
}
class _VolunteerEmergencyScreenState extends State<VolunteerEmergencyScreen> {
  late Future<EmergencyDetails> _future;
  bool _busy = false;
  @override void initState() { super.initState(); _future = VolunteerEmergencyService().details(widget.emergencyId); }
  Future<void> _action(bool resolve) async {
    if (_busy) return; setState(() => _busy = true);
    try {
      final result = resolve ? await VolunteerEmergencyService().resolve(widget.emergencyId) : await VolunteerEmergencyService().accept(widget.emergencyId);
      if (mounted) setState(() => _future = Future.value(result));
    } on AuthException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Emergency Details')),
    body: FutureBuilder<EmergencyDetails>(future: _future, builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snap.error}')));
      final e = snap.data!;
      return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Card(
        child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(Icons.emergency_rounded, size: 64, color: Theme.of(context).colorScheme.error),
          Text('SOS #${e.emergencyId}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 18), Text('User: ${e.userName}'), Text('Phone: ${e.userPhone}'), Text('Status: ${e.status}'), Text('Time: ${e.createdAt.toLocal()}'),
          Text('Latitude: ${e.latitude}'), Text('Longitude: ${e.longitude}'),
          if (e.volunteerName != null) Text('Accepted by: ${e.volunteerName}'), const SizedBox(height: 18),
          FilledButton.icon(onPressed: _busy || e.status != 'ACTIVE' ? null : () => _action(false), icon: const Icon(Icons.volunteer_activism), label: const Text('Accept Emergency')),
          const SizedBox(height: 10), OutlinedButton.icon(onPressed: () => MapLauncherService.open('https://www.google.com/maps?q=${e.latitude},${e.longitude}'), icon: const Icon(Icons.navigation), label: const Text('Open Location')),
          OutlinedButton.icon(onPressed: e.userPhone.isEmpty ? null : () => launchUrl(Uri(scheme: 'tel', path: e.userPhone), mode: LaunchMode.externalApplication), icon: const Icon(Icons.call), label: const Text('Call User')),
          if (e.status == 'ACCEPTED') FilledButton.tonalIcon(onPressed: _busy ? null : () => _action(true), icon: const Icon(Icons.task_alt), label: const Text('Mark as Resolved')),
        ])),
      ))));
    }),
  );
}
