import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'face_enrollment_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const route = '/profile';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;
  UserProfile? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final profile = await StorageService.instance.loadProfile();
    if (profile == null || !mounted) return;
    setState(() {
      _existing = profile;
      _nicknameController.text = profile.nickname;
      _noteController.text = profile.note;
    });
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写昵称')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = _existing;
    await StorageService.instance.saveProfile(
      UserProfile(
        nickname: nickname,
        note: _noteController.text.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    if (existing != null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, FaceEnrollmentScreen.route);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建个人资料')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '本应用为单用户本地模式，资料仅保存在本机。',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '昵称 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('下一步：录入人脸'),
            ),
          ],
        ),
      ),
    );
  }
}
