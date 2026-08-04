import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/sync/sync_engine.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_item_model.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_list_model.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

class MockSyncQueueService extends Mock implements SyncQueueService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockShoppingListRemoteDataSource extends Mock implements ShoppingListRemoteDataSource {}

class MockShoppingItemRemoteDataSource extends Mock implements ShoppingItemRemoteDataSource {}

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
    sortOrder: 0,
  );

  setUp(() {
    queue = MockSyncQueueService();
    networkInfo = MockNetworkInfo();
    listRemote = MockShoppingListRemoteDataSource();
    itemRemote = MockShoppingItemRemoteDataSource();
    engine = SyncEngine(queue, networkInfo, listRemote, itemRemote);

    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => queue.markSynced(any())).thenAnswer((_) async {});
    when(() => queue.markFailedAttempt(any(), maxRetries: any(named: 'maxRetries')))
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
}
