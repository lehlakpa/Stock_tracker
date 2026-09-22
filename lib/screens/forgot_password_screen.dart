import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_notification.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resetPassword)),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSizes.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formWidth),
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: email,
                    label: AppStrings.email,
                    keyboard: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  CustomButton(
                    label: 'Send reset link',
                    loading: auth.busy,
                    onPressed: () async {
                      if (!form.currentState!.validate()) return;
                      final ok = await auth.resetPassword(email.text);
                      if (context.mounted) {
                        showNotice(
                          context,
                          ok
                              ? 'If this account exists, a reset link has been sent.'
                              : auth.error!,
                          error: !ok,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
