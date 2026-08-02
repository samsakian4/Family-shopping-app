import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/features/family/data/datasources/family_remote_data_source.dart';
import 'package:family_shopping_app/features/family/data/repositories/family_repository_impl.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';
import 'package:family_shopping_app/features/family/domain/usecases/create_family_usecase.dart';
import 'package:family_shopping_app/features/family/domain/usecases/family_query_usecases.dart';
import 'package:family_shopping_app/features/family/domain/usecases/join_family_usecase.dart';
import 'package:family_shopping_app/features/family/domain/usecases/member_management_usecases.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'family_providers.g.dart';

@Riverpod(keepAlive: true)
FamilyRemoteDataSource familyRemoteDataSource(Ref ref) {
  return FamilyRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
FamilyRepository familyRepository(Ref ref) {
  return FamilyRepositoryImpl(
    ref.watch(familyRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
  );
}

@riverpod
CreateFamilyUseCase createFamilyUseCase(Ref ref) =>
    CreateFamilyUseCase(ref.watch(familyRepositoryProvider));

@riverpod
JoinFamilyUseCase joinFamilyUseCase(Ref ref) =>
    JoinFamilyUseCase(ref.watch(familyRepositoryProvider));

@riverpod
LeaveFamilyUseCase leaveFamilyUseCase(Ref ref) =>
    LeaveFamilyUseCase(ref.watch(familyRepositoryProvider));

@riverpod
RemoveMemberUseCase removeMemberUseCase(Ref ref) =>
    RemoveMemberUseCase(ref.watch(familyRepositoryProvider));

@riverpod
RegenerateInviteCodeUseCase regenerateInviteCodeUseCase(Ref ref) =>
    RegenerateInviteCodeUseCase(ref.watch(familyRepositoryProvider));

@riverpod
GetMembersUseCase getMembersUseCase(Ref ref) =>
    GetMembersUseCase(ref.watch(familyRepositoryProvider));

/// The current user's family, or null if they haven't joined/created one
/// yet. Re-fetch by invalidating this provider after create/join/leave.
@riverpod
Future<FamilyEntity?> myFamily(Ref ref) async {
  final useCase = GetMyFamilyUseCase(ref.watch(familyRepositoryProvider));
  final result = await useCase(const NoParams());
  return result.fold((failure) => throw failure.message, (family) => family);
}

/// Realtime members list for a family (04_SYSTEM_ARCHITECTURE.md -
/// Realtime Architecture).
@riverpod
Stream<List<FamilyMemberEntity>> familyMembers(Ref ref, String familyId) {
  return ref.watch(familyRepositoryProvider).watchMembers(familyId: familyId);
}
