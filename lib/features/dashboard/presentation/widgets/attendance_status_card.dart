import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../viewmodel/dashboard_state.dart';

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({
    super.key,
    required this.today,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final TodayAttendance today;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  String get _statusLabel => switch (today.status) {
    AttendanceDayStatus.notCheckedIn => 'Not checked in',
    AttendanceDayStatus.checkedIn => 'Checked in',
    AttendanceDayStatus.checkedOut => 'Checked out',
  };

  String get _elapsedCaption => today.status == AttendanceDayStatus.checkedOut
      ? 'Total time worked today'
      : 'Time worked today';

  String _timeLabel(DateTime? t) => t == null ? '—' : DateFormat.jm().format(t);

  String get _locationLine {
    final distance = today.distanceFromOfficeMeters;
    if (distance == null) return '';
    if (today.status == AttendanceDayStatus.checkedOut) {
      return 'Location captured · ${distance.round()} m from office';
    }
    return 'Within office range · ${distance.round()} m of '
        '${today.officeRadiusMeters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('EEE, d MMM').format(today.date),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textOnPrimaryMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ElapsedTimer(
            runningSince: today.status == AttendanceDayStatus.checkedIn
                ? today.checkInTime
                : null,
            fixed: today.elapsed,
          ),
          const SizedBox(height: 4),
          Text(
            _elapsedCaption,
            style: TextStyle(color: AppColors.textOnPrimaryMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in',
                      style: TextStyle(
                        color: AppColors.textOnPrimaryMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLabel(today.checkInTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-out',
                      style: TextStyle(
                        color: AppColors.textOnPrimaryMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLabel(today.checkOutTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_locationLine.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationLine,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          switch (today.status) {
            AttendanceDayStatus.notCheckedIn => PrimaryButton(
              label: 'Check in',
              variant: ButtonStyleVariant.filledLight,
              onPressed: onCheckIn,
            ),
            AttendanceDayStatus.checkedIn => PrimaryButton(
              label: 'Check out',
              variant: ButtonStyleVariant.filledLight,
              onPressed: onCheckOut,
            ),
            AttendanceDayStatus.checkedOut => PrimaryButton(
              label: 'Attendance complete for today',
              variant: ButtonStyleVariant.filledLight,
              onPressed: null,
            ),
          },
        ],
      ),
    );
  }
}

/// Shows hh:mm:ss. Ticks every second while [runningSince] is set (checked
/// in); otherwise shows [fixed].
class _ElapsedTimer extends StatefulWidget {
  const _ElapsedTimer({required this.runningSince, required this.fixed});

  final DateTime? runningSince;
  final Duration fixed;

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_ElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runningSince != widget.runningSince) _syncTicker();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = widget.runningSince == null
        ? null
        : Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final since = widget.runningSince;
    var elapsed = since == null ? widget.fixed : DateTime.now().difference(since);
    if (elapsed.isNegative) elapsed = Duration.zero;

    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$h:$m:$s', style: AppTextStyles.timerDisplay);
  }
}
