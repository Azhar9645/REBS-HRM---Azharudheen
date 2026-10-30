enum AttendanceEventType { checkIn, checkOut }

/// Sync status of a single check-in/out attempt. `pendingSync` only ever
/// exists locally, before the event has been POSTed successfully.
enum EventSyncStatus { pendingSync, synced, rejected }

AttendanceEventType _parseEventType(String value) =>
    value == 'checkIn' ? AttendanceEventType.checkIn : AttendanceEventType.checkOut;

EventSyncStatus _parseEventStatus(String? value) => switch (value) {
  'pendingSync' => EventSyncStatus.pendingSync,
  'rejected' => EventSyncStatus.rejected,
  _ => EventSyncStatus.synced,
};

/// A single check-in or check-out attempt. This is the write-ahead-log
/// entity persisted in the `pending_events` box before (and while) it is
/// synced to the server — see Phase 5/6.
class AttendanceEventDto {
  const AttendanceEventDto({
    required this.eventId,
    required this.type,
    required this.timestamp,
    required this.status,
    this.rejectionReason,
    this.latitude,
    this.longitude,
  });

  final String eventId;
  final AttendanceEventType type;
  final DateTime timestamp;
  final EventSyncStatus status;
  final String? rejectionReason;
  final double? latitude;
  final double? longitude;

  AttendanceEventDto copyWith({EventSyncStatus? status, String? rejectionReason}) =>
      AttendanceEventDto(
        eventId: eventId,
        type: type,
        timestamp: timestamp,
        status: status ?? this.status,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        latitude: latitude,
        longitude: longitude,
      );

  factory AttendanceEventDto.fromJson(Map<String, dynamic> json) =>
      AttendanceEventDto(
        eventId: json['eventId'] as String,
        type: _parseEventType(json['type'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: _parseEventStatus(json['status'] as String?),
        rejectionReason: json['rejectionReason'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'type': type == AttendanceEventType.checkIn ? 'checkIn' : 'checkOut',
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'rejectionReason': rejectionReason,
    'latitude': latitude,
    'longitude': longitude,
  };
}
