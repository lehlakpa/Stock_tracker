import 'dart:async';
import '../models/stock_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/app_error.dart';
import 'async_provider.dart';

class StockProvider extends AsyncProvider {
  final FirestoreService service;
  final UserModel user;
  List<StockModel> products = [];
  List<StockUpdate> history = [];
  bool loading = true;
  int historyLimit = 100;
  bool get hasMoreHistory => history.length >= historyLimit;
  void loadMoreHistory() {
    historyLimit += 100;
    _subscribeHistory();
  }

  String? error, historyError;
  StreamSubscription<List<StockModel>>? _products;
  StreamSubscription<List<StockUpdate>>? _history;
  StockProvider(this.service, this.user) {
    subscribe();
  }
  void subscribe() {
    _products?.cancel();
    _history?.cancel();
    error = null;
    historyError = null;
    loading = products.isEmpty;
    _products = service.products().listen(
      (data) {
        products = data;
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
    _subscribeHistory();
  }

  void _subscribeHistory() {
    _history?.cancel();
    _history = service
        .history(user, limit: historyLimit)
        .listen(
          (data) {
            history = data;
            historyError = null;
            changed();
          },
          onError: (Object e) {
            historyError = errorMessage(e);
            changed();
          },
        );
  }

  @override
  void dispose() {
    _products?.cancel();
    _history?.cancel();
    super.dispose();
  }

  Future<bool> deleteProduct(String productId) =>
      save(() => service.deleteProduct(productId, user));
}
