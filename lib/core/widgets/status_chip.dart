import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusChipVariant { synced, pending, rejected, offline, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
  });

  final String label;
  final StatusChipVariant variant;
  final IconData? icon;

  (Color bg, Color fg, IconData defaultIcon) _colorsFor(StatusChipVariant v) {
    switch (v) {
      case StatusChipVariant.synced:
        return (AppColors.successBg, AppColors.success, Icons.check);
      case StatusChipVariant.pending:
        return (AppColors.pendingBg, AppColors.pending, Icons.access_time);
      case StatusChipVariant.rejected:
        return (AppColors.rejectedBg, AppColors.rejected, Icons.close);
      case StatusChipVariant.offline:
        return (AppColors.offline, Colors.white, Icons.wifi_off);
      case StatusChipVariant.neutral:
        return (
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary,
          Icons.circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, defaultIcon) = _colorsFor(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? defaultIcon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
