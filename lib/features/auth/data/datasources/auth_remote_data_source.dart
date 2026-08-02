import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/auth/data/models/user_model.dart';

/// Talks to Supabase directly. This is the ONLY place in the auth feature
/// that imports supabase_flutter's auth types besides the model mapper
/// (04_SYSTEM_ARCHITECTURE.md - Data Layer: API communication).
abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserModel> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> resetPassword({required String email});

  Future<void> changePassword({required String newPassword});

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sb.SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('ثبت‌نام ناموفق بود');
      }
      // profiles row is created server-side by the handle_new_user()
      // trigger (see supabase/migrations/001_...sql) — no client insert.
      return UserModel.fromSupabase(authUser: user);
    } on sb.AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final response =
          await _client.auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw const AuthException('اطلاعات ورود صحیح نیست');
      }
      final profile = await _fetchProfile(user.id);
      return UserModel.fromSupabase(authUser: user, profileRow: profile);
    } on sb.AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on sb.AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = await _fetchProfile(user.id);
    return UserModel.fromSupabase(authUser: user, profileRow: profile);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      final profile = await _fetchProfile(user.id);
      return UserModel.fromSupabase(authUser: user, profileRow: profile);
    });
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      return await _client.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (_) {
      // Non-fatal: fall back to auth-only data rather than blocking login.
      return null;
    }
  }

  String _mapAuthError(sb.AuthException e) {
    // Friendly Persian messages (10_UI_UX.md - Error Experience: never
    // show raw technical messages).
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'اطلاعات ورود صحیح نیست';
    }
    if (msg.contains('already registered') || msg.contains('user already exists')) {
      return 'این ایمیل قبلاً ثبت‌نام کرده است';
    }
    if (msg.contains('password')) {
      return 'رمز عبور معتبر نیست';
    }
    return 'خطایی رخ داد. دوباره تلاش کنید';
  }
}
