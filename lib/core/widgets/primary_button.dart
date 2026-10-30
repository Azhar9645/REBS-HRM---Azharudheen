import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonStyleVariant { filled, outlined, filledLight }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonStyleVariant.filled,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonStyleVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );

    switch (variant) {
      case ButtonStyleVariant.filled:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.35,
              ),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );
      case ButtonStyleVariant.outlined:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: disabled
                  ? AppColors.textSecondary
                  : AppColors.primary,
              side: BorderSide(
                color: disabled ? AppColors.divider : AppColors.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: content,
          ),
        );
      case ButtonStyleVariant.filledLight:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
              disabledForegroundColor: AppColors.primary.withValues(
                alpha: 0.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );
    }
  }
}
