import '../../../core/data/local/auth_local_data_source.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, AuthLocalDataSource? local})
    : _api = apiClient ?? ApiClient(),
      _local = local ?? AuthLocalDataSource();

  final ApiClient _api;
  final AuthLocalDataSource _local;

  bool get isLoggedIn => _local.isLoggedIn;

  Future<void> login({required String employeeId, required String password}) async {
    final result = await _api.login(employeeId, password);
    await _local.saveSession(
      token: result['token'] as String,
      employeeId: employeeId,
    );
  }

  Future<void> logout() => _local.clearSession();
}
