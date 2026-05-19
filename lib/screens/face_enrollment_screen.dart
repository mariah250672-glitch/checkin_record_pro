import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/face_service.dart';
import '../services/storage_service.dart';
import '../widgets/face_camera_panel.dart';
import 'geofence_setup_screen.dart';
import 'home_screen.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  static const route = '/face-enroll';

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _controller;
  CameraDescription? _camera;
  final _samples = <List<double>>[];
  bool _capturing = false;
  String _status = '请将面部置于画面中央，点击按钮采集';

  int get _required => FaceService.enrollmentSamples;

  Future<List<double>?> _captureOneEmbedding() async {
    final controller = _controller;
    final camera = _camera;
    if (controller == null || camera == null) return null;

    final completer = Completer<List<double>?>();
    final rotation = controller.description.sensorOrientation;

    await controller.startImageStream((image) async {
      if (completer.isCompleted) return;
      try {
        final embedding = await FaceService.instance.embeddingFromCameraImage(
          image,
          camera,
          rotation,
        );
        if (embedding != null && !completer.isCompleted) {
          await controller.stopImageStream();
          completer.complete(embedding);
        }
      } catch (_) {}
    });

    try {
      return await completer.future.timeout(
        const Duration(seconds: 8),
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

  Future<void> _captureFromStream() async {
    if (_capturing) return;
    setState(() {
      _capturing = true;
      _status = '正在分析人脸…';
    });

    final embedding = await _captureOneEmbedding();
    if (!mounted) return;

    if (embedding == null) {
      setState(() {
        _capturing = false;
        _status = '未检测到人脸，请正对摄像头重试';
      });
      return;
    }

    _samples.add(embedding);
    if (_samples.length >= _required) {
      try {
        await FaceService.instance.enrollFromSamples(_samples);
        if (!mounted) return;
        final hasGeofence =
            await StorageService.instance.loadGeofence() != null;
        if (hasGeofence) {
          Navigator.pushReplacementNamed(context, HomeScreen.route);
        } else {
          Navigator.pushReplacementNamed(context, GeofenceSetupScreen.route);
        }
      } catch (e) {
        setState(() {
          _capturing = false;
          _status = '保存失败: $e';
        });
      }
      return;
    }

    setState(() {
      _capturing = false;
      _status = '已采集 ${_samples.length}/$_required，请略微转头后再次采集';
    });
  }

  void _onCameraReady(CameraController controller, CameraDescription camera) {
    _controller = controller;
    _camera = camera;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('录入人脸')),
      body: Column(
        children: [
          Expanded(
            child: FaceCameraPanel(
              overlayHint: _status,
              busy: _capturing,
              onCameraReady: _onCameraReady,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: _samples.length / _required),
                const SizedBox(height: 8),
                Text('进度: ${_samples.length}/$_required'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _capturing ? null : _captureFromStream,
                  child: const Text('采集当前人脸'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
