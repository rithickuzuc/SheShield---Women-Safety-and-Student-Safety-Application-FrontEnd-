class LocationUpdateResponse {
  const LocationUpdateResponse({
    required this.message,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.locationUpdatedAt,
  });

  final String message;
  final int userId;
  final double latitude;
  final double longitude;
  final DateTime locationUpdatedAt;

  factory LocationUpdateResponse.fromJson(Map<String, dynamic> json) {
    return LocationUpdateResponse(
      message: json['message'] as String? ?? 'Location updated successfully',
      userId: (json['userId'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationUpdatedAt: DateTime.parse(json['locationUpdatedAt'] as String),
    );
  }
}
