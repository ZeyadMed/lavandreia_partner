import 'package:dio/dio.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';

/// نتيجة التجديد: لازم نفرّق بين إن الـ refresh token نفسه اترفض
/// (الجلسة انتهت فعلاً) وبين إن التجديد وقع بسبب النت أو السيرفر.
sealed class RefreshResult {
  const RefreshResult();
}

/// اتجدد بنجاح وده الـ accessToken الجديد
final class RefreshSuccess extends RefreshResult {
  const RefreshSuccess(this.accessToken);
  final String accessToken;
}

/// السيرفر رفض الـ refresh token أو مفيش واحد محفوظ، يعني الجلسة انتهت
final class RefreshInvalid extends RefreshResult {
  const RefreshInvalid();
}

/// فشل مؤقت (نت، timeout، 5xx) — الـ refresh token لسه سليم فمانمسحوش
final class RefreshTransientFailure extends RefreshResult {
  const RefreshTransientFailure();
}

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
  Future<RefreshResult>? _ongoingRefresh;

  bool get hasRefreshToken {
    final token = CacheManager.getRefreshTokenSync();
    return token != null && token.isNotEmpty;
  }

  /// المكالمات المتوازية بتشارك نفس العملية.
  Future<RefreshResult> refresh() {
    return _ongoingRefresh ??= _performRefresh().whenComplete(() {
      _ongoingRefresh = null;
    });
  }

  Future<RefreshResult> _performRefresh() async {
    final refreshToken = CacheManager.getRefreshTokenSync();
    if (refreshToken == null || refreshToken.isEmpty) {
      loggerWarn('Refresh skipped: no refresh token stored');
      return const RefreshInvalid();
    }

    try {
      final response = await _dio.post(
        Endpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data is! Map) {
        loggerError('Refresh failed: unexpected response shape');
        return const RefreshTransientFailure();
      }

      // التوكنز ممكن تيجي في أول الريسبونس أو جوه data زي اللوجين
      final payload = data['data'] is Map ? data['data'] as Map : data;
      final newAccessToken = payload['accessToken'] as String?;
      final newRefreshToken = payload['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        loggerError('Refresh failed: response had no accessToken');
        return const RefreshTransientFailure();
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
      return RefreshSuccess(newAccessToken);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      loggerError('Refresh request failed: $statusCode $e');
      // بس رفض صريح من السيرفر يعني الجلسة انتهت، غير كده نحتفظ بالتوكنز
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        return const RefreshInvalid();
      }
      return const RefreshTransientFailure();
    } catch (e) {
      loggerError('Refresh request failed: $e');
      return const RefreshTransientFailure();
    }
  }
}
