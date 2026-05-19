import '../models/block.dart';
import '../models/check_in_record.dart';
import 'storage_service.dart';

class ChainValidationResult {
  ChainValidationResult({required this.valid, this.brokenIndex});

  final bool valid;
  final int? brokenIndex;
}

class BlockchainService {
  BlockchainService._();
  static final BlockchainService instance = BlockchainService._();

  final _storage = StorageService.instance;

  Future<List<Block>> getChain() => _storage.loadChain();

  Future<String> getChainTailHash() async {
    final chain = await getChain();
    return chain.last.hash;
  }

  Future<ChainValidationResult> validateChain() async {
    final chain = await getChain();
    if (chain.isEmpty) {
      return ChainValidationResult(valid: false, brokenIndex: 0);
    }

    for (var i = 0; i < chain.length; i++) {
      final block = chain[i];
      final expectedHash = Block.computeHash(
        index: block.index,
        prevHash: block.prevHash,
        timestamp: block.timestamp,
        payload: block.payload,
      );
      if (expectedHash != block.hash) {
        return ChainValidationResult(valid: false, brokenIndex: i);
      }
      if (i > 0 && block.prevHash != chain[i - 1].hash) {
        return ChainValidationResult(valid: false, brokenIndex: i);
      }
    }
    return ChainValidationResult(valid: true);
  }

  Future<Block> appendCheckIn(CheckInRecord record) async {
    final chain = await getChain();
    final prev = chain.last;
    final index = prev.index + 1;
    final timestamp = DateTime.now();
    final payload = {
      'type': 'checkin',
      'data': record.toPayload(),
    };
    final hash = Block.computeHash(
      index: index,
      prevHash: prev.hash,
      timestamp: timestamp,
      payload: payload,
    );
    final block = Block(
      index: index,
      timestamp: timestamp,
      payload: payload,
      prevHash: prev.hash,
      hash: hash,
    );
    chain.add(block);
    await _storage.saveChain(chain);
    return block;
  }

  Future<Block?> findBlockByRecordId(String recordId) async {
    final chain = await getChain();
    for (final block in chain.reversed) {
      final record = block.checkInRecord;
      if (record?.id == recordId) return block;
    }
    return null;
  }
}
