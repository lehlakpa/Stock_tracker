import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

abstract class NotificationMutation extends NotificationEvent {
  final String operationId;
  const NotificationMutation({required this.operationId});
  @override
  List<Object?> get props => [operationId];
}

class NotificationsSubscriptionRequested extends NotificationEvent {
  const NotificationsSubscriptionRequested();
  @override
  List<Object?> get props => [];
}

class NotificationReadRequested extends NotificationMutation {
  final String id;
  const NotificationReadRequested(this.id, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, id];
}

class AllNotificationsReadRequested extends NotificationMutation {
  const AllNotificationsReadRequested({required super.operationId});
  @override
  List<Object?> get props => [...super.props];
}
