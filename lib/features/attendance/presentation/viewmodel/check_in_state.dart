import 'package:equatable/equatable.dart';

enum AttendanceAction { checkIn, checkOut }

sealed class CheckInState extends Equatable {
  const CheckInState();

  @override
  List<Object?> get props => [];
}

class CheckInLocating extends CheckInState {
  const CheckInLocating();
}

class CheckInPermissionDenied extends CheckInState {
  const CheckInPermissionDenied({this.permanently = false});

  final bool permanently;

  @override
  List<Object?> get props => [permanently];
}

class CheckInLocationUnavailable extends CheckInState {
  const CheckInLocationUnavailable();
}

class CheckInReady extends CheckInState {
  const CheckInReady({
    required this.action,
    required this.distanceMeters,
    required this.officeRadiusMeters,
    required this.gpsAccuracyMeters,
    this.lastKnownAt,
    this.excessMetersLastChecked,
  });

  final AttendanceAction action;
  final double distanceMeters;
  final double officeRadiusMeters;
  final double gpsAccuracyMeters;

  /// Set when no fresh fix arrived and the device's last known position
  /// (taken at this time) was used instead.
  final DateTime? lastKnownAt;
  final double? excessMetersLastChecked;

  bool get isWithinRange => distanceMeters <= officeRadiusMeters;

  @override
  List<Object?> get props => [
    action,
    distanceMeters,
    officeRadiusMeters,
    gpsAccuracyMeters,
    lastKnownAt,
    excessMetersLastChecked,
  ];
}

class CheckInSubmitting extends CheckInState {
  const CheckInSubmitting();
}

class CheckInSubmitted extends CheckInState {
  const CheckInSubmitted();
}
