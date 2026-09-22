import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../widgets/account_form.dart';

class RegisterAdminScreen extends StatelessWidget {
  const RegisterAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerAdmin)),
      body: const AccountForm(role: 'admin'),
    );
  }
}
