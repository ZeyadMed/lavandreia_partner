import 'package:dio/dio.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/token_refresh_service.dart';

/// بيحط الـ accessToken على كل ريكوست، ولما ييجي 401 بيجدده
/// بالـ refreshToken ويعيد الريكوست تاني من غير ما المستخدم يحس.
///
/// كده التوكن بيتقرا من الكاش وقت الطلب نفسه، مش وقت تسجيل الـ Dio،
/// فبعد اللوجين مش محتاجين نعمل reset للـ DI عشان الهيدر يتحدث.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenRefreshService refreshService,
  }) : _dio = dio,
       _refreshService = refreshService;

  final Dio _dio;
  final TokenRefreshService _refreshService;

  static const _retriedFlag = 'auth_interceptor_retried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // طلب التجديد نفسه بياخد التوكن في الـ body مش في الهيدر
    if (options.path.contains(Endpoints.refreshToken)) {
      return handler.next(options);
    }

    final accessToken = await CacheManager.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    final isUnauthorized = statusCode == 401;
    final isRefreshCall = requestOptions.path.contains(Endpoints.refreshToken);
    final alreadyRetried = requestOptions.extra[_retriedFlag] == true;

    // بنجدد مرة واحدة بس لكل ريكوست، وماننجددش لطلب التجديد نفسه
    if (!isUnauthorized || isRefreshCall || alreadyRetried) {
      return handler.next(err);
    }

    if (!_refreshService.hasRefreshToken) {
      loggerWarn('Got 401 with no refresh token stored');
      await _expireSession();
      return handler.next(err);
    }

    final newAccessToken = await _refreshService.refresh();
    if (newAccessToken == null) {
      loggerWarn('Refresh failed, session expired');
      await _expireSession();
      return handler.next(err);
    }

    try {
      final retried = await _retry(requestOptions, newAccessToken);
      return handler.resolve(retried);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    return _dio.fetch(
      requestOptions
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..extra[_retriedFlag] = true,
    );
  }

  /// بنمسح التوكنز بس، والتوجيه للوجين بيحصل في `_handleDioError`
  /// لما الـ 401 يوصله بعد ما التجديد فشل — عشان مايبقاش فيه مسارين
  /// بيبعتوا المستخدم على اللوجين في نفس الوقت.
  Future<void> _expireSession() async {
    await CacheManager.clearTokens();
  }
}
