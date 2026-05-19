import '../models/block.dart';
import '../models/check_in_record.dart';
import '../models/qr_payload.dart';
import 'blockchain_service.dart';

class QrService {
  QrService._();
  static final QrService instance = QrService._();

  Future<QrPayload> buildPayloadForRecord({
    required CheckInRecord record,
    required Block block,
    required String chainTailHash,
  }) async {
    return QrPayload(
      version: QrPayload.currentVersion,
      recordId: record.id,
      timestamp: block.timestamp.toIso8601String(),
      latitude: record.latitude,
      longitude: record.longitude,
      accuracyMeters: record.accuracyMeters,
      faceMatchScore: record.faceMatchScore,
      withinGeofence: record.withinGeofence,
      deviceNote: record.deviceNote,
      payloadHash: block.payloadHash,
      blockIndex: block.index,
      blockHash: block.hash,
      prevBlockHash: block.prevHash,
      chainTailHash: chainTailHash,
    );
  }

  Future<QrPayload?> buildPayloadByRecordId(String recordId) async {
    final block =
        await BlockchainService.instance.findBlockByRecordId(recordId);
    if (block == null) return null;
    final record = block.checkInRecord;
    if (record == null) return null;
    final tail = await BlockchainService.instance.getChainTailHash();
    return buildPayloadForRecord(
      record: record,
      block: block,
      chainTailHash: tail,
    );
  }
}
