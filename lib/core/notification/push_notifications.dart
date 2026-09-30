import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/main.dart';

/// إشعارات الـ push من FCM، زي OrderCreated و TripRequested و AdjustmentResolved
/// أي إشعار بيحدّث ليستات الطلبات، واللي فيه orderId بيحدّث الطلب لو مفتوح،
/// والضغط عليه بيفتح تفاصيل الطلب
abstract final class PushNotifications {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Channel',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// الطلب اللي الأبلكيشن اتفتح من الإشعار بتاعه وهو مقفول خالص
  /// بيتفتح لما الرئيسية تظهر، عشان السبلاش مايغطيش عليه
  static int? _pendingOrderId;

  /// الرئيسية ظهرت، فأي طلب جاي من إشعار يتفتح على طول
  static bool _isHomeReady = false;

  /// كل خطوة ليها timeout عشان لو حاجة من Firebase علّقت
  /// الإشعارات بس هي اللي تقف، مش الأبلكيشن
  static Future<void> init() async {
    try {
      await _init();
    } catch (e, stackTrace) {
      loggerError(stackTrace);
      loggerWarn('Push notifications init failed: $e');
    }
  }

  static Future<void> _init() async {
    const timeout = Duration(seconds: 10);
    final messaging = FirebaseMessaging.instance;
    // الإذن الأول، لأن iOS مش بيدي الـ APNs token من غيره
    await messaging.requestPermission().timeout(const Duration(minutes: 1));
    unawaited(CacheManager.fetchAndSaveFcmToken());
    // في iOS الإشعار بيظهر لوحده والأبلكيشن مفتوح، في أندرويد بنظهره إحنا
    await messaging
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        )
        .timeout(timeout);

    await _localNotifications
        .initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            // الإذن اتطلب خلاص من FCM فوق
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (response) =>
              _openOrder(int.tryParse(response.payload ?? '')),
        )
        .timeout(timeout);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    messaging.onTokenRefresh.listen(CacheManager.saveFcmTokenToken);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _openOrder(_orderIdOf(message)),
    );

    final initialMessage = await messaging.getInitialMessage().timeout(timeout);
    if (initialMessage == null) return;
    _pendingOrderId = _orderIdOf(initialMessage);
    // لو الرئيسية ظهرت قبل ما الإشعار يوصل
    if (_isHomeReady) openPendingOrder();
  }

  /// بتتنادى من الرئيسية أول ما تظهر
  static void openPendingOrder() {
    _isHomeReady = true;
    final orderId = _pendingOrderId;
    _pendingOrderId = null;
    _openOrder(orderId);
  }

  /// الـ data فيها نفس حقول الإشعار المحفوظ: { "type", "orderId", "deliveryTripId" }
  static int? _orderIdOf(RemoteMessage message) =>
      int.tryParse('${message.data['orderId'] ?? ''}');

  static void _onForegroundMessage(RemoteMessage message) {
    logger('Push received: ${message.data}');
    final orderId = _orderIdOf(message);
    OrdersCubit.notifyServerChanged(orderId);

    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) return;
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: orderId?.toString(),
    );
  }

  static void _openOrder(int? orderId) {
    final context = navigatorKey.currentContext;
    if (orderId == null || context == null) return;
    openOrderDetailsById(context, orderId);
  }
}
