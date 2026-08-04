import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/features/shopping/data/models/category_local.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_item_local.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_list_local.dart';

/// Opens the single Isar instance for the app
/// (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md - Local Database Technology).
/// Called once from `main()` before `runApp`.
class AppDatabase {
  AppDatabase._();

  static Future<Isar> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        ShoppingListLocalSchema,
        ShoppingItemLocalSchema,
        CategoryLocalSchema,
        SyncQueueEntrySchema,
        // New collections (profile cache, family cache, ...) are added
        // here as their offline support lands — never remove an existing
        // schema without a migration plan (26_DATABASE_MIGRATION_STRATEGY.md
        // principles apply to local schemas too).
      ],
      directory: dir.path,
      name: 'family_shopping_app',
    );
  }
}
