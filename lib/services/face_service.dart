import 'dart:math';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'storage_service.dart';

class FaceMatchResult {
  FaceMatchResult({required this.matched, required this.score});

  final bool matched;
  final double score;
}

class FaceService {
  FaceService._();
  static final FaceService instance = FaceService._();

  static const double matchThreshold = 0.82;
  static const int enrollmentSamples = 3;
  static const int faceSize = 64;

  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: false,
    ),
  );

  final _storage = StorageService.instance;

  Future<void> dispose() => _detector.close();

  Future<List<Face>> detectFaces(InputImage image) async {
    return _detector.processImage(image);
  }

  InputImage inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    int rotation,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      throw Exception('不支持的相机图像格式');
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(rotation) ??
            InputImageRotation.rotation0deg,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<List<double>?> embeddingFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    int rotation,
  ) async {
    final input = inputImageFromCameraImage(image, camera, rotation);
    final faces = await detectFaces(input);
    if (faces.isEmpty) return null;
    final face = faces.first;
    final rgb = _cameraImageToRgb(image);
    if (rgb == null) return null;
    return _embeddingFromRgb(rgb, image.width, image.height, face);
  }

  Future<FaceMatchResult> matchCameraImage(
    CameraImage image,
    CameraDescription camera,
    int rotation,
  ) async {
    final template = await _storage.loadFaceEmbedding();
    if (template == null) {
      return FaceMatchResult(matched: false, score: 0);
    }
    final embedding = await embeddingFromCameraImage(image, camera, rotation);
    if (embedding == null) {
      return FaceMatchResult(matched: false, score: 0);
    }
    final score = _cosineSimilarity(template, embedding);
    return FaceMatchResult(
      matched: score >= matchThreshold,
      score: score,
    );
  }

  Future<void> enrollFromSamples(List<List<double>> samples) async {
    if (samples.isEmpty) {
      throw Exception('未采集到有效人脸样本');
    }
    final dim = samples.first.length;
    final avg = List<double>.filled(dim, 0);
    for (final sample in samples) {
      for (var i = 0; i < dim; i++) {
        avg[i] += sample[i];
      }
    }
    for (var i = 0; i < dim; i++) {
      avg[i] /= samples.length;
    }
    final normalized = _l2Normalize(avg);
    await _storage.saveFaceEmbedding(normalized);
    await _storage.setFaceEnrolled(true);
  }

  img.Image? _cameraImageToRgb(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _yuv420ToImage(image);
    }
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return _bgra8888ToImage(image);
    }
    return null;
  }

  img.Image? _yuv420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final out = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvRow = (y ~/ 2) * uPlane.bytesPerRow;
        final uvCol = (x ~/ 2) * uPlane.bytesPerPixel!;
        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvRow + uvCol];
        final vValue = vPlane.bytes[uvRow + uvCol];
        final rgb = _yuvToRgb(yValue, uValue, vValue);
        out.setPixelRgb(x, y, rgb[0], rgb[1], rgb[2]);
      }
    }
    return out;
  }

  List<int> _yuvToRgb(int y, int u, int v) {
    var r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
    var g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round().clamp(0, 255);
    var b = (y + 1.772 * (u - 128)).round().clamp(0, 255);
    return [r, g, b];
  }

  img.Image? _bgra8888ToImage(CameraImage image) {
    final plane = image.planes.first;
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: plane.bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  List<double>? _embeddingFromRgb(
    img.Image source,
    int frameWidth,
    int frameHeight,
    Face face,
  ) {
    final box = face.boundingBox;
    final left = box.left.clamp(0, frameWidth - 1).toInt();
    final top = box.top.clamp(0, frameHeight - 1).toInt();
    final right = box.right.clamp(0, frameWidth.toDouble()).toInt();
    final bottom = box.bottom.clamp(0, frameHeight.toDouble()).toInt();
    final w = (right - left).clamp(1, frameWidth);
    final h = (bottom - top).clamp(1, frameHeight);
    final cropped = img.copyCrop(
      source,
      x: left,
      y: top,
      width: w,
      height: h,
    );
    final resized = img.copyResize(
      cropped,
      width: faceSize,
      height: faceSize,
      interpolation: img.Interpolation.linear,
    );
    final gray = img.grayscale(resized);
    final vector = <double>[];
    for (var y = 0; y < faceSize; y++) {
      for (var x = 0; x < faceSize; x++) {
        final pixel = gray.getPixel(x, y);
        vector.add(pixel.r / 255.0);
      }
    }
    return _l2Normalize(vector);
  }

  List<double> _l2Normalize(List<double> vector) {
    var norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = sqrt(norm);
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    final len = min(a.length, b.length);
    var dot = 0.0;
    for (var i = 0; i < len; i++) {
      dot += a[i] * b[i];
    }
    return dot.clamp(-1.0, 1.0);
  }
}
