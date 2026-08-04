/// Sync states for any locally-cached record (07_SYNC_ENGINE.md -
/// Synchronization States). `isar_generator` maps enums via `@enumerated`.
enum SyncStatus { pending, syncing, synced, failed, conflict }
