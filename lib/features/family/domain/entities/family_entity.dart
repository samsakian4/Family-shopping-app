import 'package:equatable/equatable.dart';

enum FamilyRole { owner, admin, member }

FamilyRole familyRoleFromString(String value) {
  return FamilyRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => FamilyRole.member,
  );
}

class FamilyEntity extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String invitationCode;

  const FamilyEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.invitationCode,
  });

  @override
  List<Object?> get props => [id, name, ownerId, invitationCode];
}

class FamilyMemberEntity extends Equatable {
  final String userId;
  final String familyId;
  final FamilyRole role;
  final String? displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const FamilyMemberEntity({
    required this.userId,
    required this.familyId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [userId, familyId, role, displayName, avatarUrl, joinedAt];
}
