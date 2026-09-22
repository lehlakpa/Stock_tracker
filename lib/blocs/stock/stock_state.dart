import 'package:equatable/equatable.dart';
import '../../models/stock_model.dart';

enum StockStatus { initial, loading, loaded, submitting, success, failure }

class StockState extends Equatable {
  final StockStatus status;
  final List<StockModel> products;
  final List<StockUpdate> history;
  final String query;
  final String category;
  final bool lowOnly;
  final int effect;
  final String? operationId;
  final String? error;
  const StockState({
    this.status = StockStatus.initial,
    this.products = const [],
    this.history = const [],
    this.query = '',
    this.category = 'All',
    this.lowOnly = false,
    this.effect = 0,
    this.operationId,
    this.error,
  });
  bool get submitting => status == StockStatus.submitting;
  bool get loading =>
      status == StockStatus.initial || status == StockStatus.loading;
  List<StockModel> get filtered => products
      .where(
        (p) =>
            (p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.sku.toLowerCase().contains(query.toLowerCase())) &&
            (category == 'All' || p.category == category) &&
            (!lowOnly || p.isLow),
      )
      .toList();
  StockState copyWith({
    StockStatus? status,
    List<StockModel>? products,
    List<StockUpdate>? history,
    String? query,
    String? category,
    bool? lowOnly,
    int? effect,
    String? operationId,
    String? error,
    bool clearError = false,
  }) {
    final next = StockState(
      status: status ?? this.status,
      products: products ?? this.products,
      history: history ?? this.history,
      query: query ?? this.query,
      category: category ?? this.category,
      lowOnly: lowOnly ?? this.lowOnly,
      effect: effect ?? this.effect,
      operationId: operationId ?? this.operationId,
      error: error ?? this.error,
    );
    return switch (next.status) {
      StockStatus.initial => StockInitial.from(next, clearError: clearError),
      StockStatus.loading => StockLoading.from(next, clearError: clearError),
      StockStatus.loaded => StockLoaded.from(next, clearError: clearError),
      StockStatus.submitting => StockSubmitting.from(
        next,
        clearError: clearError,
      ),
      StockStatus.success => StockSuccess.from(next, clearError: clearError),
      StockStatus.failure => StockFailure.from(next, clearError: clearError),
    };
  }

  @override
  List<Object?> get props => [
    status,
    products,
    history,
    query,
    category,
    lowOnly,
    effect,
    operationId,
    error,
  ];
}

class StockInitial extends StockState {
  const StockInitial() : super(status: StockStatus.initial);
  StockInitial.from(StockState s, {bool clearError = false})
    : super(
        status: StockStatus.initial,
        products: s.products,
        history: s.history,
        query: s.query,
        category: s.category,
        lowOnly: s.lowOnly,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StockLoading extends StockState {
  const StockLoading() : super(status: StockStatus.loading);
  StockLoading.from(StockState s, {bool clearError = false})
    : super(
        status: StockStatus.loading,
        products: s.products,
        history: s.history,
        query: s.query,
        category: s.category,
        lowOnly: s.lowOnly,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StockLoaded extends StockState {
  const StockLoaded() : super(status: StockStatus.loaded);
  StockLoaded.from(StockState s, {bool clearError = false})
    : super(
        status: StockStatus.loaded,
        products: s.products,
        history: s.history,
        query: s.query,
        category: s.category,
        lowOnly: s.lowOnly,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StockSubmitting extends StockState {
  const StockSubmitting() : super(status: StockStatus.submitting);
  StockSubmitting.from(StockState s, {bool clearError = false})
    : super(
        status: StockStatus.submitting,
        products: s.products,
        history: s.history,
        query: s.query,
        category: s.category,
        lowOnly: s.lowOnly,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StockSuccess extends StockState {
  const StockSuccess() : super(status: StockStatus.success);
  StockSuccess.from(StockState s, {bool clearError = false})
    : super(
        status: StockStatus.success,
        products: s.products,
        history: s.history,
        query: s.query,
        category: s.category,
        lowOnly: s.lowOnly,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class StockFailure extends StockState {
  const StockFailure() : super(status: StockStatus.failure);
  StockFailure.from(StockState s, {bool clearError = false})
    : super(
        status: StockStatus.failure,
        products: s.products,
        history: s.history,
        query: s.query,
        category: s.category,
        lowOnly: s.lowOnly,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}
