class EmergencyDetails {
  const EmergencyDetails({required this.emergencyId, required this.userName,
    required this.userPhone, required this.latitude, required this.longitude,
    required this.status, required this.createdAt, this.volunteerId,
    this.volunteerName, this.volunteerPhone, this.acceptedAt, this.resolvedAt});
  final int emergencyId;
  final String userName, userPhone, status;
  final double latitude, longitude;
  final DateTime createdAt;
  final int? volunteerId;
  final String? volunteerName, volunteerPhone;
  final DateTime? acceptedAt, resolvedAt;
  factory EmergencyDetails.fromJson(Map<String, dynamic> json) => EmergencyDetails(
    emergencyId: (json['emergencyId'] as num).toInt(),
    userName: json['userName']?.toString() ?? 'User',
    userPhone: json['userPhone']?.toString() ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    status: json['status']?.toString() ?? 'ACTIVE',
    createdAt: DateTime.parse(json['createdAt'].toString()),
    volunteerId: (json['volunteerId'] as num?)?.toInt(),
    volunteerName: json['volunteerName']?.toString(), volunteerPhone: json['volunteerPhone']?.toString(),
    acceptedAt: json['acceptedAt'] == null ? null : DateTime.parse(json['acceptedAt'].toString()),
    resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'].toString()),
  );
}
