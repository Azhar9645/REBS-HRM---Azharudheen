import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

/// Reusable centered icon + title + message panel used for error states,
/// permission-denied states, and similar full-screen notices.
class FullScreenMessage extends StatelessWidget {
  const FullScreenMessage({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 14, height: 1.4),
          ),
          if (primaryActionLabel != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              label: primaryActionLabel!,
              onPressed: onPrimaryAction,
            ),
          ],
          if (secondaryActionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(
                secondaryActionLabel!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
