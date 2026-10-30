import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Like [isOnline], but treats a failure to even determine connectivity
  /// (no platform implementation available, a plugin error, etc.) as
  /// offline rather than letting it propagate as a hard error.
  Future<bool> isOnlineSafe() async {
    try {
      return await isOnline();
    } catch (_) {
      return false;
    }
  }

  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
