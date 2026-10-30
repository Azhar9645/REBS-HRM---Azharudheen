import 'package:equatable/equatable.dart';
import '../../../../core/models/attendance_record.dart';

export '../../../../core/models/attendance_record.dart';

class SyncEventSummary extends Equatable {
  const SyncEventSummary({
    required this.title,
    required this.status,
    required this.description,
    required this.requestId,
  });

  final String title;
  final RecordSyncStatus status;
  final String description;
  final String requestId;

  @override
  List<Object?> get props => [title, status, description, requestId];
}

sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncLoading extends SyncState {
  const SyncLoading();
}

class SyncLoaded extends SyncState {
  const SyncLoaded({
    required this.events,
    this.isOffline = true,
    this.lastSyncedLabel,
    this.isSyncing = false,
  });

  final List<SyncEventSummary> events;
  final bool isOffline;
  final String? lastSyncedLabel;
  final bool isSyncing;

  int get pendingCount =>
      events.where((e) => e.status == RecordSyncStatus.pending).length;
  int get syncedCount =>
      events.where((e) => e.status == RecordSyncStatus.synced).length;
  int get rejectedCount =>
      events.where((e) => e.status == RecordSyncStatus.rejected).length;

  SyncLoaded copyWith({
    List<SyncEventSummary>? events,
    bool? isOffline,
    String? lastSyncedLabel,
    bool? isSyncing,
  }) {
    return SyncLoaded(
      events: events ?? this.events,
      isOffline: isOffline ?? this.isOffline,
      lastSyncedLabel: lastSyncedLabel ?? this.lastSyncedLabel,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [events, isOffline, lastSyncedLabel, isSyncing];
}
