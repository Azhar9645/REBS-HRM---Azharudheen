import 'package:equatable/equatable.dart';
import '../../../../core/models/leave_request.dart';

sealed class ApplyLeaveEvent extends Equatable {
  const ApplyLeaveEvent();

  @override
  List<Object?> get props => [];
}

class ApplyLeaveTypeChanged extends ApplyLeaveEvent {
  const ApplyLeaveTypeChanged(this.type);

  final LeaveType type;

  @override
  List<Object?> get props => [type];
}

class ApplyLeaveStartDateChanged extends ApplyLeaveEvent {
  const ApplyLeaveStartDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ApplyLeaveEndDateChanged extends ApplyLeaveEvent {
  const ApplyLeaveEndDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ApplyLeaveReasonChanged extends ApplyLeaveEvent {
  const ApplyLeaveReasonChanged(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

class ApplyLeaveSubmitRequested extends ApplyLeaveEvent {
  const ApplyLeaveSubmitRequested();
}

/// Dispatched by the screen once, right after creating the bloc, with the
/// result of a one-time connectivity check (submitting requires being
/// online; see DEVELOPMENT_PLAN.md Phase 8).
class ApplyLeaveConnectivityChanged extends ApplyLeaveEvent {
  const ApplyLeaveConnectivityChanged({required this.isOffline});

  final bool isOffline;

  @override
  List<Object?> get props => [isOffline];
}
