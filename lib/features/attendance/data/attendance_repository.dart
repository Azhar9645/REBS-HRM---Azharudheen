import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/local/attendance_local_data_source.dart';
import '../../../core/data/local/local_store.dart';
import '../../../core/data/local/pending_events_local_data_source.dart';
import '../../../core/data/models/attendance_event_dto.dart';
import '../../../core/data/models/attendance_record_dto.dart';
import '../../../core/models/attendance_record.dart' show RecordSyncStatus;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/connectivity_service.dart';

class MonthAttendance {
  const MonthAttendance({
    required this.month,
    required this.records,
    required this.isOffline,
    this.cachedAtLabel,
  });

  final DateTime month;
  final List<AttendanceRecordDto> records;
  final bool isOffline;
  final String? cachedAtLabel;
}

/// Shared attendance data layer: the write-ahead log for check-in/out
/// attempts (Phase 5), the sync engine that drains it against the server
/// (Phase 6), and month/day reads that merge server-confirmed records with
/// any of this device's own not-yet-synced or rejected attempts (Phase 7).
class AttendanceRepository {
  AttendanceRepository({
    ApiClient? apiClient,
    AttendanceLocalDataSource? attendanceLocal,
    PendingEventsLocalDataSource? pendingEventsLocal,
    ConnectivityService? connectivity,
    Uuid? uuid,
  }) : _api = apiClient ?? ApiClient(),
       _attendanceLocal = attendanceLocal ?? AttendanceLocalDataSource(),
       _pendingEventsLocal = pendingEventsLocal ?? PendingEventsLocalDataSource(),
       _connectivity = connectivity ?? ConnectivityService(),
       _uuid = uuid ?? const Uuid();

  final ApiClient _api;
  final AttendanceLocalDataSource _attendanceLocal;
  final PendingEventsLocalDataSource _pendingEventsLocal;
  final ConnectivityService _connectivity;
  final Uuid _uuid;

  int get pendingCount => _pendingEventsLocal.pendingCount;

  /// Fires when a check-in/out is recorded or its sync status changes.
  Stream<void> get eventsChanged => _pendingEventsLocal.changes;

  /// This device's full check-in/out attempt history (any status), for
  /// the Sync screen's activity list.
  List<AttendanceEventDto> get allEvents => _pendingEventsLocal.readAll();

  // --- Phase 5: write-ahead log ---------------------------------------

  /// Persists the attempt locally *before* any network call, so it
  /// survives the app being killed or losing connectivity mid-submit.
  Future<AttendanceEventDto> recordAttempt({
    required AttendanceEventType type,
    double? latitude,
    double? longitude,
  }) async {
    final event = AttendanceEventDto(
      eventId: _uuid.v4(),
      type: type,
      timestamp: DateTime.now(),
      status: EventSyncStatus.pendingSync,
      latitude: latitude,
      longitude: longitude,
    );
    await _pendingEventsLocal.upsert(event);
    return event;
  }

  /// The server-confirmed record for [day] (if cached), overlaid with any
  /// of this device's own pending/rejected attempts for that day — so a
  /// just-submitted check-in shows up immediately, before the next sync +
  /// refetch round-trip.
  AttendanceRecordDto? mergedRecordForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    AttendanceRecordDto? serverRecord;
    for (final record in _attendanceLocal.readAll()) {
      if (record.date == dayKey) {
        serverRecord = record;
        break;
      }
    }

    final localEvents =
        _pendingEventsLocal.readAll()
            .where((e) => _dateOnly(e.timestamp) == dayKey)
            .where((e) => e.status != EventSyncStatus.synced)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (localEvents.isEmpty) return serverRecord;

    var checkInTime = serverRecord?.checkInTime;
    var checkOutTime = serverRecord?.checkOutTime;
    var status = serverRecord?.status ?? RecordSyncStatus.synced;
    var note = serverRecord?.note;

    for (final event in localEvents) {
      if (event.type == AttendanceEventType.checkIn) {
        checkInTime = event.timestamp;
      } else {
        checkOutTime = event.timestamp;
      }
      if (event.status == EventSyncStatus.rejected) {
        status = RecordSyncStatus.rejected;
        note = event.rejectionReason;
      } else if (status != RecordSyncStatus.rejected) {
        status = RecordSyncStatus.pending;
      }
    }

    return AttendanceRecordDto(
      date: dayKey,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      status: status,
      note: note,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // --- Phase 6: sync engine --------------------------------------------

  /// Drains the pending queue against the server, in the original order
  /// the attempts were made, using each event's `eventId` as an
  /// idempotency key so a retry can never create a duplicate record.
  Future<void> syncAll() async {
    if (!await _connectivity.isOnlineSafe()) return;

    final pending =
        _pendingEventsLocal.readAll()
            .where((e) => e.status == EventSyncStatus.pendingSync)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final event in pending) {
      final keepGoing = await _syncOne(event);
      if (!keepGoing) break;
    }
  }

  Future<bool> _syncOne(AttendanceEventDto event) async {
    try {
      await _api.postAttendanceEvent(event.toJson());
      await _pendingEventsLocal.upsert(event.copyWith(status: EventSyncStatus.synced));
      return true;
    } on ApiException catch (e) {
      if (e.isConflict) {
        final data = e.data;
        if (data != null && data['eventId'] == event.eventId) {
          // Idempotent replay: the server already has this exact event.
          await _pendingEventsLocal.upsert(event.copyWith(status: EventSyncStatus.synced));
        } else {
          await _pendingEventsLocal.upsert(
            event.copyWith(
              status: EventSyncStatus.rejected,
              rejectionReason: data?['error'] as String? ?? e.message,
            ),
          );
        }
        return true;
      }
      if (e.isValidationError) {
        await _pendingEventsLocal.upsert(
          event.copyWith(
            status: EventSyncStatus.rejected,
            rejectionReason: e.data?['error'] as String? ?? e.message,
          ),
        );
        return true;
      }
      // Server error / timeout / connection error: the POST may or may not
      // have actually landed, so check before deciding whether to retry.
      return _recheckAfterFailure(event);
    }
  }

  Future<bool> _recheckAfterFailure(AttendanceEventDto event) async {
    try {
      final body = await _api.getAttendanceEvent(event.eventId);
      final status = body['status'] as String?;
      if (status == 'synced') {
        await _pendingEventsLocal.upsert(event.copyWith(status: EventSyncStatus.synced));
      } else if (status == 'rejected') {
        await _pendingEventsLocal.upsert(
          event.copyWith(
            status: EventSyncStatus.rejected,
            rejectionReason: body['rejectionReason'] as String?,
          ),
        );
      }
      // Any definitive answer (including 404 below) means the server is
      // reachable, so keep syncing the rest of the queue.
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return true; // never reached the server; leave pending
      return false; // still unreachable; stop this run, the rest would fail too
    } catch (_) {
      return false;
    }
  }

  // --- Phase 7: history -------------------------------------------------

  Future<MonthAttendance> loadMonth(DateTime month) async {
    final monthKey = _monthKey(month);
    if (await _connectivity.isOnlineSafe()) {
      try {
        final body = await _api.getAttendance(month: monthKey);
        final records = (body['records'] as List)
            .map((r) => AttendanceRecordDto.fromJson(r as Map<String, dynamic>))
            .toList();
        await _attendanceLocal.saveAll(records);
        await LocalStore.metaBox.put(
          'attendance_cached_at_$monthKey',
          DateTime.now().toIso8601String(),
        );
        return _buildMonth(month, records, isOffline: false);
      } catch (_) {
        return _buildMonthFromCache(month);
      }
    }
    return _buildMonthFromCache(month);
  }

  MonthAttendance _buildMonthFromCache(DateTime month) {
    final monthKey = _monthKey(month);
    final records = _attendanceLocal.readAll()
        .where((r) => r.date.year == month.year && r.date.month == month.month)
        .toList();
    final cachedAtRaw = LocalStore.metaBox.get('attendance_cached_at_$monthKey') as String?;
    return _buildMonth(
      month,
      records,
      isOffline: true,
      cachedAtLabel: cachedAtRaw == null
          ? null
          : DateFormat('h:mm a').format(DateTime.parse(cachedAtRaw)),
    );
  }

  MonthAttendance _buildMonth(
    DateTime month,
    List<AttendanceRecordDto> records,
    {required bool isOffline, String? cachedAtLabel}
  ) {
    final merged = [...records];
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      final todayKey = DateTime(now.year, now.month, now.day);
      final mergedToday = mergedRecordForDay(todayKey);
      merged.removeWhere((r) => r.date == todayKey);
      if (mergedToday != null) merged.add(mergedToday);
    }
    merged.sort((a, b) => b.date.compareTo(a.date));
    return MonthAttendance(
      month: month,
      records: merged,
      isOffline: isOffline,
      cachedAtLabel: cachedAtLabel,
    );
  }

  static String _monthKey(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
}
