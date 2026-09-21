import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'high importance channel',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final _firebaseMessaging = FirebaseMessaging.instance;
  Future<void> initNotifiction() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await _firebaseMessaging.getToken();
    log('FCMToken: $fcmToken');

    FirebaseMessaging.onBackgroundMessage(handleBckgroundMessage);
    await initPushNotifiction();
    await initLocalNotification();
  }

  Future<void> initLocalNotification() async {
    const ios = DarwinInitializationSettings();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: android, iOS: ios);
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
        handelMessage(message);
      },
    );
    final platform =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!;

    await platform.createNotificationChannel(_androidChannel);
  }

  Future<void> handleBckgroundMessage(RemoteMessage? message) async {
    if (message == null) return;
    log('onBackgroundMessage titel : ${message.notification!.title}');
    log('onBackgroundMessage body : ${message.notification!.body}');
    log('onBackgroundMessage data : ${message.data}');
    log('onBackgroundMessage msg id : ${message.messageId}');
    log('onBackgroundMessage sender id : ${message.senderId}');
    log('onBackgroundMessage send time: ${message.sentTime}');
    log('onBackgroundMessage ttl: ${message.ttl}');
  }

  void handelMessage(RemoteMessage? message) {
    if (message == null) return;
    log('messege clicked');
  }

  Future<void> initPushNotifiction() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) => handelMessage(message));
    FirebaseMessaging.onMessage.listen((message) => handelMessage(message));
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => handleBckgroundMessage(message));
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: _androidChannel.importance,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    });
  }
}
