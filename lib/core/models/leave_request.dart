import 'package:equatable/equatable.dart';

enum LeaveType { casual, sick }

enum LeaveRequestStatus { pending, approved, rejected }

extension LeaveTypeLabel on LeaveType {
  String get label => switch (this) {
    LeaveType.casual => 'Casual leave',
    LeaveType.sick => 'Sick leave',
  };
}

class LeaveRequestSummary extends Equatable {
  const LeaveRequestSummary({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    this.rejectionReason,
  });

  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String reason;
  final LeaveRequestStatus status;
  final String? rejectionReason;

  @override
  List<Object?> get props => [
    type,
    startDate,
    endDate,
    days,
    reason,
    status,
    rejectionReason,
  ];
}
