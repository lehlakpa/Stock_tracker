import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_notification.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String message;
  const AccessDeniedScreen({super.key, this.message = AppStrings.inactive});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.accessDenied)),
    body: Center(
      child: Padding(
        padding: AppSizes.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            CustomButton(
              label: AppStrings.logout,
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                if (!await auth.logout() && context.mounted) {
                  showNotice(context, auth.error!, error: true);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
