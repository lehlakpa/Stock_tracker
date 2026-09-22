import 'app_error.dart';

/// Rolls back only the newly created login if its profile cannot be saved.
Future<void> provisionAccount<T>({
  required Future<T> Function() createLogin,
  required Future<void> Function(T) saveProfile,
  required Future<void> Function(T) deleteLogin,
}) async {
  final login = await createLogin();
  try {
    await saveProfile(login);
  } catch (_) {
    try {
      await deleteLogin(login);
    } catch (_) {
      throw const AppException(
        'The profile could not be saved and account cleanup failed. '
        'Ask the project owner to remove the incomplete Auth account before retrying.',
      );
    }
    rethrow;
  }
}
