import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sheshield/config/api_config.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/push_notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VolunteerDeviceService {
  static const _storage = FlutterSecureStorage();
  static const _idKey = 'volunteer_id';
  static const _phoneKey = 'volunteer_phone';
  Future<void> register({required int volunteerId, required String phone}) async {
    final token = await PushNotificationService.instance.getToken();
    final jwt = await AuthService().readToken();
    if (token == null || jwt == null) throw const AuthException('Notification or login token is unavailable.');
    final response = await http.post(
      ApiConfig.endpoint('/api/volunteers/device'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwt'},
      body: jsonEncode({'volunteerId': volunteerId, 'phone': phone.trim(), 'fcmToken': token}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(body['message']?.toString() ?? 'Volunteer device registration failed.');
    }
    await Future.wait([
      _storage.write(key: _idKey, value: volunteerId.toString()),
      _storage.write(key: _phoneKey, value: phone.trim()),
    ]);
  }

  Future<({int id, String phone})?> readIdentity() async {
    final values = await Future.wait([_storage.read(key: _idKey), _storage.read(key: _phoneKey)]);
    final id = int.tryParse(values[0] ?? '');
    if (id == null || values[1] == null) return null;
    return (id: id, phone: values[1]!);
  }
}
