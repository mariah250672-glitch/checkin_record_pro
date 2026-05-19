import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/check_in_record.dart';
import '../services/blockchain_service.dart';
import '../services/face_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/face_camera_panel.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  CameraController? _controller;
  CameraDescription? _camera;
  bool _processing = false;
  bool _locationReady = false;
  String _status = '正在获取定位…';
  double? _distanceMeters;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _prepareLocation();
  }

  Future<void> _prepareLocation() async {
    final fence = await StorageService.instance.loadGeofence();
    if (fence == null) {
      setState(() => _status = '未设置签到范围');
      return;
    }
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      final distance = LocationService.instance.distanceToGeofenceCenter(
        fence: fence,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      final within = LocationService.instance.isWithinGeofence(
        fence: fence,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      setState(() {
        _distanceMeters = distance;
        _status = within
            ? '已在签到范围内（距圆心 ${distance.round()}m），请进行人脸校验'
            : '不在签到范围内（距圆心 ${distance.round()}m，允许 ${fence.radiusMeters.round()}m），无法签到';
      });
      if (!within) return;
      _position = pos;
      _locationReady = true;
    } catch (e) {
      setState(() => _status = '$e');
    }
  }

  Future<void> _submitCheckIn() async {
    final fence = await StorageService.instance.loadGeofence();
    final pos = _position;
    if (fence == null || pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位未就绪或不在范围内')),
      );
      return;
    }

    final within = LocationService.instance.isWithinGeofence(
      fence: fence,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!within) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置异常：已拒绝签到')),
      );
      return;
    }

    setState(() {
      _processing = true;
      _status = '正在校验人脸…';
    });

    final match = await _captureFaceMatch();
    if (!mounted) return;

    if (match == null || !match.matched) {
      setState(() {
        _processing = false;
        _status = match == null
            ? '未检测到人脸'
            : '人脸不匹配（${(match.score * 100).toStringAsFixed(1)}%）';
      });
      return;
    }

    final record = CheckInRecord(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      faceMatchScore: match.score,
      withinGeofence: true,
      deviceNote: 'android',
    );

    try {
      await BlockchainService.instance.appendCheckIn(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('签到成功，已写入本地区块链')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _processing = false;
        _status = '写入失败: $e';
      });
    }
  }

  Future<FaceMatchResult?> _captureFaceMatch() async {
    final controller = _controller;
    final camera = _camera;
    if (controller == null || camera == null) return null;

    final completer = Completer<FaceMatchResult?>();
    final rotation = controller.description.sensorOrientation;

    await controller.startImageStream((image) async {
      if (completer.isCompleted) return;
      try {
        final result = await FaceService.instance.matchCameraImage(
          image,
          camera,
          rotation,
        );
        if (result.matched && !completer.isCompleted) {
          await controller.stopImageStream();
          completer.complete(result);
        }
      } catch (_) {}
    });

    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          if (controller.value.isStreamingImages) {
            await controller.stopImageStream();
          }
          return null;
        },
      );
    } catch (_) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      return null;
    }
  }

  void _onCameraReady(CameraController controller, CameraDescription camera) {
    _controller = controller;
    _camera = camera;
  }

  bool get _canSubmit => _locationReady && !_processing;

  @override
  Widget build(BuildContext context) {
    final canCheckIn = _canSubmit;
    return Scaffold(
      appBar: AppBar(title: const Text('签到')),
      body: Column(
        children: [
          Expanded(
            child: FaceCameraPanel(
              overlayHint: _status,
              busy: _processing,
              onCameraReady: _onCameraReady,
            ),
          ),
          if (_distanceMeters != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('距签到点: ${_distanceMeters!.round()} 米'),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: canCheckIn ? _submitCheckIn : null,
              child: _processing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认签到'),
            ),
          ),
        ],
      ),
    );
  }
}
