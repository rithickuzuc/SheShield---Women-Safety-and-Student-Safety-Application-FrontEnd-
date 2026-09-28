import 'package:flutter/material.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/volunteer_device_service.dart';

class VolunteerDeviceScreen extends StatefulWidget {
  const VolunteerDeviceScreen({super.key});
  @override State<VolunteerDeviceScreen> createState() => _VolunteerDeviceScreenState();
}

class _VolunteerDeviceScreenState extends State<VolunteerDeviceScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (!_form.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    try {
      await VolunteerDeviceService().register(volunteerId: int.parse(_id.text), phone: _phone.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer notifications enabled successfully.')));
      Navigator.pop(context);
    } on AuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override void dispose() { _id.dispose(); _phone.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Volunteer Safety Circle')),
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.volunteer_activism_rounded, size: 72, color: Color(0xFF8E3A62)),
        const SizedBox(height: 18),
        const Text('Enable Volunteer Alerts', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Enter the verified volunteer ID and matching phone number. This device will receive nearby SOS alerts.', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextFormField(controller: _id, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Volunteer ID', prefixIcon: Icon(Icons.badge_outlined)), validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a valid volunteer ID' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Registered Phone', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => (v?.trim().length ?? 0) < 7 ? 'Enter the registered phone number' : null),
        const SizedBox(height: 22),
        FilledButton.icon(onPressed: _loading ? null : _register, icon: _loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.notifications_active_outlined), label: const Text('Enable Notifications')),
      ])),
    ))),
  );
}
