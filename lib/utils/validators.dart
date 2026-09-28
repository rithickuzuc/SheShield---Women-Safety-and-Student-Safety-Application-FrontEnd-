abstract final class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'Email');
    if (requiredError != null) return requiredError;
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address';
  }

  static String? password(String? value) {
    final requiredError = required(value, 'Password');
    if (requiredError != null) return requiredError;
    return value!.length >= 8 ? null : 'Password must be at least 8 characters';
  }

  static String? phone(String? value) {
    final requiredError = required(value, 'Phone number');
    if (requiredError != null) return requiredError;
    final normalized = value!.replaceAll(RegExp(r'[\s()-]'), '');
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(normalized)
        ? null
        : 'Enter a valid 10–15 digit phone number';
  }
}
