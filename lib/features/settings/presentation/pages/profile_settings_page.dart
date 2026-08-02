import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_shopping_app/features/settings/presentation/providers/profile_controller.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// Profile settings screen (12_NAVIGATION.md - /settings/profile,
/// FT-003 Profile Management).
class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _nameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final Uint8List bytes = await file.readAsBytes();
    final extension = file.name.split('.').last;

    final ok = await ref
        .read(profileControllerProvider.notifier)
        .uploadAvatar(bytes, extension);

    if (ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تصویر پروفایل بروزرسانی شد')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final controllerState = ref.watch(profileControllerProvider);
    final isLoading = controllerState.isLoading;

    ref.listen(profileControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل من')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا در بارگذاری پروفایل')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('کاربر یافت نشد'));
          }
          if (!_initialized) {
            _nameController.text = user.displayName ?? '';
            _initialized = true;
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : _pickAndUploadAvatar,
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? const Icon(Icons.person, size: 48)
                                : null,
                          ),
                          const CircleAvatar(
                            radius: 14,
                            child: Icon(Icons.edit, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(user.email, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _nameController,
                    label: 'نام نمایشی',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPrimaryButton(
                    label: 'ذخیره تغییرات',
                    isLoading: isLoading,
                    onPressed: () async {
                      final ok = await ref
                          .read(profileControllerProvider.notifier)
                          .updateProfile(displayName: _nameController.text.trim());
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('ذخیره شد')));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
