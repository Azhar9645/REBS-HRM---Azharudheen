import 'package:intl/intl.dart';

import '../../../core/data/local/leave_local_data_source.dart';
import '../../../core/data/local/local_store.dart';
import '../../../core/data/models/leave_balance_dto.dart';
import '../../../core/data/models/leave_request_dto.dart';
import '../../../core/models/leave_request.dart' show LeaveType, LeaveRequestStatus;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/date_only.dart';

class LeaveNoDataException implements Exception {
  const LeaveNoDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LeaveData {
  const LeaveData({
    required this.balance,
    required this.requests,
    required this.isOffline,
    this.cachedAtLabel,
  });

  final LeaveBalanceDto balance;
  final List<LeaveRequestDto> requests;
  final bool isOffline;
  final String? cachedAtLabel;
}

/// Offline-first, same pattern as DashboardRepository: tries the API,
/// caches on success, falls back to cache (flagged `isOffline`) otherwise.
class LeaveRepository {
  LeaveRepository({
    ApiClient? apiClient,
    LeaveLocalDataSource? leaveLocal,
    ConnectivityService? connectivity,
  }) : _api = apiClient ?? ApiClient(),
       _leaveLocal = leaveLocal ?? LeaveLocalDataSource(),
       _connectivity = connectivity ?? ConnectivityService();

  static const _cachedAtKey = 'leave_cached_at';

  final ApiClient _api;
  final LeaveLocalDataSource _leaveLocal;
  final ConnectivityService _connectivity;

  /// Cached balance, synchronously — used for local pre-validation (does
  /// the requested range fit the balance) before a submit attempt.
  int get availableDays => _leaveLocal.readBalance()?.availableDays ?? 0;

  Future<LeaveData> load() async {
    if (await _connectivity.isOnlineSafe()) {
      try {
        return await _loadFromApi();
      } catch (_) {
        return _loadFromCacheOrThrow();
      }
    }
    return _loadFromCacheOrThrow();
  }

  Future<LeaveData> _loadFromApi() async {
    final body = await _api.getLeave();
    final balance = LeaveBalanceDto.fromJson(body['balance'] as Map<String, dynamic>);
    final requests = (body['requests'] as List)
        .map((r) => LeaveRequestDto.fromJson(r as Map<String, dynamic>))
        .toList();

    await _leaveLocal.saveBalance(balance);
    await _leaveLocal.saveRequests(requests);
    await LocalStore.metaBox.put(_cachedAtKey, DateTime.now().toIso8601String());

    return LeaveData(balance: balance, requests: requests, isOffline: false);
  }

  Future<LeaveData> _loadFromCacheOrThrow() async {
    final balance = _leaveLocal.readBalance();
    if (balance == null) {
      throw const LeaveNoDataException(
        "Couldn't load your leave details. Nothing is saved on this phone yet.",
      );
    }
    final cachedAtRaw = LocalStore.metaBox.get(_cachedAtKey) as String?;
    return LeaveData(
      balance: balance,
      requests: _leaveLocal.readRequests(),
      isOffline: true,
      cachedAtLabel: cachedAtRaw == null
          ? null
          : DateFormat('h:mm a').format(DateTime.parse(cachedAtRaw)),
    );
  }

  /// Local pre-check mirroring the server's overlap rule, so the Apply
  /// screen can warn before the user submits. Only Pending/Approved
  /// requests block a new range; the submit itself always re-validates
  /// server-side too.
  String? overlapWarning({required DateTime start, required DateTime end}) {
    for (final r in _leaveLocal.readRequests()) {
      if (r.status == LeaveRequestStatus.rejected) continue;
      final overlaps = !end.isBefore(r.startDate) && !start.isAfter(r.endDate);
      if (overlaps) {
        final statusLabel = r.status == LeaveRequestStatus.approved
            ? 'approved'
            : 'pending';
        return 'Overlaps your $statusLabel request for '
            '${_short(r.startDate)} – ${_short(r.endDate)}.';
      }
    }
    return null;
  }

  Future<LeaveRequestDto> submit({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    if (!await _connectivity.isOnlineSafe()) {
      throw const ApiException('Submitting a leave request needs an internet connection.');
    }

    final body = await _api.postLeaveRequest({
      'type': type == LeaveType.sick ? 'sick' : 'casual',
      'startDate': dateOnlyString(startDate),
      'endDate': dateOnlyString(endDate),
      'reason': reason,
    });
    final created = LeaveRequestDto.fromJson(body);

    // Refresh the cache so the Leave tab reflects the new request
    // immediately, without waiting for its own next fetch.
    await _leaveLocal.saveRequests([..._leaveLocal.readRequests(), created]);

    return created;
  }

  static String _short(DateTime d) =>
      '${d.day} ${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][d.month - 1]}';
}
