import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> updateProfile({String? displayName, String? language, String? theme});
  Future<String> uploadAvatar(Uint8List bytes, {required String fileExtension});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final sb.SupabaseClient _client;

  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? language,
    String? theme,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException('کاربر وارد نشده است');
    }
    try {
      final updates = <String, dynamic>{
        if (displayName != null) 'display_name': displayName,
        if (language != null) 'language': language,
        if (theme != null) 'theme': theme,
      };
      final row = await _client
          .from('profiles')
          .update(updates)
          .eq('id', authUser.id)
          .select()
          .single();
      return UserModel.fromSupabase(authUser: authUser, profileRow: row);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, {required String fileExtension}) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException('کاربر وارد نشده است');
    }
    try {
      // Path is relative to the 'avatars' bucket itself: {user_id}/profile.jpg
      // (bucket_id already scopes it — no need to repeat "avatars/").
      // This must match the storage.foldername(name)[1] = auth.uid() check
      // in supabase/migrations/002_avatars_storage.sql.
      final path = '${authUser.id}/profile.$fileExtension';
      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(
              upsert: true,
              contentType: 'image/$fileExtension',
            ),
          );
      final signedUrl =
          await _client.storage.from('avatars').createSignedUrl(path, 60 * 60 * 24 * 7);

      await _client
          .from('profiles')
          .update({'avatar_url': signedUrl}).eq('id', authUser.id);

      return signedUrl;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
