import 'package:flutter/material.dart';
import 'package:sheshield/services/guardian_service.dart';

class GuardianPairingScreen extends StatefulWidget {
  const GuardianPairingScreen({super.key, required this.userId});
  final int userId;
  @override State<GuardianPairingScreen> createState() => _GuardianPairingScreenState();
}

class _GuardianPairingScreenState extends State<GuardianPairingScreen> {
  late final Future<Map<String, dynamic>> future;
  @override void initState() { super.initState(); future = GuardianService().pairing(widget.userId); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guardian Access')),
    body: Center(child: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return snapshot.hasError ? Text('${snapshot.error}') : const CircularProgressIndicator();
        final data = snapshot.data!;
        return Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.family_restroom, size: 64, color: Color(0xFF8E3A62)),
          const Text('Share with your guardian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18), Text('Student email\n${data['studentEmail']}', textAlign: TextAlign.center),
          const SizedBox(height: 15), Text(data['pairingCode'].toString(), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 8)),
          const SizedBox(height: 10), const Text('Use this email and 6-digit code in Guardian Login.', textAlign: TextAlign.center),
        ])));
      },
    )),
  );
}
