import 'package:equatable/equatable.dart';
import '../../models/account_input.dart';
import '../../models/user_model.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();
  @override
  List<Object?> get props => [];
}

abstract class StaffMutation extends StaffEvent {
  final String operationId;
  const StaffMutation({required this.operationId});
  @override
  List<Object?> get props => [operationId];
}

class StaffSubscriptionRequested extends StaffEvent {
  const StaffSubscriptionRequested();
  @override
  List<Object?> get props => [];
}

class StaffCreateRequested extends StaffMutation {
  final AccountInput input;
  const StaffCreateRequested(this.input, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, input];
}

class AdminCreateRequested extends StaffMutation {
  final AccountInput input;
  const AdminCreateRequested(this.input, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, input];
}

class StaffActivationChanged extends StaffMutation {
  final UserModel user;
  final bool active;
  const StaffActivationChanged(
    this.user,
    this.active, {
    required super.operationId,
  });
  @override
  List<Object?> get props => [...super.props, user, active];
}

class StaffUpdateRequested extends StaffMutation {
  final String uid;
  final String name;
  final String phone;
  final String branch;
  const StaffUpdateRequested(
    this.uid,
    this.name,
    this.phone,
    this.branch, {
    required super.operationId,
  });
  @override
  List<Object?> get props => [...super.props, uid, name, phone, branch];
}
