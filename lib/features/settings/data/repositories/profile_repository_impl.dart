import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/settings/data/datasources/profile_remote_data_source.dart';
import 'package:family_shopping_app/features/settings/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ProfileRepositoryImpl(this._remote, this._networkInfo);

  @override
  ResultFuture<UserEntity> updateProfile({
    String? displayName,
    String? language,
    String? theme,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final user = await _remote.updateProfile(
        displayName: displayName,
        language: language,
        theme: theme,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<String> uploadAvatar(Uint8List bytes, {required String fileExtension}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final url = await _remote.uploadAvatar(bytes, fileExtension: fileExtension);
      return Right(url);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
