import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../models/user_model.dart';
import '../../repositories/stock_repository.dart';
import '../../services/app_error.dart';
import 'stock_event.dart';
import 'stock_state.dart';
export 'stock_event.dart';
export 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockRepository repository;
  final UserModel user;
  StockBloc(this.repository, this.user) : super(const StockInitial()) {
    on<StockSubscriptionRequested>((event, emit) async {
      emit(
        state.copyWith(
          status: state.products.isEmpty ? StockStatus.loading : state.status,
          clearError: true,
        ),
      );
      await emit.forEach<StockSnapshot>(
        repository.watch(user),
        onData: (data) => state.copyWith(
          products: List.unmodifiable(data.products),
          history: List.unmodifiable(data.history),
          status: state.loading ? StockStatus.loaded : state.status,
        ),
        onError: (e, _) => state.copyWith(
          status: StockStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
          operationId: 'subscription',
        ),
      );
    }, transformer: restartable());
    on<StockSearchChanged>(
      (event, emit) => emit(state.copyWith(query: event.query)),
    );
    on<StockCategoryChanged>(
      (event, emit) => emit(
        state.copyWith(category: event.category, lowOnly: event.lowOnly),
      ),
    );
    on<StockMutation>((event, emit) async {
      emit(
        state.copyWith(
          status: StockStatus.submitting,
          operationId: event.operationId,
          clearError: true,
        ),
      );
      try {
        switch (event) {
          case StockAddRequested():
            await repository.addProduct(event.fields, event.quantity, user);
          case StockUpdateRequested():
            await repository.updateQuantity(
              event.productId,
              event.delta,
              event.note,
              user,
              details: event.details,
            );
          case StockSaleRequested():
            await repository.recordPurchase(
              event.purchase.toMap(),
              event.purchase.productId,
              event.purchase.quantity,
              user,
              operationId: event.operationId,
            );
        }
        emit(
          state.copyWith(
            status: StockStatus.success,
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: StockStatus.failure,
            error: errorMessage(e),
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      }
    }, transformer: droppable());
  }
}
