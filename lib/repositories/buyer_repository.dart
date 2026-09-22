import '../models/buyer_model.dart';
import '../models/purchase_input.dart';
import '../models/user_model.dart';
import 'stock_repository.dart';

class BuyerRepository {
  final StockRepository stock;
  BuyerRepository(this.stock);
  Stream<List<BuyerModel>> watch() => stock.buyers();
  Future<void> add(PurchaseInput input, UserModel actor, String operationId) =>
      stock.recordPurchase(
        input.toMap(),
        input.productId,
        input.quantity,
        actor,
        operationId: operationId,
      );
}
