import 'user_model.dart';

class NotificationModel {
  final String id, title, message, recipientUid;
  final bool isRead;
  final DateTime? createdAt;
  NotificationModel.fromMap(Map<String, dynamic> d)
    : id = d['id'],
      title = d['title'],
      message = d['message'],
      recipientUid = d['recipientUid'],
      isRead = d['isRead'] == true,
      createdAt = readDate(d['createdAt']);
}
