import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/qr_payload.dart';

class VerifyScanScreen extends StatefulWidget {
  const VerifyScanScreen({super.key});

  static const route = '/verify';

  @override
  State<VerifyScanScreen> createState() => _VerifyScanScreenState();
}

class _VerifyScanScreenState extends State<VerifyScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;
  VerificationResult? _result;
  QrPayload? _payload;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final payload = QrPayload.decode(raw);
    if (payload == null) return;

    _handled = true;
    _controller.stop();
    final result = payload.verifyIntegrity();
    setState(() {
      _payload = payload;
      _result = result;
    });
  }

  void _scanAgain() {
    setState(() {
      _handled = false;
      _result = null;
      _payload = null;
    });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null && _payload != null) {
      return _buildResult();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('扫码校验')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('扫描签到记录详情页中的二维码'),
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final payload = _payload!;
    final result = _result!;
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    DateTime? time;
    try {
      time = DateTime.parse(payload.timestamp);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: const Text('校验结果')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              result.valid ? Icons.check_circle : Icons.cancel,
              color: result.valid ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              result.valid ? '校验通过' : '校验失败',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(result.message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (time != null) Text('区块时间: ${fmt.format(time)}'),
            Text('记录 ID: ${payload.recordId}'),
            Text(
              '位置: ${payload.latitude.toStringAsFixed(6)}, ${payload.longitude.toStringAsFixed(6)}',
            ),
            Text('人脸得分: ${(payload.faceMatchScore * 100).toStringAsFixed(1)}%'),
            Text('链尾哈希前缀: ${payload.chainTailHash.substring(0, 12)}…'),
            const Spacer(),
            FilledButton(
              onPressed: _scanAgain,
              child: const Text('继续扫描'),
            ),
          ],
        ),
      ),
    );
  }
}
