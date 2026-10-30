import 'package:equatable/equatable.dart';
import '../../../../core/models/attendance_record.dart';

export '../../../../core/models/attendance_record.dart';

sealed class AttendanceHistoryState extends Equatable {
  const AttendanceHistoryState();

  @override
  List<Object?> get props => [];
}

class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading();
}

class AttendanceHistoryError extends AttendanceHistoryState {
  const AttendanceHistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  const AttendanceHistoryLoaded({
    required this.month,
    required this.records,
    this.isOffline = false,
    this.updatedAtLabel,
  });

  final DateTime month;
  final List<AttendanceRecordSummary> records;
  final bool isOffline;
  final String? updatedAtLabel;

  @override
  List<Object?> get props => [month, records, isOffline, updatedAtLabel];
}
