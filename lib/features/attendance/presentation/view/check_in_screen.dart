import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/full_screen_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../viewmodel/check_in_bloc.dart';
import '../viewmodel/check_in_event.dart';
import '../viewmodel/check_in_state.dart';
import '../widgets/geofence_radar.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key, this.action = AttendanceAction.checkIn});

  final AttendanceAction action;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CheckInBloc(action: action)..add(const CheckInStarted()),
      child: _CheckInView(action: action),
    );
  }
}

class _CheckInView extends StatelessWidget {
  const _CheckInView({required this.action});

  final AttendanceAction action;

  String get _title => action == AttendanceAction.checkIn
      ? 'Check in'
      : 'Check out';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: BlocBuilder<CheckInBloc, CheckInState>(
          builder: (context, state) {
            return switch (state) {
              CheckInLocating() => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Getting your location…'),
                  ],
                ),
              ),
              CheckInPermissionDenied(:final permanently) => Center(
                child: FullScreenMessage(
                  icon: Icons.location_off_outlined,
                  iconColor: AppColors.pending,
                  iconBackground: AppColors.pendingBg,
                  title: 'Location is turned off',
                  message: permanently
                      ? 'Attendance needs your location to confirm you\'re '
                            'within 200 m of the office. Permission was '
                            'permanently denied — enable it from app '
                            'settings.'
                      : 'Attendance needs your location to confirm you\'re '
                            'within 200 m of the office. Turn it on for '
                            'REBS in your phone settings.',
                  primaryActionLabel: 'Open settings',
                  onPrimaryAction: () => permanently
                      ? LocationService().openAppSettings()
                      : LocationService().openLocationSettings(),
                  secondaryActionLabel: 'Not now',
                  onSecondaryAction: () => Navigator.of(context).maybePop(),
                ),
              ),
              CheckInLocationUnavailable() => Center(
                child: FullScreenMessage(
                  icon: Icons.gps_off,
                  iconColor: AppColors.rejected,
                  iconBackground: AppColors.rejectedBg,
                  title: "Couldn't get your location",
                  message:
                      'Make sure GPS is enabled and you have a clear view '
                      'of the sky, then try again.',
                  primaryActionLabel: 'Try again',
                  onPrimaryAction: () => context.read<CheckInBloc>().add(
                    const LocationRefreshRequested(),
                  ),
                ),
              ),
              CheckInSubmitting() => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Submitting…'),
                  ],
                ),
              ),
              CheckInSubmitted() => Center(
                child: FullScreenMessage(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successBg,
                  title: action == AttendanceAction.checkIn
                      ? 'Checked in'
                      : 'Checked out',
                  message: 'Saved on this phone and will sync automatically.',
                  primaryActionLabel: 'Done',
                  onPrimaryAction: () => Navigator.of(context).maybePop(),
                ),
              ),
              CheckInReady() => _ReadyContent(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _ReadyContent extends StatelessWidget {
  const _ReadyContent({required this.state});

  final CheckInReady state;

  @override
  Widget build(BuildContext context) {
    final within = state.isWithinRange;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              GeofenceRadar(
                officeRadiusMeters: state.officeRadiusMeters,
                isWithinRange: within,
              ),
              const SizedBox(height: 18),
              Text(
                '${state.distanceMeters.round()} m',
                style: AppTextStyles.bigNumber.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 4),
              Text(
                'from the office · GPS accuracy ±'
                '${state.gpsAccuracyMeters.round()} m',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!within)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.rejectedBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.rejected,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You're outside the permitted area",
                        style: TextStyle(
                          color: AppColors.rejected,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Move within ${state.officeRadiusMeters.round()} m '
                        'of the office, then refresh your location to '
                        '${state.action == AttendanceAction.checkIn ? 'check in' : 'check out'}.'
                        '${state.excessMetersLastChecked != null ? ' This device was ${state.excessMetersLastChecked!.round()} m too far when last checked.' : ''}',
                        style: const TextStyle(
                          color: AppColors.rejected,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Refresh location',
          variant: ButtonStyleVariant.outlined,
          onPressed: () => context.read<CheckInBloc>().add(
            const LocationRefreshRequested(),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: state.action == AttendanceAction.checkIn
              ? 'Check in'
              : 'Check out',
          onPressed: within
              ? () => context.read<CheckInBloc>().add(
                  const CheckInSubmitRequested(),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          'The server checks your location again when it receives the '
          '${state.action == AttendanceAction.checkIn ? 'check-in' : 'check-out'}.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
