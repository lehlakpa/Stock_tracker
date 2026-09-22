import 'package:equatable/equatable.dart';

enum DashboardStatus { initial, loading, loaded, submitting, success, failure }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final int totalStock;
  final int remainingStock;
  final int lowStockCount;
  final int electronicsQuantity;
  final int kitchenQuantity;
  final int? totalSales;
  final double? totalIncome;
  final int? totalStaff;
  final int effect;
  final String? operationId;
  final String? error;
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.totalStock = 0,
    this.remainingStock = 0,
    this.lowStockCount = 0,
    this.electronicsQuantity = 0,
    this.kitchenQuantity = 0,
    this.totalSales,
    this.totalIncome,
    this.totalStaff,
    this.effect = 0,
    this.operationId,
    this.error,
  });
  bool get submitting => status == DashboardStatus.submitting;
  bool get loading =>
      status == DashboardStatus.initial || status == DashboardStatus.loading;

  DashboardState copyWith({
    DashboardStatus? status,
    int? totalStock,
    int? remainingStock,
    int? lowStockCount,
    int? electronicsQuantity,
    int? kitchenQuantity,
    int? totalSales,
    double? totalIncome,
    int? totalStaff,
    int? effect,
    String? operationId,
    String? error,
    bool clearError = false,
  }) {
    final next = DashboardState(
      status: status ?? this.status,
      totalStock: totalStock ?? this.totalStock,
      remainingStock: remainingStock ?? this.remainingStock,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      electronicsQuantity: electronicsQuantity ?? this.electronicsQuantity,
      kitchenQuantity: kitchenQuantity ?? this.kitchenQuantity,
      totalSales: totalSales ?? this.totalSales,
      totalIncome: totalIncome ?? this.totalIncome,
      totalStaff: totalStaff ?? this.totalStaff,
      effect: effect ?? this.effect,
      operationId: operationId ?? this.operationId,
      error: error ?? this.error,
    );
    return switch (next.status) {
      DashboardStatus.initial => DashboardInitial.from(
        next,
        clearError: clearError,
      ),
      DashboardStatus.loading => DashboardLoading.from(
        next,
        clearError: clearError,
      ),
      DashboardStatus.loaded => DashboardLoaded.from(
        next,
        clearError: clearError,
      ),
      DashboardStatus.submitting => DashboardSubmitting.from(
        next,
        clearError: clearError,
      ),
      DashboardStatus.success => DashboardSuccess.from(
        next,
        clearError: clearError,
      ),
      DashboardStatus.failure => DashboardFailure.from(
        next,
        clearError: clearError,
      ),
    };
  }

  @override
  List<Object?> get props => [
    status,
    totalStock,
    remainingStock,
    lowStockCount,
    electronicsQuantity,
    kitchenQuantity,
    totalSales,
    totalIncome,
    totalStaff,
    effect,
    operationId,
    error,
  ];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial() : super(status: DashboardStatus.initial);
  DashboardInitial.from(DashboardState s, {bool clearError = false})
    : super(
        status: DashboardStatus.initial,
        totalStock: s.totalStock,
        remainingStock: s.remainingStock,
        lowStockCount: s.lowStockCount,
        electronicsQuantity: s.electronicsQuantity,
        kitchenQuantity: s.kitchenQuantity,
        totalSales: s.totalSales,
        totalIncome: s.totalIncome,
        totalStaff: s.totalStaff,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class DashboardLoading extends DashboardState {
  const DashboardLoading() : super(status: DashboardStatus.loading);
  DashboardLoading.from(DashboardState s, {bool clearError = false})
    : super(
        status: DashboardStatus.loading,
        totalStock: s.totalStock,
        remainingStock: s.remainingStock,
        lowStockCount: s.lowStockCount,
        electronicsQuantity: s.electronicsQuantity,
        kitchenQuantity: s.kitchenQuantity,
        totalSales: s.totalSales,
        totalIncome: s.totalIncome,
        totalStaff: s.totalStaff,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded() : super(status: DashboardStatus.loaded);
  DashboardLoaded.from(DashboardState s, {bool clearError = false})
    : super(
        status: DashboardStatus.loaded,
        totalStock: s.totalStock,
        remainingStock: s.remainingStock,
        lowStockCount: s.lowStockCount,
        electronicsQuantity: s.electronicsQuantity,
        kitchenQuantity: s.kitchenQuantity,
        totalSales: s.totalSales,
        totalIncome: s.totalIncome,
        totalStaff: s.totalStaff,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class DashboardSubmitting extends DashboardState {
  const DashboardSubmitting() : super(status: DashboardStatus.submitting);
  DashboardSubmitting.from(DashboardState s, {bool clearError = false})
    : super(
        status: DashboardStatus.submitting,
        totalStock: s.totalStock,
        remainingStock: s.remainingStock,
        lowStockCount: s.lowStockCount,
        electronicsQuantity: s.electronicsQuantity,
        kitchenQuantity: s.kitchenQuantity,
        totalSales: s.totalSales,
        totalIncome: s.totalIncome,
        totalStaff: s.totalStaff,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class DashboardSuccess extends DashboardState {
  const DashboardSuccess() : super(status: DashboardStatus.success);
  DashboardSuccess.from(DashboardState s, {bool clearError = false})
    : super(
        status: DashboardStatus.success,
        totalStock: s.totalStock,
        remainingStock: s.remainingStock,
        lowStockCount: s.lowStockCount,
        electronicsQuantity: s.electronicsQuantity,
        kitchenQuantity: s.kitchenQuantity,
        totalSales: s.totalSales,
        totalIncome: s.totalIncome,
        totalStaff: s.totalStaff,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}

class DashboardFailure extends DashboardState {
  const DashboardFailure() : super(status: DashboardStatus.failure);
  DashboardFailure.from(DashboardState s, {bool clearError = false})
    : super(
        status: DashboardStatus.failure,
        totalStock: s.totalStock,
        remainingStock: s.remainingStock,
        lowStockCount: s.lowStockCount,
        electronicsQuantity: s.electronicsQuantity,
        kitchenQuantity: s.kitchenQuantity,
        totalSales: s.totalSales,
        totalIncome: s.totalIncome,
        totalStaff: s.totalStaff,
        effect: s.effect,
        operationId: s.operationId,
        error: clearError ? null : s.error,
      );
}
