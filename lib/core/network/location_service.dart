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

  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );

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
