import 'user_model.dart';
import 'payment_status.dart';

class BuyerModel {
  final String id,
      name,
      phone,
      address,
      productId,
      productName,
      notes,
      recordedByUid,
      recordedByName;
  final int quantity;
  final PaymentStatus paymentStatus;
  final double unitPrice, totalAmount;
  final DateTime? purchaseDate, warrantyStartDate, warrantyEndDate, createdAt;
  BuyerModel.fromMap(Map<String, dynamic> d)
    : id = d['id'],
      paymentStatus = PaymentStatus.fromValue(d['paymentStatus']),
      name = d['name'],
      phone = d['phone'],
      address = (d['address'] as String? ?? ''),
      productId = d['productId'],
      productName = d['productName'],
      notes = (d['notes'] as String? ?? ''),
      recordedByUid = d['recordedByUid'],
      recordedByName = (d['recordedByName'] as String? ?? ''),
      quantity = d['quantity'],
      unitPrice = (d['unitPrice'] as num).toDouble(),
      totalAmount = (d['totalAmount'] as num).toDouble(),
      purchaseDate = readDate(d['purchaseDate']),
      warrantyStartDate =
          readDate(d['warrantyStartDate']) ?? readDate(d['purchaseDate']),
      warrantyEndDate =
          readDate(d['warrantyEndDate']) ?? readDate(d['expiresDate']),
      createdAt = readDate(d['createdAt']);
}
