import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

abstract class DashboardMutation extends DashboardEvent {
  final String operationId;
  const DashboardMutation({required this.operationId});
  @override
  List<Object?> get props => [operationId];
}

class DashboardSubscriptionRequested extends DashboardEvent {
  const DashboardSubscriptionRequested();
  @override
  List<Object?> get props => [];
}

class DashboardRefreshRequested extends DashboardMutation {
  const DashboardRefreshRequested({required super.operationId});
  @override
  List<Object?> get props => [...super.props];
}
