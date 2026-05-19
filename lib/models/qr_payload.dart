import 'dart:convert';

import '../utils/hash_utils.dart';

/// S2 自包含校验二维码载荷。
class QrPayload {
  QrPayload({
    required this.version,
    required this.recordId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.faceMatchScore,
    required this.withinGeofence,
    required this.deviceNote,
    required this.payloadHash,
    required this.blockIndex,
    required this.blockHash,
    required this.prevBlockHash,
    required this.chainTailHash,
  });

  static const int currentVersion = 1;
  static const String type = 'checkin_verify';

  final int version;
  final String recordId;
  final String timestamp;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double faceMatchScore;
  final bool withinGeofence;
  final String deviceNote;
  final String payloadHash;
  final int blockIndex;
  final String blockHash;
  final String prevBlockHash;
  final String chainTailHash;

  Map<String, dynamic> toJson() => {
        'v': version,
        'type': type,
        'recordId': recordId,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'faceMatchScore': faceMatchScore,
        'withinGeofence': withinGeofence,
        'deviceNote': deviceNote,
        'payloadHash': payloadHash,
        'blockIndex': blockIndex,
        'blockHash': blockHash,
        'prevBlockHash': prevBlockHash,
        'chainTailHash': chainTailHash,
      };

  String encode() => jsonEncode(toJson());

  static QrPayload? decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['type'] != type) return null;
      return QrPayload(
        version: json['v'] as int? ?? 1,
        recordId: json['recordId'] as String,
        timestamp: json['timestamp'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
        faceMatchScore: (json['faceMatchScore'] as num).toDouble(),
        withinGeofence: json['withinGeofence'] as bool? ?? true,
        deviceNote: json['deviceNote'] as String? ?? '',
        payloadHash: json['payloadHash'] as String,
        blockIndex: json['blockIndex'] as int,
        blockHash: json['blockHash'] as String,
        prevBlockHash: json['prevBlockHash'] as String,
        chainTailHash: json['chainTailHash'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// 根据 QR 内字段复算 payload 哈希并校验 block 哈希结构。
  VerificationResult verifyIntegrity() {
    final payload = {
      'type': 'checkin',
      'data': {
        'id': recordId,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'faceMatchScore': faceMatchScore,
        'withinGeofence': withinGeofence,
        'deviceNote': deviceNote,
      },
    };
    final expectedPayloadHash = sha256Hex(canonicalJson(payload));
    if (expectedPayloadHash != payloadHash) {
      return VerificationResult(
        valid: false,
        message: '记录内容哈希不匹配，数据可能被篡改',
      );
    }

    final blockBody = {
      'index': blockIndex,
      'prevHash': prevBlockHash,
      'timestamp': timestamp,
      'payload': payload,
    };
    final expectedBlockHash = sha256Hex(canonicalJson(blockBody));
    if (expectedBlockHash != blockHash) {
      return VerificationResult(
        valid: false,
        message: '区块哈希不匹配，链上结构可能被篡改',
      );
    }

    return VerificationResult(
      valid: true,
      message: '校验通过：记录与区块哈希一致（链尾: ${chainTailHash.substring(0, 8)}…）',
    );
  }
}

class VerificationResult {
  VerificationResult({required this.valid, required this.message});

  final bool valid;
  final String message;
}
