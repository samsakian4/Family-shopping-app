import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_controller.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_providers.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';

/// Invite screen (12_NAVIGATION.md - /family/invite, FT-011: Generate code
/// / Share invitation).
class FamilyInvitePage extends ConsumerWidget {
  const FamilyInvitePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(myFamilyProvider);
    final controllerState = ref.watch(familyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('دعوت عضو جدید')),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (family) {
          if (family == null) {
            return const Center(child: Text('ابتدا باید عضو یک خانواده شوید'));
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('این کد را با اعضای خانواده به اشتراک بگذارید'),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    family.invitationCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: family.invitationCode));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('کپی شد')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('کپی کد'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: 'ساخت کد جدید',
                  isLoading: controllerState.isLoading,
                  onPressed: () async {
                    final newCode = await ref
                        .read(familyControllerProvider.notifier)
                        .regenerateInviteCode();
                    if (newCode != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('کد جدید ساخته شد')));
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
