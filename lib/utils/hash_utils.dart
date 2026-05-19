import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 对 Map 做键排序后 JSON 编码，保证哈希可复现。
String canonicalJson(Map<String, dynamic> data) {
  final sorted = _sortMap(data);
  return jsonEncode(sorted);
}

Map<String, dynamic> _sortMap(Map<String, dynamic> map) {
  final keys = map.keys.toList()..sort();
  final result = <String, dynamic>{};
  for (final key in keys) {
    final value = map[key];
    if (value is Map<String, dynamic>) {
      result[key] = _sortMap(value);
    } else if (value is List) {
      result[key] = value;
    } else {
      result[key] = value;
    }
  }
  return result;
}

String sha256Hex(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}
