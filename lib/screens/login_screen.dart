import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_notification.dart';
import '../widgets/animated_content.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSizes.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.formWidth),
              child: Appear(
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppSizes.hero,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const Text(
                        AppStrings.tagline,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.xl),
                      CustomTextField(
                        controller: email,
                        label: AppStrings.email,
                        keyboard: TextInputType.emailAddress,
                        validator: validateEmail,
                      ),
                      CustomTextField(
                        controller: password,
                        label: AppStrings.password,
                        obscure: true,
                      ),
                      CustomButton(
                        label: AppStrings.login,
                        loading: auth.busy,
                        onPressed: () async {
                          if (!form.currentState!.validate()) return;
                          final ok = await auth.login(
                            email.text,
                            password.text,
                          );
                          if (!ok && context.mounted) {
                            showNotice(context, auth.error!, error: true);
                          }
                        },
                      ),
                      const Text(
                        'Accounts are provided by your administrator.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
