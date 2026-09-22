import 'package:equatable/equatable.dart';
import 'payment_status.dart';

class PurchaseInput extends Equatable {
  final String productId, name, phone, address, notes;
  final int quantity;
  final PaymentStatus paymentStatus;
  final DateTime purchaseDate, warrantyStartDate, warrantyEndDate;
  const PurchaseInput({
    this.paymentStatus = PaymentStatus.paid,
    required this.productId,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.quantity,
    required this.purchaseDate,
    required this.warrantyStartDate,
    required this.warrantyEndDate,
  });
  Map<String, dynamic> toMap() => {
    'paymentStatus': paymentStatus.name,
    'name': name,
    'phone': phone,
    'address': address,
    'notes': notes,
    'purchaseDate': purchaseDate,
    'warrantyStartDate': warrantyStartDate,
    'warrantyEndDate': warrantyEndDate,
  };
  @override
  List<Object?> get props => [
    paymentStatus,
    productId,
    name,
    phone,
    address,
    notes,
    quantity,
    purchaseDate,
    warrantyStartDate,
    warrantyEndDate,
  ];
}
