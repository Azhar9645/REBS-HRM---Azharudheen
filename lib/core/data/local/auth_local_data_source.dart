import 'local_store.dart';

/// Tracks whether the current device has an active logged-in session.
/// Session state is intentionally simple (no real token refresh/expiry)
/// since this backs a mock API — see `bin/mock_server.dart`.
class AuthLocalDataSource {
  static const _tokenKey = 'auth_token';
  static const _employeeIdKey = 'auth_employee_id';

  bool get isLoggedIn => LocalStore.metaBox.get(_tokenKey) != null;

  String? get employeeId => LocalStore.metaBox.get(_employeeIdKey) as String?;

  Future<void> saveSession({required String token, required String employeeId}) =>
      LocalStore.metaBox.putAll({_tokenKey: token, _employeeIdKey: employeeId});

  Future<void> clearSession() =>
      LocalStore.metaBox.deleteAll([_tokenKey, _employeeIdKey]);
}
