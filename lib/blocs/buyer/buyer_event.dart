import 'package:equatable/equatable.dart';
import '../../models/purchase_input.dart';

abstract class BuyerEvent extends Equatable {
  const BuyerEvent();
  @override
  List<Object?> get props => [];
}

abstract class BuyerMutation extends BuyerEvent {
  final String operationId;
  const BuyerMutation({required this.operationId});
  @override
  List<Object?> get props => [operationId];
}

class BuyersSubscriptionRequested extends BuyerEvent {
  const BuyersSubscriptionRequested();
  @override
  List<Object?> get props => [];
}

class BuyerSearchChanged extends BuyerEvent {
  final String query;
  const BuyerSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class BuyerDetailsRequested extends BuyerEvent {
  final String id;
  const BuyerDetailsRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class BuyerAddRequested extends BuyerMutation {
  final PurchaseInput purchase;
  const BuyerAddRequested(this.purchase, {required super.operationId});
  @override
  List<Object?> get props => [...super.props, purchase];
}
