import 'package:equatable/equatable.dart';

sealed class CheckInEvent extends Equatable {
  const CheckInEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial location fix via geolocator.
class CheckInStarted extends CheckInEvent {
  const CheckInStarted();
}

class LocationRefreshRequested extends CheckInEvent {
  const LocationRefreshRequested();
}

class CheckInSubmitRequested extends CheckInEvent {
  const CheckInSubmitRequested();
}
