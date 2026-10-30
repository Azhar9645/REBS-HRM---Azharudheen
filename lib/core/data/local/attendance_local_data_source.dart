import '../models/attendance_record_dto.dart';
import 'local_store.dart';

class AttendanceLocalDataSource {
  List<AttendanceRecordDto> readAll() => LocalStore.attendanceBox.values
      .map((raw) => AttendanceRecordDto.fromJson(Map<String, dynamic>.from(raw as Map)))
      .toList();

  Future<void> saveAll(List<AttendanceRecordDto> records) {
    final entries = {for (final r in records) _dateKey(r.date): r.toJson()};
    return LocalStore.attendanceBox.putAll(entries);
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
