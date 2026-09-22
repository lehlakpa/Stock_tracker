import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';
import '../../models/account_input.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

abstract class AuthMutation extends AuthEvent {
  final String operationId;
  const AuthMutation({required this.operationId});
  @override
  List<Object?> get props => [operationId];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
  @override
  List<Object?> get props => [];
}

class AuthenticatedUserChanged extends AuthEvent {
  final String? uid;
  const AuthenticatedUserChanged(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UserStatusChanged extends AuthEvent {
  final UserModel? user;
  final String uid;
  const UserStatusChanged(this.user, this.uid);
  @override
  List<Object?> get props => [user, uid];
}

class LoginRequested extends AuthMutation {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, email, password];
}

class PasswordResetRequested extends AuthMutation {
  final String email;
  const PasswordResetRequested(this.email, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, email];
}

class LogoutRequested extends AuthMutation {
  const LogoutRequested({required super.operationId});
  @override
  List<Object?> get props => [...super.props];
}

class CreateStaffRequested extends AuthMutation {
  final AccountInput input;
  const CreateStaffRequested(this.input, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, input];
}

class CreateAdminRequested extends AuthMutation {
  final AccountInput input;
  const CreateAdminRequested(this.input, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, input];
}
