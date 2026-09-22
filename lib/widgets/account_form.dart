import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../models/account_input.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';
import 'custom_notification.dart';

class AccountForm extends StatefulWidget {
  final String role;
  const AccountForm({super.key, required this.role});
  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final form = GlobalKey<FormState>();
  final fields = {
    for (final k in ['name', 'email', 'phone', 'branch', 'password'])
      k: TextEditingController(),
  };
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, current) =>
          prev.operationId != current.operationId ||
          prev.effect != current.effect,
      listener: (context, state) {
        if (state.submitting) return;
        if (state.status == AuthStatus.success) {
          Navigator.pop(context);
          showNotice(context, 'Account created.');
        } else if (state.status == AuthStatus.failure) {
          showNotice(context, state.error ?? 'Error occurred.', error: true);
        }
      },
      builder: (context, state) {
        final busy = state.submitting;
        return PopScope(
          canPop: !busy,
          child: AbsorbPointer(
            absorbing: busy,
            child: Form(
              key: form,
              child: ListView(
                padding: AppSizes.pagePadding,
                children: [
                  Text(
                    'Create ${widget.role} account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  CustomTextField(
                    controller: fields['name']!,
                    label: AppStrings.name,
                  ),
                  CustomTextField(
                    controller: fields['email']!,
                    label: AppStrings.email,
                    keyboard: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  CustomTextField(
                    controller: fields['phone']!,
                    label: AppStrings.phone,
                    keyboard: TextInputType.phone,
                  ),
                  CustomTextField(
                    controller: fields['branch']!,
                    label: AppStrings.branch,
                  ),
                  CustomTextField(
                    controller: fields['password']!,
                    label: 'Password',
                    obscure: true,
                    validator: (v) => v != null && v.length >= 8
                        ? null
                        : 'Use at least 8 characters.',
                  ),
                  const Text(
                    'Share the account credentials securely with the new user.',
                  ),
                  const SizedBox(height: AppSizes.md),
                  CustomButton(
                    label: 'Create account',
                    loading: busy,
                    onPressed: () {
                      if (!form.currentState!.validate()) return;
                      final input = AccountInput(
                        name: fields['name']!.text,
                        email: fields['email']!.text,
                        password: fields['password']!.text,
                        phone: fields['phone']!.text,
                        branch: fields['branch']!.text,
                      );
                      final operationId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      final event = widget.role == 'admin'
                          ? CreateAdminRequested(
                              input,
                              operationId: operationId,
                            )
                          : CreateStaffRequested(
                              input,
                              operationId: operationId,
                            );
                      context.read<AuthBloc>().add(event);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
