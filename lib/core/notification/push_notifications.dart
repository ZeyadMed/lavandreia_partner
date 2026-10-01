import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/realtime/realtime_service.dart';
import 'package:lavanderia_partner/features/notifications/presentation/view/notifications_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/main.dart';

/// إشعارات الـ push من FCM، زي OrderCreated و TripRequested و AdjustmentResolved
/// أي إشعار بيحدّث ليستات الطلبات، واللي فيه orderId بيحدّث الطلب لو مفتوح،
/// والضغط عليه بيفتح تفاصيل الطلب، ولو مفيش orderId بيفتح صفحة الإشعارات
/// والأبلكيشن مفتوح والـ realtime متصل، الحدث بيوصل منه فالإشعار مابيظهرش
abstract final class PushNotifications {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Channel',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// الأبلكيشن اتفتح من إشعار وهو مقفول خالص، و [_pendingOrderId] الطلب بتاعه
  /// بيتفتح لما الرئيسية تظهر، عشان السبلاش مايغطيش عليه
  static bool _hasPendingOpen = false;
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
    // قبل الـ fetch، عشان لو الـ APNs token اتأخر الـ FCM token يوصل من هنا
    messaging.onTokenRefresh.listen(CacheManager.saveFcmTokenToken);
    unawaited(CacheManager.fetchAndSaveFcmToken());
    // والأبلكيشن مفتوح إحنا اللي بنظهر الإشعار في الاتنين، عشان مايظهرش
    // لو الـ realtime متصل ووصّل نفس الحدث
    await messaging
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
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

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _openOrder(_orderIdOf(message)),
    );

    final initialMessage = await messaging.getInitialMessage().timeout(timeout);
    if (initialMessage == null) return;
    _hasPendingOpen = true;
    _pendingOrderId = _orderIdOf(initialMessage);
    // لو الرئيسية ظهرت قبل ما الإشعار يوصل
    if (_isHomeReady) openPendingOrder();
  }

  /// بتتنادى من الرئيسية أول ما تظهر
  static void openPendingOrder() {
    _isHomeReady = true;
    if (!_hasPendingOpen) return;
    final orderId = _pendingOrderId;
    _hasPendingOpen = false;
    _pendingOrderId = null;
    _openOrder(orderId);
  }

  /// الـ data فيها نفس حقول الإشعار المحفوظ: { "type", "orderId", "deliveryTripId" }
  static int? _orderIdOf(RemoteMessage message) =>
      int.tryParse('${message.data['orderId'] ?? ''}');

  static void _onForegroundMessage(RemoteMessage message) {
    logger('Push received: ${message.data}');
    // الحدث نفسه وصل من الـ realtime واتعرض جوه الأبلكيشن
    if (RealtimeService.isLive) return;

    final orderId = _orderIdOf(message);
    OrdersCubit.notifyServerChanged(orderId);

    final notification = message.notification;
    if (notification == null) return;
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: orderId?.toString(),
    );
  }

  /// الـ push لسه مش فيه data، فمن غير orderId بنفتح ليستة الإشعارات
  static void _openOrder(int? orderId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    if (orderId != null) {
      openOrderDetailsById(context, orderId);
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
