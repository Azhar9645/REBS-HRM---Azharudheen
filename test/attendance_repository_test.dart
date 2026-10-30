// Phase 9 required tests for AttendanceRepository, run against a real
// (in-process, isolated) instance of the Phase 2 mock API — see
// lib/mock_server/mock_api_server.dart.

import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:rebs_hrms/core/data/local/attendance_local_data_source.dart';
import 'package:rebs_hrms/core/data/local/local_store.dart';
import 'package:rebs_hrms/core/data/local/pending_events_local_data_source.dart';
import 'package:rebs_hrms/core/data/models/attendance_event_dto.dart';
import 'package:rebs_hrms/core/network/api_client.dart';
import 'package:rebs_hrms/core/network/connectivity_service.dart';
import 'package:rebs_hrms/core/utils/date_only.dart';
import 'package:rebs_hrms/features/attendance/data/attendance_repository.dart';
import 'package:rebs_hrms/mock_server/mock_api_server.dart';

class _FakeOnlineConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value([ConnectivityResult.wifi]);
}

void main() {
  ConnectivityPlatform.instance = _FakeOnlineConnectivityPlatform();

  late MockApiServer server;
  late Directory hiveDir;
  late ApiClient apiClient;
  late AttendanceRepository repository;

  setUp(() async {
    server = MockApiServer();
    // Today has no seeded events, so every test starts from a clean day.
    await server.serve(port: 0);

    hiveDir = await Directory.systemTemp.createTemp('attendance_repo_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox(LocalStore.attendanceBoxName);
    await Hive.openBox(LocalStore.pendingEventsBoxName);
    await Hive.openBox(LocalStore.metaBoxName);

    apiClient = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://localhost:${server.port}')),
    );
    repository = AttendanceRepository(
      apiClient: apiClient,
      attendanceLocal: AttendanceLocalDataSource(),
      pendingEventsLocal: PendingEventsLocalDataSource(),
      connectivity: ConnectivityService(),
    );
  });

  tearDown(() async {
    await server.close();
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  test('check-out without a check-in is rejected by the server', () async {
    await repository.recordAttempt(type: AttendanceEventType.checkOut);
    await repository.syncAll();

    final events = repository.allEvents;
    expect(events, hasLength(1));
    expect(events.single.status, EventSyncStatus.rejected);
    expect(events.single.rejectionReason, contains('before checking in'));
  });

  test(
    'retrying a POST that already landed server-side never creates a duplicate',
    () async {
      final event = await repository.recordAttempt(
        type: AttendanceEventType.checkIn,
      );

      // Simulate the request actually reaching the server once already
      // (e.g. the response was lost to a dropped connection), without the
      // repository knowing — its local copy is still pendingSync.
      await apiClient.postAttendanceEvent(event.toJson());

      // The repository now retries the very same pendingSync event. The
      // server must dedupe by eventId rather than recording it twice.
      await repository.syncAll();

      expect(repository.allEvents.single.status, EventSyncStatus.synced);

      final body = await apiClient.getAttendance();
      final records = body['records'] as List;
      final todaysRecords = records.where(
        (r) => (r as Map)['date'] == dateOnlyString(DateTime.now()),
      );
      expect(todaysRecords, hasLength(1));
    },
  );

  test(
    'pending attendance survives persistence and syncs in original order',
    () async {
      final checkIn = await repository.recordAttempt(
        type: AttendanceEventType.checkIn,
      );
      await Future.delayed(const Duration(milliseconds: 5));
      await repository.recordAttempt(type: AttendanceEventType.checkOut);

      // Simulate an app restart: close and reopen the box, then read it
      // back through a brand-new repository instance.
      await Hive.box(LocalStore.pendingEventsBoxName).close();
      await Hive.openBox(LocalStore.pendingEventsBoxName);
      final restarted = AttendanceRepository(
        apiClient: apiClient,
        attendanceLocal: AttendanceLocalDataSource(),
        pendingEventsLocal: PendingEventsLocalDataSource(),
        connectivity: ConnectivityService(),
      );

      final pendingAfterRestart = restarted.allEvents
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      expect(pendingAfterRestart.map((e) => e.type), [
        AttendanceEventType.checkIn,
        AttendanceEventType.checkOut,
      ]);
      expect(pendingAfterRestart.first.eventId, checkIn.eventId);

      await restarted.syncAll();

      expect(
        restarted.allEvents.every((e) => e.status == EventSyncStatus.synced),
        isTrue,
      );
      final body = await apiClient.getAttendance();
      final records = body['records'] as List;
      final today = records.singleWhere(
        (r) => (r as Map)['date'] == dateOnlyString(DateTime.now()),
      ) as Map;
      expect(today['checkInTime'], isNotNull);
      expect(today['checkOutTime'], isNotNull);
      expect(today['status'], 'synced');
    },
  );
}
