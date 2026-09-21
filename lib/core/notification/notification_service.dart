import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)async {
  await NotificationService._instance.setupFlutterNotification();
  await NotificationService._instance.showNotification(message);
}


class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  static NotificationService get instance => _instance;
  final _messaging = FirebaseMessaging.instance;
  final _localNotification = FlutterLocalNotificationsPlugin();
  final bool _isFlutterLocalNotificationInitilaized = false;
Future<void> initialize ()async{
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _requestPermission();
  await _messaging.subscribeToTopic('notifications');
  _setupMessageHandlers();
  // final token = _messaging.getToken();
  // loggerError(await token);
}
  Future<void> _requestPermission() async {
   await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    // logger('settings ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotification() async {
    if (_isFlutterLocalNotificationInitilaized) {
      return;
    }
    //android setup
    const channel = AndroidNotificationChannel(
        'high_importance_channel', 'High Importance Channel ',
        description: 'This channel is used for important notifications.',
        importance: Importance.high);
    await _localNotification
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const initializationAndroidIconSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    //ios
    const initializationSettingDarwin = DarwinInitializationSettings();
  const InitializationSettings(
        android: initializationAndroidIconSettings,
        iOS: initializationSettingDarwin);
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      await _localNotification.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
                'high_importance_channel', 'High Importance Channel ',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher'),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString());
    }
  }

  Future<void> _setupMessageHandlers()async{
    //foreground
      FirebaseMessaging.onMessage.listen((message){
        showNotification(message);
      });
//background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  //opened app
    final initialMessage = await _messaging.getInitialMessage();
    if(initialMessage !=null){
      _handleBackgroundMessage(initialMessage);
    }

  }
  void _handleBackgroundMessage(RemoteMessage message){
      if(message.data['type'] == 'chat'){
        //open chat screen
      }
  }
}
