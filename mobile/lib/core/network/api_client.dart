import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  /// Uploads can be slow on mobile networks; they get a longer timeout.
  static const uploadTimeout = Duration(seconds: 60);

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) =>
      _json('GET', path, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    bool authenticated = false,
  }) => _json(
    'POST',
    path,
    body: body,
    headers: headers,
    authenticated: authenticated,
  );

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) => _json('PUT', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) => _json('PATCH', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = false,
  }) => _json('DELETE', path, authenticated: authenticated);

  /// Downloads a private file (always authenticated).
  Future<Uint8List> getBytes(String path) async {
    final response = await _send(
      () => http.Request('GET', Uri.parse('$_baseUrl$path')),
      authenticated: true,
      timeout: uploadTimeout,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    _throwError(response);
  }

  /// Sends one file as multipart/form-data. The server decides the type from the bytes.
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required Map<String, String> fields,
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _send(
      () {
        final request =
            http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
              ..fields.addAll(fields)
              ..files.add(
                http.MultipartFile.fromBytes('file', bytes, filename: filename),
              );
        return request;
      },
      authenticated: true,
      timeout: uploadTimeout,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
    required bool authenticated,
  }) async {
    final response = await _send(() {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'))
        ..headers.addAll(headers);
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      return request;
    }, authenticated: authenticated);
    return _decode(response);
  }

  /// Builds a fresh request per attempt (a request can only be sent once), adds auth, and
  /// retries once after refreshing the access token on a 401.
  Future<http.Response> _send(
    http.BaseRequest Function() build, {
    required bool authenticated,
    Duration? timeout,
    bool isRetry = false,
  }) async {
    final request = build()..headers['Accept'] = 'application/json';
    final token = authenticated ? tokenProvider?.accessToken : null;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout ?? this.timeout),
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
          build,
          authenticated: true,
          timeout: timeout,
          isRetry: true,
        );
      }
    }
    return response;
  }

  /// For a non-2xx response: throws the server's error (or a generic HTTP error).
  Never _throwError(http.Response response) {
    _decode(response);
    throw ApiException(
      code: 'HTTP_${response.statusCode}',
      statusCode: response.statusCode,
    );
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
