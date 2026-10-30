import 'package:equatable/equatable.dart';

sealed class LeaveEvent extends Equatable {
  const LeaveEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial load. From Phase 8 onward this reads cache then
/// refreshes from LeaveRepository, and is also re-fired after a
/// successful submission from the Apply screen.
class LeaveStarted extends LeaveEvent {
  const LeaveStarted();
}
