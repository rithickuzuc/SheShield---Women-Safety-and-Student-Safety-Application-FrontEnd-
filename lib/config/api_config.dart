import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static Uri endpoint(String path) => Uri.parse('$baseUrl$path');
}
