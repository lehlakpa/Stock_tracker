import 'package:equatable/equatable.dart';
import '../../models/buyer_model.dart';

enum BuyerStatus { initial, loading, loaded, submitting, success, failure }

class BuyerState extends Equatable {
  final BuyerStatus status;
  final List<BuyerModel> buyers;
  final String query;
  final String? selectedId;
  final int effect;
  final String? operationId;
  final String? error;
  const BuyerState({
    this.status = BuyerStatus.initial,
    this.buyers = const [],
    this.query = '',
    this.selectedId,
    this.effect = 0,
    this.operationId,
    this.error,
  });
  bool get submitting => status == BuyerStatus.submitting;
  bool get loading =>
      status == BuyerStatus.initial || status == BuyerStatus.loading;
  List<BuyerModel> get filtered => buyers
      .where(
        (b) =>
            b.name.toLowerCase().contains(query.toLowerCase()) ||
            b.phone.contains(query),
      )
      .toList();
  BuyerModel? get selected =>
      buyers.where((b) => b.id == selectedId).firstOrNull;
  BuyerState copyWith({
    BuyerStatus? status,
    List<BuyerModel>? buyers,
    String? query,
    String? selectedId,
    int? effect,
    String? operationId,
    String? error,
    bool clearError = false,
  }) {
    final next = BuyerState(
      status: status ?? this.status,
      buyers: buyers ?? this.buyers,
      query: query ?? this.query,
      selectedId: selectedId ?? this.selectedId,
      effect: effect ?? this.effect,
      operationId: operationId ?? this.operationId,
      error: error ?? this.error,
    );
    return switch (next.status) {
      BuyerStatus.initial => BuyerInitial.from(next, clearError: clearError),
      BuyerStatus.loading => BuyerLoading.from(next, clearError: clearError),
      BuyerStatus.loaded => BuyerLoaded.from(next, clearError: clearError),
      BuyerStatus.submitting => BuyerSubmitting.from(
        next,
        clearError: clearError,
      ),
      BuyerStatus.success => BuyerSuccess.from(next, clearError: clearError),
      BuyerStatus.failure => BuyerFailure.from(next, clearError: clearError),
    };
  }

  @override
  List<Object?> get props => [
    status,
    buyers,
    query,
    selectedId,
    effect,
    operationId,
    error,
  ];
}

class BuyerInitial extends BuyerState {
  const BuyerInitial() : super(status: BuyerStatus.initial);
  BuyerInitial.from(BuyerState s, {bool clearError = false})
    : super(
        status: BuyerStatus.initial,
        buyers: s.buyers,
        query: s.query,
        selectedId: s.selectedId,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class BuyerLoading extends BuyerState {
  const BuyerLoading() : super(status: BuyerStatus.loading);
  BuyerLoading.from(BuyerState s, {bool clearError = false})
    : super(
        status: BuyerStatus.loading,
        buyers: s.buyers,
        query: s.query,
        selectedId: s.selectedId,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class BuyerLoaded extends BuyerState {
  const BuyerLoaded() : super(status: BuyerStatus.loaded);
  BuyerLoaded.from(BuyerState s, {bool clearError = false})
    : super(
        status: BuyerStatus.loaded,
        buyers: s.buyers,
        query: s.query,
        selectedId: s.selectedId,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class BuyerSubmitting extends BuyerState {
  const BuyerSubmitting() : super(status: BuyerStatus.submitting);
  BuyerSubmitting.from(BuyerState s, {bool clearError = false})
    : super(
        status: BuyerStatus.submitting,
        buyers: s.buyers,
        query: s.query,
        selectedId: s.selectedId,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class BuyerSuccess extends BuyerState {
  const BuyerSuccess() : super(status: BuyerStatus.success);
  BuyerSuccess.from(BuyerState s, {bool clearError = false})
    : super(
        status: BuyerStatus.success,
        buyers: s.buyers,
        query: s.query,
        selectedId: s.selectedId,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class BuyerFailure extends BuyerState {
  const BuyerFailure() : super(status: BuyerStatus.failure);
  BuyerFailure.from(BuyerState s, {bool clearError = false})
    : super(
        status: BuyerStatus.failure,
        buyers: s.buyers,
        query: s.query,
        selectedId: s.selectedId,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}
