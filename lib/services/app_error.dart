import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

String errorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' => 'The email or password is incorrect.',
      'invalid-email' => 'Enter a valid email address.',
      'user-not-found' => 'No account was found for this email.',
      'email-already-in-use' => 'This email already has an account.',
      'weak-password' => 'Use a stronger password with at least 8 characters.',
      'network-request-failed' ||
      'unavailable' => 'Connection failed. Check your network and try again.',
      'permission-denied' =>
        'You do not have permission. Your account may have been deactivated.',
      'not-found' => 'The requested record no longer exists.',
      'user-disabled' =>
        'Your account is disabled. Contact your administrator.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'aborted' => 'The record changed. Please try again.',
      _ =>
        error.message ??
            'Firebase could not complete the request (${error.code}).',
    };
  }
  return 'The request could not be completed. Please try again. ($error)';
}
