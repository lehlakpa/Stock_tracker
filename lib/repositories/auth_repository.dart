import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/app_error.dart';
import '../services/account_provisioning.dart';
import '../models/operation_id.dart';

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
    : auth = auth ?? FirebaseAuth.instance,
      db = db ?? FirebaseFirestore.instance;
  Stream<String?> get authChanges =>
      auth.authStateChanges().map((user) => user?.uid);
  String? get currentUid => auth.currentUser?.uid;
  Future<void> updateProfile(
    String uid,
    String name,
    String phone,
    String branch,
  ) => db.collection('users').doc(uid).update({
    'name': name.trim(),
    'phone': phone.trim(),
    'branch': branch.trim(),
  });
  Stream<UserModel?> profile(String uid) => db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => auth.signOut();
  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  Stream<List<UserModel>> users() => db
      .collection('users')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => UserModel.fromMap(d.data())).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
  Future<void> setActive(UserModel user, bool active) async {
    if (user.role != 'staff') {
      throw const AppException('Only staff accounts can be deactivated here.');
    }
    await db.collection('users').doc(user.uid).update({'isActive': active});
  }

  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String branch,
    required String role,
  }) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AppException('Sign in as an administrator.');
    final admin = await db
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (admin.data()?['role'] != 'admin' || admin.data()?['isActive'] != true) {
      throw const AppException('An active administrator is required.');
    }
    if (!['admin', 'staff'].contains(role)) {
      throw const AppException('Invalid account role.');
    }
    if (name.trim().isEmpty || password.length < 8) {
      throw const AppException(
        'Enter a name and a password of at least 8 characters.',
      );
    }
    final secondary = await Firebase.initializeApp(
      name: 'registration-${newOperationId()}',
      options: auth.app.options,
    );
    final registrationAuth = FirebaseAuth.instanceFor(app: secondary);
    try {
      if (kIsWeb) await registrationAuth.setPersistence(Persistence.NONE);
      await provisionAccount<User>(
        createLogin: () async {
          final result = await registrationAuth.createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );
          return result.user!;
        },
        saveProfile: (newUser) async {
          if (auth.currentUser?.uid != uid) {
            throw const AppException(
              'Your administrator session changed. Sign in and try again.',
            );
          }
          // Use the original admin's Firestore instance, never the new account.
          await db.collection('users').doc(newUser.uid).set({
            'uid': newUser.uid,
            'name': name.trim(),
            'email': newUser.email!,
            'phone': phone.trim(),
            'branch': branch.trim(),
            'role': role,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': null,
          });
        },
        deleteLogin: (newUser) => newUser.delete(),
      );
    } finally {
      // Cleanup must not turn an already saved account into a reported failure.
      try {
        await registrationAuth.signOut();
      } catch (_) {
        // Disposing this isolated app also releases its local auth instance.
      }
      try {
        await secondary.delete();
      } catch (_) {
        // No main-session state or credentials are persisted by this app.
      }
    }
  }
}
