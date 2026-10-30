import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../viewmodel/apply_leave_bloc.dart';
import '../viewmodel/apply_leave_event.dart';
import '../viewmodel/apply_leave_state.dart';
import '../widgets/leave_type_toggle.dart';

class ApplyLeaveScreen extends StatelessWidget {
  const ApplyLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = ApplyLeaveBloc();
        ConnectivityService().isOnlineSafe().then(
          (online) => bloc.add(ApplyLeaveConnectivityChanged(isOffline: !online)),
        );
        return bloc;
      },
      child: const _ApplyLeaveView(),
    );
  }
}

class _ApplyLeaveView extends StatelessWidget {
  const _ApplyLeaveView();

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime(2026, 10, 28);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for leave')),
      body: BlocConsumer<ApplyLeaveBloc, ApplyLeaveState>(
        listener: (context, state) {
          if (state.submitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Leave request submitted')),
            );
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<ApplyLeaveBloc>();
          final dateFmt = DateFormat('EEE d MMM yyyy');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available balance',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${state.availableDays} days',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Leave type', style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              LeaveTypeToggle(
                value: state.type,
                onChanged: (type) => bloc.add(ApplyLeaveTypeChanged(type)),
              ),
              const SizedBox(height: 20),
              Text('Start date', style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              _DateField(
                label: state.startDate != null
                    ? dateFmt.format(state.startDate!)
                    : 'Select date',
                isError: state.overlapWarning != null,
                onTap: () => _pickDate(
                  context,
                  state.startDate,
                  (date) => bloc.add(ApplyLeaveStartDateChanged(date)),
                ),
              ),
              if (state.overlapWarning != null) ...[
                const SizedBox(height: 6),
                _WarningText(state.overlapWarning!),
              ],
              const SizedBox(height: 16),
              Text('End date', style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              _DateField(
                label: state.endDate != null
                    ? dateFmt.format(state.endDate!)
                    : 'Select date',
                isError: state.endBeforeStartError != null,
                onTap: () => _pickDate(
                  context,
                  state.endDate,
                  (date) => bloc.add(ApplyLeaveEndDateChanged(date)),
                ),
              ),
              const SizedBox(height: 6),
              if (state.endBeforeStartError != null)
                _WarningText(state.endBeforeStartError!)
              else if (state.exceedsBalanceError != null)
                _WarningText(state.exceedsBalanceError!)
              else if (state.requestedDays > 0)
                Text(
                  '${state.requestedDays} days requested · every calendar '
                  'day counts',
                  style: AppTextStyles.caption,
                ),
              const SizedBox(height: 20),
              Text('Reason', style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.reason,
                maxLines: 4,
                onChanged: (reason) => bloc.add(ApplyLeaveReasonChanged(reason)),
                decoration: InputDecoration(
                  hintText: 'Add a reason for this leave',
                  errorText: state.reasonError,
                  errorMaxLines: 2,
                ),
              ),
              if (state.submitError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.rejectedBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.submitError!,
                    style: const TextStyle(
                      color: AppColors.rejected,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: state.isSubmitting ? 'Submitting…' : 'Submit request',
                onPressed: state.canSubmit
                    ? () => bloc.add(const ApplyLeaveSubmitRequested())
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                state.isOffline
                    ? "You're offline. Connect to the internet to submit."
                    : 'The server checks these rules again when you submit.',
                textAlign: TextAlign.center,
                style: state.isOffline
                    ? AppTextStyles.caption.copyWith(color: AppColors.rejected)
                    : AppTextStyles.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.isError,
    required this.onTap,
  });

  final String label;
  final bool isError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError ? AppColors.rejected : AppColors.divider,
            width: isError ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningText extends StatelessWidget {
  const _WarningText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.rejected),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.rejected, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
