import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/leave_request.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_chip.dart';

class LeaveRequestTile extends StatelessWidget {
  const LeaveRequestTile({super.key, required this.request});

  final LeaveRequestSummary request;

  String get _dateRangeLabel {
    final fmt = DateFormat('EEE d MMM');
    final start = fmt.format(request.startDate);
    if (request.startDate == request.endDate ||
        (request.startDate.year == request.endDate.year &&
            request.startDate.month == request.endDate.month &&
            request.startDate.day == request.endDate.day)) {
      return '$start · ${request.days} day${request.days == 1 ? '' : 's'}';
    }
    final end = fmt.format(request.endDate);
    return '$start – $end · ${request.days} day${request.days == 1 ? '' : 's'}';
  }

  (StatusChipVariant, String) get _chip => switch (request.status) {
    LeaveRequestStatus.pending => (StatusChipVariant.pending, 'Pending'),
    LeaveRequestStatus.approved => (StatusChipVariant.synced, 'Approved'),
    LeaveRequestStatus.rejected => (StatusChipVariant.rejected, 'Rejected'),
  };

  @override
  Widget build(BuildContext context) {
    final (variant, label) = _chip;
    final isRejected = request.status == LeaveRequestStatus.rejected;
    final subtitle = isRejected
        ? (request.rejectionReason ?? 'Not approved')
        : request.reason;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.type.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateRangeLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isRejected
                        ? AppColors.rejected
                        : AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(label: label, variant: variant),
        ],
      ),
    );
  }
}
