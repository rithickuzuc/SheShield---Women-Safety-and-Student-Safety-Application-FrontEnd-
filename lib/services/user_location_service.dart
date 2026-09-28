import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sheshield/config/api_config.dart';
import 'package:sheshield/models/location_update_response.dart';
import 'package:sheshield/services/auth_service.dart';

class UserLocationException implements Exception {
  const UserLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UserLocationService {
  UserLocationService({http.Client? client, AuthService? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? AuthService();

  final http.Client _client;
  final AuthService _authService;

  Future<LocationUpdateResponse> updateLocation({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _authService.readToken();
    if (token == null || token.isEmpty) {
      throw const UserLocationException(
        'Your session has expired. Please login again.',
      );
    }

    try {
      final response = await _client
          .put(
            ApiConfig.endpoint('/api/users/$userId/location'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return LocationUpdateResponse.fromJson(_decode(response.body));
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const UserLocationException(
          'Your session has expired. Please login again.',
        );
      }
      throw UserLocationException(_errorMessage(response));
    } on TimeoutException {
      throw const UserLocationException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const UserLocationException('Unable to connect to SheShield.');
    } catch (error) {
      if (error is UserLocationException) rethrow;
      throw const UserLocationException(
        'Unable to update your location. Please try again.',
      );
    }
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const UserLocationException('Unexpected server response.');
    }
    return decoded;
  }

  String _errorMessage(http.Response response) {
    try {
      final message = _decode(response.body)['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    if (response.statusCode == 404) return 'User not found.';
    if (response.statusCode >= 500) {
      return 'The server is unavailable. Please try again later.';
    }
    return 'Unable to update your location. Please try again.';
  }
}
