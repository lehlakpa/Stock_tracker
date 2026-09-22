import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum AuthStatus { initial, loading, loaded, submitting, success, failure }

enum AuthAccess { checking, signedOut, active, inactive, missing, invalid }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? uid;
  final AuthAccess access;
  final int effect;
  final String? operationId;
  final String? error;
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.uid,
    this.access = AuthAccess.checking,
    this.effect = 0,
    this.operationId,
    this.error,
  });
  bool get submitting => status == AuthStatus.submitting;
  bool get loading =>
      status == AuthStatus.initial || status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? uid,
    AuthAccess? access,
    int? effect,
    String? operationId,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    final next = AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      uid: uid ?? this.uid,
      access: access ?? this.access,
      effect: effect ?? this.effect,
      operationId: operationId ?? this.operationId,
      error: error ?? this.error,
    );
    return switch (next.status) {
      AuthStatus.initial => AuthInitial.from(
        next,
        clearError: clearError,
        clearSession: clearSession,
      ),
      AuthStatus.loading => AuthLoading.from(
        next,
        clearError: clearError,
        clearSession: clearSession,
      ),
      AuthStatus.loaded => AuthLoaded.from(
        next,
        clearError: clearError,
        clearSession: clearSession,
      ),
      AuthStatus.submitting => AuthSubmitting.from(
        next,
        clearError: clearError,
        clearSession: clearSession,
      ),
      AuthStatus.success => AuthSuccess.from(
        next,
        clearError: clearError,
        clearSession: clearSession,
      ),
      AuthStatus.failure => AuthFailure.from(
        next,
        clearError: clearError,
        clearSession: clearSession,
      ),
    };
  }

  @override
  List<Object?> get props => [
    status,
    user,
    uid,
    access,
    effect,
    operationId,
    error,
  ];
}

class AuthInitial extends AuthState {
  const AuthInitial() : super(status: AuthStatus.initial);
  AuthInitial.from(
    AuthState s, {
    bool clearError = false,
    bool clearSession = false,
  }) : super(
         status: AuthStatus.initial,
         user: clearSession ? null : s.user,
         uid: clearSession ? null : s.uid,
         access: s.access,
         effect: s.effect,
         operationId: s.operationId,
         error: clearError ? null : s.error,
       );
}

class AuthLoading extends AuthState {
  const AuthLoading() : super(status: AuthStatus.loading);
  AuthLoading.from(
    AuthState s, {
    bool clearError = false,
    bool clearSession = false,
  }) : super(
         status: AuthStatus.loading,
         user: clearSession ? null : s.user,
         uid: clearSession ? null : s.uid,
         access: s.access,
         effect: s.effect,
         operationId: s.operationId,
         error: clearError ? null : s.error,
       );
}

class AuthLoaded extends AuthState {
  const AuthLoaded() : super(status: AuthStatus.loaded);
  AuthLoaded.from(
    AuthState s, {
    bool clearError = false,
    bool clearSession = false,
  }) : super(
         status: AuthStatus.loaded,
         user: clearSession ? null : s.user,
         uid: clearSession ? null : s.uid,
         access: s.access,
         effect: s.effect,
         operationId: s.operationId,
         error: clearError ? null : s.error,
       );
}

class AuthSubmitting extends AuthState {
  const AuthSubmitting() : super(status: AuthStatus.submitting);
  AuthSubmitting.from(
    AuthState s, {
    bool clearError = false,
    bool clearSession = false,
  }) : super(
         status: AuthStatus.submitting,
         user: clearSession ? null : s.user,
         uid: clearSession ? null : s.uid,
         access: s.access,
         effect: s.effect,
         operationId: s.operationId,
         error: clearError ? null : s.error,
       );
}

class AuthSuccess extends AuthState {
  const AuthSuccess() : super(status: AuthStatus.success);
  AuthSuccess.from(
    AuthState s, {
    bool clearError = false,
    bool clearSession = false,
  }) : super(
         status: AuthStatus.success,
         user: clearSession ? null : s.user,
         uid: clearSession ? null : s.uid,
         access: s.access,
         effect: s.effect,
         operationId: s.operationId,
         error: clearError ? null : s.error,
       );
}

class AuthFailure extends AuthState {
  const AuthFailure() : super(status: AuthStatus.failure);
  AuthFailure.from(
    AuthState s, {
    bool clearError = false,
    bool clearSession = false,
  }) : super(
         status: AuthStatus.failure,
         user: clearSession ? null : s.user,
         uid: clearSession ? null : s.uid,
         access: s.access,
         effect: s.effect,
         operationId: s.operationId,
         error: clearError ? null : s.error,
       );
}
