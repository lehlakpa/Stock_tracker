import 'dart:async';
import '../models/buyer_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/app_error.dart';
import 'async_provider.dart';

class BuyerProvider extends AsyncProvider {
  final FirestoreService service;
  List<BuyerModel> buyers = [];
  bool loading = true;
  String? error;
  StreamSubscription<List<BuyerModel>>? _subscription;
  BuyerProvider(this.service) {
    subscribe();
  }
  void subscribe() {
    _subscription?.cancel();
    error = null;
    loading = buyers.isEmpty;
    _subscription = service.buyers().listen(
      (data) {
        buyers = data;
        loading = false;
        error = null;
        changed();
      },
      onError: (Object e) {
        loading = false;
        error = errorMessage(e);
        changed();
      },
    );
  }

  Future<bool> update(
    String buyerId,
    Map<String, dynamic> fields,
    UserModel user,
  ) => save(() => service.updateBuyer(buyerId, fields, user));

  Future<bool> delete(String buyerId, UserModel user) =>
      save(() => service.deleteBuyer(buyerId, user));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
