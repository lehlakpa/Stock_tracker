import 'package:equatable/equatable.dart';

class AccountInput extends Equatable {
  final String name, email, password, phone, branch;
  const AccountInput({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.branch,
  });
  @override
  List<Object?> get props => [name, email, password, phone, branch];
}
