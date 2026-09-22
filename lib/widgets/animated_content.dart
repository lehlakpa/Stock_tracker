import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import 'error_state_widget.dart';
import 'loading_widget.dart';

class AnimatedContent extends StatelessWidget {
  final bool loading, empty;
  final String? error;
  final Widget child;
  final VoidCallback? retry;
  const AnimatedContent({
    super.key,
    required this.child,
    this.loading = false,
    this.empty = false,
    this.error,
    this.retry,
  });
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppSizes.duration,
    switchInCurve: AppSizes.curve,
    switchOutCurve: AppSizes.curve,
    child: loading
        ? const LoadingWidget(key: ValueKey('loading'))
        : error != null
        ? ErrorStateWidget(
            key: const ValueKey('error'),
            message: error!,
            onRetry: retry,
          )
        : empty
        ? const ErrorStateWidget(
            key: ValueKey('empty'),
            message: AppStrings.empty,
          )
        : Appear(key: const ValueKey('data'), child: child),
  );
}

class Appear extends StatefulWidget {
  final Widget child;
  const Appear({super.key, required this.child});
  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> {
  bool visible = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => visible = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: AppSizes.duration,
    curve: AppSizes.curve,
    child: AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.025),
      duration: AppSizes.duration,
      curve: AppSizes.curve,
      child: widget.child,
    ),
  );
}

Route<T> smoothRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (context, animation, secondary) => page,
  transitionDuration: AppSizes.duration,
  reverseTransitionDuration: AppSizes.duration,
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(parent: animation, curve: AppSizes.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
