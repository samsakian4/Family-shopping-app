import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// Forgot Password screen (16_AUTH.md - Password Reset flow).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
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
      appBar: AppBar(title: const Text('فراموشی رمز عبور')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _sent
              ? const Center(
                  child: Text('ایمیل بازیابی رمز عبور ارسال شد. صندوق ورودی خود را بررسی کنید.'),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: 'ایمیل',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: 'ارسال لینک بازیابی',
                      isLoading: isLoading,
                      onPressed: () async {
                        final ok = await ref
                            .read(authControllerProvider.notifier)
                            .resetPassword(email: _emailController.text);
                        if (ok) setState(() => _sent = true);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
