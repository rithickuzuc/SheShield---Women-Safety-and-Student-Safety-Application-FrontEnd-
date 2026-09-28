import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sheshield/config/api_config.dart';
import 'package:sheshield/models/user_profile.dart';
import 'package:sheshield/services/auth_service.dart';

class ProfileService {
  ProfileService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<UserProfile> getProfile() async =>
      UserProfile.fromJson(await _request('GET', '/api/users/me'));

  Future<UserProfile> updateProfile({
    required String fullName,
    required String phone,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async => UserProfile.fromJson(
    await _request('PUT', '/api/users/me/profile', body: {
      'fullName': fullName,
      'phone': phone,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    }),
  );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _request('PUT', '/api/users/me/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await AuthService().readToken();
    if (token == null) throw const AuthException('Please login again.');
    try {
      final request = http.Request(method, ApiConfig.endpoint(path))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        });
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      final errors = decoded['fieldErrors'];
      if (errors is Map && errors.isNotEmpty) {
        throw AuthException(errors.values.first.toString());
      }
      throw AuthException(decoded['message']?.toString() ?? 'Request failed.');
    } on TimeoutException {
      throw const AuthException('The server took too long to respond.');
    } on http.ClientException {
      throw const AuthException('Cannot connect to SheShield.');
    }
  }
}
