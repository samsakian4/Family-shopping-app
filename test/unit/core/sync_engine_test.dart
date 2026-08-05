import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/sync/sync_engine.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_item_model.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_list_model.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

class MockSyncQueueService extends Mock implements SyncQueueService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockShoppingListRemoteDataSource extends Mock implements ShoppingListRemoteDataSource {}

class MockShoppingItemRemoteDataSource extends Mock implements ShoppingItemRemoteDataSource {}

class MockShoppingListLocalCache extends Mock implements ShoppingListLocalCache {}

class MockShoppingItemLocalCache extends Mock implements ShoppingItemLocalCache {}

SyncQueueEntry _entry({
  required String entityType,
  required String entityId,
  required String operation,
  required Map<String, dynamic> payload,
}) {
  return SyncQueueEntry()
    ..entityType = entityType
    ..entityId = entityId
    ..operation = operation
    ..payloadJson = jsonEncode(payload)
    ..createdAt = DateTime(2026)
    ..updatedAt = DateTime(2026);
}

void main() {
  late MockSyncQueueService queue;
  late MockNetworkInfo networkInfo;
  late MockShoppingListRemoteDataSource listRemote;
  late MockShoppingItemRemoteDataSource itemRemote;
  late MockShoppingListLocalCache listCache;
  late MockShoppingItemLocalCache itemCache;
  late SyncEngine engine;

  final fakeList = ShoppingListModel(
    id: 'l1',
    ownerId: 'u1',
    title: 'خرید',
    type: ShoppingListType.personal,
    archived: false,
    estimatedTotal: 0,
    updatedAt: DateTime(2026),
  );
  final fakeItem = ShoppingItemModel(
    id: 'i1',
    shoppingListId: 'l1',
    name: 'شیر',
    quantity: 1,
    purchased: false,
    updatedAt: DateTime(2026),
    sortOrder: 0,
  );

  setUp(() {
    queue = MockSyncQueueService();
    networkInfo = MockNetworkInfo();
    listRemote = MockShoppingListRemoteDataSource();
    itemRemote = MockShoppingItemRemoteDataSource();
    listCache = MockShoppingListLocalCache();
    itemCache = MockShoppingItemLocalCache();
    engine = SyncEngine(queue, networkInfo, listRemote, itemRemote, listCache, itemCache);

    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => queue.markSynced(any())).thenAnswer((_) async {});
    when(() => queue.markFailedAttempt(any(), maxRetries: any(named: 'maxRetries')))
        .thenAnswer((_) async {});
    when(() => queue.markConflict(any())).thenAnswer((_) async {});
    when(() => queue.discard(any())).thenAnswer((_) async {});
    when(() => listCache.getCached()).thenAnswer((_) async => []);
    when(() => listCache.upsert(any())).thenAnswer((_) async {});
    when(() => listCache.upsert(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => itemCache.upsert(any())).thenAnswer((_) async {});
    when(() => itemCache.upsert(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
  });

  test('a queued shopping_list create is replayed via createList with the same id', () async {
    when(() => queue.getPending()).thenAnswer((_) async => [
          _entry(
            entityType: 'shopping_list',
            entityId: 'l1',
            operation: 'create',
            payload: {'title': 'خرید', 'type': 'personal', 'family_id': null},
          ),
        ]);
    when(() => listRemote.createList(
          id: any(named: 'id'),
          title: any(named: 'title'),
          type: any(named: 'type'),
          familyId: any(named: 'familyId'),
        )).thenAnswer((_) async => fakeList);

    await engine.processQueue();

    verify(() => listRemote.createList(
          id: 'l1',
          title: 'خرید',
          type: ShoppingListType.personal,
          familyId: null,
        )).called(1);
    verify(() => queue.markSynced(any())).called(1);
  });

  test('a queued shopping_item create is replayed via addItem with the same id', () async {
    when(() => queue.getPending()).thenAnswer((_) async => [
          _entry(
            entityType: 'shopping_item',
            entityId: 'i1',
            operation: 'create',
            payload: {
              'shopping_list_id': 'l1',
              'name': 'شیر',
              'quantity': 2,
              'unit': null,
              'category_id': null,
              'brand': null,
              'notes': null,
              'estimated_price': null,
            },
          ),
        ]);
    when(() => itemRemote.addItem(
          id: any(named: 'id'),
          shoppingListId: any(named: 'shoppingListId'),
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
          unit: any(named: 'unit'),
          categoryId: any(named: 'categoryId'),
          brand: any(named: 'brand'),
          notes: any(named: 'notes'),
          estimatedPrice: any(named: 'estimatedPrice'),
        )).thenAnswer((_) async => fakeItem);

    await engine.processQueue();

    verify(() => itemRemote.addItem(
          id: 'i1',
          shoppingListId: 'l1',
          name: 'شیر',
          quantity: 2,
          unit: null,
          categoryId: null,
          brand: null,
          notes: null,
          estimatedPrice: null,
        )).called(1);
  });

  test('a queued mark_purchased operation calls setPurchased', () async {
    when(() => queue.getPending()).thenAnswer((_) async => [
          _entry(
            entityType: 'shopping_item',
            entityId: 'i1',
            operation: 'mark_purchased',
            payload: {'purchased': true, 'purchased_price': 5000},
          ),
        ]);
    when(() => itemRemote.setPurchased(
          itemId: any(named: 'itemId'),
          purchased: any(named: 'purchased'),
          purchasedPrice: any(named: 'purchasedPrice'),
        )).thenAnswer((_) async {});

    await engine.processQueue();

    verify(() => itemRemote.setPurchased(
          itemId: 'i1',
          purchased: true,
          purchasedPrice: 5000,
        )).called(1);
  });

  test('on remote failure, the entry is marked as a failed attempt instead of synced', () async {
    when(() => queue.getPending()).thenAnswer((_) async => [
          _entry(
            entityType: 'shopping_list',
            entityId: 'l1',
            operation: 'delete',
            payload: const {},
          ),
        ]);
    when(() => listRemote.softDeleteList(listId: any(named: 'listId')))
        .thenThrow(Exception('network blip'));

    await engine.processQueue();

    verify(() => queue.markFailedAttempt(any(), maxRetries: any(named: 'maxRetries')))
        .called(1);
    verifyNever(() => queue.markSynced(any()));
  });

  test('processQueue does nothing when offline', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    when(() => queue.getPending()).thenAnswer((_) async => [
          _entry(
            entityType: 'shopping_list',
            entityId: 'l1',
            operation: 'delete',
            payload: const {},
          ),
        ]);

    await engine.processQueue();

    verifyNever(() => listRemote.softDeleteList(listId: any(named: 'listId')));
  });

  group('conflict detection (update operations only)', () {
    test('applies normally when the server row is not newer than base_updated_at', () async {
      when(() => queue.getPending()).thenAnswer((_) async => [
            _entry(
              entityType: 'shopping_list',
              entityId: 'l1',
              operation: 'update',
              payload: {
                'title': 'خرید جدید',
                'base_updated_at': DateTime(2026, 1, 1).toIso8601String(),
              },
            ),
          ]);
      when(() => listRemote.getById('l1')).thenAnswer(
        (_) async => ShoppingListModel(
          id: 'l1',
          ownerId: 'u1',
          title: 'خرید',
          type: ShoppingListType.personal,
          archived: false,
          estimatedTotal: 0,
          updatedAt: DateTime(2026, 1, 1), // same as base -> not newer
        ),
      );
      when(() => listRemote.renameList(
            listId: any(named: 'listId'),
            newTitle: any(named: 'newTitle'),
          )).thenAnswer((_) async {});

      await engine.processQueue();

      verify(() => listRemote.renameList(listId: 'l1', newTitle: 'خرید جدید')).called(1);
      verify(() => queue.markSynced(any())).called(1);
      verifyNever(() => queue.markConflict(any()));
    });

    test('marks conflict instead of applying when the server row is newer', () async {
      final entry = _entry(
        entityType: 'shopping_list',
        entityId: 'l1',
        operation: 'update',
        payload: {
          'title': 'خرید من',
          'base_updated_at': DateTime(2026, 1, 1).toIso8601String(),
        },
      );
      when(() => queue.getPending()).thenAnswer((_) async => [entry]);
      when(() => listRemote.getById('l1')).thenAnswer(
        (_) async => ShoppingListModel(
          id: 'l1',
          ownerId: 'u1',
          title: 'خرید از دستگاه دیگر',
          type: ShoppingListType.personal,
          archived: false,
          estimatedTotal: 0,
          updatedAt: DateTime(2026, 1, 2), // newer than base -> conflict
        ),
      );

      await engine.processQueue();

      verifyNever(() => listRemote.renameList(
            listId: any(named: 'listId'),
            newTitle: any(named: 'newTitle'),
          ));
      verifyNever(() => queue.markSynced(any()));
      verify(() => queue.markConflict(entry)).called(1);
    });

    test('resolveKeepLocal force-applies the queued change and marks synced', () async {
      final entry = _entry(
        entityType: 'shopping_list',
        entityId: 'l1',
        operation: 'update',
        payload: {
          'title': 'خرید من',
          'base_updated_at': DateTime(2026, 1, 1).toIso8601String(),
        },
      );
      when(() => listRemote.renameList(
            listId: any(named: 'listId'),
            newTitle: any(named: 'newTitle'),
          )).thenAnswer((_) async {});

      await engine.resolveKeepLocal(entry);

      verify(() => listRemote.renameList(listId: 'l1', newTitle: 'خرید من')).called(1);
      verify(() => queue.markSynced(entry.id)).called(1);
      // No getById call — resolveKeepLocal deliberately skips the
      // conflict re-check; the user has already made their choice.
      verifyNever(() => listRemote.getById(any()));
    });

    test('resolveDiscardLocal refreshes the cache from the server and drops the queue entry',
        () async {
      final entry = _entry(
        entityType: 'shopping_list',
        entityId: 'l1',
        operation: 'update',
        payload: {'title': 'خرید من'},
      );
      final serverList = ShoppingListModel(
        id: 'l1',
        ownerId: 'u1',
        title: 'خرید از دستگاه دیگر',
        type: ShoppingListType.personal,
        archived: false,
        estimatedTotal: 0,
        updatedAt: DateTime(2026, 1, 2),
      );
      when(() => listRemote.getById('l1')).thenAnswer((_) async => serverList);

      await engine.resolveDiscardLocal(entry);

      verify(() => listCache.upsert(serverList)).called(1);
      verify(() => queue.discard(entry.id)).called(1);
      verifyNever(() => listRemote.renameList(
            listId: any(named: 'listId'),
            newTitle: any(named: 'newTitle'),
          ));
    });
  });
}
