import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/app_error.dart';
import '../widgets/animated_content.dart';
import '../widgets/custom_draggable_sheet.dart';
import '../widgets/notification_details.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final service = NotificationService();
  int limit = 100;
  late var stream = service.watch(context.read<UserModel>().uid);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.notifications)),
    body: StreamBuilder<List<NotificationModel>>(
      stream: stream,
      builder: (context, snapshot) => AnimatedContent(
        loading: snapshot.connectionState == ConnectionState.waiting,
        error: snapshot.hasError ? errorMessage(snapshot.error!) : null,
        empty: snapshot.data?.isEmpty ?? false,
        child: ListView(
          padding: AppSizes.pagePadding,
          children: [
            ...(snapshot.data ?? []).map(
              (n) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    n.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active_outlined,
                  ),
                  title: Text(n.title),
                  subtitle: Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => CustomDraggableSheet.show(
                    context,
                    title: n.title,
                    builder: (_, scroll) => NotificationDetails(
                      notification: n,
                      service: service,
                      scrollController: scroll,
                    ),
                  ),
                ),
              ),
            ),
            if ((snapshot.data?.length ?? 0) >= limit)
              TextButton(
                onPressed: () => setState(() {
                  limit += 100;
                  stream = service.watch(
                    context.read<UserModel>().uid,
                    limit: limit,
                  );
                }),
                child: const Text('Load older notifications'),
              ),
          ],
        ),
      ),
    ),
  );
}
