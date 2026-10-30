import '../../models/attendance_record.dart' show RecordSyncStatus;
import '../../utils/date_only.dart';

RecordSyncStatus parseRecordSyncStatus(String? value) => switch (value) {
  'pending' => RecordSyncStatus.pending,
  'rejected' => RecordSyncStatus.rejected,
  _ => RecordSyncStatus.synced,
};

String recordSyncStatusToJson(RecordSyncStatus status) => switch (status) {
  RecordSyncStatus.synced => 'synced',
  RecordSyncStatus.pending => 'pending',
  RecordSyncStatus.rejected => 'rejected',
};

/// One calendar day's attendance, as returned by `GET /attendance` and
/// cached locally for offline reading.
class AttendanceRecordDto {
  const AttendanceRecordDto({
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.note,
  });

  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final RecordSyncStatus status;
  final String? note;

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordDto(
        date: DateTime.parse(json['date'] as String),
        checkInTime: json['checkInTime'] != null
            ? DateTime.parse(json['checkInTime'] as String)
            : null,
        checkOutTime: json['checkOutTime'] != null
            ? DateTime.parse(json['checkOutTime'] as String)
            : null,
        status: parseRecordSyncStatus(json['status'] as String?),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'date': dateOnlyString(date),
    'checkInTime': checkInTime?.toIso8601String(),
    'checkOutTime': checkOutTime?.toIso8601String(),
    'status': recordSyncStatusToJson(status),
    'note': note,
  };
}
