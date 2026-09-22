import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../widgets/account_form.dart';

class RegisterStaffScreen extends StatelessWidget {
  const RegisterStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerStaff)),
      body: const AccountForm(role: 'staff'),
    );
  }
}
