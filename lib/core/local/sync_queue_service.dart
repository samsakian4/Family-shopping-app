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

  /// The server changed this entity after our offline edit's base version
  /// — stop auto-retrying and surface it for the user to resolve
  /// (07_SYNC_ENGINE.md - Conflict Detection: "If automatic resolution is
  /// impossible: Preserve both versions. Prompt the user to choose.").
  Future<void> markConflict(SyncQueueEntry entry) async {
    await _isar.writeTxn(() async {
      entry.status = SyncQueueStatus.conflict;
      entry.updatedAt = DateTime.now();
      await _isar.syncQueueEntrys.put(entry);
    });
  }

  Stream<List<SyncQueueEntry>> watchConflicts() {
    return _isar.syncQueueEntrys
        .filter()
        .statusEqualTo(SyncQueueStatus.conflict)
        .watch(fireImmediately: true);
  }

  /// Re-queues a conflicted entry as pending again — used when the user
  /// picks "keep my change" and wants it retried.
  Future<void> requeue(SyncQueueEntry entry) async {
    await _isar.writeTxn(() async {
      entry.status = SyncQueueStatus.pending;
      entry.retryCount = 0;
      entry.updatedAt = DateTime.now();
      await _isar.syncQueueEntrys.put(entry);
    });
  }

  Future<void> discard(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueEntrys.delete(id);
    });
  }
}
