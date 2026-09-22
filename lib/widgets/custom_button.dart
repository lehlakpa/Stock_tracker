import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: AnimatedSwitcher(
      duration: AppSizes.duration,
      child: loading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: AppSizes.icon,
              height: AppSizes.icon,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStroke,
              ),
            )
          : Text(label, key: ValueKey(label)),
    ),
  );
}
