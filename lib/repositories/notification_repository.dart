import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore db;
  NotificationRepository({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;
  Stream<List<NotificationModel>> watch(String uid, {int limit = 100}) => db
      .collection('notifications')
      .where('recipientUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => NotificationModel.fromMap(d.data())).toList(),
      );
  Future<void> markRead(String id) => db
      .collection('notifications')
      .doc(id)
      .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
  Future<void> markAllRead(String uid) async {
    final docs = await db
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final unread = docs.docs
        .where((doc) => doc.data()['isRead'] != true)
        .toList();
    for (var offset = 0; offset < unread.length; offset += 400) {
      final batch = db.batch();
      for (final doc in unread.skip(offset).take(400)) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
