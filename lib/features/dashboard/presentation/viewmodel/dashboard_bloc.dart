import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/attendance_format.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({DashboardRepository? repository})
    : _repository = repository ?? DashboardRepository(),
      super(const DashboardLoading()) {
    on<DashboardStarted>((event, emit) async {
      emit(const DashboardLoading());
      await _load(emit);
    });
    on<DashboardRefreshRequested>((event, emit) async {
      try {
        await _load(emit, keepContentOnError: true);
      } finally {
        event.completer?.complete();
      }
    });

    _subscriptions = [
      _repository.attendanceEventsChanged.listen(
        (_) => add(const DashboardRefreshRequested()),
      ),
      // Only reload when the screen's offline/online look is now out of date,
      // not on every connectivity callback (Android fires one on startup).
      _repository.onlineChanges.listen((online) {
        final current = state;
        final stale = switch (current) {
          DashboardLoaded() => current.isOffline == online,
          DashboardError() => online,
          DashboardLoading() => false,
        };
        if (stale) add(const DashboardRefreshRequested());
      }),
    ];
  }

  final DashboardRepository _repository;
  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }

  Future<void> _load(
    Emitter<DashboardState> emit, {
    bool keepContentOnError = false,
  }) async {
    try {
      final data = await _repository.load();
      emit(_toLoaded(data));
    } on DashboardNoDataException catch (e) {
      if (kDebugMode) debugPrint('DashboardBloc: $e');
      if (keepContentOnError && state is DashboardLoaded) return;
      emit(DashboardError(e.message));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('DashboardBloc: unexpected error loading dashboard: $e');
        debugPrint('$st');
      }
      if (keepContentOnError && state is DashboardLoaded) return;
      emit(
        const DashboardError(
          'Something went wrong loading your dashboard. Pull to refresh to try again.',
        ),
      );
    }
  }

  DashboardLoaded _toLoaded(DashboardData data) {
    final today = data.today;
    final AttendanceDayStatus status;
    final Duration elapsed;
    if (today == null) {
      status = AttendanceDayStatus.notCheckedIn;
      elapsed = Duration.zero;
    } else if (today.checkOutTime != null) {
      status = AttendanceDayStatus.checkedOut;
      elapsed = today.checkOutTime!.difference(today.checkInTime!);
    } else {
      status = AttendanceDayStatus.checkedIn;
      elapsed = DateTime.now().difference(today.checkInTime!);
    }

    return DashboardLoaded(
      employee: EmployeeSummary(
        name: data.employee.name,
        employeeId: data.employee.employeeId,
        department: data.employee.department,
      ),
      today: TodayAttendance(
        status: status,
        date: DateTime.now(),
        checkInTime: today?.checkInTime,
        checkOutTime: today?.checkOutTime,
        elapsed: elapsed,
        officeRadiusMeters: data.employee.office.radiusMeters,
      ),
      leaveBalance: LeaveBalanceSummary(
        availableDays: data.leaveBalance.availableDays,
        totalDays: data.leaveBalance.totalDays,
        savedAtLabel: data.isOffline && data.cachedAtLabel != null
            ? 'Saved ${data.cachedAtLabel}'
            : null,
      ),
      recentAttendance: [
        for (final record in data.recentAttendance)
          AttendanceRecordSummary(
            date: record.date,
            checkInTime: record.checkInTime,
            checkOutTime: record.checkOutTime,
            workedLabel: workedLabelFor(record.checkInTime, record.checkOutTime),
            status: record.status,
            note: record.note,
          ),
      ],
      pendingSyncCount: data.pendingSyncCount,
      isOffline: data.isOffline,
      offlineSavedAtLabel: data.cachedAtLabel,
    );
  }
}
