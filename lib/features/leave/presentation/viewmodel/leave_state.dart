import 'package:equatable/equatable.dart';
import '../../../../core/models/leave_request.dart';

export '../../../../core/models/leave_request.dart';

sealed class LeaveState extends Equatable {
  const LeaveState();

  @override
  List<Object?> get props => [];
}

class LeaveLoading extends LeaveState {
  const LeaveLoading();
}

class LeaveError extends LeaveState {
  const LeaveError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class LeaveLoaded extends LeaveState {
  const LeaveLoaded({
    required this.availableDays,
    required this.requests,
    this.isOffline = false,
    this.updatedAtLabel,
  });

  final int availableDays;
  final List<LeaveRequestSummary> requests;
  final bool isOffline;
  final String? updatedAtLabel;

  @override
  List<Object?> get props => [
    availableDays,
    requests,
    isOffline,
    updatedAtLabel,
  ];
}
