# REBS HRMS — Employee Workspace: Development Plan

Architecture: **MVVM**, state management: **flutter_bloc only**, uniformly `Bloc` (not `Cubit`) with explicit event classes for every feature — consistency across the app, and an explicit, testable event log for the two screens where it earns its keep: Check-in/out submit and Sync-now both guard against a repeated tap by checking `state` synchronously at the top of the handler, before any `await` — since a Bloc event handler's synchronous prefix always completes before the next dispatched event's handler begins, this is sufficient on its own (no extra event-transformer package needed) to stop a duplicate attendance/sync event.

Strategy: **Phase 1 builds every screen with static/mock data only** (no API, no DB, no location, no sync logic). Once the UI matches the reference 1:1 and navigation works, each later phase wires one feature at a time to real data, replacing the mock ViewModel with a real one — the Views don't change.

---

## 1. Architecture

```
View (Widget)  →  ViewModel (Bloc<Event, State>)  →  Repository  →  { LocalDataSource, RemoteDataSource }
```

- **View**: StatelessWidget, no logic in `build()`, reads state via `BlocBuilder`/`BlocConsumer`, writes via `context.read<XBloc>().add(Event(...))`.
- **ViewModel**: `Bloc<Event, State>`. Owns UI state as a sealed/union class (`Loading / Loaded / Empty / Error / Offline`) and a sealed `Event` class per feature (e.g. `CheckInStarted`, `CheckInSubmitRequested`). Phase 1 event handlers just emit a hardcoded `Loaded` state so the same Event/State shape survives into later phases — only the handler body changes when real repositories land.
- **Repository**: business rules + decides local vs remote. Added from Phase 3 onward.
- **Data sources**: local persistence (Hive/Drift) and remote (Dio). Added from Phase 3 onward.

### Folder structure

```
bin/
  mock_server.dart                 # thin CLI entry point, see README.md
lib/
  mock_server/mock_api_server.dart  # the actual Phase 2 mock API (Dart shelf); lives in
                                     # lib/ (not just bin/) so Phase 9 tests can start their
                                     # own isolated in-process instance on an ephemeral port
  main.dart                        # MaterialApp (RebsHrmsApp), theme, router — app.dart merged in here
  bottom_nav_bar/
    nav_bar.dart                   # bottom nav scaffold (NavBar): Home / Attendance / Leave / Sync
  core/
    models/ (attendance_record.dart, leave_request.dart)
    theme/ (app_colors.dart, app_text_styles.dart, app_theme.dart)
    widgets/ (status_chip.dart, section_card.dart, empty_state_card.dart,
               full_screen_message.dart, loading_skeleton.dart, primary_button.dart,
               offline_banner.dart, attendance_record_tile.dart)
    router/app_router.dart
  features/
    dashboard/presentation/
      view/dashboard_screen.dart
      viewmodel/dashboard_bloc.dart, dashboard_event.dart, dashboard_state.dart
      widgets/ attendance_status_card.dart, leave_balance_card.dart, recent_attendance_card.dart
    attendance/
      data/attendance_repository.dart     # write-ahead log + sync engine + month/day reads;
                                           # shared by check-in, sync, history AND dashboard
      presentation/
        view/attendance_screen.dart       # full history + month selector
        view/check_in_screen.dart         # geofence / check-in flow
        viewmodel/attendance_history_bloc.dart + check_in_bloc.dart (+ *_event.dart, *_state.dart)
        widgets/ month_selector.dart, geofence_radar.dart
    leave/
      data/leave_repository.dart
      presentation/
        view/leave_screen.dart
        view/apply_leave_screen.dart
        viewmodel/leave_bloc.dart + apply_leave_bloc.dart (+ *_event.dart, *_state.dart)
        widgets/ leave_request_tile.dart, leave_type_toggle.dart
    sync/presentation/
      view/sync_queue_screen.dart
      viewmodel/sync_bloc.dart, sync_event.dart, sync_state.dart
      widgets/ sync_stat_card.dart, sync_event_tile.dart
```

`full_screen_message.dart` is the shared error/empty/permission-denied panel (covers the "Error state" and "Location permission denied" rows in §2 with one configurable widget instead of separate ones).

From Phase 3 onward, each feature also gets `domain/` (models, rules) and `data/` (repository, local/remote datasource) siblings next to `presentation/`. No separate `sync/data/` repository exists — the Sync screen reads/drains the same `AttendanceRepository` as Check-in and Attendance history, since "pending events" is one shared concept, not a sync-specific one. Entities and infrastructure used by *more than one* feature live under `core/` instead of being duplicated per-feature:

```
  core/
    data/
      models/   (EmployeeDto, AttendanceRecordDto, AttendanceEventDto, LeaveBalanceDto, LeaveRequestDto)
      local/     (local_store.dart + one *_local_data_source.dart per entity, Hive-backed)
    network/    (api_config.dart, api_client.dart, api_exception.dart, connectivity_service.dart,
                 location_service.dart)
    utils/      (date_only.dart, attendance_format.dart — tiny pure helpers shared across repos/blocs)
```

---

## 2. Screen inventory (from UI reference)

| # | Screen | Route | Notes |
|---|--------|-------|-------|
| 1 | **Home / Dashboard** | `/` (tab) | Header (avatar, name, ID, department, sync chip), attendance status card (timer, check-in/out times, location line, action button), leave balance card, recent-5 attendance list. Must support: loading (skeleton), empty/first-day, error/no-saved-data, offline banner, checked-in, checked-out, pending states. |
| 2 | **Check-in** (and Check-out) | `/check-in` (push) | Radar-style circle visualization (office + "You" + distance line), distance readout + GPS accuracy, outside-range warning banner, Refresh location / Check in buttons, footnote about server re-validation. |
| 3 | **Attendance history** | `/attendance` (tab) | Month selector, full list of records with per-record status chip (Synced / Pending / Rejected). |
| 4 | **Leave** | `/leave` (tab) | Balance readout, "Apply for leave" button, connectivity note, list of requests with status chips and rejection reason text. |
| 5 | **Apply for leave** | `/leave/apply` (push) | Balance banner, Casual/Sick segmented toggle, start/end date pickers with inline validation (overlap, days vs balance), reason textarea with live char-count validation, submit button, server re-check footnote. |
| 6 | **Sync queue** | `/sync` (tab) | Offline/online chip, Pending/Synced/Rejected stat cards, Sync now button, event list (type, time, status, request ID, description). |

Shared, non-screen states to build as reusable widgets (not separate routes):
- Loading skeleton (shimmer blocks matching dashboard layout)
- Empty state ("No attendance records yet")
- Error state ("Couldn't load your dashboard" + Try again)
- Offline banner (top strip: "You're offline. Showing data saved at …")
- Location permission denied / permanently denied panel ("Open settings" / "Not now")

Bottom navigation: **Home · Attendance · Leave · Sync**, with a badge on Sync showing pending-event count.

---

## 3. Phase-by-phase plan

### Phase 0 — Project setup (30 min) ✅
- [x] Add packages: `flutter_bloc`, `equatable`, `go_router`, `intl`, `uuid`. Deferred to the phase that needs them: `dio` (Phase 3), `hive`/`hive_flutter` (Phase 3), `connectivity_plus` (Phase 3), `geolocator` (Phase 5), `get_it` (if/when a DI container is needed).
- [x] Theme set up (`app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`); `MaterialApp` lives in `main.dart` (merged in from the former `app.dart`).
- [x] Set up `nav_bar.dart` (`NavBar`, in `lib/bottom_nav_bar/`) with `NavigationBar` for the 4 tabs, badge on Sync.

### Phase 1 — UI only, static data ✅
Build every screen listed above exactly as in the reference, each ViewModel emitting a **hardcoded state** (no repository, no API, no DB, no geolocation). Goal: pixel-accurate, fully navigable app shell.

- [x] Shared widgets: `StatusChip` (Synced/Pending/Rejected/Offline/Checked-in/Checked-out variants), `SectionCard`, `EmptyStateCard`, `FullScreenMessage` (covers error + location-permission-denied panels), `LoadingSkeleton`/`DashboardSkeleton`, `PrimaryButton`, `OfflineBanner`.
- [x] Dashboard screen — all 5 sub-states (loading / empty-first-day / error / checked-in-synced / checked-out-offline-pending) wired as Bloc states, switchable via a dev-only debug menu (bug icon in the AppBar); to be removed once Phase 4 lands real data.
- [x] Check-in screen — radar visualization (`GeofenceRadar`) with distance + GPS accuracy, outside-range warning banner, enabled/disabled Check-in button, locating/submitting/submitted states, and the location-permission-denied panel (denied / permanently denied / unavailable) — also switchable via a dev debug menu.
- [x] Attendance history screen — month selector + static list.
- [x] Leave screen — static list with all 3 status variants + rejection reason styling.
- [x] Apply for leave screen — segmented Casual/Sick toggle, date pickers, live overlap/end-before-start/exceeds-balance/reason-length validation messages, submit button, server-recheck footnote.
- [x] Sync queue screen — online/offline chip, Pending/Synced/Rejected stat cards, Sync now button, event list.
- [x] Navigation wired: bottom nav ↔ tabs, Home → Check-in (push), Leave → Apply (push), back navigation — via `go_router`.
- [ ] Responsive check on at least 2 Android screen sizes (small phone + tablet width) — not yet verified, do this manually before moving past Phase 1 for real.

**Exit criteria:** app runs, every screen/state in the reference can be reached and looks right, zero business logic, zero network/DB code. Met, except the responsive check above is still outstanding.

### Phase 2 — Mock API (45 min) ✅
- [x] Local mock server (`bin/mock_server.dart`, Dart `shelf`) implementing 6 endpoints: `GET /employee/me`, `GET /attendance`, `POST /attendance/events`, `GET /attendance/events/:eventId`, `GET /leave`, `POST /leave/requests`.
- [x] Scenario switches via `?simulate=` and `POST /debug/scenario`: success, slow, timeout, serverError, duplicate, validationError. Real validation logic (idempotent eventId dedupe, check-in/out ordering, leave overlap/balance/reason-length) runs by default without forcing a scenario.
- [x] Documented in README.md: how to run it, base URL per platform (emulator/simulator/device), endpoint table, scenario list.

### Phase 3 — Core data infrastructure (1–1.5h) ✅
- [x] Models: `lib/core/data/models/` — `EmployeeDto`/`OfficeConfigDto`, `AttendanceRecordDto`, `AttendanceEventDto`, `LeaveBalanceDto`, `LeaveRequestDto` (DTO suffix to avoid colliding with the existing presentation-layer `*Summary` types in `core/models/`, which the dashboard bloc maps DTOs into). Reuses the existing `RecordSyncStatus`/`LeaveType`/`LeaveRequestStatus` enums rather than duplicating them.
- [x] Local persistence: `lib/core/data/local/local_store.dart` opens 5 Hive boxes (employee/attendance/pending_events/leave/app_meta) — values stored as plain JSON-able maps via the DTOs' `toJson()`/`fromJson()`, no codegen needed. Per-entity data sources: `EmployeeLocalDataSource`, `AttendanceLocalDataSource`, `LeaveLocalDataSource`, `PendingEventsLocalDataSource` (the `pending_events` write-ahead log itself is only exercised starting Phase 5/6; Phase 4 just reads its count for the sync badge).
- [x] `ApiClient` (`lib/core/network/api_client.dart`, Dio) wrapping all 6 mock-API endpoints, with `ApiException` carrying status code + decoded body (so a 409 idempotent replay's payload isn't lost). Base URL in `api_config.dart` (emulator/simulator default, `--dart-define=API_BASE_URL=` override).
- [x] `ConnectivityService` (`lib/core/network/connectivity_service.dart`) wrapping `connectivity_plus`.

### Phase 4 — Dashboard wiring (1h) ✅
- [x] `DashboardRepository` (`lib/features/dashboard/data/dashboard_repository.dart`): offline-first — tries the API, caches to Hive on success, falls back to cache (flagged `isOffline`) on any failure, including a failed/unavailable connectivity check. Throws `DashboardNoDataException` only when there's truly nothing cached yet.
- [x] `DashboardBloc` rewritten to call the repository instead of emitting hardcoded fixtures; the Phase 1 dev-only "preview state" menu removed from `DashboardBloc`/`DashboardScreen` now that real data flows (per the Phase 1 plan note to remove it here). Pull-to-refresh added to the loaded view.
- [x] Verified end-to-end against the live mock server (`dart run bin/mock_server.dart`): employee/leave/attendance load correctly, offline-cache fallback works, and the widget smoke tests (seeded via Hive directly, no live server needed) all pass. The "empty/first-day" and "error/no-saved-data" states aren't separately coded — they fall out naturally from the same `DashboardLoaded`/`DashboardError` logic (no cached attendance yet vs. no cache *and* no network at all).

### Phase 5 — Attendance check-in/out (1.5h) ✅
- [x] `LocationService` (`lib/core/network/location_service.dart`, wraps `geolocator`): permission flow (denied / permanently denied / service-disabled → mapped to the existing `CheckInPermissionDenied`/`CheckInLocationUnavailable` states, no new UI states needed), `distanceBetween`, `openAppSettings`/`openLocationSettings` wired to the "Open settings" button.
- [x] Check-in screen wired to real location: office lat/lng/radius come from the cached `EmployeeDto` (Phase 3/4), distance from a real `Geolocator.getCurrentPosition()` fix. The Phase 1 dev-preview menu removed, matching the Phase 4 precedent.
- [x] `CheckInBloc` writes a locally-persisted `AttendanceEventDto` (UUID `eventId`, status `pendingSync`) via `AttendanceRepository.recordAttempt()` *before* any network call — the submit path never awaits the network, so it's unaffected by being offline or the app being killed right after. A best-effort immediate `syncAll()` fires in the background afterwards so an online user doesn't have to visit the Sync tab.
- [x] Enforced via `AttendanceRepository.mergedRecordForDay()`: check-out is blocked without an open (pending/synced, non-rejected) check-in for today; a second check-in is blocked while one is already open. Repeated taps still guarded by the existing synchronous-state-check pattern (no `bloc_concurrency` dependency).

### Phase 6 — Offline sync engine (1h) ✅
- [x] Sync queue screen wired to `AttendanceRepository.allEvents` — the `pending_events` box doubles as both the write-ahead queue and the activity log (entries are upserted with their latest status, never deleted, so a synced/rejected attempt stays visible as a record of what happened).
- [x] "Sync Now" (`SyncBloc`) + auto-sync-on-reconnect via `ConnectivityService.onStatusChange`. Events sync in original (timestamp) order.
- [x] `AttendanceRepository.syncAll()` POSTs with the event's `eventId` as the idempotency key.
- [x] Conflict handling: a 409 whose body echoes the *same* `eventId` is an idempotent replay → marked Synced (it already succeeded server-side); any other 409/422 → marked Rejected with the server's reason. On a timeout/5xx/connection error, re-checks via `GET /attendance/events/:eventId` before giving up — 404 (never reached the server) leaves it pending for the next attempt and keeps draining the rest of the queue; a still-unreachable server stops the run early rather than letting every remaining event time out too.
- [x] Badge count: `AttendanceRepository.pendingCount`, read by `DashboardRepository` (unchanged since Phase 4 — it was already wired to the same box, just via a different accessor).

### Phase 7 — Attendance history wiring (30–45 min) ✅
- [x] `AttendanceRepository.loadMonth()`: fetches/caches `/attendance?month=YYYY-MM` (offline-first, same pattern as Dashboard/Leave), merges in any local pending/rejected events for the current day via the same `mergedRecordForDay()` Check-in/Dashboard already use — one merge implementation, not three.

### Phase 8 — Leave feature wiring (1h) ✅
- [x] `LeaveRepository` (`lib/features/leave/data/leave_repository.dart`): balance + requests, offline-first cache, same shape as `DashboardRepository`.
- [x] Local validation mirrors the server: `overlapWarning()` checks the cached requests (Pending/Approved only) before submit; date-order, reason-length (≥10 chars) and balance checks already lived in `ApplyLeaveState` from Phase 1 and needed no changes, since the server re-validates all of them anyway and `ApplyLeaveBloc` surfaces its message via `submitError` distinctly from the inline local-validation text.
- [x] Submit requires connectivity: `ApplyLeaveState.isOffline` (set from a one-time check dispatched by the screen right after creating the bloc) disables Submit and swaps the footnote to an offline notice; `LeaveRepository.submit()` also guards server-side as a safety net. Returning from a successful submit re-fires `LeaveStarted` on the Leave tab's *existing* `LeaveBloc` (via the push's `bool` result — `/leave/apply` is a `parentNavigatorKey` route, so it isn't a descendant of `LeaveScreen`'s `BlocProvider` and can't just `context.read` it).

### Phase 9 — Required tests (1h) ✅
- [x] Check-out without check-in is rejected — `test/attendance_repository_test.dart`.
- [x] Repeated submission/retry does not create duplicate attendance (idempotency key test) — same file; also refactored `bin/mock_server.dart`'s logic into `lib/mock_server/mock_api_server.dart` (a `MockApiServer` class, state per-instance) so tests can start their own isolated, in-process server on an ephemeral port instead of needing a separately-running process.
- [x] Pending attendance survives persistence and syncs in order — same file (closes and reopens the Hive box mid-test to simulate an app restart).
- [x] Overlapping leave dates are rejected — `test/leave_repository_test.dart` (both the local pre-check and the server's own rejection).
- [x] Loading/error/pending-sync states — `test/dashboard_sync_states_widget_test.dart`.
- Also fixed in `test/widget_test.dart`: `CheckInBloc` now needs a fake `GeolocatorPlatform` (same reason the earlier Phase 4 work needed one for `connectivity_plus` — there's no desktop embedder to answer the platform channel under `flutter_tester`, and it hangs rather than throwing).

**Note on testing `flutter_tester` quirks hit along the way** (useful if this trips you up again): real `dart:io` async work (Hive, temp dirs) must happen in `setUp`/`setUpAll`, never inside a `testWidgets` body — that body runs in a fake-async zone where real IO never completes. And background test/server processes on Windows sometimes survive this harness's cancel signal; if `flutter test` or the mock server ever seems to hang for no reason, check for and kill stray `dart`/`dartaotruntime`/`flutter_tester` processes before assuming the code is at fault.

### Phase 10 — Polish, README, APK, demo video (45 min)
- [ ] README: architecture, setup, assumptions, completed features, limitations, time spent, device-side vs server-side validation notes, AI-tool disclosure.
- [ ] Build debug APK.
- [ ] Record 3–5 min demo per the assignment's required flow.

---

## 4. Notes / assumptions carried from the brief
- Single preconfigured employee, no login.
- One attendance session per day, no overnight shifts, configurable company timezone.
- All calendar days count as leave days (no weekend/holiday exclusion).
- Background execution while the app is terminated is out of scope — sync only runs while the app is open (foreground/resumed).
- Office coordinates configurable in code/config for reviewers to simulate locations (e.g. via emulator extended controls or a debug override).
