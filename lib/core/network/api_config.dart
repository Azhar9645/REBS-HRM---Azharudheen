import 'dart:io';

/// Base URL for the Phase 2 mock API (see `bin/mock_server.dart`).
///
/// Override at build/run time with `--dart-define=API_BASE_URL=http://...`
/// — needed for a physical device, which can't reach `10.0.2.2` or
/// `localhost` on the host machine.
class ApiConfig {
  ApiConfig._();

  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }
}
