import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../models/user_model.dart';
import '../../repositories/dashboard_repository.dart';
import '../../services/app_error.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
export 'dashboard_event.dart';
export 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;
  final UserModel user;
  DashboardBloc(this.repository, this.user) : super(const DashboardInitial()) {
    on<DashboardSubscriptionRequested>((event, emit) async {
      emit(state.copyWith(status: DashboardStatus.loading, clearError: true));
      await emit.forEach<DashboardInput>(
        repository.watch(user),
        onData: (input) => _calculate(
          input,
          state.loading ? DashboardStatus.loaded : state.status,
        ),
        onError: (e, _) => state.copyWith(
          status: DashboardStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
          operationId: 'subscription',
        ),
      );
    }, transformer: restartable());
    on<DashboardRefreshRequested>((event, emit) async {
      emit(
        state.copyWith(
          status: DashboardStatus.submitting,
          operationId: event.operationId,
          clearError: true,
        ),
      );
      try {
        final input = await repository.watch(user).first;
        emit(
          _calculate(
            input,
            DashboardStatus.success,
          ).copyWith(effect: state.effect + 1, operationId: event.operationId),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: DashboardStatus.failure,
            error: errorMessage(e),
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      }
    }, transformer: droppable());
  }
  DashboardState _calculate(DashboardInput input, DashboardStatus status) =>
      state.copyWith(
        status: status,
        totalStock: input.products.fold<int>(0, (s, p) => s + p.addedQuantity),
        remainingStock: input.products.fold<int>(
          0,
          (s, p) => s + p.remainingQuantity,
        ),
        lowStockCount: input.products.where((p) => p.isLow).length,
        electronicsQuantity: input.products
            .where((p) => p.category.toLowerCase().contains('electronic'))
            .fold<int>(0, (s, p) => s + p.remainingQuantity),
        kitchenQuantity: input.products
            .where((p) => p.category.toLowerCase().contains('kitchen'))
            .fold<int>(0, (s, p) => s + p.remainingQuantity),
        totalSales: user.isAdmin ? input.sales : null,
        totalIncome: user.isAdmin ? input.income : null,
        totalStaff: user.isAdmin ? input.staffCount : null,
      );
}
