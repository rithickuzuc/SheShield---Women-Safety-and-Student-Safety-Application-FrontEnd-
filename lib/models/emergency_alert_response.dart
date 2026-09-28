class EmergencyAlertResponse {
  const EmergencyAlertResponse({
    required this.message,
    required this.emergencyId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.emergencyType,
    required this.status,
    required this.createdAt,
    required this.nearbyVolunteers,
    required this.notificationsSent,
    required this.notificationMessage,
  });

  final String message;
  final int emergencyId;
  final int userId;
  final double latitude;
  final double longitude;
  final String emergencyType;
  final String status;
  final DateTime createdAt;
  final List<NearbyVolunteer> nearbyVolunteers;
  final int notificationsSent;
  final String notificationMessage;

  // Compatibility aliases for the existing history screen.
  int get alertId => emergencyId;
  String get alertType => emergencyType;
  String get mapUrl => '';

  factory EmergencyAlertResponse.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertResponse(
      message:
          json['message'] as String? ?? 'Emergency alert created successfully',
      emergencyId: (json['emergencyId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      emergencyType: json['emergencyType'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      nearbyVolunteers: (json['nearbyVolunteers'] as List<dynamic>? ?? const [])
          .map((item) => NearbyVolunteer.fromJson(item as Map<String, dynamic>)).toList(),
      notificationsSent: (json['notificationsSent'] as num?)?.toInt() ?? 0,
      notificationMessage: json['notificationMessage'] as String? ?? 'Notification status unavailable',
    );
  }
}

class NearbyVolunteer {
  const NearbyVolunteer({required this.volunteerId, required this.name, required this.phone,
    required this.category, required this.college, required this.distanceKm});
  final int volunteerId;
  final String name;
  final String phone;
  final String category;
  final String college;
  final double distanceKm;
  factory NearbyVolunteer.fromJson(Map<String, dynamic> json) => NearbyVolunteer(
    volunteerId: (json['volunteerId'] as num).toInt(), name: json['name'] as String,
    phone: json['phone'] as String, category: json['category'] as String,
    college: json['college'] as String, distanceKm: (json['distanceKm'] as num).toDouble());
}
