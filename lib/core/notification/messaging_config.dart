import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lavanderia_partner/core/extensions/string_extension.dart';

import '../helpers/logger.dart';

class MessagingConfig {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Safety Tip 1: Add a flag to track if initialization is complete
  static bool _initializationComplete = false;

  // Safety Tip 2: Queue for notifications received before initialization
  static final List<Map<String, dynamic>> _pendingNotifications = [];

  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> initFirebaseMessaging() async {
    if (_initializationComplete) return;

    try {
      await createNotificationChannel();

      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Safety Tip 3: Request permissions with error handling
      final NotificationSettings settings = await messaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          )
          .catchError((e) {
            log('Error requesting notification permissions: $e');
            return const NotificationSettings(
              authorizationStatus: AuthorizationStatus.denied,
              alert: AppleNotificationSetting.disabled,
              announcement: AppleNotificationSetting.disabled,
              badge: AppleNotificationSetting.disabled,
              carPlay: AppleNotificationSetting.disabled,
              criticalAlert: AppleNotificationSetting.disabled,
              sound: AppleNotificationSetting.disabled,
              lockScreen: AppleNotificationSetting.disabled,
              notificationCenter: AppleNotificationSetting.disabled,
              providesAppNotificationSettings:
                  AppleNotificationSetting.disabled,
              showPreviews: AppleShowPreviewSetting.whenAuthenticated,
              timeSensitive: AppleNotificationSetting.disabled,
            );
          });

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // Safety Tip 4: Initialize notifications with robust error handling
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          log("Notification tapped: ${response.payload}");
          if (response.payload != null) {
            try {
              final data =
                  jsonDecode(response.payload!) as Map<String, dynamic>;
              _handleNotificationWithSafetyChecks(data);
            } catch (e) {
              log('Error parsing notification payload: $e');
            }
          }
        },
      );

      // Safety Tip 5: Handle all possible permission states
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          log('User granted permission');
          break;
        case AuthorizationStatus.provisional:
          log('User granted provisional permission');
          break;
        case AuthorizationStatus.denied:
          log('User denied permission');
          break;
        case AuthorizationStatus.notDetermined:
          log('Permission not determined');
          break;
      }

      // Safety Tip 6: Add error handling for topic subscription
      try {
        await FirebaseMessaging.instance.subscribeToTopic('notifications');
      } catch (e) {
        log('Error subscribing to topic: $e');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newFCM) async {
        // Handle token refresh with your backend
      });

      FirebaseMessaging.instance.getToken().then((token) async {
        // Handle token with your backend
      });

      // Safety Tip 7: Add error handling for message listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
        _incrementBadgeCount();
        log("Foreground message received");
        try {
          final RemoteNotification? notification = event.notification;
          if (notification != null) {
            await flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  channelDescription:
                      'This channel is used for important notifications.',
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: jsonEncode(event.data),
            );
          }
        } catch (err) {
          log('Error showing local notification: $err');
        }
      });

      // Modified handlers with safety checks
      FirebaseMessaging.instance.getInitialMessage().then((
        RemoteMessage? message,
      ) {
        _incrementBadgeCount();
        if (message != null) {
          log('Terminated state message received');
          // navigatorKey.currentState!.context.read<NotificationBadgeCubit>().incrementUnreadCount();
          _handleNotificationWithSafetyChecks(message.data);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _incrementBadgeCount();
        log('Background state message received');
        _handleNotificationWithSafetyChecks(message.data);
      });

      _initializationComplete = true;

      // Safety Tip 8: Process any pending notifications
      if (_pendingNotifications.isNotEmpty) {
        log('Processing ${_pendingNotifications.length} pending notifications');
        for (final data in _pendingNotifications) {
          _handleNotificationWithSafetyChecks(data);
        }
        _pendingNotifications.clear();
      }
    } catch (e) {
      log('Error initializing Firebase Messaging: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> messageHandler(RemoteMessage message) async {
    log('Background message handler triggered');

    // Safety Tip 9: Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    _incrementBadgeCount();
    try {
      log('Background message data: ${message.data}');

      // Safety Tip 10: Store the notification if app isn't ready
      if (!_initializationComplete) {
        _pendingNotifications.add(message.data);
        log('Added notification to pending queue');
        return;
      }

      // Wait for app to potentially initialize
      await Future.delayed(const Duration(milliseconds: 500));

      _handleNotificationWithSafetyChecks(message.data);
    } catch (e) {
      log('Error in background message handler: $e');
    }
  }

  // Safety Tip 11: Centralized notification handling with all safety checks
  static void _handleNotificationWithSafetyChecks(Map<String, dynamic> data) {
    try {
      // Safety Tip 12: Use post-frame callback to ensure widget tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processNotificationData(data);
      });
    } catch (e) {
      log('Error in notification handler: $e');
    }
  }

  // Safety Tip 13: Separate data processing from navigation logic
  static void _processNotificationData(Map<String, dynamic> data) {
    _incrementBadgeCount();

    try {
      final String? route = data['route'];
      logger('Notification route: $route');

      if (route == null) {
        loggerError(
          'Route missing or navigator not ready - adding to pending queue',
        );
        _pendingNotifications.add(data);
        return;
      }
      // Get the bloc instance and refresh notifications

      // Safety Tip 14: Use a switch statement for better route handling
      switch (route) {
        case "show_order_for_nurse":
          _navigateToPatientScreen(data);
          break;
        case "notification":
          _navigateToNotificationScreen();
          break;
        default:
          log('Unknown notification route: $route');
      }
    } catch (e) {
      log('Error processing notification data: $e');
    }
  }

  // Safety Tip 15: Isolate navigation methods for better error handling
  static void _navigateToPatientScreen(Map<String, dynamic> data) {
    try {
      final id = data['order_id']?.toString().toInt;
      final phoneNumber = data['phone_number']?.toString();

      if (id == null || phoneNumber == null) {
        loggerError(
          'Missing required parameters for patient screen id $id or phone number $phoneNumber',
        );
        return;
      }

      // _goToScreen(
      //   PationtScreen(id: id, phoneNumber: phoneNumber),
      // );
    } catch (e) {
      log('Error navigating to patient screen: $e');
    }
  }

  static void _navigateToNotificationScreen() {
    try {
      // _goToScreen(const NurserNotificationScreen());
    } catch (e) {
      log('Error navigating to notification screen: $e');
    }
  }

  // static void _goToScreen(Widget widget) {
  //   if (navigatorKey.currentState != null) {
  //     navigatorKey.currentState?.context.go(widget);
  //   } else {
  //     log('Navigator context is not available');
  //   }
  // }

  static void _incrementBadgeCount() {
    try {
      // Try to get cubit from service locator first
      // getIt<NotificationBadgeCubit>().incrementUnreadCount();
      log('Incremented badge count via service locator');
    } catch (e) {
      // Fallback to navigator context if available
      // if (navigatorKey.currentState != null) {
      //   navigatorKey.currentState!.context
      //       .read<NotificationBadgeCubit>()
      //       .incrementUnreadCount();
      //   log('Incremented badge count via navigator context');
      // } else {
      //   log('Could not increment badge - no access to cubit');
      // }
    }
  }

  // Safety Tip 16: Dispose method to clear notifications and reset state
  static void dispose() {
    flutterLocalNotificationsPlugin.cancelAll();
    _initializationComplete = false;
    _pendingNotifications.clear();
  }
}
