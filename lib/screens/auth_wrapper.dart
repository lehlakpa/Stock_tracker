import '../constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/buyer_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/error_state_widget.dart';
import 'access_denied_screen.dart';
import 'admin/admin_dashboard.dart';
import 'staff/staff_dashboard.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) return const SplashScreen();
    if (!auth.signedIn) return const LoginScreen();
    if (auth.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account unavailable'),
          actions: [
            TextButton(
              onPressed: auth.logout,
              child: const Text(AppStrings.logout),
            ),
          ],
        ),
        body: ErrorStateWidget(
          message: auth.error ?? 'User profile missing.',
          onRetry: auth.retry,
        ),
      );
    }
    final user = auth.user!;
    if (!user.isActive || !user.hasValidRole) return const AccessDeniedScreen();
    return _Session(
      key: ValueKey('${user.uid}-${user.role}-${user.name}'),
      user: user,
    );
  }
}

class _Session extends StatelessWidget {
  final UserModel user;
  const _Session({super.key, required this.user});
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: user),
      Provider(create: (_) => FirestoreService()),
      ChangeNotifierProvider(
        create: (c) => StockProvider(c.read<FirestoreService>(), user),
      ),
      ChangeNotifierProvider(
        create: (c) => BuyerProvider(c.read<FirestoreService>()),
      ),
    ],
    child: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) =>
            user.isAdmin ? const AdminDashboard() : const StaffDashboard(),
      ),
    ),
  );
}
