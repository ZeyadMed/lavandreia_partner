import 'package:dio/dio.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';

/// بيتولى تجديد الـ accessToken باستخدام الـ refreshToken.
///
/// بيستخدم Dio مستقل (من غير الانترسبتور) عشان لو التجديد نفسه رجع 401
/// مايدخلش في لوب لا نهائي بيحاول يجدد التجديد.
class TokenRefreshService {
  TokenRefreshService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Endpoints.baseUrl,
              connectTimeout: const Duration(seconds: 60),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Accept-Encoding': 'identity',
                'Accept-Language': 'ar',
              },
            ),
          );

  final Dio _dio;

  /// لو فيه تجديد شغال بالفعل، أي ريكوست تاني بيستنى نفس النتيجة
  /// بدل ما نبعت كذا طلب تجديد في نفس الوقت ونحرق الـ refresh token.
  Future<String?>? _ongoingRefresh;

  bool get hasRefreshToken {
    final token = CacheManager.getRefreshTokenSync();
    return token != null && token.isNotEmpty;
  }

  /// بترجع accessToken جديد، أو null لو التجديد فشل.
  /// المكالمات المتوازية بتشارك نفس العملية.
  Future<String?> refresh() {
    return _ongoingRefresh ??= _performRefresh().whenComplete(() {
      _ongoingRefresh = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = CacheManager.getRefreshTokenSync();
    if (refreshToken == null || refreshToken.isEmpty) {
      loggerWarn('Refresh skipped: no refresh token stored');
      return null;
    }

    try {
      final response = await _dio.post(
        Endpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data is! Map) {
        loggerError('Refresh failed: unexpected response shape');
        return null;
      }

      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        loggerError('Refresh failed: response had no accessToken');
        return null;
      }

      // الباك اند بيدوّر الـ refresh token، فلو رجع واحد جديد لازم نحفظه
      // وإلا الطلب الجاي هيستخدم توكن محروق.
      await CacheManager.saveTokens(
        accessToken: newAccessToken,
        refreshToken: (newRefreshToken != null && newRefreshToken.isNotEmpty)
            ? newRefreshToken
            : refreshToken,
      );

      logger('Access token refreshed');
      return newAccessToken;
    } on DioException catch (e) {
      loggerError('Refresh request failed: ${e.response?.statusCode} $e');
      return null;
    } catch (e) {
      loggerError('Refresh request failed: $e');
      return null;
    }
  }
}
