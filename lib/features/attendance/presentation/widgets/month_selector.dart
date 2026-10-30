import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}
