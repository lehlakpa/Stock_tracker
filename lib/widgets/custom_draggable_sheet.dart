import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CustomDraggableSheet extends StatefulWidget {
  final double initialChildSize, minChildSize, maxChildSize;
  final List<double> snapSizes;
  final String title;
  final Widget Function(BuildContext, ScrollController) builder;
  final DraggableScrollableController? controller;
  const CustomDraggableSheet({
    super.key,
    required this.title,
    required this.builder,
    this.initialChildSize = 0.7,
    this.minChildSize = 0.35,
    this.maxChildSize = 0.95,
    this.snapSizes = const [0.35, 0.7, 0.95],
    this.controller,
  });
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget Function(BuildContext, ScrollController) builder,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: AppColors.transparent,
    builder: (context) => CustomDraggableSheet(title: title, builder: builder),
  );
  @override
  State<CustomDraggableSheet> createState() => _CustomDraggableSheetState();
}

class _CustomDraggableSheetState extends State<CustomDraggableSheet> {
  late final DraggableScrollableController controller =
      widget.controller ?? DraggableScrollableController();
  double previousInset = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset > previousInset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.isAttached) {
          controller.animateTo(
            widget.maxChildSize,
            duration: AppSizes.duration,
            curve: AppSizes.curve,
          );
        }
      });
    }
    previousInset = inset;
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    controller: controller,
    initialChildSize: widget.initialChildSize,
    minChildSize: widget.minChildSize,
    maxChildSize: widget.maxChildSize,
    expand: false,
    shouldCloseOnMinExtent: false,
    snap: true,
    snapSizes: widget.snapSizes,
    builder: (context, scroll) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.sm),
              child: Container(
                width: AppSizes.button,
                height: AppSizes.xs,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(child: widget.builder(context, scroll)),
          ],
        ),
      ),
    ),
  );
}
