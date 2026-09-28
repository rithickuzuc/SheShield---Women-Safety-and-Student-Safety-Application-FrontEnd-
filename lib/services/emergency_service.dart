import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sheshield/config/api_config.dart';
import 'package:sheshield/models/emergency_alert_response.dart';
import 'package:sheshield/services/auth_service.dart';

class EmergencyException implements Exception {
  const EmergencyException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EmergencyService {
  EmergencyService({http.Client? client, AuthService? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? AuthService();

  final http.Client _client;
  final AuthService _authService;

  Future<EmergencyAlertResponse> triggerSos({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _authService.readToken();
    if (token == null || token.isEmpty) {
      throw const EmergencyException(
        'Your session has expired. Please log in again.',
      );
    }

    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('/api/emergency/sos'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userId': userId,
              'latitude': latitude,
              'longitude': longitude,
              'emergencyType': 'SOS',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return EmergencyAlertResponse.fromJson(_decode(response.body));
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const EmergencyException(
          'Your session has expired. Please log in again.',
        );
      }
      throw EmergencyException(_errorMessage(response));
    } on TimeoutException {
      throw const EmergencyException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const EmergencyException(
        'Cannot connect to SheShield. Check your connection and ensure the backend is running.',
      );
    } catch (error) {
      if (error is EmergencyException) rethrow;
      throw const EmergencyException(
        'Emergency SOS could not be activated. Please try again.',
      );
    }
  }

  // Kept only so the existing, currently unwired history screen still compiles.
  // SOS history is intentionally outside STEP 12.
  Future<List<EmergencyAlertResponse>> getHistory() async {
    throw const EmergencyException(
      'SOS history will be available in a later step.',
    );
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const EmergencyException('Unexpected server response.');
    }
    return decoded;
  }

  String _errorMessage(http.Response response) {
    try {
      final body = _decode(response.body);
      final fieldErrors = body['fieldErrors'];
      if (fieldErrors is Map && fieldErrors.isNotEmpty) {
        return fieldErrors.values.first.toString();
      }
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return response.statusCode >= 500
        ? 'The server is unavailable. Please try again later.'
        : 'Emergency SOS could not be activated. Please try again.';
  }
}
