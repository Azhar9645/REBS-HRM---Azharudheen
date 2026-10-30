import 'package:flutter/material.dart';
import '../../../../core/models/attendance_record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/attendance_record_tile.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../../core/widgets/section_card.dart';

class RecentAttendanceCard extends StatelessWidget {
  const RecentAttendanceCard({
    super.key,
    required this.records,
    required this.onViewAll,
  });

  final List<AttendanceRecordSummary> records;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent attendance', style: AppTextStyles.cardTitle),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.link,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          if (records.isEmpty)
            const EmptyStateCard(
              icon: Icons.schedule,
              title: 'No attendance records yet',
              message:
                  'Your check-ins and check-outs will show up here after '
                  'your first day.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  AttendanceRecordTile(record: records[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
