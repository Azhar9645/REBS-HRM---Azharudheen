import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial load of the local pending_events table.
class SyncStarted extends SyncEvent {
  const SyncStarted();
}

/// Guarded in the handler (not a transformer): a repeated tap on "Sync now"
/// while a sync is already running doesn't start a second drain.
class SyncNowRequested extends SyncEvent {
  const SyncNowRequested();
}

/// The local queue or connectivity changed; rebuild the list in place.
class SyncQueueChanged extends SyncEvent {
  const SyncQueueChanged();
}
