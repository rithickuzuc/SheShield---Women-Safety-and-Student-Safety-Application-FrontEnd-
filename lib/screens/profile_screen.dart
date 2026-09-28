import 'package:flutter/material.dart';
import 'package:sheshield/models/login_response.dart';
import 'package:sheshield/models/user_profile.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});
  final LoginResponse user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _service = ProfileService();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _fill(await _service.getProfile());
    } on AuthException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(UserProfile profile) {
    _name.text = profile.fullName;
    _phone.text = profile.phone;
    _contactName.text = profile.emergencyContactName;
    _contactPhone.text = profile.emergencyContactPhone;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final profile = await _service.updateProfile(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        emergencyContactName: _contactName.text.trim(),
        emergencyContactPhone: _contactPhone.text.trim(),
      );
      final updated = widget.user.copyWith(
        fullName: profile.fullName,
        emergencyContactName: profile.emergencyContactName,
        emergencyContactPhone: profile.emergencyContactPhone,
      );
      await AuthService().updateStoredProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop(updated);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New Password'), validator: (value) => (value?.length ?? 0) < 8 ? 'Use at least 8 characters' : null),
            const SizedBox(height: 12),
            TextFormField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password'), validator: (value) => value != next.text ? 'Passwords do not match' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Change')),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await _service.changePassword(currentPassword: current.text, newPassword: next.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
    } on AuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  static String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;
  String? _phoneValidator(String? value) {
    if (_required(value) case final error?) return error;
    return RegExp(r'^[0-9+() -]{7,20}$').hasMatch(value!.trim()) ? null : 'Enter a valid phone number';
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _contactName.dispose(); _contactPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Icon(Icons.account_circle_rounded, size: 76, color: Color(0xFF8E3A62)),
                    const SizedBox(height: 20),
                    TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)), validator: _required),
                    const SizedBox(height: 14),
                    TextFormField(initialValue: widget.user.email, readOnly: true, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 14),
                    TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)), validator: _phoneValidator),
                    const SizedBox(height: 24),
                    Text('Emergency Contact', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    TextFormField(controller: _contactName, decoration: const InputDecoration(labelText: 'Contact Name', prefixIcon: Icon(Icons.contact_emergency_outlined)), validator: _required),
                    const SizedBox(height: 14),
                    TextFormField(controller: _contactPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Phone', prefixIcon: Icon(Icons.phone_in_talk_outlined)), validator: _phoneValidator),
                    if (_error != null) ...[const SizedBox(height: 14), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
                    const SizedBox(height: 22),
                    FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Save Profile')),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.lock_reset_rounded), label: const Text('Change Password')),
                  ]),
                ),
              ),
            ),
          ),
  );
}
