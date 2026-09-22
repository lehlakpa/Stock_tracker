import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_error.dart';
import '../../widgets/animated_content.dart';
import '../../widgets/custom_draggable_sheet.dart';
import '../../widgets/staff_details.dart';
import '../../widgets/shared_widgets.dart';
import '../access_denied_screen.dart';
import 'register_staff_screen.dart';
import 'register_admin_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  late final stream = context.read<AuthProvider>().service.users();
  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserModel>().isAdmin) {
      return const AccessDeniedScreen(message: AppStrings.adminRequired);
    }
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text(AppStrings.team)),
      body: Column(
        children: [
          Padding(
            padding: AppSizes.pagePadding,
            child: Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    smoothRoute(
                      BlocProvider(
                        create: (_) =>
                            AuthBloc(context.read<AuthProvider>().service),
                        child: const RegisterStaffScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text(AppStrings.registerStaff),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    smoothRoute(
                      BlocProvider(
                        create: (_) =>
                            AuthBloc(context.read<AuthProvider>().service),
                        child: const RegisterAdminScreen(),
                      ),
                    ),
                  ),
                  child: const Text(AppStrings.registerAdmin),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: stream,
              builder: (context, snapshot) => AnimatedContent(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.hasError ? errorMessage(snapshot.error!) : null,
                empty: snapshot.data?.isEmpty ?? false,
                child: ListView(
                  padding: AppSizes.pagePadding,
                  children: (snapshot.data ?? [])
                      .map(
                        (u) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: InitialTile(u.name),
                            title: Text(u.name),
                            subtitle: Text(
                              '${u.email}\n${u.role} · ${u.isActive ? "Active" : "Inactive"}',
                            ),
                            isThreeLine: true,
                            trailing: StatusPill(
                              u.isActive
                                  ? (u.isAdmin ? 'Admin' : 'Staff')
                                  : 'Paused',
                            ),
                            onTap: () => CustomDraggableSheet.show(
                              context,
                              title: 'Staff details',
                              builder: (_, scroll) => StaffDetails(
                                uid: u.uid,
                                scrollController: scroll,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
