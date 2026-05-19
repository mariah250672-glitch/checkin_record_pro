import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'face_enrollment_screen.dart';
import 'geofence_setup_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = StorageService.instance;
    final profile = await storage.loadProfile();
    if (!mounted) return;

    if (profile == null) {
      Navigator.pushReplacementNamed(context, ProfileSetupScreen.route);
      return;
    }
    if (!await storage.isFaceEnrolled()) {
      Navigator.pushReplacementNamed(context, FaceEnrollmentScreen.route);
      return;
    }
    if (await storage.loadGeofence() == null) {
      Navigator.pushReplacementNamed(context, GeofenceSetupScreen.route);
      return;
    }
    await storage.setOnboardingDone(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, HomeScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 72, color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('签到记录器', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('正在初始化本地区块链…'),
          ],
        ),
      ),
    );
  }
}
