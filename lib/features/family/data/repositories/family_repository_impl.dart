import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/family/data/datasources/family_remote_data_source.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FamilyRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  FamilyRepositoryImpl(this._remote, this._networkInfo);

  @override
  ResultFuture<FamilyEntity> createFamily({required String name}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.createFamily(name: name));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<FamilyEntity> joinFamily({required String invitationCode}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.joinFamily(invitationCode: invitationCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> leaveFamily() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.leaveFamily();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> removeMember({required String memberUserId}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.removeMember(memberUserId: memberUserId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<String> regenerateInviteCode() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.regenerateInviteCode());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<FamilyEntity?> getMyFamily() async {
    try {
      return Right(await _remote.getMyFamily());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<List<FamilyMemberEntity>> getMembers({required String familyId}) async {
    try {
      return Right(await _remote.getMembers(familyId: familyId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<List<FamilyMemberEntity>> watchMembers({required String familyId}) {
    return _remote.watchMembers(familyId: familyId);
  }
}
