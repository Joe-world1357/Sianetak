import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sianetak_customer/core/network/api_client.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';

class _Tokens implements AccessTokenProvider {
  _Tokens(this._token);
  String? _token;
  int refreshes = 0;
  bool refreshSucceeds = true;

  @override
  String? get accessToken => _token;

  @override
  Future<bool> refreshAccessToken() async {
    refreshes++;
    if (!refreshSucceeds) return false;
    _token = 'new-token';
    return true;
  }
}

http.Response json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('parses a successful JSON response', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test/api/v1/',
      httpClient: MockClient((r) async {
        expect(r.url.toString(), 'http://api.test/api/v1/catalog/categories');
        return json({'items': []}, 200);
      }),
    );
    expect(await api.get('/catalog/categories'), {'items': <Object>[]});
  });

  test(
    'turns an error body into an ApiException with code and details',
    () async {
      final api = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient(
          (_) async => json({
            'error': {
              'code': 'OTP_INVALID',
              'message': 'The code is incorrect',
              'details': {'attemptsRemaining': 3},
            },
          }, 400),
        ),
      );
      await expectLater(
        api.post('/auth/otp/verify'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'OTP_INVALID')
              .having((e) => e.statusCode, 'status', 400)
              .having((e) => e.intDetail('attemptsRemaining'), 'detail', 3),
        ),
      );
    },
  );

  test('reports connection failures as network errors', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient(
        (_) async => throw http.ClientException('offline'),
      ),
    );
    await expectLater(
      api.get('/catalog/categories'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', ApiException.network),
      ),
    );
  });

  test('reports a non-JSON body as a bad response', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient(
        (_) async => http.Response('<html>502</html>', 502),
      ),
    );
    await expectLater(
      api.get('/catalog/categories'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiException.badResponse,
        ),
      ),
    );
  });

  test('sends the bearer token and retries once after a 401', () async {
    final tokens = _Tokens('old-token');
    final sent = <String?>[];
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        sent.add(r.headers['Authorization']);
        return sent.length == 1
            ? json({
                'error': {'code': 'UNAUTHENTICATED'},
              }, 401)
            : json({'id': 'u1'}, 200);
      }),
    )..tokenProvider = tokens;

    expect(await api.get('/me', authenticated: true), {'id': 'u1'});
    expect(sent, ['Bearer old-token', 'Bearer new-token']);
    expect(tokens.refreshes, 1);
  });

  test('does not retry when the refresh fails, and surfaces the 401', () async {
    final tokens = _Tokens('old-token')..refreshSucceeds = false;
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((_) async {
        calls++;
        return json({
          'error': {'code': 'UNAUTHENTICATED'},
        }, 401);
      }),
    )..tokenProvider = tokens;

    await expectLater(
      api.get('/me', authenticated: true),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHENTICATED'),
      ),
    );
    expect(calls, 1);
  });

  test('never attaches a token to guest requests', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        expect(r.headers.containsKey('Authorization'), isFalse);
        return json({'items': []}, 200);
      }),
    )..tokenProvider = _Tokens('secret');
    await api.get('/catalog/categories');
  });

  test('sends extra headers such as the idempotency key', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        expect(r.method, 'POST');
        expect(r.headers['Idempotency-Key'], 'key-1');
        expect(r.headers['Authorization'], 'Bearer secret');
        expect(jsonDecode(r.body), {'a': 1});
        return json({'id': 'r1'}, 201);
      }),
    )..tokenProvider = _Tokens('secret');
    expect(
      await api.post(
        '/requests',
        body: {'a': 1},
        headers: {'Idempotency-Key': 'key-1'},
        authenticated: true,
      ),
      {'id': 'r1'},
    );
  });

  test('uploads a file as authenticated multipart form data', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        expect(r.method, 'POST');
        expect(r.headers['Authorization'], 'Bearer secret');
        expect(r.headers['content-type'], startsWith('multipart/form-data'));
        final body = utf8.decode(r.bodyBytes, allowMalformed: true);
        expect(body, contains('name="purpose"'));
        expect(body, contains('request_photo'));
        expect(body, contains('filename="photo.jpg"'));
        return json({'id': 'm1', 'contentType': 'image/jpeg'}, 201);
      }),
    )..tokenProvider = _Tokens('secret');
    final result = await api.uploadFile(
      '/media',
      fields: {'purpose': 'request_photo'},
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'photo.jpg',
    );
    expect(result['id'], 'm1');
  });

  test('downloads private bytes with credentials and maps a 404', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        expect(r.headers['Authorization'], 'Bearer secret');
        if (r.url.path.endsWith('/missing/content')) {
          return json({
            'error': {'code': 'MEDIA_NOT_FOUND', 'message': 'x'},
          }, 404);
        }
        return http.Response.bytes([7, 8, 9], 200);
      }),
    )..tokenProvider = _Tokens('secret');
    expect(await api.getBytes('/media/m1/content'), [7, 8, 9]);
    await expectLater(
      api.getBytes('/media/missing/content'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'MEDIA_NOT_FOUND'),
      ),
    );
  });

  test('a 204 delete succeeds without a body', () async {
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        expect(r.method, 'DELETE');
        return http.Response('', 204);
      }),
    )..tokenProvider = _Tokens('secret');
    await api.delete('/me/addresses/a1', authenticated: true);
  });
}
