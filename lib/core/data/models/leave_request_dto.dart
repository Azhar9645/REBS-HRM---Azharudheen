import '../../models/leave_request.dart' show LeaveType, LeaveRequestStatus;
import '../../utils/date_only.dart';

LeaveType _parseLeaveType(String value) =>
    value == 'sick' ? LeaveType.sick : LeaveType.casual;

LeaveRequestStatus _parseLeaveStatus(String value) => switch (value) {
  'approved' => LeaveRequestStatus.approved,
  'rejected' => LeaveRequestStatus.rejected,
  _ => LeaveRequestStatus.pending,
};

class LeaveRequestDto {
  const LeaveRequestDto({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
  });

  final String id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String reason;
  final LeaveRequestStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) => LeaveRequestDto(
    id: json['id'] as String,
    type: _parseLeaveType(json['type'] as String),
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    days: json['days'] as int,
    reason: json['reason'] as String,
    status: _parseLeaveStatus(json['status'] as String),
    rejectionReason: json['rejectionReason'] as String?,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == LeaveType.sick ? 'sick' : 'casual',
    'startDate': dateOnlyString(startDate),
    'endDate': dateOnlyString(endDate),
    'days': days,
    'reason': reason,
    'status': status.name,
    'rejectionReason': rejectionReason,
    'submittedAt': submittedAt.toIso8601String(),
  };
}
