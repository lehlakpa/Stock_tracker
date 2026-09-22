import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';
import '../../services/app_error.dart';
import 'notification_event.dart';
import 'notification_state.dart';
export 'notification_event.dart';
export 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  final String uid;
  NotificationBloc(this.repository, this.uid)
    : super(const NotificationInitial()) {
    on<NotificationsSubscriptionRequested>((event, emit) async {
      emit(
        state.copyWith(
          status: state.notifications.isEmpty
              ? NotificationStatus.loading
              : state.status,
          clearError: true,
        ),
      );
      await emit.forEach<List<NotificationModel>>(
        repository.watch(uid),
        onData: (data) => state.copyWith(
          notifications: List.unmodifiable(data),
          status: state.loading ? NotificationStatus.loaded : state.status,
        ),
        onError: (e, _) => state.copyWith(
          status: NotificationStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
          operationId: 'subscription',
        ),
      );
    }, transformer: restartable());
    on<NotificationMutation>((event, emit) async {
      emit(
        state.copyWith(
          status: NotificationStatus.submitting,
          operationId: event.operationId,
          clearError: true,
        ),
      );
      try {
        switch (event) {
          case NotificationReadRequested():
            await repository.markRead(event.id);
          case AllNotificationsReadRequested():
            await repository.markAllRead(uid);
        }
        emit(
          state.copyWith(
            status: NotificationStatus.success,
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: NotificationStatus.failure,
            error: errorMessage(e),
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      }
    }, transformer: droppable());
  }
}
