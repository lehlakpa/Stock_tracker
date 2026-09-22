import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../models/user_model.dart';
import '../../repositories/staff_repository.dart';
import '../../services/app_error.dart';
import 'staff_event.dart';
import 'staff_state.dart';
export 'staff_event.dart';
export 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository repository;
  StaffBloc(this.repository) : super(const StaffInitial()) {
    on<StaffSubscriptionRequested>((event, emit) async {
      emit(
        state.copyWith(
          status: state.users.isEmpty ? StaffStatus.loading : state.status,
          clearError: true,
        ),
      );
      await emit.forEach<List<UserModel>>(
        repository.watch(),
        onData: (data) => state.copyWith(
          users: List.unmodifiable(data),
          status: state.loading ? StaffStatus.loaded : state.status,
        ),
        onError: (e, _) => state.copyWith(
          status: StaffStatus.failure,
          error: errorMessage(e),
          effect: state.effect + 1,
          operationId: 'subscription',
        ),
      );
    }, transformer: restartable());
    on<StaffMutation>((event, emit) async {
      emit(
        state.copyWith(
          status: StaffStatus.submitting,
          operationId: event.operationId,
          clearError: true,
        ),
      );
      try {
        switch (event) {
          case StaffCreateRequested():
            await repository.create(event.input, 'staff');
          case AdminCreateRequested():
            await repository.create(event.input, 'admin');
          case StaffActivationChanged():
            await repository.setActive(event.user, event.active);
          case StaffUpdateRequested():
            await repository.update(
              event.uid,
              event.name,
              event.phone,
              event.branch,
            );
        }
        emit(
          state.copyWith(
            status: StaffStatus.success,
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: StaffStatus.failure,
            error: errorMessage(e),
            effect: state.effect + 1,
            operationId: event.operationId,
          ),
        );
      }
    }, transformer: droppable());
  }
}
