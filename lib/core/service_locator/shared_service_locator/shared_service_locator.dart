import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:lavanderia_partner/core/helpers/location_service.dart';
import 'package:lavanderia_partner/core/http/api_consumer.dart';
import 'package:lavanderia_partner/core/http/auth_interceptor.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/token_refresh_service.dart';
// import 'package:lavanderia_partner/features/home/presentation/view_model/location_controller.dart';
// import 'package:lavanderia_partner/features/laundry_details/presentation/view_model/selected_services_controller.dart';

class SharedServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    getIt.registerLazySingleton<TokenRefreshService>(
      () => TokenRefreshService(),
    );

    getIt.registerLazySingleton<Dio>(() {
      final dio = Dio(
        BaseOptions(
          baseUrl: Endpoints.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            // Disable gzip/deflate from server to avoid malformed compressed responses
            'Accept-Encoding': 'identity',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Accept-Language': 'ar',
            //  AppRouter.router.configuration.navigatorKey
            //             .currentContext?.isArabic ??
            //         false
            //     ? 'ar'
            //     : 'en',
          },
        ),
      );

      // الـ Authorization بقى بيتحط في الانترسبتور وقت كل ريكوست،
      // مش هنا وقت التسجيل، عشان ياخد أحدث توكن بعد اللوجين أو التجديد.
      dio.interceptors.add(
        AuthInterceptor(dio: dio, refreshService: getIt<TokenRefreshService>()),
      );

      if (kDebugMode) {
        dio.interceptors.add(
          PrettyDioLogger(
            logPrint: (object) {
              log(object.toString());
            },
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            compact: true,
            enabled: true,
            request: true,
            maxWidth: 90,
          ),
        );
      }

      return dio;
    });
    getIt.registerLazySingleton<ApiConsumer>(
      () => BaseApiConsumer(dio: getIt<Dio>()),
    );

    getIt.registerLazySingleton<LocationService>(() => LocationService());

    // singleton مش lazy عشان العنوان يفضل محفوظ ويتشارك بين الشاشات
    // فأي شاشة تانية (زي تأكيد الطلب) تقرا نفس العنوان من غير ما تجيبه تاني
    // getIt.registerLazySingleton<LocationController>(
    //   () => LocationController(service: getIt<LocationService>()),
    // );

    // السلة singleton عشان تفضل عايشة بعد ما تخرج من شاشة تفاصيل المغسلة
    // فتاب السلة في البوتوم ناف يقرا من نفس الحاجات اللي اتضافت
    // getIt.registerLazySingleton<SelectedServicesController>(
    //   () => SelectedServicesController(),
    // );

    // getIt.registerLazySingleton<PusherConsumer>(() => PusherConsumerImpl(appKey: "69d83bf354bcf8c0a712",cluster:"mt1" ));
    // getIt.registerLazySingleton<LocalNotificationConsumer>(() => LocalNotificationServiceImpl()..initialize());
    // getIt.registerLazySingleton<FirebaseService>(() => FirebaseService(getIt()));
    // getIt<FirebaseService>().initializeFirebaseMessaging();
  }
}
