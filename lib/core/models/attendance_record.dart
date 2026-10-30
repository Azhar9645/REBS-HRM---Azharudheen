import 'package:equatable/equatable.dart';

enum RecordSyncStatus { synced, pending, rejected }

/// Shared shape for a single day's attendance row, used by both the
/// dashboard's "recent attendance" list and the full attendance history
/// screen.
class AttendanceRecordSummary extends Equatable {
  const AttendanceRecordSummary({
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.workedLabel,
    required this.status,
    this.note,
  });

  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? workedLabel;
  final RecordSyncStatus status;
  final String? note;

  @override
  List<Object?> get props => [
    date,
    checkInTime,
    checkOutTime,
    workedLabel,
    status,
    note,
  ];
}
