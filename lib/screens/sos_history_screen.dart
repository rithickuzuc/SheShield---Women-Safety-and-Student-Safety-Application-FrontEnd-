import 'package:flutter/material.dart';
import 'package:sheshield/models/emergency_alert_response.dart';
import 'package:sheshield/services/emergency_service.dart';
import 'package:sheshield/services/map_launcher_service.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  late Future<List<EmergencyAlertResponse>> _history;

  @override
  void initState() {
    super.initState();
    _history = EmergencyService().getHistory();
  }

  void _retry() {
    setState(_replaceHistory);
  }

  void _replaceHistory() {
    _history = EmergencyService().getHistory();
  }

  Future<void> _openLocation(String mapUrl) async {
    try {
      await MapLauncherService.open(mapUrl);
    } on MapLauncherException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS History')),
      body: SafeArea(
        child: FutureBuilder<List<EmergencyAlertResponse>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is EmergencyException
                  ? (snapshot.error! as EmergencyException).message
                  : 'Unable to load SOS history.';
              return _HistoryMessage(
                icon: Icons.error_outline_rounded,
                message: message,
                actionLabel: 'Retry',
                onAction: _retry,
              );
            }

            final alerts = snapshot.data ?? const [];
            if (alerts.isEmpty) {
              return const _HistoryMessage(
                icon: Icons.history_rounded,
                message: 'No emergency alerts yet.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _retry();
                await _history;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: alerts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _AlertCard(
                  alert: alerts[index],
                  onViewLocation: () => _openLocation(alerts[index].mapUrl),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onViewLocation});
  final EmergencyAlertResponse alert;
  final VoidCallback onViewLocation;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final date = alert.createdAt.toLocal();
    final dateText =
        '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
    final timeText = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE9DDE3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE9ED),
                  child: Icon(Icons.sos_rounded, color: Color(0xFFB3264D)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'SOS Alert',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(status: alert.status),
              ],
            ),
            const SizedBox(height: 18),
            Text('$dateText at $timeText'),
            const SizedBox(height: 10),
            Text('Latitude: ${alert.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${alert.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onViewLocation,
              icon: const Icon(Icons.map_outlined),
              label: const Text('View Location'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE5F5EC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: Color(0xFF237A4B),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
