import '../models/account_input.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class StaffRepository {
  final AuthRepository auth;
  StaffRepository(this.auth);
  Stream<List<UserModel>> watch() => auth.users();
  Future<void> create(AccountInput input, String role) => auth.createAccount(
    name: input.name,
    email: input.email,
    password: input.password,
    phone: input.phone,
    branch: input.branch,
    role: role,
  );
  Future<void> setActive(UserModel user, bool active) =>
      auth.setActive(user, active);
  Future<void> update(String uid, String name, String phone, String branch) =>
      auth.updateProfile(uid, name, phone, branch);
}
