import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';

class FamilyModel extends FamilyEntity {
  const FamilyModel({
    required super.id,
    required super.name,
    required super.ownerId,
    required super.invitationCode,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      invitationCode: json['invitation_code'] as String,
    );
  }
}

class FamilyMemberModel extends FamilyMemberEntity {
  const FamilyMemberModel({
    required super.userId,
    required super.familyId,
    required super.role,
    required super.joinedAt,
    super.displayName,
    super.avatarUrl,
  });

  /// Built from a `family_members` row joined with `profiles`
  /// (select: `*, profiles(display_name, avatar_url)`).
  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return FamilyMemberModel(
      userId: json['user_id'] as String,
      familyId: json['family_id'] as String,
      role: familyRoleFromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
