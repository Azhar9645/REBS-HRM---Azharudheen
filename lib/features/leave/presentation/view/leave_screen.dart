import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_card.dart';
import '../../../../core/widgets/full_screen_message.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_card.dart';
import '../viewmodel/leave_bloc.dart';
import '../viewmodel/leave_event.dart';
import '../viewmodel/leave_state.dart';
import '../widgets/leave_request_tile.dart';
import 'apply_leave_screen.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaveBloc()..add(const LeaveStarted()),
      child: const _LeaveView(),
    );
  }
}

class _LeaveView extends StatelessWidget {
  const _LeaveView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave')),
      body: BlocBuilder<LeaveBloc, LeaveState>(
        builder: (context, state) {
          return switch (state) {
            LeaveLoading() => const DashboardSkeleton(),
            LeaveError(:final message) => Center(
              child: FullScreenMessage(
                icon: Icons.error_outline,
                iconColor: AppColors.rejected,
                iconBackground: AppColors.rejectedBg,
                title: "Couldn't load leave",
                message: message,
              ),
            ),
            LeaveLoaded() => _LeaveContent(state: state),
          };
        },
      ),
    );
  }
}

class _LeaveContent extends StatelessWidget {
  const _LeaveContent({required this.state});

  final LeaveLoaded state;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leave balance', style: AppTextStyles.caption),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${state.availableDays}',
                        style: AppTextStyles.bigNumber,
                      ),
                      Text('days available', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Apply for leave',
                icon: Icons.add,
                onPressed: () async {
                  final bloc = context.read<LeaveBloc>();
                  final submitted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                  );
                  if (submitted == true) bloc.add(const LeaveStarted());
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Submitting a request needs an internet connection.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: state.requests.isEmpty
                    ? const EmptyStateCard(
                        icon: Icons.event_available,
                        title: 'No leave requests yet',
                        message:
                            'Requests you submit will show up here with '
                            'their approval status.',
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < state.requests.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            LeaveRequestTile(request: state.requests[i]),
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
