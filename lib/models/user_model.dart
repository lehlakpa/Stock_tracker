import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? readDate(dynamic value) => value is Timestamp ? value.toDate() : null;

class UserModel {
  final String uid, name, email, phone, role, branch;
  final bool isActive;
  final DateTime? createdAt, lastLogin;
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.branch,
    required this.isActive,
    this.createdAt,
    this.lastLogin,
  });
  bool get isAdmin => role == 'admin';
  bool get hasValidRole => role == 'admin' || role == 'staff';
  factory UserModel.fromMap(Map<String, dynamic> d) => UserModel(
    uid: d['uid'] as String,
    name: d['name'] as String,
    email: d['email'] as String,
    phone: (d['phone'] as String? ?? ''),
    role: d['role'] as String,
    branch: (d['branch'] as String? ?? ''),
    isActive: d['isActive'] == true,
    createdAt: readDate(d['createdAt']),
    lastLogin: readDate(d['lastLogin']),
  );
}
