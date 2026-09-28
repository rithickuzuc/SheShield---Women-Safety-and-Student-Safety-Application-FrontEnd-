class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String emergencyContactName;
  final String emergencyContactPhone;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: (json['userId'] as num).toInt(),
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    emergencyContactName: json['emergencyContactName'] as String,
    emergencyContactPhone: json['emergencyContactPhone'] as String,
  );
}
