import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/models/attendance_event_dto.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../attendance/data/attendance_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    AttendanceRepository? repository,
    ConnectivityService? connectivity,
  }) : _repository = repository ?? AttendanceRepository(),
       _connectivity = connectivity ?? ConnectivityService(),
       super(const SyncLoading()) {
    on<SyncStarted>(_onStarted);
    on<SyncNowRequested>(_onSyncNowRequested);
    on<SyncQueueChanged>(_onQueueChanged);
    _subscriptions = [
      _connectivity.onStatusChange.listen((online) {
        add(const SyncQueueChanged());
        if (online) add(const SyncNowRequested());
      }),
      _repository.eventsChanged.listen((_) => add(const SyncQueueChanged())),
    ];
  }

  final AttendanceRepository _repository;
  final ConnectivityService _connectivity;
  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }

  Future<void> _onQueueChanged(
    SyncQueueChanged event,
    Emitter<SyncState> emit,
  ) async {
    final rebuilt = await _buildLoaded();
    final current = state;
    emit(
      current is SyncLoaded
          ? rebuilt.copyWith(
              isSyncing: current.isSyncing,
              lastSyncedLabel: current.lastSyncedLabel,
            )
          : rebuilt,
    );
  }

  Future<void> _onStarted(SyncStarted event, Emitter<SyncState> emit) async {
    emit(const SyncLoading());
    emit(await _buildLoaded());
  }

  Future<void> _onSyncNowRequested(
    SyncNowRequested event,
    Emitter<SyncState> emit,
  ) async {
    // Guards against a repeated tap: this check and the emit below both
    // run synchronously (before the first await), so a second dispatch
    // of this event always sees the updated state, even without an
    // explicit event transformer.
    final current = state;
    if (current is! SyncLoaded || current.isSyncing) return;

    emit(current.copyWith(isSyncing: true));
    await _repository.syncAll();
    final rebuilt = await _buildLoaded();
    emit(rebuilt.copyWith(isSyncing: false, lastSyncedLabel: 'just now'));
  }

  Future<SyncLoaded> _buildLoaded() async {
    final isOffline = !await _connectivity.isOnlineSafe();
    return SyncLoaded(events: _eventSummaries(), isOffline: isOffline);
  }

  List<SyncEventSummary> _eventSummaries() {
    final events = _repository.allEvents
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return [for (final e in events) _toSummary(e)];
  }

  SyncEventSummary _toSummary(AttendanceEventDto event) {
    final typeLabel = event.type == AttendanceEventType.checkIn
        ? 'Check-in'
        : 'Check-out';
    final title = '$typeLabel · ${DateFormat.jm().format(event.timestamp)}';
    final dayLabel = _dayLabel(event.timestamp);

    final (status, description) = switch (event.status) {
      EventSyncStatus.pendingSync => (
        RecordSyncStatus.pending,
        '$dayLabel · waiting for a connection',
      ),
      EventSyncStatus.synced => (
        RecordSyncStatus.synced,
        '$dayLabel · confirmed by server',
      ),
      EventSyncStatus.rejected => (
        RecordSyncStatus.rejected,
        '$dayLabel · ${event.rejectionReason ?? 'rejected by server'}',
      ),
    };

    return SyncEventSummary(
      title: title,
      status: status,
      description: description,
      requestId:
          '${event.eventId.substring(0, 4)}-${event.eventId.substring(4, 8)}',
    );
  }

  String _dayLabel(DateTime timestamp) {
    final now = DateTime.now();
    final isToday =
        timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
    return isToday ? 'Today' : DateFormat('EEE d MMM').format(timestamp);
  }
}
