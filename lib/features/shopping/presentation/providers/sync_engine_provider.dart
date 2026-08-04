import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  );
  ref.onDispose(engine.dispose);
  return engine;
}
