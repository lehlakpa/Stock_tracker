import 'package:equatable/equatable.dart';
import '../../models/notification_model.dart';

enum NotificationStatus {
  initial,
  loading,
  loaded,
  submitting,
  success,
  failure,
}

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationModel> notifications;
  final int effect;
  final String? operationId;
  final String? error;
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.effect = 0,
    this.operationId,
    this.error,
  });
  bool get submitting => status == NotificationStatus.submitting;
  bool get loading =>
      status == NotificationStatus.initial ||
      status == NotificationStatus.loading;

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? notifications,
    int? effect,
    String? operationId,
    String? error,
    bool clearError = false,
  }) {
    final next = NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      effect: effect ?? this.effect,
      operationId: operationId ?? this.operationId,
      error: error ?? this.error,
    );
    return switch (next.status) {
      NotificationStatus.initial => NotificationInitial.from(
        next,
        clearError: clearError,
      ),
      NotificationStatus.loading => NotificationLoading.from(
        next,
        clearError: clearError,
      ),
      NotificationStatus.loaded => NotificationLoaded.from(
        next,
        clearError: clearError,
      ),
      NotificationStatus.submitting => NotificationSubmitting.from(
        next,
        clearError: clearError,
      ),
      NotificationStatus.success => NotificationSuccess.from(
        next,
        clearError: clearError,
      ),
      NotificationStatus.failure => NotificationFailure.from(
        next,
        clearError: clearError,
      ),
    };
  }

  @override
  List<Object?> get props => [
    status,
    notifications,
    effect,
    operationId,
    error,
  ];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial() : super(status: NotificationStatus.initial);
  NotificationInitial.from(NotificationState s, {bool clearError = false})
    : super(
        status: NotificationStatus.initial,
        notifications: s.notifications,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class NotificationLoading extends NotificationState {
  const NotificationLoading() : super(status: NotificationStatus.loading);
  NotificationLoading.from(NotificationState s, {bool clearError = false})
    : super(
        status: NotificationStatus.loading,
        notifications: s.notifications,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded() : super(status: NotificationStatus.loaded);
  NotificationLoaded.from(NotificationState s, {bool clearError = false})
    : super(
        status: NotificationStatus.loaded,
        notifications: s.notifications,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class NotificationSubmitting extends NotificationState {
  const NotificationSubmitting() : super(status: NotificationStatus.submitting);
  NotificationSubmitting.from(NotificationState s, {bool clearError = false})
    : super(
        status: NotificationStatus.submitting,
        notifications: s.notifications,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class NotificationSuccess extends NotificationState {
  const NotificationSuccess() : super(status: NotificationStatus.success);
  NotificationSuccess.from(NotificationState s, {bool clearError = false})
    : super(
        status: NotificationStatus.success,
        notifications: s.notifications,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class NotificationFailure extends NotificationState {
  const NotificationFailure() : super(status: NotificationStatus.failure);
  NotificationFailure.from(NotificationState s, {bool clearError = false})
    : super(
        status: NotificationStatus.failure,
        notifications: s.notifications,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}
