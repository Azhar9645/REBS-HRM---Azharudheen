import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/local/auth_local_data_source.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/full_screen_message.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/view/login_screen.dart';
import '../../../attendance/presentation/view/attendance_screen.dart';
import '../../../attendance/presentation/view/check_in_screen.dart';
import '../../../attendance/presentation/viewmodel/check_in_state.dart';
import '../../../leave/presentation/view/apply_leave_screen.dart';
import '../viewmodel/dashboard_bloc.dart';
import '../viewmodel/dashboard_event.dart';
import '../viewmodel/dashboard_state.dart';
import '../widgets/attendance_status_card.dart';
import '../widgets/leave_balance_card.dart';
import '../widgets/recent_attendance_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardBloc()..add(const DashboardStarted()),
      child: const _DashboardView(),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Log out?', style: AppTextStyles.sectionTitle),
      content: Text(
        "You'll need to sign in again to view your dashboard.",
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Log out',
            style: TextStyle(
              color: AppColors.rejected,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await AuthLocalDataSource().clearSession();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardLoading() => const DashboardSkeleton(),
            DashboardError(:final message) => Center(
              child: FullScreenMessage(
                icon: Icons.error_outline,
                iconColor: AppColors.rejected,
                iconBackground: AppColors.rejectedBg,
                title: "Couldn't load your dashboard",
                message: message,
                primaryActionLabel: 'Try again',
                onPrimaryAction: () => context.read<DashboardBloc>().add(
                  const DashboardStarted(),
                ),
              ),
            ),
            DashboardLoaded() => RefreshIndicator(
              onRefresh: () {
                final completer = Completer<void>();
                context.read<DashboardBloc>().add(
                  DashboardRefreshRequested(completer: completer),
                );
                return completer.future;
              },
              child: _DashboardContent(state: state),
            ),
          };
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state});

  final DashboardLoaded state;

  Future<void> _openCheckIn(BuildContext context, AttendanceAction action) async {
    final bloc = context.read<DashboardBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckInScreen(action: action)),
    );
    bloc.add(const DashboardRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (state.isOffline)
          OfflineBanner(
            message: state.offlineSavedAtLabel == null
                ? "You're offline. Showing saved data."
                : "You're offline. Showing data saved at "
                      '${state.offlineSavedAtLabel}.',
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      state.employee.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.employee.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${state.employee.employeeId} · '
                          '${state.employee.department}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.isOffline)
                    StatusChip(
                      label: '${state.pendingSyncCount} pending',
                      variant: StatusChipVariant.pending,
                    )
                  else
                    const StatusChip(
                      label: 'Synced',
                      variant: StatusChipVariant.synced,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AttendanceStatusCard(
                today: state.today,
                onCheckIn: () =>
                    _openCheckIn(context, AttendanceAction.checkIn),
                onCheckOut: () =>
                    _openCheckIn(context, AttendanceAction.checkOut),
              ),
              const SizedBox(height: 16),
              LeaveBalanceCard(
                balance: state.leaveBalance,
                onApplyForLeave: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                ),
              ),
              const SizedBox(height: 16),
              RecentAttendanceCard(
                records: state.recentAttendance,
                onViewAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
