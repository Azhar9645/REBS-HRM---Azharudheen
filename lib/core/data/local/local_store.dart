import 'package:hive_flutter/hive_flutter.dart';

/// Opens the Hive boxes used for offline caching. Values are stored as
/// plain JSON-able maps (the DTOs' `toJson()`/`fromJson()`), so no Hive
/// type adapters or codegen are needed.
class LocalStore {
  LocalStore._();

  static const employeeBoxName = 'employee_cache';
  static const attendanceBoxName = 'attendance_cache';
  static const pendingEventsBoxName = 'pending_events';
  static const leaveBoxName = 'leave_cache';
  static const metaBoxName = 'app_meta';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(employeeBoxName),
      Hive.openBox(attendanceBoxName),
      Hive.openBox(pendingEventsBoxName),
      Hive.openBox(leaveBoxName),
      Hive.openBox(metaBoxName),
    ]);
    _initialized = true;
  }

  static Box get employeeBox => Hive.box(employeeBoxName);
  static Box get attendanceBox => Hive.box(attendanceBoxName);
  static Box get pendingEventsBox => Hive.box(pendingEventsBoxName);
  static Box get leaveBox => Hive.box(leaveBoxName);
  static Box get metaBox => Hive.box(metaBoxName);
}
