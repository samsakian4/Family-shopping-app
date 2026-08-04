import 'package:isar/isar.dart';

part 'sync_queue_entry.g.dart';

/// One queued offline write operation (07_SYNC_ENGINE.md - Queue Table).
/// Created whenever a write happens while offline (or optimistically
/// before the server confirms); processed by the sync engine in Phase 8.
@collection
class SyncQueueEntry {
  Id id = Isar.autoIncrement;

  /// e.g. 'shopping_list', 'shopping_item' (07_SYNC_ENGINE.md - entity_type).
  @Index()
  late String entityType;

  /// The entity's remote UUID (or a client-generated UUID for creates
  /// that haven't been confirmed by the server yet).
  @Index()
  late String entityId;

  /// 'create' | 'update' | 'delete' (07_SYNC_ENGINE.md - operation).
  late String operation;

  /// JSON-encoded payload of the change.
  late String payloadJson;

  int retryCount = 0;

  @enumerated
  SyncQueueStatus status = SyncQueueStatus.pending;

  late DateTime createdAt;
  late DateTime updatedAt;
}

enum SyncQueueStatus { pending, syncing, synced, failed }
