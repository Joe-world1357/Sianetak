import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Supplies the current access token and can refresh it once after a 401.
abstract class AccessTokenProvider {
  String? get accessToken;

  /// Returns true if a new access token was obtained.
  Future<bool> refreshAccessToken();
}

/// Thin JSON-over-HTTP client. All failures surface as [ApiException].
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _http = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _http;
  final Duration timeout;
  AccessTokenProvider? tokenProvider;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) =>
      _send('GET', path, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
    bool isRetry = false,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final token = authenticated ? tokenProvider?.accessToken : null;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      );
    } on TimeoutException {
      throw const ApiException(code: ApiException.network);
    } on http.ClientException {
      throw const ApiException(code: ApiException.network);
    }

    if (response.statusCode == 401 &&
        authenticated &&
        !isRetry &&
        tokenProvider != null) {
      if (await tokenProvider!.refreshAccessToken()) {
        return _send(
          method,
          path,
          body: body,
          authenticated: true,
          isRetry: true,
        );
      }
    }
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    Object? json;
    if (response.bodyBytes.isNotEmpty) {
      try {
        json = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiException(code: ApiException.badResponse, statusCode: status);
      }
    }
    if (status >= 200 && status < 300) {
      if (json == null) return const {};
      if (json is Map<String, dynamic>) return json;
      throw ApiException(code: ApiException.badResponse, statusCode: status);
    }
    final error = json is Map<String, dynamic> ? json['error'] : null;
    if (error is Map<String, dynamic>) {
      final details = error['details'];
      throw ApiException(
        code: error['code'] as String? ?? 'UNKNOWN',
        statusCode: status,
        message: error['message'] as String?,
        details: details is Map<String, dynamic> ? details : const {},
      );
    }
    throw ApiException(code: 'HTTP_$status', statusCode: status);
  }
}
