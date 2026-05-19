import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/block.dart';
import '../models/qr_payload.dart';
import '../services/blockchain_service.dart';
import '../services/qr_service.dart';

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.block});

  final Block block;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  QrPayload? _qrPayload;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buildQr();
  }

  Future<void> _buildQr() async {
    final record = widget.block.checkInRecord;
    if (record == null) return;
    final tail = await BlockchainService.instance.getChainTailHash();
    final payload = await QrService.instance.buildPayloadForRecord(
      record: record,
      block: widget.block,
      chainTailHash: tail,
    );
    if (!mounted) return;
    setState(() {
      _qrPayload = payload;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.block.checkInRecord;
    if (record == null) {
      return const Scaffold(
        body: Center(child: Text('无效记录')),
      );
    }
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final qrData = _qrPayload?.encode();

    return Scaffold(
      appBar: AppBar(title: const Text('记录详情')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('时间', style: Theme.of(context).textTheme.labelLarge),
            Text(fmt.format(record.timestamp)),
            const SizedBox(height: 12),
            Text('位置', style: Theme.of(context).textTheme.labelLarge),
            Text('${record.latitude}, ${record.longitude}'),
            Text('精度约 ${record.accuracyMeters.round()} 米'),
            const SizedBox(height: 12),
            Text('人脸匹配', style: Theme.of(context).textTheme.labelLarge),
            Text('${(record.faceMatchScore * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            Text('区块哈希', style: Theme.of(context).textTheme.labelLarge),
            SelectableText(
              widget.block.hash,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            Text('校验二维码（S2 自包含）', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (qrData != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240,
                    gapless: true,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              '另一台设备可使用「扫码校验」扫描此码，无需联网。',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
