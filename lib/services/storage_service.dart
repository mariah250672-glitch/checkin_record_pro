import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/block.dart';
import '../models/geofence_config.dart';
import '../models/user_profile.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _keyProfile = 'user_profile';
  static const _keyGeofence = 'geofence_config';
  static const _keyFaceEnrolled = 'face_enrolled';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _faceTemplateKey = 'face_template_embedding';

  final _secure = const FlutterSecureStorage();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<File> get _chainFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/blockchain.json');
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyProfile);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _prefs;
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  Future<GeofenceConfig?> loadGeofence() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyGeofence);
    if (raw == null) return null;
    return GeofenceConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveGeofence(GeofenceConfig config) async {
    final prefs = await _prefs;
    await prefs.setString(_keyGeofence, jsonEncode(config.toJson()));
  }

  Future<bool> isFaceEnrolled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyFaceEnrolled) ?? false;
  }

  Future<void> setFaceEnrolled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyFaceEnrolled, value);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboardingDone, value);
  }

  Future<void> saveFaceEmbedding(List<double> embedding) async {
    await _secure.write(
      key: _faceTemplateKey,
      value: jsonEncode(embedding),
    );
  }

  Future<List<double>?> loadFaceEmbedding() async {
    final raw = await _secure.read(key: _faceTemplateKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => (e as num).toDouble()).toList();
  }

  Future<void> clearFaceEmbedding() async {
    await _secure.delete(key: _faceTemplateKey);
    await setFaceEnrolled(false);
  }

  Future<List<Block>> loadChain() async {
    final file = await _chainFile;
    if (!await file.exists()) {
      final genesis = Block.genesis();
      await saveChain([genesis]);
      return [genesis];
    }
    final content = await file.readAsString();
    final list = jsonDecode(content) as List;
    return list
        .map((e) => Block.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveChain(List<Block> chain) async {
    final file = await _chainFile;
    final encoded = jsonEncode(chain.map((b) => b.toJson()).toList());
    await file.writeAsString(encoded);
  }

  Future<String> exportChainSnapshot() async {
    final file = await _chainFile;
    return file.readAsString();
  }
}
