// Phase 2 mock API server for REBS HRMS.
//
// Run:   dart run bin/mock_server.dart [port] [--lat=<deg>] [--lng=<deg>] [--radius=<m>]
//                                      [--data=<file>] [--fresh]
//   port      default 8080
//   --lat     office latitude   (default 10.05566 — Kochi Campus, TIZ Kalamassery)
//   --lng     office longitude  (default 76.35416)
//   --radius  check-in geofence radius in metres (default 200)
//   --data    file that keeps check-ins/leave across restarts
//             (default mock_server_data.json in the current folder)
//   --fresh   wipe that file and start again with the demo data
//
// Base URL from Android emulator: http://10.0.2.2:<port>
// Base URL from iOS simulator / desktop: http://localhost:<port>
// Base URL from a USB-connected phone: http://localhost:<port> after
//   `adb reverse tcp:<port> tcp:<port>` (see SETUP.md)
//
// Endpoints:
//   POST /auth/login
//   GET  /employee/me
//   GET  /attendance?month=YYYY-MM
//   POST /attendance/events
//   GET  /attendance/events/:eventId
//   GET  /leave
//   POST /leave/requests
//   POST /debug/scenario   { "endpoint": "attendance"|"leave", "mode": "..." }
//   POST /debug/reset
//
// Every mutating/slow endpoint honours an optional `simulate` query param
// (success | slow | timeout | serverError | duplicate | validationError),
// which overrides whatever was set via /debug/scenario for that one call.
// See README.md for the full scenario list and example curl commands.
//
// The actual server logic lives in lib/mock_server/mock_api_server.dart so
// Phase 9 tests can start their own isolated, in-process instance.

import 'dart:io';

import 'package:rebs_hrms/mock_server/mock_api_server.dart';

const _usage =
    'Usage: dart run bin/mock_server.dart [port] [--lat=<deg>] [--lng=<deg>] '
    '[--radius=<m>] [--data=<file>] [--fresh]';

void main(List<String> args) async {
  var port = 8080;
  var lat = MockApiServer.defaultOfficeLatitude;
  var lng = MockApiServer.defaultOfficeLongitude;
  var radius = MockApiServer.defaultOfficeRadiusMeters;
  var dataPath = 'mock_server_data.json';
  var fresh = false;

  for (final arg in args) {
    final (key, value) = arg.contains('=')
        ? (arg.substring(0, arg.indexOf('=')), arg.substring(arg.indexOf('=') + 1))
        : (arg, '');
    switch (key) {
      case '--lat':
        lat = _parse(arg, value, min: -90, max: 90);
      case '--lng':
        lng = _parse(arg, value, min: -180, max: 180);
      case '--radius':
        radius = _parse(arg, value, min: 1, max: 100000);
      case '--data':
        if (value.isEmpty) _fail('"--data" needs a file name, e.g. --data=my_data.json');
        dataPath = value;
      case '--fresh':
        fresh = true;
      case '--help' || '-h':
        stdout.writeln(_usage);
        return;
      default:
        final p = int.tryParse(arg);
        if (p == null) _fail('Unknown argument: $arg');
        port = p;
    }
  }

  final dataFile = File(dataPath);
  if (fresh && dataFile.existsSync()) dataFile.deleteSync();
  final resumed = dataFile.existsSync();

  final server = await MockApiServer(
    officeLatitude: lat,
    officeLongitude: lng,
    officeRadiusMeters: radius,
    dataFilePath: dataPath,
  ).serve(port: port);
  stdout.writeln('REBS HRMS mock API listening on http://${server.address.host}:${server.port}');
  stdout.writeln('Office: $lat, $lng (check-in radius ${radius.toStringAsFixed(0)} m)');
  stdout.writeln(
    resumed
        ? 'Data: loaded saved check-ins and leave from ${dataFile.absolute.path}'
        : 'Data: started with demo data, saving to ${dataFile.absolute.path}',
  );
  stdout.writeln('From Android emulator, use http://10.0.2.2:${server.port}. Ctrl+C to stop.');
}

double _parse(String arg, String value, {required double min, required double max}) {
  final v = double.tryParse(value);
  if (v == null || v < min || v > max) {
    _fail('Invalid value in "$arg" (expected a number between $min and $max).');
  }
  return v;
}

Never _fail(String message) {
  stderr.writeln(message);
  stderr.writeln(_usage);
  exit(64);
}
