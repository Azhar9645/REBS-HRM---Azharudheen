import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'api_exception.dart';

/// Thin wrapper around the Phase 2 mock API (`bin/mock_server.dart`).
/// Returns decoded JSON maps; callers parse them into DTOs.
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  final Dio _dio;

  Future<Map<String, dynamic>> login(String employeeId, String password) =>
      _post('/auth/login', {'employeeId': employeeId, 'password': password});

  Future<Map<String, dynamic>> getEmployee() => _get('/employee/me');

  Future<Map<String, dynamic>> getAttendance({String? month}) =>
      _get('/attendance', query: month == null ? null : {'month': month});

  Future<Map<String, dynamic>> postAttendanceEvent(Map<String, dynamic> body) =>
      _post('/attendance/events', body);

  Future<Map<String, dynamic>> getAttendanceEvent(String eventId) =>
      _get('/attendance/events/$eventId');

  Future<Map<String, dynamic>> getLeave() => _get('/leave');

  Future<Map<String, dynamic>> postLeaveRequest(Map<String, dynamic> body) =>
      _post('/leave/requests', body);

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final body = data is Map ? Map<String, dynamic>.from(data) : null;
    final serverMessage = body?['error'] as String?;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('The server took too long to respond.', statusCode: statusCode, data: body);
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException("Couldn't reach the server.", statusCode: statusCode, data: body);
    }
    return ApiException(
      serverMessage ?? 'Something went wrong talking to the server.',
      statusCode: statusCode,
      data: body,
    );
  }
}
