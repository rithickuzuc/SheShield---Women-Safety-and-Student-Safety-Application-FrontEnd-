import 'package:flutter/material.dart';
import 'package:sheshield/screens/volunteer_emergency_screen.dart';

abstract final class AppNavigator {
  static final key = GlobalKey<NavigatorState>();
  static void openEmergency(int emergencyId) {
    key.currentState?.push(MaterialPageRoute<void>(
      builder: (_) => VolunteerEmergencyScreen(emergencyId: emergencyId),
    ));
  }
}
