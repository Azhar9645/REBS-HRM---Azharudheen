import '../models/attendance_event_dto.dart';
import 'local_store.dart';

/// Log of this device's own check-in/out attempts, keyed by `eventId`.
/// Doubles as the write-ahead queue (status `pendingSync` until synced)
/// and the Sync screen's activity history — entries are never deleted,
/// just upserted with their latest status, so a synced/rejected entry
/// stays visible as a record of the attempt.
class PendingEventsLocalDataSource {
  List<AttendanceEventDto> readAll() => LocalStore.pendingEventsBox.values
      .map((raw) => AttendanceEventDto.fromJson(Map<String, dynamic>.from(raw as Map)))
      .toList();

  Future<void> upsert(AttendanceEventDto event) =>
      LocalStore.pendingEventsBox.put(event.eventId, event.toJson());

  /// Fires whenever any attempt is added or changes status (e.g. synced).
  Stream<void> get changes => LocalStore.pendingEventsBox.watch().map((_) {});

  int get pendingCount => LocalStore.pendingEventsBox.values
      .where((raw) => (raw as Map)['status'] == EventSyncStatus.pendingSync.name)
      .length;
}
