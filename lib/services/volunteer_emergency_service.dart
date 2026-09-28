import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sheshield/config/api_config.dart';
import 'package:sheshield/models/emergency_details.dart';
import 'package:sheshield/services/auth_service.dart';
import 'package:sheshield/services/volunteer_device_service.dart';
import 'package:sheshield/services/push_notification_service.dart';

class VolunteerEmergencyService {
  Future<EmergencyDetails> details(int id) => _request('GET', '/api/emergency/$id');
  Future<EmergencyDetails> accept(int id) => _action(id, 'accept');
  Future<EmergencyDetails> resolve(int id) => _action(id, 'resolve');
  Future<EmergencyDetails> _action(int id, String action) async {
    final identity = await VolunteerDeviceService().readIdentity();
    final fcmToken = await PushNotificationService.instance.getToken();
    if (fcmToken == null && identity == null) {
      throw const AuthException('This device is not registered as a volunteer.');
    }
    final body = <String, dynamic>{'fcmToken': fcmToken};
    if (identity case final stored?) {
      body['volunteerId'] = stored.id;
      body['phone'] = stored.phone;
    }
    return _request('PUT', '/api/emergency/$id/$action', body: body);
  }
  Future<EmergencyDetails> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final jwt = await AuthService().readToken();
    if (jwt == null) throw const AuthException('Please login again.');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwt'};
    final response = method == 'GET'
        ? await http.get(ApiConfig.endpoint(path), headers: headers)
        : await http.put(ApiConfig.endpoint(path), headers: headers, body: jsonEncode(body));
    final json = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) throw AuthException(json['message']?.toString() ?? 'Emergency request failed.');
    return EmergencyDetails.fromJson(json);
  }
}
