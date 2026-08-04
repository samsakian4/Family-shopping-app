import 'dart:convert';

import 'package:isar/isar.dart';

import 'package:family_shopping_app/core/local/sync_queue_entry.dart';

/// CRUD over the offline write queue (07_SYNC_ENGINE.md - Queue Table).
class SyncQueueService {
  final Isar _isar;
  SyncQueueService(this._isar);

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.syncQueueEntrys.put(
        SyncQueueEntry()
          ..entityType = entityType
          ..entityId = entityId
          ..operation = operation
          ..payloadJson = jsonEncode(payload)
          ..status = SyncQueueStatus.pending
          ..createdAt = now
          ..updatedAt = now,
      );
    });
  }

  Future<List<SyncQueueEntry>> getPending() {
    return _isar.syncQueueEntrys
        .filter()
        .statusEqualTo(SyncQueueStatus.pending)
        .sortByCreatedAt()
        .findAll();
  }

  Stream<int> watchPendingCount() {
    return _isar.syncQueueEntrys
        .filter()
        .statusEqualTo(SyncQueueStatus.pending)
        .watch(fireImmediately: true)
        .map((rows) => rows.length);
  }

  Future<void> markSynced(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueEntrys.delete(id);
    });
  }

  /// Bumps retry count / marks failed after exhausting the retry policy
  /// (07_SYNC_ENGINE.md - Retry Policy).
  Future<void> markFailedAttempt(SyncQueueEntry entry, {required int maxRetries}) async {
    await _isar.writeTxn(() async {
      entry.retryCount += 1;
      entry.status = entry.retryCount >= maxRetries
          ? SyncQueueStatus.failed
          : SyncQueueStatus.pending;
      entry.updatedAt = DateTime.now();
      await _isar.syncQueueEntrys.put(entry);
    });
  }
}
