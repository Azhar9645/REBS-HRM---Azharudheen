import '../models/leave_balance_dto.dart';
import '../models/leave_request_dto.dart';
import 'local_store.dart';

class LeaveLocalDataSource {
  static const _balanceKey = 'balance';
  static const _requestsKey = 'requests';

  LeaveBalanceDto? readBalance() {
    final raw = LocalStore.leaveBox.get(_balanceKey);
    if (raw == null) return null;
    return LeaveBalanceDto.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveBalance(LeaveBalanceDto balance) =>
      LocalStore.leaveBox.put(_balanceKey, balance.toJson());

  List<LeaveRequestDto> readRequests() {
    final raw = LocalStore.leaveBox.get(_requestsKey) as List?;
    if (raw == null) return [];
    return raw
        .map((e) => LeaveRequestDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveRequests(List<LeaveRequestDto> requests) => LocalStore.leaveBox
      .put(_requestsKey, requests.map((r) => r.toJson()).toList());
}
