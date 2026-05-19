import 'package:flutter/material.dart';

import 'screens/face_enrollment_screen.dart';
import 'screens/geofence_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_scan_screen.dart';

class CheckinApp extends StatelessWidget {
  const CheckinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '签到记录器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        ProfileSetupScreen.route: (_) => const ProfileSetupScreen(),
        FaceEnrollmentScreen.route: (_) => const FaceEnrollmentScreen(),
        GeofenceSetupScreen.route: (_) => const GeofenceSetupScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        VerifyScanScreen.route: (_) => const VerifyScanScreen(),
      },
    );
  }
}
