import 'package:equatable/equatable.dart';
import '../../models/purchase_input.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

abstract class StockMutation extends StockEvent {
  final String operationId;
  const StockMutation({required this.operationId});
  @override
  List<Object?> get props => [operationId];
}

class StockSubscriptionRequested extends StockEvent {
  const StockSubscriptionRequested();
  @override
  List<Object?> get props => [];
}

class StockSearchChanged extends StockEvent {
  final String query;
  const StockSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class StockCategoryChanged extends StockEvent {
  final String category;
  final bool lowOnly;
  const StockCategoryChanged(this.category, this.lowOnly);
  @override
  List<Object?> get props => [category, lowOnly];
}

class StockAddRequested extends StockMutation {
  final Map<String, dynamic> fields;
  final int quantity;
  const StockAddRequested(
    this.fields,
    this.quantity, {
    required super.operationId,
  });
  @override
  List<Object?> get props => [...super.props, fields, quantity];
}

class StockUpdateRequested extends StockMutation {
  final String productId;
  final int delta;
  final String note;
  final Map<String, dynamic>? details;
  const StockUpdateRequested(
    this.productId,
    this.delta,
    this.note,
    this.details, {
    required super.operationId,
  });
  @override
  List<Object?> get props => [...super.props, productId, delta, note, details];
}

class StockSaleRequested extends StockMutation {
  final PurchaseInput purchase;
  const StockSaleRequested(this.purchase, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, purchase];
}
