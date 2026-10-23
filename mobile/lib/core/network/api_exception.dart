/// A failed API call, carrying the server's stable error `code` (see backend `ErrorCode`).
class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.statusCode,
    this.message,
    this.details = const {},
  });

  /// No response from the server (offline, DNS, timeout, connection refused).
  static const network = 'NETWORK_ERROR';

  /// The response could not be understood.
  static const badResponse = 'BAD_RESPONSE';

  final String code;
  final int? statusCode;
  final String? message;
  final Map<String, dynamic> details;

  int? intDetail(String key) {
    final value = details[key];
    return value is int ? value : null;
  }

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($code, status: $statusCode)';
}
