import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_controller.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_providers.dart';

/// Members screen (12_NAVIGATION.md - /family/members, FT-012).
class FamilyMembersPage extends ConsumerWidget {
  const FamilyMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(myFamilyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('اعضای خانواده')),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (family) {
          if (family == null) {
            return const Center(child: Text('ابتدا باید عضو یک خانواده شوید'));
          }
          return _MembersList(familyId: family.id);
        },
      ),
    );
  }
}

class _MembersList extends ConsumerWidget {
  final String familyId;
  const _MembersList({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider(familyId));
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final currentUserId = currentUserAsync.valueOrNull?.id;

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (members) {
        final me = members.where((m) => m.userId == currentUserId).toList();
        final canManage = me.isNotEmpty &&
            (me.first.role == FamilyRole.owner || me.first.role == FamilyRole.admin);

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: members.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                child: member.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(member.displayName ?? 'کاربر'),
              subtitle: Text(_roleLabel(member.role)),
              trailing: canManage && member.role != FamilyRole.owner
                  ? IconButton(
                      icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(familyControllerProvider.notifier)
                            .removeMember(member.userId);
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  String _roleLabel(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return 'مالک';
      case FamilyRole.admin:
        return 'مدیر';
      case FamilyRole.member:
        return 'عضو';
    }
  }
}
