import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/leave_repository.dart';
import 'apply_leave_event.dart';
import 'apply_leave_state.dart';

class ApplyLeaveBloc extends Bloc<ApplyLeaveEvent, ApplyLeaveState> {
  ApplyLeaveBloc({LeaveRepository? repository})
    : _repository = repository ?? LeaveRepository(),
      super(ApplyLeaveState(availableDays: (repository ?? LeaveRepository()).availableDays)) {
    on<ApplyLeaveTypeChanged>(_onTypeChanged);
    on<ApplyLeaveStartDateChanged>(_onStartDateChanged);
    on<ApplyLeaveEndDateChanged>(_onEndDateChanged);
    on<ApplyLeaveReasonChanged>(_onReasonChanged);
    on<ApplyLeaveSubmitRequested>(_onSubmitRequested);
    on<ApplyLeaveConnectivityChanged>(_onConnectivityChanged);
  }

  final LeaveRepository _repository;

  void _onTypeChanged(ApplyLeaveTypeChanged event, Emitter<ApplyLeaveState> emit) {
    emit(state.copyWith(type: event.type));
  }

  void _onStartDateChanged(
    ApplyLeaveStartDateChanged event,
    Emitter<ApplyLeaveState> emit,
  ) {
    final warning = _overlapWarning(event.date, state.endDate);
    emit(
      state.copyWith(
        startDate: event.date,
        overlapWarning: warning,
        clearOverlapWarning: warning == null,
      ),
    );
  }

  void _onEndDateChanged(
    ApplyLeaveEndDateChanged event,
    Emitter<ApplyLeaveState> emit,
  ) {
    final warning = _overlapWarning(state.startDate, event.date);
    emit(
      state.copyWith(
        endDate: event.date,
        overlapWarning: warning,
        clearOverlapWarning: warning == null,
      ),
    );
  }

  void _onReasonChanged(ApplyLeaveReasonChanged event, Emitter<ApplyLeaveState> emit) {
    emit(state.copyWith(reason: event.reason));
  }

  void _onConnectivityChanged(
    ApplyLeaveConnectivityChanged event,
    Emitter<ApplyLeaveState> emit,
  ) {
    emit(state.copyWith(isOffline: event.isOffline));
  }

  Future<void> _onSubmitRequested(
    ApplyLeaveSubmitRequested event,
    Emitter<ApplyLeaveState> emit,
  ) async {
    // canSubmit already factors in !isSubmitting, and this check plus the
    // emit below both run synchronously (before the first await), so a
    // repeated tap is rejected even without an explicit event transformer.
    if (!state.canSubmit) return;
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      await _repository.submit(
        type: state.type,
        startDate: state.startDate!,
        endDate: state.endDate!,
        reason: state.reason.trim(),
      );
      emit(state.copyWith(isSubmitting: false, submitted: true));
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: 'Something went wrong submitting this request. Try again.',
        ),
      );
    }
  }

  String? _overlapWarning(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    return _repository.overlapWarning(start: start, end: end);
  }
}
