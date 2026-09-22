import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: AppSizes.pagePadding,
    child: Center(child: CircularProgressIndicator()),
  );
}
