import 'dart:convert';

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
}
