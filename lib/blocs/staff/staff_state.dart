import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum StaffStatus { initial, loading, loaded, submitting, success, failure }

class StaffState extends Equatable {
  final StaffStatus status;
  final List<UserModel> users;
  final int effect;
  final String? operationId;
  final String? error;
  const StaffState({
    this.status = StaffStatus.initial,
    this.users = const [],
    this.effect = 0,
    this.operationId,
    this.error,
  });
  bool get submitting => status == StaffStatus.submitting;
  bool get loading =>
      status == StaffStatus.initial || status == StaffStatus.loading;

  StaffState copyWith({
    StaffStatus? status,
    List<UserModel>? users,
    int? effect,
    String? operationId,
    String? error,
    bool clearError = false,
  }) {
    final next = StaffState(
      status: status ?? this.status,
      users: users ?? this.users,
      effect: effect ?? this.effect,
      operationId: operationId ?? this.operationId,
      error: error ?? this.error,
    );
    return switch (next.status) {
      StaffStatus.initial => StaffInitial.from(next, clearError: clearError),
      StaffStatus.loading => StaffLoading.from(next, clearError: clearError),
      StaffStatus.loaded => StaffLoaded.from(next, clearError: clearError),
      StaffStatus.submitting => StaffSubmitting.from(
        next,
        clearError: clearError,
      ),
      StaffStatus.success => StaffSuccess.from(next, clearError: clearError),
      StaffStatus.failure => StaffFailure.from(next, clearError: clearError),
    };
  }

  @override
  List<Object?> get props => [status, users, effect, operationId, error];
}

class StaffInitial extends StaffState {
  const StaffInitial() : super(status: StaffStatus.initial);
  StaffInitial.from(StaffState s, {bool clearError = false})
    : super(
        status: StaffStatus.initial,
        users: s.users,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StaffLoading extends StaffState {
  const StaffLoading() : super(status: StaffStatus.loading);
  StaffLoading.from(StaffState s, {bool clearError = false})
    : super(
        status: StaffStatus.loading,
        users: s.users,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StaffLoaded extends StaffState {
  const StaffLoaded() : super(status: StaffStatus.loaded);
  StaffLoaded.from(StaffState s, {bool clearError = false})
    : super(
        status: StaffStatus.loaded,
        users: s.users,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StaffSubmitting extends StaffState {
  const StaffSubmitting() : super(status: StaffStatus.submitting);
  StaffSubmitting.from(StaffState s, {bool clearError = false})
    : super(
        status: StaffStatus.submitting,
        users: s.users,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StaffSuccess extends StaffState {
  const StaffSuccess() : super(status: StaffStatus.success);
  StaffSuccess.from(StaffState s, {bool clearError = false})
    : super(
        status: StaffStatus.success,
        users: s.users,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StaffFailure extends StaffState {
  const StaffFailure() : super(status: StaffStatus.failure);
  StaffFailure.from(StaffState s, {bool clearError = false})
    : super(
        status: StaffStatus.failure,
        users: s.users,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}
