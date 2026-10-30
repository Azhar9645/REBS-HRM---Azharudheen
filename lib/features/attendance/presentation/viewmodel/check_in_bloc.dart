import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/data/local/employee_local_data_source.dart';
import '../../../../core/data/models/attendance_event_dto.dart';
import '../../../../core/models/attendance_record.dart';
import '../../../../core/network/location_service.dart';
import '../../data/attendance_repository.dart';
import 'check_in_event.dart';
import 'check_in_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc({
    required AttendanceAction action,
    LocationService? locationService,
    AttendanceRepository? attendanceRepository,
    EmployeeLocalDataSource? employeeLocal,
  }) : _action = action,
       _location = locationService ?? LocationService(),
       _repository = attendanceRepository ?? AttendanceRepository(),
       _employeeLocal = employeeLocal ?? EmployeeLocalDataSource(),
       super(const CheckInLocating()) {
    on<CheckInStarted>((event, emit) => _locate(emit));
    on<LocationRefreshRequested>((event, emit) => _locate(emit));
    on<CheckInSubmitRequested>(_onSubmitRequested);
  }

  final AttendanceAction _action;
  final LocationService _location;
  final AttendanceRepository _repository;
  final EmployeeLocalDataSource _employeeLocal;

  Position? _lastPosition;

  Future<void> _locate(Emitter<CheckInState> emit) async {
    emit(const CheckInLocating());

    final office = _employeeLocal.read()?.office;
    if (office == null) {
      emit(const CheckInLocationUnavailable());
      return;
    }

    final LocationAccessResult access;
    try {
      access = await _location.ensureAccess();
    } catch (_) {
      emit(const CheckInLocationUnavailable());
      return;
    }
    switch (access) {
      case LocationAccessResult.deniedForever:
        emit(const CheckInPermissionDenied(permanently: true));
        return;
      case LocationAccessResult.denied:
      case LocationAccessResult.serviceDisabled:
        emit(const CheckInPermissionDenied());
        return;
      case LocationAccessResult.granted:
        break;
    }

    try {
      final position = await _location.getCurrentPosition();
      _lastPosition = position;

      final distance = _location.distanceBetween(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: office.latitude,
        endLongitude: office.longitude,
      );
      final within = distance <= office.radiusMeters;

      emit(
        CheckInReady(
          action: _action,
          distanceMeters: distance,
          officeRadiusMeters: office.radiusMeters,
          gpsAccuracyMeters: position.accuracy,
          excessMetersLastChecked: within ? null : distance - office.radiusMeters,
        ),
      );
    } catch (_) {
      emit(const CheckInLocationUnavailable());
    }
  }

  Future<void> _onSubmitRequested(
    CheckInSubmitRequested event,
    Emitter<CheckInState> emit,
  ) async {
    // Guards against a repeated tap: this check and the emit below both
    // run synchronously (before the first await), so a second dispatch
    // of this event always sees the updated state, even without an
    // explicit event transformer.
    final current = state;
    if (current is! CheckInReady || !current.isWithinRange) return;

    final today = _repository.mergedRecordForDay(DateTime.now());
    final alreadyCheckedIn =
        today?.checkInTime != null &&
        today?.status != RecordSyncStatus.rejected;
    if (_action == AttendanceAction.checkIn &&
        alreadyCheckedIn &&
        today?.checkOutTime == null) {
      return;
    }
    if (_action == AttendanceAction.checkOut && !alreadyCheckedIn) {
      return;
    }

    emit(const CheckInSubmitting());
    await _repository.recordAttempt(
      type: _action == AttendanceAction.checkIn
          ? AttendanceEventType.checkIn
          : AttendanceEventType.checkOut,
      latitude: _lastPosition?.latitude,
      longitude: _lastPosition?.longitude,
    );
    emit(const CheckInSubmitted());

    // Best-effort immediate sync so the user doesn't have to visit the
    // Sync tab if they're online; the event is already safely persisted
    // either way and will be retried from there if this fails.
    unawaited(_repository.syncAll());
  }
}
