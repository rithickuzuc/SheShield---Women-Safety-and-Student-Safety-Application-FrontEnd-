import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sheshield/navigation/app_navigator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payloads are displayed by Android while the app is backgrounded.
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  Future<String?> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await messaging.setAutoInitEnabled(true);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    return messaging.getToken();
  }

  Future<void> openInitialNotification() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _openMessage(message);
  }

  void _openMessage(RemoteMessage message) {
    final id = int.tryParse(message.data['emergencyId'] ?? '');
    if (id != null) AppNavigator.openEmergency(id);
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
