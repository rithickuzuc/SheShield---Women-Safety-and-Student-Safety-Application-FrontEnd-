class LoginResponse {
  const LoginResponse({
    required this.message,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.token,
  });

  final String message;
  final int userId;
  final String fullName;
  final String email;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String token;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String? ?? 'Login successful',
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      emergencyContactName:
          json['emergencyContactName'] as String? ?? 'Not available',
      emergencyContactPhone:
          json['emergencyContactPhone'] as String? ?? 'Not available',
      token: json['token'] as String,
    );
  }

  LoginResponse copyWith({
    String? fullName,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) => LoginResponse(
    message: message,
    userId: userId,
    fullName: fullName ?? this.fullName,
    email: email,
    emergencyContactName:
        emergencyContactName ?? this.emergencyContactName,
    emergencyContactPhone:
        emergencyContactPhone ?? this.emergencyContactPhone,
    token: token,
  );
}
