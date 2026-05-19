class GeofenceConfig {
  GeofenceConfig({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GeofenceConfig.fromJson(Map<String, dynamic> json) {
    return GeofenceConfig(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
