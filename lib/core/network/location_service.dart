import 'package:geolocator/geolocator.dart';

enum LocationAccessResult { granted, denied, deniedForever, serviceDisabled }

class LocationService {
  Future<LocationAccessResult> ensureAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAccessResult.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.deniedForever => LocationAccessResult.deniedForever,
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationAccessResult.granted,
      _ => LocationAccessResult.denied,
    };
  }

  /// How old the device's last known fix may be and still stand in for a
  /// fresh one.
  static const maxLastKnownAge = Duration(minutes: 10);

  /// Returns a fresh fix, or — if none arrives within [timeLimit] — the
  /// device's last known position when it is under [maxLastKnownAge] old.
  /// Offline (e.g. airplane mode) the phone loses Wi-Fi/cell-assisted
  /// positioning, and indoors a GPS-only fix often never arrives.
  Future<({Position position, bool isLastKnown})> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return (position: position, isLastKnown: false);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <= maxLastKnownAge) {
        return (position: last, isLastKnown: true);
      }
      rethrow;
    }
  }

  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) => Geolocator.distanceBetween(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
