import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// Login screen (16_AUTH.md - Login Flow).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
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
      // On success the auth stream flips isAuthenticated=true and the
      // router's redirect callback takes the user to /home automatically
      // (12_NAVIGATION.md - Login Flow) — no manual navigation needed here.
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ورود')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _emailController,
                label: 'ایمیل',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordController,
                label: 'رمز عبور',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(RoutePaths.forgotPassword),
                  child: const Text('رمز عبور را فراموش کرده‌اید؟'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'ورود',
                isLoading: isLoading,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signIn(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.push(RoutePaths.register),
                child: const Text('حساب کاربری ندارید؟ ثبت‌نام کنید'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
