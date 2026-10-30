/// Thrown by [ApiClient] for any failed request. [statusCode] is null for
/// connectivity/timeout failures that never got an HTTP response. [data] is
/// the decoded response body, when there was one — e.g. a 409 idempotent
/// replay still carries the original event, which callers may want.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}
