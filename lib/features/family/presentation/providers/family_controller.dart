import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/features/family/domain/usecases/create_family_usecase.dart';
import 'package:family_shopping_app/features/family/domain/usecases/family_query_usecases.dart';
import 'package:family_shopping_app/features/family/domain/usecases/join_family_usecase.dart';
import 'package:family_shopping_app/features/family/domain/usecases/member_management_usecases.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_providers.dart';

part 'family_controller.g.dart';

@riverpod
class FamilyController extends _$FamilyController {
  @override
  FutureOr<void> build() {}

  Future<bool> createFamily(String name) => _run(
        () => ref.read(createFamilyUseCaseProvider)(CreateFamilyParams(name: name)),
      );

  Future<bool> joinFamily(String code) => _run(
        () => ref.read(joinFamilyUseCaseProvider)(JoinFamilyParams(invitationCode: code)),
      );

  Future<bool> leaveFamily() =>
      _run(() => ref.read(leaveFamilyUseCaseProvider)(const NoParams()));

  Future<bool> removeMember(String userId) => _run(
        () => ref
            .read(removeMemberUseCaseProvider)(RemoveMemberParams(memberUserId: userId)),
      );

  Future<String?> regenerateInviteCode() async {
    state = const AsyncLoading();
    final result = await ref.read(regenerateInviteCodeUseCaseProvider)(const NoParams());
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return null;
      },
      (code) {
        state = const AsyncData(null);
        ref.invalidate(myFamilyProvider);
        return code;
      },
    );
  }

  /// Shared success/error handling for the create/join/leave/remove actions
  /// above — they all return `ResultFuture<T>` and all need the same
  /// "loading -> refresh myFamily on success -> surface error" flow.
  Future<bool> _run(Future<dynamic> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(myFamilyProvider);
        return true;
      },
    );
  }
}
