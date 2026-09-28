class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String emergencyContactName;
  final String emergencyContactPhone;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'password': password,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
  };
}
