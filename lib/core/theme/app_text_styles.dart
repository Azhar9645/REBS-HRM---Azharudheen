import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.textPrimary,
  );

  static final screenTitle = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  static final sectionTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static final cardTitle = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static final body = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500);

  static final caption = _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static final timerDisplay = _base.copyWith(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary,
    letterSpacing: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final bigNumber = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w800,
  );
}
