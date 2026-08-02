import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_controller.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_providers.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// Family main screen (12_NAVIGATION.md - /family, FT-010/FT-011).
class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(myFamilyProvider);
    final controllerState = ref.watch(familyControllerProvider);

    ref.listen(familyControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('خانواده')),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (family) {
          if (family == null) {
            return _NoFamilyView(
              isLoading: controllerState.isLoading,
              onCreate: (name) => ref.read(familyControllerProvider.notifier).createFamily(name),
              onJoin: (code) => ref.read(familyControllerProvider.notifier).joinFamily(code),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(family.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Text('کد دعوت: '),
                            SelectableText(
                              family.invitationCode,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: family.invitationCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('کد دعوت کپی شد')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('اعضای خانواده'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push(RoutePaths.familyMembers),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_outlined),
                  title: const Text('دعوت عضو جدید'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push(RoutePaths.familyInvite),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: controllerState.isLoading
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ترک خانواده'),
                              content: const Text('آیا مطمئن هستید؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('انصراف'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('ترک خانواده'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref.read(familyControllerProvider.notifier).leaveFamily();
                          }
                        },
                  child: const Text('ترک خانواده'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NoFamilyView extends StatelessWidget {
  final bool isLoading;
  final Future<bool> Function(String name) onCreate;
  final Future<bool> Function(String code) onJoin;

  const _NoFamilyView({
    required this.isLoading,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.family_restroom, size: 64),
            const SizedBox(height: AppSpacing.md),
            const Text('شما هنوز عضو هیچ خانواده‌ای نیستید', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'ساخت خانواده جدید',
              isLoading: isLoading,
              onPressed: () => _showCreateDialog(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: isLoading ? null : () => _showJoinDialog(context),
              child: const SizedBox(
                width: double.infinity,
                child: Text('پیوستن با کد دعوت', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ساخت خانواده'),
        content: AppTextField(controller: controller, label: 'نام خانواده'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCreate(controller.text);
            },
            child: const Text('ساخت'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پیوستن به خانواده'),
        content: AppTextField(controller: controller, label: 'کد دعوت'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onJoin(controller.text);
            },
            child: const Text('پیوستن'),
          ),
        ],
      ),
    );
  }
}
