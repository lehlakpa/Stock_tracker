import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_sizes.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/app_error.dart';
import 'animated_content.dart';
import 'custom_button.dart';
import 'custom_notification.dart';
import 'shared_widgets.dart';

class StaffDetails extends StatefulWidget {
  final String uid;
  final ScrollController scrollController;
  const StaffDetails({
    super.key,
    required this.uid,
    required this.scrollController,
  });
  @override
  State<StaffDetails> createState() => _StaffDetailsState();
}

class _StaffDetailsState extends State<StaffDetails> {
  bool saving = false;
  late final stream = context.read<AuthProvider>().service.profile(widget.uid);
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: StreamBuilder<UserModel?>(
      stream: stream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return AnimatedContent(
          loading: snapshot.connectionState == ConnectionState.waiting,
          error: snapshot.hasError
              ? errorMessage(snapshot.error!)
              : user == null
              ? 'User profile missing.'
              : null,
          child: ListView(
            controller: widget.scrollController,
            padding: AppSizes.pagePadding,
            children: user == null
                ? []
                : [
                    Center(child: InitialTile(user.name)),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        children: [
                          DetailLine('Email', user.email),
                          DetailLine('Phone', user.phone),
                          DetailLine('Branch', user.branch),
                          DetailLine('Role', user.isAdmin ? 'Admin' : 'Staff'),
                          DetailLine(
                            'Access',
                            user.isActive ? 'Active' : 'Paused',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    if (user.role == 'staff')
                      CustomButton(
                        label: user.isActive
                            ? 'Deactivate staff'
                            : 'Activate staff',
                        loading: saving,
                        onPressed: () async {
                          setState(() => saving = true);
                          try {
                            await context
                                .read<AuthProvider>()
                                .service
                                .setActive(user, !user.isActive);
                            if (context.mounted) {
                              Navigator.pop(context);
                              showNotice(context, 'Staff access updated.');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showNotice(context, errorMessage(e), error: true);
                            }
                          } finally {
                            if (mounted) setState(() => saving = false);
                          }
                        },
                      ),
                  ],
          ),
        );
      },
    ),
  );
}
