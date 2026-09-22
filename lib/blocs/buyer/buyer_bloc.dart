import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../models/user_model.dart';
import '../../models/buyer_model.dart';
import '../../repositories/buyer_repository.dart';
import '../../services/app_error.dart';
import 'buyer_event.dart';
import 'buyer_state.dart';
export 'buyer_event.dart';
export 'buyer_state.dart';

class BuyerBloc extends Bloc<BuyerEvent, BuyerState> {
  final BuyerRepository repository;
  final UserModel user;
  BuyerBloc(this.repository, this.user) : super(const BuyerInitial()) {
    on<BuyersSubscriptionRequested>((event, emit) async {
      emit(
        state.copyWith(
          status: state.buyers.isEmpty ? BuyerStatus.loading : state.status,
          clearError: true,
        ),
      );
      await emit.forEach<List<BuyerModel>>(
        repository.watch(),
        onData: (data) => state.copyWith(
          buyers: List.unmodifiable(data),
          status: state.loading ? BuyerStatus.loaded : state.status,
        ),
        onError: (e, _) => state.copyWith(
          status: BuyerStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
          operationId: 'subscription',
        ),
      );
    }, transformer: restartable());
    on<BuyerSearchChanged>(
      (event, emit) => emit(state.copyWith(query: event.query)),
    );
    on<BuyerDetailsRequested>((event, emit) {
      if (!state.buyers.any((b) => b.id == event.id)) {
        emit(
          state.copyWith(
            status: BuyerStatus.failure,
            error: 'Buyer record no longer exists.',
            effect: state.effect + 1,
            operationId: 'details',
          ),
        );
        return;
      }
      emit(state.copyWith(selectedId: event.id));
    });
    on<BuyerMutation>((event, emit) async {
      emit(
        state.copyWith(
          status: BuyerStatus.submitting,
          operationId: event.operationId,
          clearError: true,
        ),
      );
      try {
        if (event is BuyerAddRequested) {
          await repository.add(event.purchase, user, event.operationId);
        }
        emit(
          state.copyWith(
            status: BuyerStatus.success,
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: BuyerStatus.failure,
            error: errorMessage(e),
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      }
    }, transformer: droppable());
  }
}
