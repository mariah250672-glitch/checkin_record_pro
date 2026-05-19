import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/geofence_config.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<bool> ensurePermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('请开启设备定位服务');
    }
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      throw Exception('需要定位权限才能签到');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  bool isWithinGeofence({
    required GeofenceConfig fence,
    required double latitude,
    required double longitude,
  }) {
    final distance = Geolocator.distanceBetween(
      fence.latitude,
      fence.longitude,
      latitude,
      longitude,
    );
    return distance <= fence.radiusMeters;
  }

  double distanceToGeofenceCenter({
    required GeofenceConfig fence,
    required double latitude,
    required double longitude,
  }) {
    return Geolocator.distanceBetween(
      fence.latitude,
      fence.longitude,
      latitude,
      longitude,
    );
  }
}
