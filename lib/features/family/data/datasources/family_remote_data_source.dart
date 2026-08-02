import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/family/data/models/family_model.dart';

abstract class FamilyRemoteDataSource {
  Future<FamilyModel> createFamily({required String name});
  Future<FamilyModel> joinFamily({required String invitationCode});
  Future<void> leaveFamily();
  Future<void> removeMember({required String memberUserId});
  Future<String> regenerateInviteCode();
  Future<FamilyModel?> getMyFamily();
  Future<List<FamilyMemberModel>> getMembers({required String familyId});
  Stream<List<FamilyMemberModel>> watchMembers({required String familyId});
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  final sb.SupabaseClient _client;

  FamilyRemoteDataSourceImpl(this._client);

  static const _memberSelect = '*, profiles(display_name, avatar_url)';

  @override
  Future<FamilyModel> createFamily({required String name}) async {
    try {
      final row = await _client.rpc('create_family', params: {'p_name': name});
      return FamilyModel.fromJson(row as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw ServerException(_mapError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FamilyModel> joinFamily({required String invitationCode}) async {
    try {
      final row = await _client
          .rpc('join_family_by_code', params: {'p_code': invitationCode});
      return FamilyModel.fromJson(row as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw ServerException(_mapError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> leaveFamily() async {
    try {
      await _client.rpc('leave_family');
    } on sb.PostgrestException catch (e) {
      throw ServerException(_mapError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeMember({required String memberUserId}) async {
    try {
      await _client.rpc(
        'remove_family_member',
        params: {'p_member_user_id': memberUserId},
      );
    } on sb.PostgrestException catch (e) {
      throw ServerException(_mapError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> regenerateInviteCode() async {
    try {
      final result = await _client.rpc('regenerate_invite_code');
      return result as String;
    } on sb.PostgrestException catch (e) {
      throw ServerException(_mapError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FamilyModel?> getMyFamily() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('کاربر وارد نشده است');
    try {
      final membership = await _client
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (membership == null) return null;

      final family = await _client
          .from('families')
          .select()
          .eq('id', membership['family_id'] as String)
          .single();
      return FamilyModel.fromJson(family);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<FamilyMemberModel>> getMembers({required String familyId}) async {
    try {
      final rows = await _client
          .from('family_members')
          .select(_memberSelect)
          .eq('family_id', familyId)
          .order('joined_at');
      return (rows as List)
          .map((r) => FamilyMemberModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<FamilyMemberModel>> watchMembers({required String familyId}) {
    // Realtime member list (04_SYSTEM_ARCHITECTURE.md - Realtime Architecture:
    // "Member joined"). Supabase's .stream() re-emits the full row set on
    // every change, which is not joined with profiles, so we re-fetch the
    // joined view on each tick to keep display_name/avatar_url populated.
    return _client
        .from('family_members')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .asyncMap((_) => getMembers(familyId: familyId));
  }

  String _mapError(sb.PostgrestException e) {
    switch (e.message) {
      case 'ALREADY_IN_FAMILY':
        return 'شما در حال حاضر عضو یک خانواده هستید';
      case 'INVALID_CODE':
        return 'کد دعوت نامعتبر است';
      case 'NOT_IN_FAMILY':
        return 'شما عضو هیچ خانواده‌ای نیستید';
      case 'OWNER_CANNOT_LEAVE':
        return 'مالک خانواده نمی‌تواند خانواده را ترک کند';
      case 'PERMISSION_DENIED':
        return 'شما دسترسی لازم برای این عملیات را ندارید';
      case 'NOT_SAME_FAMILY':
        return 'این کاربر عضو خانواده شما نیست';
      case 'CANNOT_REMOVE_OWNER':
        return 'نمی‌توان مالک خانواده را حذف کرد';
      default:
        return 'خطایی رخ داد. دوباره تلاش کنید';
    }
  }
}
