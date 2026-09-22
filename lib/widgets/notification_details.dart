import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/app_error.dart';
import 'custom_button.dart';
import 'custom_notification.dart';

class NotificationDetails extends StatefulWidget {
  final NotificationModel notification;
  final NotificationService service;
  final ScrollController scrollController;
  const NotificationDetails({
    super.key,
    required this.notification,
    required this.service,
    required this.scrollController,
  });
  @override
  State<NotificationDetails> createState() => _NotificationDetailsState();
}

class _NotificationDetailsState extends State<NotificationDetails> {
  bool saving = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: ListView(
      controller: widget.scrollController,
      padding: AppSizes.pagePadding,
      children: [
        Text(widget.notification.message),
        const SizedBox(height: AppSizes.lg),
        CustomButton(
          label: 'Mark as read',
          loading: saving,
          onPressed: () async {
            setState(() => saving = true);
            try {
              await widget.service.markRead(widget.notification.id);
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                showNotice(context, errorMessage(e), error: true);
              }
            } finally {
              if (mounted) setState(() => saving = false);
            }
          },
        ),
      ],
    ),
  );
}
