import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/attendance_record_tile.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../../core/widgets/full_screen_message.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/section_card.dart';
import '../viewmodel/attendance_history_bloc.dart';
import '../viewmodel/attendance_history_event.dart';
import '../viewmodel/attendance_history_state.dart';
import '../widgets/month_selector.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AttendanceHistoryBloc()..add(const AttendanceHistoryStarted()),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: BlocBuilder<AttendanceHistoryBloc, AttendanceHistoryState>(
        builder: (context, state) {
          return switch (state) {
            AttendanceHistoryLoading() => const DashboardSkeleton(),
            AttendanceHistoryError(:final message) => Center(
              child: FullScreenMessage(
                icon: Icons.error_outline,
                iconColor: AppColors.rejected,
                iconBackground: AppColors.rejectedBg,
                title: "Couldn't load attendance",
                message: message,
              ),
            ),
            AttendanceHistoryLoaded() => _AttendanceContent(state: state),
          };
        },
      ),
    );
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent({required this.state});

  final AttendanceHistoryLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (state.isOffline)
          OfflineBanner(
            message: 'Saved on this phone'
                '${state.updatedAtLabel != null ? ' · updated ${state.updatedAtLabel}' : ''}.',
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MonthSelector(
                month: state.month,
                onPrevious: () => context.read<AttendanceHistoryBloc>().add(
                  const AttendanceHistoryPreviousMonthRequested(),
                ),
                onNext: () => context.read<AttendanceHistoryBloc>().add(
                  const AttendanceHistoryNextMonthRequested(),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: state.records.isEmpty
                    ? const EmptyStateCard(
                        icon: Icons.event_busy,
                        title: 'No records for this month',
                        message:
                            'Attendance for this month will show up here '
                            'once available.',
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < state.records.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            AttendanceRecordTile(record: state.records[i]),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
