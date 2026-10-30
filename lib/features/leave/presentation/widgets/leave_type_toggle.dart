import 'package:flutter/material.dart';
import '../../../../core/models/leave_request.dart';
import '../../../../core/theme/app_colors.dart';

class LeaveTypeToggle extends StatelessWidget {
  const LeaveTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LeaveType value;
  final ValueChanged<LeaveType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: LeaveType.values.map((type) {
          final selected = type == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  type == LeaveType.casual ? 'Casual' : 'Sick',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
