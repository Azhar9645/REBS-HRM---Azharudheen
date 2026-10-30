import 'package:equatable/equatable.dart';
import '../../../../core/models/attendance_record.dart';

export '../../../../core/models/attendance_record.dart';

enum AttendanceDayStatus { notCheckedIn, checkedIn, checkedOut }

class EmployeeSummary extends Equatable {
  const EmployeeSummary({
    required this.name,
    required this.employeeId,
    required this.department,
  });

  final String name;
  final String employeeId;
  final String department;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  @override
  List<Object?> get props => [name, employeeId, department];
}

class TodayAttendance extends Equatable {
  const TodayAttendance({
    required this.status,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.elapsed,
    this.distanceFromOfficeMeters,
    this.officeRadiusMeters = 200,
  });

  final AttendanceDayStatus status;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration elapsed;
  final double? distanceFromOfficeMeters;
  final double officeRadiusMeters;

  @override
  List<Object?> get props => [
    status,
    date,
    checkInTime,
    checkOutTime,
    elapsed,
    distanceFromOfficeMeters,
    officeRadiusMeters,
  ];
}

class LeaveBalanceSummary extends Equatable {
  const LeaveBalanceSummary({
    required this.availableDays,
    required this.totalDays,
    this.savedAtLabel,
  });

  final int availableDays;
  final int totalDays;

  /// Non-null only while showing cached/offline data, e.g. "Saved 5:40 PM".
  final String? savedAtLabel;

  @override
  List<Object?> get props => [availableDays, totalDays, savedAtLabel];
}

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.employee,
    required this.today,
    required this.leaveBalance,
    required this.recentAttendance,
    required this.pendingSyncCount,
    this.isOffline = false,
    this.offlineSavedAtLabel,
  });

  final EmployeeSummary employee;
  final TodayAttendance today;
  final LeaveBalanceSummary leaveBalance;
  final List<AttendanceRecordSummary> recentAttendance;
  final int pendingSyncCount;
  final bool isOffline;
  final String? offlineSavedAtLabel;

  @override
  List<Object?> get props => [
    employee,
    today,
    leaveBalance,
    recentAttendance,
    pendingSyncCount,
    isOffline,
    offlineSavedAtLabel,
  ];
}
