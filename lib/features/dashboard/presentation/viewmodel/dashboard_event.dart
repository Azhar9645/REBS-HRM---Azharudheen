import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial load: reads cache first if offline, otherwise
/// refreshes from [DashboardRepository] and caches the result.
class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// Reloads while keeping the current content on screen (no skeleton).
/// [completer] completes once the reload finishes, so a pull-to-refresh
/// spinner can stay visible until then.
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested({this.completer});

  final Completer<void>? completer;
}
