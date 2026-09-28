import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sheshield/models/emergency_alert_response.dart';
import 'package:sheshield/models/login_response.dart';
import 'package:sheshield/screens/login_screen.dart';
import 'package:sheshield/screens/profile_screen.dart';
import 'package:sheshield/screens/fake_call_screen.dart';
import 'package:sheshield/screens/volunteer_device_screen.dart';
import 'package:sheshield/screens/evidence_vault_screen.dart';
import 'package:sheshield/screens/safety_heat_map_screen.dart';
import 'package:sheshield/screens/night_safety_route_screen.dart';
import 'package:sheshield/screens/guardian_pairing_screen.dart';
import 'package:sheshield/screens/smart_walk_screen.dart';
import 'package:sheshield/services/guardian_service.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/emergency_service.dart';
import 'package:sheshield/services/location_service.dart';
import 'package:sheshield/services/shake_sos_service.dart';
import 'package:sheshield/services/user_location_service.dart';
import 'package:sheshield/services/evidence_vault_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sheshield/ui/sheshield_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final LoginResponse user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LoginResponse _user;
  bool _sosLoading = false;
  bool _locationUpdating = false;
  late final ShakeSosService _shakeService;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _shakeService = ShakeSosService(onTripleShake: _onTripleShake)..start();
    GuardianService().sync(_user.userId);
  }

  @override
  void dispose() {
    _shakeService.dispose();
    super.dispose();
  }

  Future<void> _onTripleShake() async {
    if (!mounted || _sosLoading) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Triple shake detected. Activating silent SOS…'),
        backgroundColor: Color(0xFFB3264D),
      ),
    );
    await _activateSos();
  }

  Future<void> _scheduleFakeCall() async {
    String caller = 'Dad';
    int delay = 5;
    final start = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Start Fake Call'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: caller,
                decoration: const InputDecoration(labelText: 'Caller'),
                items: const [
                  DropdownMenuItem(value: 'Dad', child: Text('Dad')),
                  DropdownMenuItem(
                    value: 'Security Office',
                    child: Text('Security Office'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => caller = value ?? caller),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: delay,
                decoration: const InputDecoration(labelText: 'Call after'),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 seconds')),
                  DropdownMenuItem(value: 10, child: Text('10 seconds')),
                  DropdownMenuItem(value: 20, child: Text('20 seconds')),
                ],
                onChanged: (value) =>
                    setDialogState(() => delay = value ?? delay),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
    if (start != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fake call will start in $delay seconds.')),
    );
    await Future<void>.delayed(Duration(seconds: delay));
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => FakeCallScreen(callerName: caller)),
    );
  }

  Future<void> _openProfile() async {
    final updated = await Navigator.of(context).push<LoginResponse>(
      MaterialPageRoute(builder: (_) => ProfileScreen(user: _user)),
    );
    if (updated != null && mounted) setState(() => _user = updated);
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmSos(BuildContext context) async {
    if (_sosLoading) return;
    var seconds = 3;
    Timer? timer;
    final shouldActivate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (activeTimer) {
            seconds--;
            if (seconds <= 0) {
              activeTimer.cancel();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            } else if (dialogContext.mounted) {
              setDialogState(() {});
            }
          });
          return AlertDialog(
            icon: Icon(
              Icons.sos_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text('Emergency SOS in $seconds'),
            content: const Text(
              'Cancel now if SOS was pressed accidentally. Otherwise the emergency flow will start automatically.',
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton.tonalIcon(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(dialogContext).pop(false);
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel SOS'),
              ),
            ],
          );
        },
      ),
    );
    timer?.cancel();
    if (shouldActivate != true || !mounted) return;
    await _activateSos();
  }

  Future<void> _activateSos() async {
    if (_sosLoading) return;
    setState(() => _sosLoading = true);
    try {
      final position = await LocationService().getCurrentPosition();
      final alert = await EmergencyService().triggerSos(
        userId: _user.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await EvidenceVaultService().create(
        emergencyId: alert.emergencyId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert activated.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF237A4B),
        ),
      );
      await _openEmergencyDialer();
      await _showSosResult(alert);
    } on LocationException catch (error) {
      _showSosError(error.message);
    } on EmergencyException catch (error) {
      _showSosError(error.message);
    } finally {
      if (mounted) setState(() => _sosLoading = false);
    }
  }

  Future<void> _openEmergencyDialer() async {
    final phone = _user.emergencyContactPhone.trim();
    if (phone.isEmpty || phone.toLowerCase() == 'not available') return;
    try {
      await launchUrl(
        Uri(scheme: 'tel', path: phone),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      _showSosError('Unable to open emergency contact dialer.');
    }
  }

  Future<void> _showSosResult(EmergencyAlertResponse alert) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.verified_rounded,
          size: 44,
          color: Color(0xFF237A4B),
        ),
        title: const Text('Emergency Active'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Emergency ID: ${alert.emergencyId}'),
              Text('Time: ${alert.createdAt.toLocal()}'),
              const Text('Location status: Location captured'),
              Text(
                'Nearby verified volunteers: ${alert.nearbyVolunteers.length}',
              ),
              Text('Volunteer notifications sent: ${alert.notificationsSent}'),
              Text('Push status: ${alert.notificationMessage}'),
              const SizedBox(height: 12),
              Text('Latitude: ${alert.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${alert.longitude.toStringAsFixed(6)}'),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const EvidenceVaultScreen()),
              );
            },
            icon: const Icon(Icons.security_rounded),
            label: const Text('Evidence Vault'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSosError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming in the next step'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateMyLocation() async {
    if (_locationUpdating) return;
    setState(() => _locationUpdating = true);
    try {
      final position = await LocationService().getCurrentPosition();
      final result = await UserLocationService().updateLocation(
        userId: _user.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.message}: '
            '${result.latitude.toStringAsFixed(6)}, '
            '${result.longitude.toStringAsFixed(6)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF237A4B),
        ),
      );
    } on LocationException catch (error) {
      _showSosError(error.message);
    } on UserLocationException catch (error) {
      _showSosError(error.message);
    } finally {
      if (mounted) setState(() => _locationUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SheShieldColors.rose, SheShieldColors.violet],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: SheShieldColors.rose.withValues(alpha: .3),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SheShield',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: SheShieldColors.wine,
                fontSize: 23,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [SheShieldColors.rose, SheShieldColors.violet],
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeSection(user: _user),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _SosCard(
                                onPressed: () => _confirmSos(context),
                                isLoading: _sosLoading,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  const _SafetyStatusCard(),
                                  const SizedBox(height: 20),
                                  _EmergencyContactCard(user: _user),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _SosCard(
                          onPressed: () => _confirmSos(context),
                          isLoading: _sosLoading,
                        ),
                        const SizedBox(height: 20),
                        const _SafetyStatusCard(),
                        const SizedBox(height: 20),
                        _EmergencyContactCard(user: _user),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _locationUpdating
                              ? null
                              : _updateMyLocation,
                          icon: _locationUpdating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: Text(
                            _locationUpdating
                                ? 'Updating Location...'
                                : 'Update My Location',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _SafetyToolsCard(onFakeCall: _scheduleFakeCall),
                      const SizedBox(height: 30),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _QuickActions(
                        wide: wide,
                        onPressed: () => _comingSoon(context),
                        onVolunteer: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const VolunteerDeviceScreen(),
                          ),
                        ),
                        onEvidence: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const EvidenceVaultScreen(),
                          ),
                        ),
                        onHeatMap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const SafetyHeatMapScreen(),
                          ),
                        ),
                        onNightRoute: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const NightSafetyRouteScreen(),
                          ),
                        ),
                        onGuardian: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                GuardianPairingScreen(userId: _user.userId),
                          ),
                        ),
                        onSmartWalk: () async {
                          await _shakeService.stop();
                          if (!context.mounted) return;
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => SmartWalkScreen(user: _user),
                            ),
                          );
                          if (mounted) _shakeService.start();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SafetyToolsCard extends StatelessWidget {
  const _SafetyToolsCard({required this.onFakeCall});
  final VoidCallback onFakeCall;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Silent Safety Tools',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Icon(Icons.vibration_rounded)),
          title: Text(
            'Triple-shake SOS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Enabled while SheShield is open. Shake the phone 3 times within 5 seconds.',
          ),
          trailing: Icon(Icons.check_circle, color: Color(0xFF237A4B)),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.phone_callback_rounded),
          ),
          title: const Text(
            'Fake Call Rescue',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Schedule a simulated incoming call.'),
          trailing: FilledButton(
            onPressed: onFakeCall,
            child: const Text('Start'),
          ),
        ),
      ],
    ),
  );
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.user});
  final LoginResponse user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          SheShieldColors.wine,
          SheShieldColors.rose,
          SheShieldColors.violet,
        ],
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: SheShieldColors.wine.withValues(alpha: .25),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${user.fullName}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: .88),
          ),
        ),
      ],
    ),
  );
}

class _SosCard extends StatelessWidget {
  const _SosCard({required this.onPressed, required this.isLoading});
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: const Color(0xFFFFE9ED),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 38),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Emergency SOS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF852746),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap to activate'),
          const SizedBox(height: 28),
          Semantics(
            button: true,
            label: 'Activate Emergency SOS',
            child: GestureDetector(
              onTap: isLoading ? null : onPressed,
              child: _PulseSos(
                child: Container(
                  width: 168,
                  height: 168,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF4778),
                        Color(0xFFB2164D),
                        Color(0xFF74173F),
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3DB3264D),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SafetyStatusCard extends StatelessWidget {
  const _SafetyStatusCard();

  @override
  Widget build(BuildContext context) => _DashboardCard(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFFE5F5EC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Color(0xFF237A4B),
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety Status',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'You are safe',
                style: TextStyle(
                  color: Color(0xFF237A4B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmergencyContactCard extends StatefulWidget {
  const _EmergencyContactCard({required this.user});
  final LoginResponse user;

  @override
  State<_EmergencyContactCard> createState() => _EmergencyContactCardState();
}

class _EmergencyContactCardState extends State<_EmergencyContactCard> {
  bool _smsLoading = false;

  Future<void> _openDialer(BuildContext context) async {
    final phoneNumber = widget.user.emergencyContactPhone.trim();
    if (phoneNumber.isEmpty) {
      _showActionError(
        context,
        'Emergency contact phone number is not available.',
      );
      return;
    }

    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: phoneNumber),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showActionError(context, 'Unable to open phone dialer.');
      }
    } catch (_) {
      if (context.mounted) {
        _showActionError(context, 'Unable to open phone dialer.');
      }
    }
  }

  Future<void> _openSmsComposer(BuildContext context) async {
    if (_smsLoading) return;
    final phoneNumber = widget.user.emergencyContactPhone.trim();
    if (phoneNumber.isEmpty) {
      _showActionError(
        context,
        'Emergency contact phone number is not available.',
      );
      return;
    }

    setState(() => _smsLoading = true);
    try {
      final position = await LocationService().getCurrentPosition();
      final mapUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      final message =
          '🚨 SheShield Emergency Alert\n\n'
          'I need emergency assistance.\n\n'
          'My current location:\n'
          '$mapUrl\n\n'
          'Please contact me immediately.';
      final opened = await launchUrl(
        Uri(
          scheme: 'sms',
          path: phoneNumber,
          queryParameters: {'body': message},
        ),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showActionError(context, 'Unable to open SMS application.');
      }
    } on LocationException {
      if (context.mounted) {
        _showActionError(context, 'Unable to get your current location.');
      }
    } catch (_) {
      if (context.mounted) {
        _showActionError(context, 'Unable to open SMS application.');
      }
    } finally {
      if (mounted) setState(() => _smsLoading = false);
    }
  }

  void _showActionError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => _DashboardCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.contact_emergency_outlined),
            SizedBox(width: 10),
            Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          widget.user.emergencyContactName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(widget.user.emergencyContactPhone),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openDialer(context),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call'),
            ),
            OutlinedButton.icon(
              onPressed: _smsLoading ? null : () => _openSmsComposer(context),
              icon: _smsLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined),
              label: const Text('Send SMS'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.wide,
    required this.onPressed,
    required this.onVolunteer,
    required this.onEvidence,
    required this.onHeatMap,
    required this.onNightRoute,
    required this.onGuardian,
    required this.onSmartWalk,
  });
  final bool wide;
  final VoidCallback onPressed;
  final VoidCallback onVolunteer;
  final VoidCallback onEvidence;
  final VoidCallback onHeatMap;
  final VoidCallback onNightRoute;
  final VoidCallback onGuardian;
  final VoidCallback onSmartWalk;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (
        'Volunteer Safety Circle',
        Icons.volunteer_activism_outlined,
        Color(0xFFE94B89),
      ),
      ('Evidence Vault', Icons.security_rounded, Color(0xFF7257D5)),
      ('Campus Safety Heat Map', Icons.map_outlined, Color(0xFFF0803C)),
      ('Night Safety Route', Icons.route_outlined, Color(0xFF1AA6A6)),
      ('Guardian Access', Icons.family_restroom, Color(0xFF3975D5)),
      ('Smart Walk Mode', Icons.directions_walk, Color(0xFF25A66A)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: wide ? 1.5 : 1.25,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: index == 0
              ? onVolunteer
              : (index == 1
                    ? onEvidence
                    : (index == 2
                          ? onHeatMap
                          : (index == 3
                                ? onNightRoute
                                : (index == 4 ? onGuardian : onSmartWalk)))),
          borderRadius: BorderRadius.circular(18),
          child: _DashboardCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action.$3.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(action.$2, size: 30, color: action.$3),
                ),
                const SizedBox(height: 12),
                Text(
                  action.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => NeonGlass(child: child);
}

class _PulseSos extends StatefulWidget {
  const _PulseSos({required this.child});
  final Widget child;
  @override
  State<_PulseSos> createState() => _PulseSosState();
}

class _PulseSosState extends State<_PulseSos>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (_, child) => SizedBox(
      width: 204,
      height: 204,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: .82 + c.value * .18,
            child: Container(
              width: 202,
              height: 202,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SheShieldColors.rose.withValues(
                    alpha: .42 * (1 - c.value),
                  ),
                  width: 4,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: .90 + c.value * .10,
            child: Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SheShieldColors.rose.withValues(
                      alpha: .22 + c.value * .18,
                    ),
                    blurRadius: 26 + c.value * 18,
                    spreadRadius: 3 + c.value * 6,
                  ),
                ],
              ),
            ),
          ),
          child!,
        ],
      ),
    ),
    child: widget.child,
  );
}
