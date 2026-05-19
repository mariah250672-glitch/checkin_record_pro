import '../utils/hash_utils.dart';
import 'check_in_record.dart';

class Block {
  Block({
    required this.index,
    required this.timestamp,
    required this.payload,
    required this.prevHash,
    required this.hash,
  });

  final int index;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final String prevHash;
  final String hash;

  CheckInRecord? get checkInRecord {
    if (payload['type'] != 'checkin') return null;
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return null;
    return CheckInRecord.fromPayload(data);
  }

  String get payloadHash => sha256Hex(canonicalJson(payload));

  static String computeHash({
    required int index,
    required String prevHash,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) {
    final body = {
      'index': index,
      'prevHash': prevHash,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
    return sha256Hex(canonicalJson(body));
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
        'prevHash': prevHash,
        'hash': hash,
      };

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      index: json['index'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      prevHash: json['prevHash'] as String,
      hash: json['hash'] as String,
    );
  }

  static Block genesis() {
    final payload = {
      'type': 'genesis',
      'message': 'Checkin Record Pro Genesis',
    };
    const prevHash = '0';
    final timestamp = DateTime.now();
    final hash = computeHash(
      index: 0,
      prevHash: prevHash,
      timestamp: timestamp,
      payload: payload,
    );
    return Block(
      index: 0,
      timestamp: timestamp,
      payload: payload,
      prevHash: prevHash,
      hash: hash,
    );
  }
}
