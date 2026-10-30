import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Small in-card empty state (e.g. "No attendance records yet").
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
