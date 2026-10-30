import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/leave_request_dto.dart';
import '../../data/leave_repository.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  LeaveBloc({LeaveRepository? repository})
    : _repository = repository ?? LeaveRepository(),
      super(const LeaveLoading()) {
    on<LeaveStarted>(_onStarted);
  }

  final LeaveRepository _repository;

  Future<void> _onStarted(LeaveStarted event, Emitter<LeaveState> emit) async {
    emit(const LeaveLoading());
    try {
      final data = await _repository.load();
      emit(
        LeaveLoaded(
          availableDays: data.balance.availableDays,
          requests: [for (final r in data.requests) _toSummary(r)],
          isOffline: data.isOffline,
          updatedAtLabel: data.cachedAtLabel,
        ),
      );
    } on LeaveNoDataException catch (e) {
      emit(LeaveError(e.message));
    } catch (_) {
      emit(const LeaveError('Something went wrong loading your leave details.'));
    }
  }

  LeaveRequestSummary _toSummary(LeaveRequestDto r) => LeaveRequestSummary(
    type: r.type,
    startDate: r.startDate,
    endDate: r.endDate,
    days: r.days,
    reason: r.reason,
    status: r.status,
    rejectionReason: r.rejectionReason,
  );
}
