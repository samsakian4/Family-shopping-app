import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';

abstract class FamilyRepository {
  ResultFuture<FamilyEntity> createFamily({required String name});

  ResultFuture<FamilyEntity> joinFamily({required String invitationCode});

  ResultFuture<void> leaveFamily();

  ResultFuture<void> removeMember({required String memberUserId});

  ResultFuture<String> regenerateInviteCode();

  /// Null when the current user isn't in a family yet.
  ResultFuture<FamilyEntity?> getMyFamily();

  ResultFuture<List<FamilyMemberEntity>> getMembers({required String familyId});

  /// Realtime stream of member changes for the given family
  /// (04_SYSTEM_ARCHITECTURE.md - Realtime Architecture: "Member joined").
  Stream<List<FamilyMemberEntity>> watchMembers({required String familyId});
}
