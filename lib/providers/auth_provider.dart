import 'dart:async';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/app_error.dart';
import 'async_provider.dart';

class AuthProvider extends AsyncProvider {
  final AuthService service;
  StreamSubscription<String?>? _auth;
  StreamSubscription<UserModel?>? _profile;
  String? _uid;
  int _generation = 0;
  UserModel? user;
  bool loading = true;
  String? _profileError;
  String? get error => saveError ?? _profileError;
  bool get busy => saving;
  bool get signedIn => _uid != null;
  AuthProvider(this.service) {
    _auth = service.authChanges.listen(
      _listen,
      onError: (Object e) {
        loading = false;
        _profileError = errorMessage(e);
        changed();
      },
    );
  }
  void _listen(String? uid) {
    final generation = ++_generation;
    _profile?.cancel();
    _profile = null;
    _uid = uid;
    user = null;
    _profileError = null;
    loading = uid != null;
    changed();
    if (uid == null) return;
    _profile = service
        .profile(uid)
        .listen(
          (value) {
            if (disposed || generation != _generation) return;
            user = value;
            loading = false;
            _profileError = value == null
                ? 'Your user profile is missing. Contact your administrator.'
                : null;
            changed();
          },
          onError: (Object e) {
            if (disposed || generation != _generation) return;
            user = null;
            loading = false;
            _profileError = errorMessage(e);
            changed();
          },
        );
  }

  void retry() => _listen(_uid);
  Future<bool> run(Future<void> Function() action) => save(action);
  Future<bool> login(String email, String password) =>
      run(() => service.login(email, password));
  Future<bool> logout() => run(service.logout);
  Future<bool> resetPassword(String email) =>
      run(() => service.resetPassword(email));
  @override
  void dispose() {
    ++_generation;
    _auth?.cancel();
    _profile?.cancel();
    super.dispose();
  }
}
