import 'package:flutter/material.dart';

import '../models/geofence_config.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class GeofenceSetupScreen extends StatefulWidget {
  const GeofenceSetupScreen({super.key});

  static const route = '/geofence';

  @override
  State<GeofenceSetupScreen> createState() => _GeofenceSetupScreenState();
}

class _GeofenceSetupScreenState extends State<GeofenceSetupScreen> {
  double _radius = 100;
  double? _lat;
  double? _lng;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final fence = await StorageService.instance.loadGeofence();
    if (fence == null || !mounted) return;
    setState(() {
      _lat = fence.latitude;
      _lng = fence.longitude;
      _radius = fence.radiusMeters;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先设置签到点位置')),
      );
      return;
    }
    final alreadyOnboarded =
        await StorageService.instance.isOnboardingDone();
    await StorageService.instance.saveGeofence(
      GeofenceConfig(
        latitude: _lat!,
        longitude: _lng!,
        radiusMeters: _radius,
        updatedAt: DateTime.now(),
      ),
    );
    await StorageService.instance.setOnboardingDone(true);
    if (!mounted) return;
    if (alreadyOnboarded && Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置签到范围')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '方案 A：以选定坐标为圆心，超出半径将拒绝签到。',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loading ? null : _useCurrentLocation,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('使用当前位置作为签到点'),
            ),
            const SizedBox(height: 16),
            if (_lat != null && _lng != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '圆心: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('允许半径: ${_radius.round()} 米'),
            Slider(
              value: _radius,
              min: 50,
              max: 500,
              divisions: 9,
              label: '${_radius.round()} m',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _save,
              child: const Text('完成设置并进入首页'),
            ),
          ],
        ),
      ),
    );
  }
}
