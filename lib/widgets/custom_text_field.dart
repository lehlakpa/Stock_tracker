import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure, requiredField;
  final TextInputType? keyboard;
  final int lines;
  final String? Function(String?)? validator;
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.requiredField = true,
    this.keyboard,
    this.lines = 1,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: lines,
      keyboardType: keyboard,
      autocorrect: !obscure,
      enableSuggestions: !obscure,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (v) => requiredField && (v == null || v.trim().isEmpty)
              ? AppStrings.required
              : null,
    ),
  );
}

String? validateEmail(String? value) =>
    value != null &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? null
    : 'Enter a valid email address.';
String? validateNumber(
  String? value, {
  bool integer = false,
  bool positive = false,
  bool signed = false,
}) {
  final n = integer ? int.tryParse(value ?? '') : double.tryParse(value ?? '');
  if (n == null || !n.isFinite || (!signed && n < 0) || (positive && n <= 0)) {
    return positive
        ? 'Enter a number greater than zero.'
        : 'Enter a valid ${signed ? "" : "non-negative "}number.';
  }
  return null;
}
