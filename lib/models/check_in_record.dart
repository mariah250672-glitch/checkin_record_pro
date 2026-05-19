class CheckInRecord {
  CheckInRecord({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.faceMatchScore,
    required this.withinGeofence,
    required this.deviceNote,
  });

  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double faceMatchScore;
  final bool withinGeofence;
  final String deviceNote;

  Map<String, dynamic> toPayload() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'faceMatchScore': faceMatchScore,
        'withinGeofence': withinGeofence,
        'deviceNote': deviceNote,
      };

  factory CheckInRecord.fromPayload(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      faceMatchScore: (json['faceMatchScore'] as num).toDouble(),
      withinGeofence: json['withinGeofence'] as bool,
      deviceNote: json['deviceNote'] as String? ?? '',
    );
  }
}
