import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/data/local/attendance_local_data_source.dart';
import '../../../core/data/local/employee_local_data_source.dart';
import '../../../core/data/local/leave_local_data_source.dart';
import '../../../core/data/local/local_store.dart';
import '../../../core/data/models/attendance_record_dto.dart';
import '../../../core/data/models/employee_dto.dart';
import '../../../core/data/models/leave_balance_dto.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../attendance/data/attendance_repository.dart';

/// Thrown when there is nothing to show at all: the device has never
/// successfully loaded the dashboard before, and the network isn't
/// reachable right now either.
class DashboardNoDataException implements Exception {
  const DashboardNoDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashboardData {
  const DashboardData({
    required this.employee,
    required this.today,
    required this.leaveBalance,
    required this.recentAttendance,
    required this.pendingSyncCount,
    required this.isOffline,
    this.cachedAtLabel,
  });

  final EmployeeDto employee;

  /// Null when there's no attendance record for today yet (not checked in).
  final AttendanceRecordDto? today;
  final LeaveBalanceDto leaveBalance;

  /// Most recent days first, including today once there's a record for it.
  final List<AttendanceRecordDto> recentAttendance;
  final int pendingSyncCount;
  final bool isOffline;
  final String? cachedAtLabel;
}

/// Offline-first: tries the API first, caches on success, and falls back
/// to the local cache (flagged `isOffline`) if the network is unreachable
/// or the request fails.
class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
    EmployeeLocalDataSource? employeeLocal,
    AttendanceLocalDataSource? attendanceLocal,
    LeaveLocalDataSource? leaveLocal,
    AttendanceRepository? attendanceRepository,
    ConnectivityService? connectivity,
  }) : _api = apiClient ?? ApiClient(),
       _employeeLocal = employeeLocal ?? EmployeeLocalDataSource(),
       _attendanceLocal = attendanceLocal ?? AttendanceLocalDataSource(),
       _leaveLocal = leaveLocal ?? LeaveLocalDataSource(),
       _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
       _connectivity = connectivity ?? ConnectivityService();

  static const _cachedAtKey = 'dashboard_cached_at';

  final ApiClient _api;
  final EmployeeLocalDataSource _employeeLocal;
  final AttendanceLocalDataSource _attendanceLocal;
  final LeaveLocalDataSource _leaveLocal;
  final AttendanceRepository _attendanceRepository;
  final ConnectivityService _connectivity;

  Stream<void> get attendanceEventsChanged => _attendanceRepository.eventsChanged;

  Stream<bool> get onlineChanges => _connectivity.onStatusChange;

  Future<DashboardData> load() async {
    if (await _connectivity.isOnlineSafe()) {
      try {
        return await _loadFromApi();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('DashboardRepository: _loadFromApi failed: $e');
          debugPrint('$st');
        }
        return _loadFromCacheOrThrow();
      }
    }
    return _loadFromCacheOrThrow();
  }

  Future<DashboardData> _loadFromApi() async {
    final results = await Future.wait([
      _api.getEmployee(),
      _api.getAttendance(),
      _api.getLeave(),
    ]);

    final employee = EmployeeDto.fromJson(results[0]);
    final records = (results[1]['records'] as List)
        .map((r) => AttendanceRecordDto.fromJson(r as Map<String, dynamic>))
        .toList();
    final balance = LeaveBalanceDto.fromJson(
      results[2]['balance'] as Map<String, dynamic>,
    );

    await _employeeLocal.save(employee);
    await _attendanceLocal.saveAll(records);
    await _leaveLocal.saveBalance(balance);
    await LocalStore.metaBox.put(_cachedAtKey, DateTime.now().toIso8601String());

    return _buildDashboardData(
      employee: employee,
      records: records,
      balance: balance,
      isOffline: false,
    );
  }

  Future<DashboardData> _loadFromCacheOrThrow() async {
    final employee = _employeeLocal.read();
    final balance = _leaveLocal.readBalance();
    if (employee == null || balance == null) {
      throw const DashboardNoDataException(
        "Couldn't load your dashboard. Nothing is saved on this phone yet, "
        'so we have nothing to show.',
      );
    }

    final cachedAtRaw = LocalStore.metaBox.get(_cachedAtKey) as String?;
    final cachedAtLabel = cachedAtRaw != null
        ? DateFormat('h:mm a').format(DateTime.parse(cachedAtRaw))
        : null;

    return _buildDashboardData(
      employee: employee,
      records: _attendanceLocal.readAll(),
      balance: balance,
      isOffline: true,
      cachedAtLabel: cachedAtLabel,
    );
  }

  DashboardData _buildDashboardData({
    required EmployeeDto employee,
    required List<AttendanceRecordDto> records,
    required LeaveBalanceDto balance,
    required bool isOffline,
    String? cachedAtLabel,
  }) {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    final today = _attendanceRepository.mergedRecordForDay(todayKey);
    final recent = [...records]..removeWhere((r) => r.date == todayKey);
    if (today != null) recent.add(today);
    recent.sort((a, b) => b.date.compareTo(a.date));

    return DashboardData(
      employee: employee,
      today: today,
      leaveBalance: balance,
      recentAttendance: recent.take(5).toList(),
      pendingSyncCount: _attendanceRepository.pendingCount,
      isOffline: isOffline,
      cachedAtLabel: cachedAtLabel,
    );
  }
}
