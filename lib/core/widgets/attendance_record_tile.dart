import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../theme/app_colors.dart';
import 'status_chip.dart';

class AttendanceRecordTile extends StatelessWidget {
  const AttendanceRecordTile({super.key, required this.record});

  final AttendanceRecordSummary record;

  String get _timeRange {
    if (record.checkInTime == null) return '—';
    final inLabel = DateFormat.jm().format(record.checkInTime!);
    final outLabel = record.checkOutTime != null
        ? DateFormat.jm().format(record.checkOutTime!)
        : '—';
    return '$inLabel – $outLabel';
  }

  StatusChipVariant get _variant => switch (record.status) {
    RecordSyncStatus.synced => StatusChipVariant.synced,
    RecordSyncStatus.pending => StatusChipVariant.pending,
    RecordSyncStatus.rejected => StatusChipVariant.rejected,
  };

  String get _chipLabel => switch (record.status) {
    RecordSyncStatus.synced => 'Synced',
    RecordSyncStatus.pending => 'Pending',
    RecordSyncStatus.rejected => 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final subtitle = record.note ?? record.workedLabel ?? '';
    final subtitleColor = record.status == RecordSyncStatus.rejected
        ? AppColors.rejected
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE').format(record.date).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${record.date.day}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timeRange,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: subtitleColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(label: _chipLabel, variant: _variant),
        ],
      ),
    );
  }
}
