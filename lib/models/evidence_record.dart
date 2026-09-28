class EvidenceRecord {
  const EvidenceRecord({required this.id, required this.emergencyId, required this.createdAt,
    required this.latitude, required this.longitude, this.audioPath, this.videoPath});
  final String id;
  final int emergencyId;
  final DateTime createdAt;
  final double latitude, longitude;
  final String? audioPath, videoPath;
  Map<String, dynamic> toJson() => {'id': id, 'emergencyId': emergencyId, 'createdAt': createdAt.toIso8601String(), 'latitude': latitude, 'longitude': longitude, 'audioPath': audioPath, 'videoPath': videoPath};
  factory EvidenceRecord.fromJson(Map<String, dynamic> json) => EvidenceRecord(id: json['id'].toString(), emergencyId: (json['emergencyId'] as num).toInt(), createdAt: DateTime.parse(json['createdAt'].toString()), latitude: (json['latitude'] as num).toDouble(), longitude: (json['longitude'] as num).toDouble(), audioPath: json['audioPath']?.toString(), videoPath: json['videoPath']?.toString());
  EvidenceRecord copyWith({String? audioPath, String? videoPath}) => EvidenceRecord(id: id, emergencyId: emergencyId, createdAt: createdAt, latitude: latitude, longitude: longitude, audioPath: audioPath ?? this.audioPath, videoPath: videoPath ?? this.videoPath);
}
