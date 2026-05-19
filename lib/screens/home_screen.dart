import 'package:flutter/material.dart';

import '../services/blockchain_service.dart';
import '../services/storage_service.dart';
import 'check_in_screen.dart';
import 'face_enrollment_screen.dart';
import 'geofence_setup_screen.dart';
import 'history_screen.dart';
import 'profile_setup_screen.dart';
import 'verify_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nickname = '';
  String _chainStatus = '校验中…';
  bool _chainValid = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await StorageService.instance.loadProfile();
    final validation = await BlockchainService.instance.validateChain();
    if (!mounted) return;
    setState(() {
      _nickname = profile?.nickname ?? '用户';
      _chainValid = validation.valid;
      _chainStatus = validation.valid
          ? '本地区块链完整'
          : '链已损坏（索引 ${validation.brokenIndex}）';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('签到记录器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('你好，$_nickname', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _chainValid ? Icons.verified : Icons.warning,
                  color: _chainValid ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_chainStatus)),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckInScreen()),
                );
                _load();
              },
              icon: const Icon(Icons.fingerprint),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('立即签到', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('签到历史'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, VerifyScanScreen.route);
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('扫码校验记录'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('重新录入人脸'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, FaceEnrollmentScreen.route);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('修改签到范围'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, GeofenceSetupScreen.route);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('编辑资料'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, ProfileSetupScreen.route);
              },
            ),
          ],
        ),
      ),
    );
  }
}
