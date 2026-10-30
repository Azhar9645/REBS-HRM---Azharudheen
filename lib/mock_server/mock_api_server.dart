// Phase 2 mock API for REBS HRMS. See bin/mock_server.dart for how to run
// it standalone, and README.md for the endpoint/scenario reference.
//
// Lives under lib/ (not just bin/) so Phase 9 tests can start an isolated,
// in-process instance on an ephemeral port instead of shelling out to a
// separate server — each `MockApiServer()` has its own state, so parallel
// tests never see each other's data.

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class MockApiServer {
  MockApiServer({
    this.officeLatitude = defaultOfficeLatitude,
    this.officeLongitude = defaultOfficeLongitude,
    this.officeRadiusMeters = defaultOfficeRadiusMeters,
    String? dataFilePath,
  }) : _dataFile = dataFilePath == null ? null : File(dataFilePath) {
    if (!_load()) reset();
  }

  /// When set, attendance events and leave requests are saved here after
  /// every change and reloaded on start, so restarting the server doesn't
  /// forget today's check-in. Null (the default, used by tests) keeps
  /// everything in memory only.
  final File? _dataFile;

  // Kochi Campus (Technology Innovation Zone, Kalamassery). Override via
  // bin/mock_server.dart flags.
  static const defaultOfficeLatitude = 10.05566;
  static const defaultOfficeLongitude = 76.35416;
  static const defaultOfficeRadiusMeters = 200.0;

  final double officeLatitude;
  final double officeLongitude;
  final double officeRadiusMeters;

  static const _uuid = Uuid();

  static const _employee = {
    'employeeId': 'EMP-0142',
    'name': 'Azhar',
    'department': 'Developer',
  };

  // Demo login credentials for the Phase 2 mock API.
  static const _validEmployeeId = 'EMP-0142';
  static const _validPassword = 'welcome123';

  Map<String, double> get _office => {
    'latitude': officeLatitude,
    'longitude': officeLongitude,
    'radiusMeters': officeRadiusMeters,
  };

  static const _initialLeaveBalance = {'availableDays': 9, 'totalDays': 12};

  /// Scenario mode currently armed per endpoint group, settable via
  /// POST /debug/scenario and overridable per-call with ?simulate=.
  final Map<String, String> _scenario = {'attendance': 'success', 'leave': 'success'};

  List<Map<String, dynamic>> _attendanceEvents = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  HttpServer? _server;

  int? get port => _server?.port;

  Future<HttpServer> serve({int port = 0}) async {
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_buildRouter().call);
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    return _server!;
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Reseeds all in-memory data and clears armed scenarios.
  void reset() {
    final now = DateTime(2026, 10, 28);
    _attendanceEvents = [
      for (final offset in [1, 2, 5, 6])
        ..._dayEvents(now.subtract(Duration(days: offset)), 9, 0 + offset, 18, offset),
    ];
    _leaveRequests = [
      {
        'id': _uuid.v4(),
        'type': 'casual',
        'startDate': '2026-10-10',
        'endDate': '2026-10-11',
        'days': 2,
        'reason': 'Family function',
        'status': 'approved',
        'rejectionReason': null,
        'submittedAt': DateTime(2026, 10, 5).toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'type': 'sick',
        'startDate': '2026-09-14',
        'endDate': '2026-09-14',
        'days': 1,
        'reason': 'Fever',
        'status': 'rejected',
        'rejectionReason': 'Submitted after the leave date had passed.',
        'submittedAt': DateTime(2026, 9, 15).toIso8601String(),
      },
    ];
    _scenario['attendance'] = 'success';
    _scenario['leave'] = 'success';
    _save();
  }

  bool _load() {
    final file = _dataFile;
    if (file == null || !file.existsSync()) return false;
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      _attendanceEvents = [
        for (final e in data['attendanceEvents'] as List) Map<String, dynamic>.from(e as Map),
      ];
      _leaveRequests = [
        for (final r in data['leaveRequests'] as List) Map<String, dynamic>.from(r as Map),
      ];
      return true;
    } catch (e) {
      stderr.writeln('Could not read ${file.path} ($e). Starting with fresh demo data.');
      return false;
    }
  }

  void _save() {
    _dataFile?.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'attendanceEvents': _attendanceEvents,
        'leaveRequests': _leaveRequests,
      }),
    );
  }

  List<Map<String, dynamic>> _dayEvents(
    DateTime day,
    int inH,
    int inM,
    int outH,
    int outM,
  ) {
    final checkIn = DateTime(day.year, day.month, day.day, inH, inM);
    final checkOut = DateTime(day.year, day.month, day.day, outH, outM);
    return [
      {
        'eventId': _uuid.v4(),
        'type': 'checkIn',
        'timestamp': checkIn.toIso8601String(),
        'status': 'synced',
        'rejectionReason': null,
      },
      {
        'eventId': _uuid.v4(),
        'type': 'checkOut',
        'timestamp': checkOut.toIso8601String(),
        'status': 'synced',
        'rejectionReason': null,
      },
    ];
  }

  Response _json(Object? body, {int status = 200}) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  String _resolveMode(Request request, String group) =>
      request.url.queryParameters['simulate'] ?? _scenario[group] ?? 'success';

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Response> _postLogin(Request request) async {
    final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final employeeId = (payload['employeeId'] as String? ?? '').trim();
    final password = payload['password'] as String? ?? '';

    if (employeeId.isEmpty || password.isEmpty) {
      return _json({'error': 'employeeId and password are required'}, status: 400);
    }
    if (employeeId != _validEmployeeId || password != _validPassword) {
      return _json({'error': 'Invalid employee ID or password.'}, status: 401);
    }

    return _json({
      'token': _uuid.v4(),
      'employee': {..._employee, 'office': _office},
    });
  }

  Future<Response> _getEmployee(Request request) async =>
      _json({..._employee, 'office': _office});

  Future<Response> _getAttendance(Request request) async {
    final month = request.url.queryParameters['month'];
    final events = [..._attendanceEvents]
      ..sort(
        (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
      );

    final byDay = <String, Map<String, dynamic>>{};
    for (final event in events) {
      final ts = DateTime.parse(event['timestamp'] as String);
      final key = _dateKey(ts);
      if (month != null && !key.startsWith(month)) continue;
      final record = byDay.putIfAbsent(
        key,
        () => {
          'date': key,
          'checkInTime': null,
          'checkOutTime': null,
          'status': 'synced',
          'note': null,
        },
      );
      if (event['type'] == 'checkIn') {
        record['checkInTime'] = event['timestamp'];
      } else {
        record['checkOutTime'] = event['timestamp'];
      }
      if (event['status'] == 'pending' && record['status'] != 'rejected') {
        record['status'] = 'pending';
      } else if (event['status'] == 'rejected') {
        record['status'] = 'rejected';
        record['note'] = event['rejectionReason'];
      }
    }

    final records = byDay.values.toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return _json({'records': records});
  }

  Future<Response> _postAttendanceEvent(Request request) async {
    final mode = _resolveMode(request, 'attendance');
    final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final eventId = payload['eventId'] as String?;

    if (eventId == null || eventId.isEmpty) {
      return _json({'error': 'eventId is required'}, status: 400);
    }

    if (mode == 'slow') {
      await Future.delayed(const Duration(seconds: 4));
    } else if (mode == 'timeout') {
      await Future.delayed(const Duration(seconds: 20));
    } else if (mode == 'serverError') {
      return _json({'error': 'Internal server error, try again later.'}, status: 500);
    } else if (mode == 'duplicate') {
      return _json({'error': 'Event already recorded', 'eventId': eventId}, status: 409);
    }

    final existing = _attendanceEvents.firstWhere(
      (e) => e['eventId'] == eventId,
      orElse: () => const {},
    );
    if (existing.isNotEmpty) {
      // Idempotent replay: same eventId posted again returns the stored result.
      return _json(existing, status: 409);
    }

    final type = payload['type'] as String?;
    if (type != 'checkIn' && type != 'checkOut') {
      return _json({'error': 'type must be checkIn or checkOut'}, status: 400);
    }

    final timestamp = DateTime.tryParse(payload['timestamp'] as String? ?? '') ??
        DateTime.now();
    final todayKey = _dateKey(timestamp);
    final todaysEvents = _attendanceEvents.where(
      (e) => _dateKey(DateTime.parse(e['timestamp'] as String)) == todayKey,
    );
    final hasOpenCheckIn = todaysEvents.any((e) => e['type'] == 'checkIn');
    final hasCheckOut = todaysEvents.any((e) => e['type'] == 'checkOut');

    if (type == 'checkOut' && !hasOpenCheckIn) {
      return _json({'error': 'Cannot check out before checking in'}, status: 422);
    }
    if (type == 'checkIn' && hasOpenCheckIn && !hasCheckOut) {
      return _json({'error': 'Already checked in today'}, status: 409);
    }

    final record = {
      'eventId': eventId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'status': 'synced',
      'rejectionReason': null,
    };
    _attendanceEvents.add(record);
    _save();
    return _json(record, status: 201);
  }

  Future<Response> _getAttendanceEvent(Request request, String eventId) async {
    final event = _attendanceEvents.firstWhere(
      (e) => e['eventId'] == eventId,
      orElse: () => const {},
    );
    if (event.isEmpty) return _json({'error': 'Not found'}, status: 404);
    return _json(event);
  }

  Future<Response> _getLeave(Request request) async {
    final usedDays = _leaveRequests
        .where((r) => r['status'] == 'approved')
        .fold<int>(0, (sum, r) => sum + (r['days'] as int));
    final balance = {
      'availableDays': _initialLeaveBalance['totalDays']! - usedDays,
      'totalDays': _initialLeaveBalance['totalDays'],
    };
    final requests = [..._leaveRequests]
      ..sort((a, b) => (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    return _json({'balance': balance, 'requests': requests});
  }

  Future<Response> _postLeaveRequest(Request request) async {
    final mode = _resolveMode(request, 'leave');
    final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    if (mode == 'slow') {
      await Future.delayed(const Duration(seconds: 4));
    } else if (mode == 'timeout') {
      await Future.delayed(const Duration(seconds: 20));
    } else if (mode == 'serverError') {
      return _json({'error': 'Internal server error, try again later.'}, status: 500);
    } else if (mode == 'validationError') {
      return _json(
        {'error': 'This leave request could not be validated by the server.'},
        status: 422,
      );
    }

    final type = payload['type'] as String?;
    final startDate = DateTime.tryParse(payload['startDate'] as String? ?? '');
    final endDate = DateTime.tryParse(payload['endDate'] as String? ?? '');
    final reason = (payload['reason'] as String? ?? '').trim();

    if (type != 'casual' && type != 'sick') {
      return _json({'error': 'type must be casual or sick'}, status: 400);
    }
    if (startDate == null || endDate == null) {
      return _json({'error': 'startDate and endDate are required'}, status: 400);
    }
    if (endDate.isBefore(startDate)) {
      return _json({'error': 'endDate must not be before startDate'}, status: 422);
    }
    if (reason.length < 10) {
      return _json({'error': 'reason must be at least 10 characters'}, status: 422);
    }

    final requestedDays = endDate.difference(startDate).inDays + 1;

    final overlaps = _leaveRequests.any((r) {
      if (r['status'] == 'rejected') return false;
      final existingStart = DateTime.parse(r['startDate'] as String);
      final existingEnd = DateTime.parse(r['endDate'] as String);
      return !endDate.isBefore(existingStart) && !startDate.isAfter(existingEnd);
    });
    if (overlaps) {
      return _json({'error': 'This overlaps an existing leave request.'}, status: 422);
    }

    final usedDays = _leaveRequests
        .where((r) => r['status'] == 'approved')
        .fold<int>(0, (sum, r) => sum + (r['days'] as int));
    final availableDays = _initialLeaveBalance['totalDays']! - usedDays;
    if (requestedDays > availableDays) {
      return _json(
        {'error': 'Requested $requestedDays days exceeds your balance of $availableDays.'},
        status: 422,
      );
    }

    final record = {
      'id': _uuid.v4(),
      'type': type,
      'startDate': payload['startDate'],
      'endDate': payload['endDate'],
      'days': requestedDays,
      'reason': reason,
      'status': 'pending',
      'rejectionReason': null,
      'submittedAt': DateTime.now().toIso8601String(),
    };
    _leaveRequests.add(record);
    _save();
    return _json(record, status: 201);
  }

  Future<Response> _postDebugScenario(Request request) async {
    final payload = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final endpoint = payload['endpoint'] as String?;
    final mode = payload['mode'] as String?;
    if (endpoint == null || mode == null || !_scenario.containsKey(endpoint)) {
      return _json(
        {'error': 'endpoint must be one of ${_scenario.keys.toList()}, mode is required'},
        status: 400,
      );
    }
    _scenario[endpoint] = mode;
    return _json({'endpoint': endpoint, 'mode': mode});
  }

  Future<Response> _postDebugReset(Request request) async {
    reset();
    return _json({'reset': true});
  }

  Router _buildRouter() {
    final router = Router();
    router.post('/auth/login', _postLogin);
    router.get('/employee/me', _getEmployee);
    router.get('/attendance', _getAttendance);
    router.post('/attendance/events', _postAttendanceEvent);
    router.get('/attendance/events/<eventId>', _getAttendanceEvent);
    router.get('/leave', _getLeave);
    router.post('/leave/requests', _postLeaveRequest);
    router.post('/debug/scenario', _postDebugScenario);
    router.post('/debug/reset', _postDebugReset);
    return router;
  }
}
