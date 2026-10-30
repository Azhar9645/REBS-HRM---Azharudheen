import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/attendance_record_dto.dart';
import '../../../../core/utils/attendance_format.dart';
import '../../data/attendance_repository.dart';
import 'attendance_history_event.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryBloc
    extends Bloc<AttendanceHistoryEvent, AttendanceHistoryState> {
  AttendanceHistoryBloc({AttendanceRepository? repository})
    : _repository = repository ?? AttendanceRepository(),
      super(const AttendanceHistoryLoading()) {
    on<AttendanceHistoryStarted>(_onStarted);
    on<AttendanceHistoryNextMonthRequested>(_onNextMonthRequested);
    on<AttendanceHistoryPreviousMonthRequested>(_onPreviousMonthRequested);
    on<AttendanceHistoryRefreshRequested>((event, emit) async {
      final current = state;
      if (current is AttendanceHistoryLoaded) {
        await _load(current.month, emit, quiet: true);
      }
    });
    _eventsSubscription = _repository.eventsChanged.listen(
      (_) => add(const AttendanceHistoryRefreshRequested()),
    );
  }

  final AttendanceRepository _repository;
  late final StreamSubscription<void> _eventsSubscription;

  @override
  Future<void> close() async {
    await _eventsSubscription.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    AttendanceHistoryStarted event,
    Emitter<AttendanceHistoryState> emit,
  ) {
    final now = DateTime.now();
    return _load(DateTime(now.year, now.month), emit);
  }

  Future<void> _onNextMonthRequested(
    AttendanceHistoryNextMonthRequested event,
    Emitter<AttendanceHistoryState> emit,
  ) async {
    final current = state;
    if (current is AttendanceHistoryLoaded) {
      await _load(DateTime(current.month.year, current.month.month + 1), emit);
    }
  }

  Future<void> _onPreviousMonthRequested(
    AttendanceHistoryPreviousMonthRequested event,
    Emitter<AttendanceHistoryState> emit,
  ) async {
    final current = state;
    if (current is AttendanceHistoryLoaded) {
      await _load(DateTime(current.month.year, current.month.month - 1), emit);
    }
  }

  Future<void> _load(
    DateTime month,
    Emitter<AttendanceHistoryState> emit, {
    bool quiet = false,
  }) async {
    if (!quiet) emit(const AttendanceHistoryLoading());
    try {
      final data = await _repository.loadMonth(month);
      emit(
        AttendanceHistoryLoaded(
          month: data.month,
          records: [for (final r in data.records) _toSummary(r)],
          isOffline: data.isOffline,
          updatedAtLabel: data.cachedAtLabel,
        ),
      );
    } catch (_) {
      if (quiet) return;
      emit(
        const AttendanceHistoryError(
          "Couldn't load your attendance history. Pull down to try again.",
        ),
      );
    }
  }

  AttendanceRecordSummary _toSummary(AttendanceRecordDto r) => AttendanceRecordSummary(
    date: r.date,
    checkInTime: r.checkInTime,
    checkOutTime: r.checkOutTime,
    workedLabel: workedLabelFor(r.checkInTime, r.checkOutTime),
    status: r.status,
    note: r.note,
  );
}
