import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../models/account_input.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/app_error.dart';
import 'auth_event.dart';
import 'auth_state.dart';
export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  AuthBloc(this.repository) : super(const AuthInitial()) {
    on<AuthStarted>((event, emit) async {
      await emit.forEach<String?>(
        repository.authChanges,
        onData: (uid) {
          add(AuthenticatedUserChanged(uid));
          return state;
        },
        onError: (e, _) => state.copyWith(
          status: AuthStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
        ),
      );
    }, transformer: restartable());
    on<AuthenticatedUserChanged>((event, emit) async {
      if (event.uid == null) {
        emit(
          state.copyWith(
            status: AuthStatus.loaded,
            access: AuthAccess.signedOut,
            clearSession: true,
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.loading,
          access: AuthAccess.checking,
          uid: event.uid,
          clearError: true,
        ),
      );
      await emit.forEach<UserModel?>(
        repository.profile(event.uid!),
        onData: (user) {
          add(UserStatusChanged(user, event.uid!));
          return state;
        },
        onError: (e, _) => state.copyWith(
          status: AuthStatus.failure,
          access: AuthAccess.missing,
          error: errorMessage(e),
          effect: state.effect + 1,
        ),
      );
    }, transformer: restartable());
    on<UserStatusChanged>((event, emit) {
      if (state.uid != event.uid) return;
      final user = event.user;
      final access = user == null
          ? AuthAccess.missing
          : !user.isActive
          ? AuthAccess.inactive
          : !user.hasValidRole
          ? AuthAccess.invalid
          : AuthAccess.active;
      emit(
        state.copyWith(
          user: user,
          access: access,
          status: state.submitting ? AuthStatus.submitting : AuthStatus.loaded,
          error: user == null
              ? 'Your user profile is missing. Contact your administrator.'
              : null,
          clearError: user != null,
        ),
      );
    });
    on<AuthMutation>(_mutate, transformer: droppable());
  }
  Future<void> _mutate(AuthMutation event, Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        operationId: event.operationId,
        clearError: true,
      ),
    );
    try {
      switch (event) {
        case LoginRequested():
          await repository.login(event.email, event.password);
        case PasswordResetRequested():
          await repository.resetPassword(event.email);
        case LogoutRequested():
          await repository.logout();
        case CreateStaffRequested():
          await _create(event.input, 'staff');
        case CreateAdminRequested():
          await _create(event.input, 'admin');
      }
      emit(
        state.copyWith(
          status: AuthStatus.success,
          effect: state.effect + 1,
          operationId: event.operationId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
          operationId: event.operationId,
        ),
      );
    }
  }

  Future<void> _create(AccountInput input, String role) =>
      repository.createAccount(
        name: input.name,
        email: input.email,
        password: input.password,
        phone: input.phone,
        branch: input.branch,
        role: role,
      );
}
