// Phase 9 required test: overlapping leave dates are rejected, both by
// the local pre-check and by the server itself.

import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:rebs_hrms/core/data/local/leave_local_data_source.dart';
import 'package:rebs_hrms/core/data/local/local_store.dart';
import 'package:rebs_hrms/core/models/leave_request.dart';
import 'package:rebs_hrms/core/network/api_client.dart';
import 'package:rebs_hrms/core/network/api_exception.dart';
import 'package:rebs_hrms/core/network/connectivity_service.dart';
import 'package:rebs_hrms/features/leave/data/leave_repository.dart';
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
  late LeaveRepository repository;

  setUp(() async {
    server = MockApiServer();
    await server.serve(port: 0);
    // The mock server seeds an approved casual request for 2026-10-10..11.

    hiveDir = await Directory.systemTemp.createTemp('leave_repo_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox(LocalStore.leaveBoxName);
    await Hive.openBox(LocalStore.metaBoxName);

    repository = LeaveRepository(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://localhost:${server.port}')),
      ),
      leaveLocal: LeaveLocalDataSource(),
      connectivity: ConnectivityService(),
    );

    await repository.load(); // populate the cache the pre-check reads from
  });

  tearDown(() async {
    await server.close();
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  test('local pre-check flags an overlap with the seeded approved request', () async {
    final warning = repository.overlapWarning(
      start: DateTime(2026, 10, 11),
      end: DateTime(2026, 10, 12),
    );
    expect(warning, isNotNull);
    expect(warning, contains('approved'));
  });

  test('the server also rejects a submission that overlaps an existing request', () async {
    await expectLater(
      repository.submit(
        type: LeaveType.casual,
        startDate: DateTime(2026, 10, 11),
        endDate: DateTime(2026, 10, 12),
        reason: 'Overlapping request to test server-side rejection',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.isValidationError, 'isValidationError', isTrue),
      ),
    );
  });

  test('a non-overlapping submission succeeds and is cached locally', () async {
    final created = await repository.submit(
      type: LeaveType.casual,
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 2),
      reason: 'Does not overlap anything, should go through fine',
    );

    expect(created.status, LeaveRequestStatus.pending);
    final cached = LeaveLocalDataSource().readRequests();
    expect(cached.any((r) => r.id == created.id), isTrue);
  });
}
