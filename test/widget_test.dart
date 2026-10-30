// Smoke test: app boots, dashboard reads from a pre-seeded local cache
// (no live mock server needed), and every screen is reachable
// through real navigation without throwing.
//
// Feature tests (idempotency, offline persistence, leave overlap
// validation, etc.) live in the other test files.

import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:hive/hive.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:rebs_hrms/core/data/local/attendance_local_data_source.dart';
import 'package:rebs_hrms/core/data/local/auth_local_data_source.dart';
import 'package:rebs_hrms/core/data/local/employee_local_data_source.dart';
import 'package:rebs_hrms/core/data/local/leave_local_data_source.dart';
import 'package:rebs_hrms/core/data/local/local_store.dart';
import 'package:rebs_hrms/core/data/models/attendance_record_dto.dart';
import 'package:rebs_hrms/core/data/models/employee_dto.dart';
import 'package:rebs_hrms/core/data/models/leave_balance_dto.dart';
import 'package:rebs_hrms/core/models/attendance_record.dart';
import 'package:rebs_hrms/main.dart';

/// connectivity_plus's platform channel never resolves under `flutter test`
/// (there's no desktop embedder to answer it), so this swaps in the
/// plugin's own test-support fake platform rather than hanging forever.
class _FakeOfflineConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.none,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value([ConnectivityResult.none]);
}

/// Same deal as connectivity_plus above: no desktop embedder to answer
/// geolocator's platform channel under `flutter test`, so this fakes a
/// fixed position ~312 m from the seeded office (12.9716, 77.5946; 200 m
/// radius) — outside range, matching this file's existing expectations.
class _FakeGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      Position(
        latitude: 12.9744036,
        longitude: 77.5946,
        timestamp: DateTime.now(),
        accuracy: 12,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    ConnectivityPlatform.instance = _FakeOfflineConnectivityPlatform();
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform();

    hiveDir = await Directory.systemTemp.createTemp('rebs_hrms_test_hive_');
    Hive.init(hiveDir.path);
    await Hive.openBox(LocalStore.employeeBoxName);
    await Hive.openBox(LocalStore.attendanceBoxName);
    await Hive.openBox(LocalStore.pendingEventsBoxName);
    await Hive.openBox(LocalStore.leaveBoxName);
    await Hive.openBox(LocalStore.metaBoxName);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await EmployeeLocalDataSource().save(
      const EmployeeDto(
        employeeId: 'EMP-0142',
        name: 'Anjali Menon',
        department: 'Operations',
        office: OfficeConfigDto(
          latitude: 12.9716,
          longitude: 77.5946,
          radiusMeters: 200,
        ),
      ),
    );
    await AttendanceLocalDataSource().saveAll([
      AttendanceRecordDto(
        date: today,
        checkInTime: DateTime(today.year, today.month, today.day, 9, 4),
        status: RecordSyncStatus.synced,
      ),
    ]);
    await LeaveLocalDataSource().saveBalance(
      const LeaveBalanceDto(availableDays: 9, totalDays: 12),
    );
    await AuthLocalDataSource().saveSession(
      token: 'test-session-token',
      employeeId: 'EMP-0142',
    );
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  testWidgets('dashboard loads and shows the cached employee', (tester) async {
    await tester.pumpWidget(const RebsHrmsApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('Anjali Menon'), findsOneWidget);
    expect(find.text('Check out'), findsOneWidget);
  });

  testWidgets('bottom nav reaches Attendance, Leave and Sync tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const RebsHrmsApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.text('October 2026'), findsOneWidget);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.text('Apply for leave'), findsWidgets);

    await tester.tap(find.text('Sync'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.text('Sync now'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.text('Anjali Menon'), findsOneWidget);
  });

  testWidgets('check-in screen is reachable and shows the geofence state', (
    tester,
  ) async {
    await tester.pumpWidget(const RebsHrmsApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.text('Check out'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('312 m'), findsOneWidget);
    expect(find.text("You're outside the permitted area"), findsOneWidget);
  });

  testWidgets('apply-leave screen is reachable from the Leave tab', (
    tester,
  ) async {
    await tester.pumpWidget(const RebsHrmsApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.text('Apply for leave'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('Available balance'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Submit request'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Submit request'), findsOneWidget);
  });
}
