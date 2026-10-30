import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/section_card.dart';
import '../viewmodel/dashboard_state.dart';

class LeaveBalanceCard extends StatelessWidget {
  const LeaveBalanceCard({
    super.key,
    required this.balance,
    required this.onApplyForLeave,
  });

  final LeaveBalanceSummary balance;
  final VoidCallback onApplyForLeave;

  @override
  Widget build(BuildContext context) {
    final ratio = balance.totalDays == 0
        ? 0.0
        : balance.availableDays / balance.totalDays;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Leave balance', style: AppTextStyles.cardTitle),
              Text(
                balance.savedAtLabel ?? 'Calendar days',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${balance.availableDays}', style: AppTextStyles.bigNumber),
              const SizedBox(width: 6),
              Text(
                'days available of ${balance.totalDays}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onApplyForLeave,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apply for leave',
                  style: TextStyle(
                    color: AppColors.link,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.link),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
