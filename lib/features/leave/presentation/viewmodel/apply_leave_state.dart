import 'package:equatable/equatable.dart';
import '../../../../core/models/leave_request.dart';

export '../../../../core/models/leave_request.dart';

class ApplyLeaveState extends Equatable {
  const ApplyLeaveState({
    this.availableDays = 0,
    this.type = LeaveType.casual,
    this.startDate,
    this.endDate,
    this.reason = '',
    this.overlapWarning,
    this.isSubmitting = false,
    this.submitError,
    this.submitted = false,
    this.isOffline = false,
  });

  final int availableDays;
  final LeaveType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String reason;
  final bool isOffline;

  /// Non-null when the selected range overlaps an existing Pending/Approved
  /// request, e.g. "Overlaps your pending request for 2 Nov – 3 Nov."
  final String? overlapWarning;

  final bool isSubmitting;
  final String? submitError;
  final bool submitted;

  int get requestedDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  int get reasonLength => reason.trim().length;

  String? get endBeforeStartError {
    if (startDate == null || endDate == null) return null;
    return endDate!.isBefore(startDate!)
        ? 'End date cannot be before the start date.'
        : null;
  }

  String? get exceedsBalanceError {
    if (requestedDays == 0) return null;
    return requestedDays > availableDays
        ? 'Requested $requestedDays days exceeds your balance of '
              '$availableDays days.'
        : null;
  }

  String? get reasonError {
    if (reason.isEmpty) return null;
    return reasonLength < 10
        ? 'Add at least 10 characters, not counting spaces. You have '
              '$reasonLength.'
        : null;
  }

  bool get canSubmit =>
      !isOffline &&
      startDate != null &&
      endDate != null &&
      overlapWarning == null &&
      endBeforeStartError == null &&
      exceedsBalanceError == null &&
      reasonLength >= 10 &&
      !isSubmitting;

  ApplyLeaveState copyWith({
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? overlapWarning,
    bool clearOverlapWarning = false,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitted,
    bool? isOffline,
  }) {
    return ApplyLeaveState(
      availableDays: availableDays,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      overlapWarning: clearOverlapWarning
          ? null
          : (overlapWarning ?? this.overlapWarning),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitted: submitted ?? this.submitted,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
    availableDays,
    type,
    startDate,
    endDate,
    reason,
    overlapWarning,
    isSubmitting,
    submitError,
    submitted,
    isOffline,
  ];
}
