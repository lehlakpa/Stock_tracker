import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

SnackBar _buildSnackBar(String message, Color color) => SnackBar(
  backgroundColor: color,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius),
  ),
  content: Text(message, style: const TextStyle(color: AppColors.white)),
);

SnackBar successSnackBar(String message) =>
    _buildSnackBar(message, AppColors.success);

SnackBar errorSnackBar(String message) =>
    _buildSnackBar(message, AppColors.error);

void showNotice(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(error ? errorSnackBar(message) : successSnackBar(message));
}
