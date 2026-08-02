import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// Register screen (16_AUTH.md - Registration Flow / Fields).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(authControllerProvider);
    final isLoading = controllerState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ساخت حساب کاربری')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'نام نمایشی',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _emailController,
                label: 'ایمیل',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordController,
                label: 'رمز عبور (حداقل ۸ کاراکتر)',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'ثبت‌نام',
                isLoading: isLoading,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signUp(
                        email: _emailController.text,
                        password: _passwordController.text,
                        displayName: _nameController.text,
                      );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('قبلاً ثبت‌نام کرده‌اید؟ وارد شوید'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
