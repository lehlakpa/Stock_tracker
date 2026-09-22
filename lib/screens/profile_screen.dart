import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_sizes.dart';
import '../widgets/shared_widgets.dart';
import '../constants/app_strings.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

import '../widgets/custom_notification.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final auth = context.watch<AuthProvider>();
    return ListView(
      padding: AppSizes.pagePadding,
      children: [
        Center(child: InitialTile(user.name)),
        const SizedBox(height: AppSizes.lg),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: AppSizes.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailLine('Email', user.email),
                DetailLine('Phone', user.phone),
                DetailLine('Branch', user.branch),
                DetailLine('Role', user.isAdmin ? 'Admin' : 'Staff'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        OutlinedButton(
          onPressed: auth.busy
              ? null
              : () async {
                  if (!await auth.logout() && context.mounted) {
                    showNotice(context, auth.error!, error: true);
                  }
                },
          child: const Text(AppStrings.logout),
        ),
      ],
    );
  }
}
