import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl(this._remote, this._networkInfo);

  @override
  ResultFuture<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await _remote.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final user = await _remote.signIn(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> signOut() async {
    try {
      await _remote.signOut();
      return const Right(null);
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> resetPassword({required String email}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.resetPassword(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> changePassword({required String newPassword}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.changePassword(newPassword: newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<UserEntity?> getCurrentUser() async {
    try {
      final user = await _remote.getCurrentUser();
      return Right(user);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _remote.authStateChanges;
}
