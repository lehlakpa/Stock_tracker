import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/buyer_model.dart';
import '../models/stock_model.dart';
import '../models/user_model.dart';
import '../services/app_error.dart';
import 'stream_combine.dart';

class StockSnapshot {
  final List<StockModel> products;
  final List<StockUpdate> history;
  const StockSnapshot(this.products, this.history);
}

class StockRepository {
  Stream<StockSnapshot> watch(UserModel user) =>
      combineStreams([products(), history(user)]).map(
        (data) => StockSnapshot(
          data[0] as List<StockModel>,
          data[1] as List<StockUpdate>,
        ),
      );
  final FirebaseFirestore db;
  StockRepository({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;
  Stream<List<StockModel>> products() => db
      .collection('products')
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => StockModel.fromMap(d.data())).toList());
  Stream<List<BuyerModel>> buyers() => db
      .collection('buyers')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => BuyerModel.fromMap(d.data())).toList());
  Stream<List<StockUpdate>> history(UserModel user, {int limit = 100}) {
    Query<Map<String, dynamic>> q = db.collection('stock_updates');
    if (!user.isAdmin) q = q.where('updatedByUid', isEqualTo: user.uid);
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => StockUpdate.fromMap(d.data())).toList());
  }

  Stream<Map<String, dynamic>> report() => db
      .collection('financial_reports')
      .doc('summary')
      .snapshots()
      .map((d) => d.data() ?? {'totalSales': 0, 'totalIncome': 0});
  Map<String, dynamic> _actor(UserModel u) => {
    'lastUpdatedAt': FieldValue.serverTimestamp(),
    'lastUpdatedByUid': u.uid,
    'lastUpdatedByName': u.name,
    'lastUpdatedByEmail': u.email,
  };
  Map<String, dynamic> _history(
    String id,
    String productId,
    String name,
    int before,
    int after,
    String type,
    String note,
    UserModel u,
  ) => {
    'id': id,
    'productId': productId,
    'productName': name,
    'previousQuantity': before,
    'changedQuantity': after - before,
    'newQuantity': after,
    'updateType': type,
    'note': note,
    'updatedByUid': u.uid,
    'updatedByName': u.name,
    'updatedByEmail': u.email,
    'createdAt': FieldValue.serverTimestamp(),
  };
  Future<void> addProduct(
    Map<String, dynamic> fields,
    int quantity,
    UserModel user, {
    String? operationId,
  }) async {
    if (!user.isAdmin) {
      throw const AppException('Only administrators can add products.');
    }
    if (quantity < 0) throw const AppException('Quantity cannot be negative.');
    final product = db.collection('products').doc(operationId);
    final log = db.collection('stock_updates').doc(product.id);
    await db.runTransaction((batch) async {
      if ((await batch.get(product)).exists) return;
      batch.set(product, {
        ...fields,
        'id': product.id,
        'addedQuantity': quantity,
        'soldQuantity': 0,
        'remainingQuantity': quantity,
        'addedDate': FieldValue.serverTimestamp(),
        ..._actor(user),
      });
      batch.set(
        log,
        _history(
          log.id,
          product.id,
          fields['name'],
          0,
          quantity,
          'stock_added',
          'Initial stock',
          user,
        ),
      );
    });
  }

  Future<void> deleteProduct(String productId, UserModel user) async {
    if (!user.isAdmin || !user.isActive) {
      throw const AppException(
        'Only active administrators can delete products.',
      );
    }
    final product = db.collection('products').doc(productId);
    final log = db.collection('stock_updates').doc();
    await db.runTransaction((tx) async {
      final doc = await tx.get(product);
      if (!doc.exists) return;
      final stock = StockModel.fromMap(doc.data()!);
      tx.set(
        log,
        _history(
          log.id,
          productId,
          stock.name,
          stock.remainingQuantity,
          0,
          'stock_removed',
          'Product deleted; existing buyer records retained',
          user,
        ),
      );
      tx.delete(product);
    });
  }

  Future<void> updateQuantity(
    String id,
    int delta,
    String note,
    UserModel user, {
    Map<String, dynamic>? details,
  }) async {
    if (delta == 0 && details == null) {
      throw const AppException('Enter a non-zero quantity change.');
    }
    final product = db.collection('products').doc(id);
    final log = db.collection('stock_updates').doc();
    await db.runTransaction((tx) async {
      final doc = await tx.get(product);
      if (!doc.exists) {
        throw const AppException('This product no longer exists.');
      }
      final p = StockModel.fromMap(doc.data()!);
      final next = p.remainingQuantity + delta;
      if (next < 0) {
        throw const AppException('Insufficient stock for this change.');
      }
      tx.update(product, {
        ...?details,
        'remainingQuantity': next,
        'addedQuantity': p.addedQuantity + delta,
        ..._actor(user),
      });
      tx.set(
        log,
        _history(
          log.id,
          id,
          details?['name'] ?? p.name,
          p.remainingQuantity,
          next,
          delta > 0
              ? 'stock_added'
              : delta < 0
              ? 'stock_removed'
              : 'correction',
          note,
          user,
        ),
      );
    });
  }

  Future<void> recordPurchase(
    Map<String, dynamic> fields,
    String productId,
    int quantity,
    UserModel user, {
    required String operationId,
  }) async {
    if (quantity <= 0) {
      throw const AppException('Quantity must be greater than zero.');
    }
    final paymentStatus = fields['paymentStatus'] ?? 'paid';
    if (paymentStatus != 'paid' && paymentStatus != 'credit') {
      throw const AppException('Choose Paid or Credit as the payment status.');
    }
    final product = db.collection('products').doc(productId);
    final buyer = db.collection('buyers').doc(operationId);
    final log = db.collection('stock_updates').doc(operationId);
    await db.runTransaction((tx) async {
      final existing = await tx.get(buyer);
      if (existing.exists) return;
      final doc = await tx.get(product);
      if (!doc.exists) {
        throw const AppException('This product no longer exists.');
      }
      final p = StockModel.fromMap(doc.data()!);
      if (p.remainingQuantity < quantity) {
        throw const AppException(
          'Insufficient stock. Reduce the purchase quantity.',
        );
      }
      final next = p.remainingQuantity - quantity;
      tx.set(buyer, {
        ...fields,
        'paymentStatus': paymentStatus,
        'id': buyer.id,
        'productId': p.id,
        'productName': p.name,
        'quantity': quantity,
        'unitPrice': p.sellingPrice,
        'totalAmount': p.sellingPrice * quantity,
        'recordedByUid': user.uid,
        'recordedByName': user.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(product, {
        'soldQuantity': p.soldQuantity + quantity,
        'remainingQuantity': next,
        ..._actor(user),
      });
      tx.set(
        log,
        _history(
          log.id,
          p.id,
          p.name,
          p.remainingQuantity,
          next,
          'sale',
          'Purchase recorded',
          user,
        ),
      );
    });
  }

  Future<void> updateBuyer(
    String buyerId,
    Map<String, dynamic> fields,
    UserModel user,
  ) async {
    if (!user.isAdmin) {
      throw const AppException('Only administrators can edit buyer records.');
    }
    if (fields.containsKey('paymentStatus') &&
        fields['paymentStatus'] != 'paid' &&
        fields['paymentStatus'] != 'credit') {
      throw const AppException('Choose Paid or Credit as the payment status.');
    }
    await db.collection('buyers').doc(buyerId).update({
      ...fields,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
      'lastUpdatedByUid': user.uid,
      'lastUpdatedByName': user.name,
    });
  }

  Future<void> deleteBuyer(String buyerId, UserModel user) async {
    if (!user.isAdmin || !user.isActive) {
      throw const AppException('Only active administrators can delete buyers.');
    }
    final buyer = db.collection('buyers').doc(buyerId);
    final log = db.collection('stock_updates').doc('delete-$buyerId');
    await db.runTransaction((tx) async {
      final existing = await tx.get(buyer);
      if (!existing.exists) return;
      final purchase = BuyerModel.fromMap(existing.data()!);
      final product = db.collection('products').doc(purchase.productId);
      final productDoc = await tx.get(product);
      if (!productDoc.exists) {
        tx.set(
          log,
          _history(
            log.id,
            product.id,
            purchase.productName,
            0,
            0,
            'correction',
            'Deleted purchase $buyerId; product already deleted, no stock restored',
            user,
          ),
        );
        tx.delete(buyer);
        return;
      }
      final stock = StockModel.fromMap(productDoc.data()!);
      final remaining = stock.remainingQuantity + purchase.quantity;
      if (purchase.quantity <= 0 ||
          stock.soldQuantity < purchase.quantity ||
          remaining > stock.addedQuantity) {
        throw const AppException(
          'Stock totals do not match this purchase. Correct them before deleting.',
        );
      }
      tx.update(product, {
        'remainingQuantity': remaining,
        'soldQuantity': stock.soldQuantity - purchase.quantity,
        ..._actor(user),
      });
      tx.set(
        log,
        _history(
          log.id,
          product.id,
          stock.name,
          stock.remainingQuantity,
          remaining,
          'correction',
          'Deleted purchase $buyerId; stock restored',
          user,
        ),
      );
      tx.delete(buyer);
    });
  }
}
