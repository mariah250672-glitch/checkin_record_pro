import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/block.dart';
import '../services/blockchain_service.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Block> _blocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chain = await BlockchainService.instance.getChain();
    final checkins = chain.where((b) => b.checkInRecord != null).toList().reversed.toList();
    if (!mounted) return;
    setState(() {
      _blocks = checkins;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('签到历史')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocks.isEmpty
              ? const Center(child: Text('暂无签到记录'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _blocks.length,
                    itemBuilder: (context, index) {
                      final block = _blocks[index];
                      final record = block.checkInRecord!;
                      final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${block.index}'),
                        ),
                        title: Text(fmt.format(record.timestamp)),
                        subtitle: Text(
                          '人脸 ${(record.faceMatchScore * 100).toStringAsFixed(0)}% · '
                          '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordDetailScreen(block: block),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
