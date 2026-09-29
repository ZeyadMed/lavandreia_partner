import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/http/auth_interceptor.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/token_refresh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Handler = Future<ResponseBody> Function(RequestOptions options);

/// adapter وهمي بيرد حسب الدالة اللي بنديهاله
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final _Handler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // لازم نستهلك الـ stream عشان الـ FormData يتقفل زي الحقيقة
    if (requestStream != null) await requestStream.drain<void>();
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Dio _dio(_Handler handler) =>
    Dio(BaseOptions(baseUrl: Endpoints.baseUrl))
      ..httpClientAdapter = _FakeAdapter(handler);

void main() {
  late int refreshCalls;

  Future<void> seedTokens() async {
    SharedPreferences.setMockInitialValues({
      'token': 'old',
      'refreshToken': 'r1',
    });
    await CacheManager.init();
  }

  TokenRefreshService refreshService(_Handler handler) =>
      TokenRefreshService(dio: _dio(handler));

  Dio apiDio(_Handler api, TokenRefreshService service) {
    final dio = _dio(api);
    dio.interceptors.add(AuthInterceptor(dio: dio, refreshService: service));
    return dio;
  }

  /// بيرجع 401 لأي ريكوست بالتوكن القديم، وبعد كده يطبق [onNew]
  _Handler rejectOld(_Handler onNew) => (o) async =>
      o.headers['Authorization'] == 'Bearer old' ? _json(401, null) : onNew(o);

  setUp(() async {
    refreshCalls = 0;
    await seedTokens();
  });

  _Handler refreshOk({bool wrapped = false}) => (o) async {
    refreshCalls++;
    final tokens = {'accessToken': 'new', 'refreshToken': 'r2'};
    return _json(200, wrapped ? {'data': tokens} : tokens);
  };

  test('401 → refresh → retry succeeds', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(200, {'ok': true})),
      refreshService(refreshOk()),
    );
    final res = await dio.get('api/laundry/profile');
    expect(res.data, {'ok': true});
    expect(await CacheManager.getAccessToken(), 'new');
    expect(CacheManager.getRefreshTokenSync(), 'r2');
  });

  test('refresh response wrapped in data is parsed', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(200, {'ok': true})),
      refreshService(refreshOk(wrapped: true)),
    );
    await dio.get('api/laundry/profile');
    expect(await CacheManager.getAccessToken(), 'new');
  });

  test('failing retry completes with error instead of hanging', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(500, {'message': 'boom'})),
      refreshService(refreshOk()),
    );
    await expectLater(
      dio.get('api/laundry/profile').timeout(const Duration(seconds: 2)),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
  });

  test('parallel 401s share a single refresh', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(200, {'ok': true})),
      refreshService(refreshOk()),
    );
    await Future.wait([
      dio.get('api/laundry/profile'),
      dio.get('api/laundry/orders'),
      dio.get('api/laundry/wallet'),
    ]);
    expect(refreshCalls, 1);
  });

  test('network failure during refresh keeps tokens', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(200, {})),
      refreshService(
        (o) async => throw DioException.connectionError(
          requestOptions: o,
          reason: 'offline',
        ),
      ),
    );
    final err = await dio
        .get('api/laundry/profile')
        .then<DioException?>((_) => null, onError: (e) => e as DioException);
    expect(err?.response?.statusCode, 401);
    expect(err?.requestOptions.extra[AuthInterceptor.sessionExpiredFlag], isNot(true));
    expect(CacheManager.getRefreshTokenSync(), 'r1');
  });

  test('rejected refresh clears tokens and flags session expired', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(200, {})),
      refreshService((o) async => _json(401, null)),
    );
    final err = await dio
        .get('api/laundry/profile')
        .then<DioException?>((_) => null, onError: (e) => e as DioException);
    expect(err?.requestOptions.extra[AuthInterceptor.sessionExpiredFlag], true);
    expect(CacheManager.getRefreshTokenSync(), isNull);
  });

  test('401 from login does not refresh or expire session', () async {
    final dio = apiDio(
      (o) async => _json(401, {'message': 'wrong password'}),
      refreshService(refreshOk()),
    );
    await expectLater(dio.post(Endpoints.login), throwsA(isA<DioException>()));
    expect(refreshCalls, 0);
    expect(CacheManager.getRefreshTokenSync(), 'r1');
  });

  test('FormData request can be retried after refresh', () async {
    final dio = apiDio(
      rejectOld((o) async => _json(200, {'ok': true})),
      refreshService(refreshOk()),
    );
    final res = await dio.post(
      'api/laundry/profile',
      data: FormData.fromMap({'name': 'x'}),
    );
    expect(res.data, {'ok': true});
  });
}
