import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../viewmodel/sync_bloc.dart';
import '../viewmodel/sync_event.dart';
import '../viewmodel/sync_state.dart';
import '../widgets/sync_event_tile.dart';
import '../widgets/sync_stat_card.dart';

class SyncQueueScreen extends StatelessWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SyncBloc()..add(const SyncStarted()),
      child: const _SyncView(),
    );
  }
}

class _SyncView extends StatelessWidget {
  const _SyncView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync queue'),
        actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              final isOffline = state is SyncLoaded && state.isOffline;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: StatusChip(
                  label: isOffline ? 'Offline' : 'Online',
                  variant: isOffline
                      ? StatusChipVariant.offline
                      : StatusChipVariant.synced,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          return switch (state) {
            SyncLoading() => const DashboardSkeleton(),
            SyncLoaded() => _SyncContent(state: state),
          };
        },
      ),
    );
  }
}

class _SyncContent extends StatelessWidget {
  const _SyncContent({required this.state});

  final SyncLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.lastSyncedLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Last synced ${state.lastSyncedLabel}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        Row(
          children: [
            SyncStatCard(
              count: state.pendingCount,
              label: 'Pending',
              background: AppColors.pendingBg,
              foreground: AppColors.pending,
            ),
            const SizedBox(width: 10),
            SyncStatCard(
              count: state.syncedCount,
              label: 'Synced',
              background: AppColors.successBg,
              foreground: AppColors.success,
            ),
            const SizedBox(width: 10),
            SyncStatCard(
              count: state.rejectedCount,
              label: 'Rejected',
              background: AppColors.rejectedBg,
              foreground: AppColors.rejected,
            ),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: state.isSyncing ? 'Syncing…' : 'Sync now',
          icon: Icons.sync,
          onPressed: state.isSyncing
              ? null
              : () => context.read<SyncBloc>().add(const SyncNowRequested()),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            children: [
              for (var i = 0; i < state.events.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                SyncEventTile(event: state.events[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
