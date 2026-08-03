import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_list_model.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

abstract class ShoppingListRemoteDataSource {
  Future<ShoppingListModel> createList({
    required String title,
    required ShoppingListType type,
    String? familyId,
  });
  Future<void> renameList({required String listId, required String newTitle});
  Future<void> setArchived({required String listId, required bool archived});
  Future<void> softDeleteList({required String listId});
  Future<void> restoreList({required String listId});
  Future<void> permanentlyDeleteList({required String listId});
  Future<List<ShoppingListModel>> getTrashedLists();
  Stream<List<ShoppingListModel>> watchMyLists();
}

class ShoppingListRemoteDataSourceImpl implements ShoppingListRemoteDataSource {
  final sb.SupabaseClient _client;

  ShoppingListRemoteDataSourceImpl(this._client);

  @override
  Future<ShoppingListModel> createList({
    required String title,
    required ShoppingListType type,
    String? familyId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('کاربر وارد نشده است');
    try {
      final row = await _client
          .from('shopping_lists')
          .insert({
            'title': title,
            'type': type.name,
            'owner_id': userId,
            'family_id': type == ShoppingListType.shared ? familyId : null,
          })
          .select()
          .single();
      return ShoppingListModel.fromJson(row);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> renameList({required String listId, required String newTitle}) async {
    try {
      await _client.from('shopping_lists').update({'title': newTitle}).eq('id', listId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setArchived({required String listId, required bool archived}) async {
    try {
      await _client.from('shopping_lists').update({'archived': archived}).eq('id', listId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> softDeleteList({required String listId}) async {
    try {
      await _client.rpc('soft_delete_shopping_list', params: {'p_list_id': listId});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> restoreList({required String listId}) async {
    try {
      await _client.rpc('restore_shopping_list', params: {'p_list_id': listId});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> permanentlyDeleteList({required String listId}) async {
    try {
      await _client.rpc('permanently_delete_shopping_list', params: {'p_list_id': listId});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ShoppingListModel>> getTrashedLists() async {
    try {
      final rows = await _client
          .from('shopping_lists')
          .select()
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);
      return (rows as List)
          .map((r) => ShoppingListModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<ShoppingListModel>> watchMyLists() {
    // Realtime (04_SYSTEM_ARCHITECTURE.md - Realtime Architecture:
    // "List renamed", product added/updated propagate the same way once
    // Shopping Items lands in the next phase).
    return _client
        .from('shopping_lists')
        .stream(primaryKey: ['id'])
        .order('updated_at')
        .map((rows) => rows
            .where((r) => r['deleted_at'] == null)
            .map((r) => ShoppingListModel.fromJson(r))
            .toList());
  }
}
