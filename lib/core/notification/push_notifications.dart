import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/realtime/realtime_service.dart';
import 'package:lavanderia_partner/features/notifications/presentation/view/notifications_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_offers_sheet.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/driver_offers_cubit.dart';
import 'package:lavanderia_partner/main.dart';

/// إشعارات الـ push من FCM، زي OrderCreated و TripRequested و AdjustmentResolved
/// أي إشعار بيحدّث ليستات الطلبات، واللي فيه orderId بيحدّث الطلب لو مفتوح،
/// والضغط عليه بيفتح تفاصيل الطلب، ولو مفيش orderId بيفتح صفحة الإشعارات
/// و TripRequested بيفتح شيت عروض الدليفرية على الرحلة بتاعته
/// والأبلكيشن مفتوح والـ realtime متصل، الحدث بيوصل منه فالإشعار مابيظهرش
abstract final class PushNotifications {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// القناة دي كمان default_notification_channel_id في الـ AndroidManifest،
  /// فإشعارات السيرفر وإحنا في الخلفية بتظهر فوق الشاشة وبصوت التنبيه
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'laundry_alerts',
    'تنبيهات الطلبات والمندوبين',
    description: 'الطلبات الجديدة وعروض المندوبين وتحديثات الطلبات',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('driver_offer'),
  );

  /// القناة القديمة من غير صوت، بنشيلها عشان ماتفضلش في إعدادات الموبايل
  static const String _oldChannelId = 'high_importance_channel';

  /// الأبلكيشن اتفتح من إشعار وهو مقفول خالص، و [_pendingData] بتاعه
  /// بيتفتح لما الرئيسية تظهر، عشان السبلاش مايغطيش عليه
  static bool _hasPendingOpen = false;
  static Map<String, dynamic> _pendingData = const {};

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
              _open(_payloadData(response.payload)),
        )
        .timeout(timeout);
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    await android?.deleteNotificationChannel(_oldChannelId);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _open(message.data),
    );

    final initialMessage = await messaging.getInitialMessage().timeout(timeout);
    if (initialMessage == null) return;
    _hasPendingOpen = true;
    _pendingData = initialMessage.data;
    // لو الرئيسية ظهرت قبل ما الإشعار يوصل
    if (_isHomeReady) openPendingOrder();
  }

  /// بتتنادى من الرئيسية أول ما تظهر
  static void openPendingOrder() {
    _isHomeReady = true;
    if (!_hasPendingOpen) return;
    final data = _pendingData;
    _hasPendingOpen = false;
    _pendingData = const {};
    _open(data);
  }

  /// الـ data فيها نفس حقول الإشعار المحفوظ: { "type", "orderId", "deliveryTripId" }
  static int? _orderIdOf(Map<String, dynamic> data) =>
      int.tryParse('${data['orderId'] ?? ''}');

  /// رحلة إشعار TripRequested، و null لأي إشعار تاني
  static int? _requestedTripIdOf(Map<String, dynamic> data) =>
      data['type'] == 'TripRequested'
      ? int.tryParse('${data['deliveryTripId'] ?? ''}')
      : null;

  /// الإشعارات المحلية القديمة كان الـ payload فيها رقم الطلب بس
  static Map<String, dynamic> _payloadData(String? payload) {
    if (payload == null || payload.isEmpty) return const {};
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // رقم الطلب لوحده
    }
    return {'orderId': payload};
  }

  static void _onForegroundMessage(RemoteMessage message) {
    logger('Push received: ${message.data}');
    // الحدث نفسه وصل من الـ realtime واتعرض جوه الأبلكيشن
    if (RealtimeService.isLive) return;

    OrdersCubit.notifyServerChanged(_orderIdOf(message.data));

    final tripId = _requestedTripIdOf(message.data);
    if (tripId != null) {
      _announceTripOffer(message, tripId);
      return;
    }
    _showLocal(message);
  }

  /// عرض دليفري والاتصال واقع: بنجيب العروض ونظهر الشيت والرنّة زي الـ realtime
  /// ولو العرض مالقيناهوش (الريكوست فشل مثلاً) بنظهر الإشعار العادي
  static Future<void> _announceTripOffer(
    RemoteMessage message,
    int tripId,
  ) async {
    await DriverOffersCubit.instance.sync();
    if (DriverOffersCubit.instance.offersFor(tripId) != null) {
      RealtimeService.announceTripOffer(tripId);
    } else {
      _showLocal(message);
    }
  }

  static void _showLocal(RemoteMessage message) {
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
          importance: _channel.importance,
          priority: Priority.max,
          sound: _channel.sound,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// TripRequested بيفتح شيت العروض، وأي إشعار تاني تفاصيل طلبه
  static void _open(Map<String, dynamic> data) {
    final tripId = _requestedTripIdOf(data);
    if (tripId != null) {
      _openTripOffers(tripId, orderId: _orderIdOf(data));
      return;
    }
    _openOrder(_orderIdOf(data));
  }

  /// لو العروض اتقبلت أو اتلغت خلاص بنفتح الطلب نفسه
  static Future<void> _openTripOffers(int tripId, {int? orderId}) async {
    await DriverOffersCubit.instance.sync();
    if (DriverOffersCubit.instance.offersFor(tripId) != null) {
      DriverOffersSheet.show(focusTripId: tripId);
    } else {
      _openOrder(orderId);
    }
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
