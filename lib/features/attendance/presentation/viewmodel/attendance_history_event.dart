import 'package:equatable/equatable.dart';

sealed class AttendanceHistoryEvent extends Equatable {
  const AttendanceHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial load. From Phase 7 onward this fetches/caches
/// `/attendance?month=YYYY-MM` via AttendanceRepository.
class AttendanceHistoryStarted extends AttendanceHistoryEvent {
  const AttendanceHistoryStarted();
}

/// Reloads the month on screen without showing the loading state, e.g.
/// after a check-in is recorded or synced.
class AttendanceHistoryRefreshRequested extends AttendanceHistoryEvent {
  const AttendanceHistoryRefreshRequested();
}

class AttendanceHistoryNextMonthRequested extends AttendanceHistoryEvent {
  const AttendanceHistoryNextMonthRequested();
}

class AttendanceHistoryPreviousMonthRequested extends AttendanceHistoryEvent {
  const AttendanceHistoryPreviousMonthRequested();
}
