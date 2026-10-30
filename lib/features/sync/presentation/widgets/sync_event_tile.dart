import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/sync_state.dart';

class SyncEventTile extends StatelessWidget {
  const SyncEventTile({super.key, required this.event});

  final SyncEventSummary event;

  (IconData, Color, Color, String) get _style => switch (event.status) {
    RecordSyncStatus.pending => (
      Icons.access_time,
      AppColors.pendingBg,
      AppColors.pending,
      'Pending sync',
    ),
    RecordSyncStatus.synced => (
      Icons.check,
      AppColors.successBg,
      AppColors.success,
      'Synced',
    ),
    RecordSyncStatus.rejected => (
      Icons.close,
      AppColors.rejectedBg,
      AppColors.rejected,
      'Rejected',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg, label) = _style;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  event.description,
                  style: TextStyle(
                    color: event.status == RecordSyncStatus.rejected
                        ? AppColors.rejected
                        : AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Request ID ${event.requestId}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
