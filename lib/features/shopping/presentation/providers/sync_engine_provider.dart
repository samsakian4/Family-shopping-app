import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/core/sync/sync_engine.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_item_providers.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_providers.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'sync_engine_provider.g.dart';

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    ref.watch(syncQueueServiceProvider),
    ref.watch(networkInfoProvider),
    ref.watch(shoppingListRemoteDataSourceProvider),
    ref.watch(shoppingItemRemoteDataSourceProvider),
    ref.watch(shoppingListLocalCacheProvider),
    ref.watch(shoppingItemLocalCacheProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
}

/// Entries the sync engine could not auto-apply because the server
/// changed first (07_SYNC_ENGINE.md - Conflict Detection).
@riverpod
Stream<List<SyncQueueEntry>> syncConflicts(Ref ref) {
  return ref.watch(syncQueueServiceProvider).watchConflicts();
}
