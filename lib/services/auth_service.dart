import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sheshield/config/api_config.dart';
import 'package:sheshield/models/login_request.dart';
import 'package:sheshield/models/login_response.dart';
import 'package:sheshield/models/register_request.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _emergencyContactNameKey = 'emergency_contact_name';
  static const _emergencyContactPhoneKey = 'emergency_contact_phone';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<String> register(RegisterRequest request) async {
    final response = await _post('/api/auth/register', request.toJson());
    if (response.statusCode == 201) {
      final body = _decode(response.body);
      return body['message'] as String? ?? 'Registration successful';
    }
    throw AuthException(_errorMessage(response));
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _post('/api/auth/login', request.toJson());
    if (response.statusCode == 200) {
      final login = LoginResponse.fromJson(_decode(response.body));
      await Future.wait([
        _storage.write(key: _tokenKey, value: login.token),
        _storage.write(key: _userIdKey, value: login.userId.toString()),
        _storage.write(key: _userNameKey, value: login.fullName),
        _storage.write(key: _userEmailKey, value: login.email),
        _storage.write(
          key: _emergencyContactNameKey,
          value: login.emergencyContactName,
        ),
        _storage.write(
          key: _emergencyContactPhoneKey,
          value: login.emergencyContactPhone,
        ),
      ]);
      return login;
    }
    throw AuthException(_errorMessage(response));
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> updateStoredProfile(LoginResponse user) => Future.wait([
    _storage.write(key: _userNameKey, value: user.fullName),
    _storage.write(
      key: _emergencyContactNameKey,
      value: user.emergencyContactName,
    ),
    _storage.write(
      key: _emergencyContactPhoneKey,
      value: user.emergencyContactPhone,
    ),
  ]);

  Future<LoginResponse?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _userIdKey),
      _storage.read(key: _userNameKey),
      _storage.read(key: _userEmailKey),
      _storage.read(key: _emergencyContactNameKey),
      _storage.read(key: _emergencyContactPhoneKey),
    ]);
    final token = values[0];
    final userId = int.tryParse(values[1] ?? '');
    final fullName = values[2];
    final email = values[3];
    if (token == null || userId == null || fullName == null || email == null) {
      return null;
    }
    return LoginResponse(
      message: 'Session restored',
      userId: userId,
      fullName: fullName,
      email: email,
      emergencyContactName: values[4] ?? 'Not available',
      emergencyContactPhone: values[5] ?? 'Not available',
      token: token,
    );
  }

  Future<void> logout() => _storage.deleteAll();

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await _client
          .post(
            ApiConfig.endpoint(path),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Cannot connect to SheShield. Check your network and ensure the backend is running.',
      );
    } catch (error) {
      if (error is AuthException) rethrow;
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Unexpected server response.');
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

    return switch (response.statusCode) {
      400 => 'Please check the information you entered.',
      401 => 'Invalid email or password.',
      409 => 'An account with this email already exists.',
      >= 500 => 'The server is unavailable. Please try again later.',
      _ => 'Request failed. Please try again.',
    };
  }
}
