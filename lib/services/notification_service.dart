import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'supabase_service.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
  'crowdnav_emergency',
  'Emergency Alerts',
  description: 'Emergency announcements and critical CrowdNav alerts.',
  importance: Importance.max,
);

const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
  'crowdnav_normal',
  'CrowdNav Notifications',
  description: 'General CrowdNav announcements and updates.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.ensureLocalNotificationsReady();
    await NotificationService.showLocalNotification(message);
  } catch (_) {
    // Never crash the background isolate because of a notification formatting issue.
  }
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _initialized = false;
  static bool _foregroundListenerAttached = false;
  static bool _tapListenerAttached = false;
  static bool _tokenRefreshListenerAttached = false;

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;

    await _requestPermissionSafely();
    await ensureLocalNotificationsReady();
    await _subscribeUserTopicsSafely(department: 'all', program: 'all');

    _listenForeground();
    _listenNotificationTap(navigatorKey);
    await _handleInitialMessageSafely(navigatorKey);
    _listenTokenRefresh();

    _initialized = true;
  }

  static Future<void> ensureLocalNotificationsReady() async {
    await _setupLocalNotifications();
    await _createChannels();
  }

  static Future<void> _requestPermissionSafely() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {
      // Permission failures should not stop the app from opening.
    }
  }

  static Future<void> _setupLocalNotifications() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (_) {},
      );
    } catch (_) {}
  }

  static Future<void> _createChannels() async {
    try {
      final androidPlugin = localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(emergencyChannel);
      await androidPlugin?.createNotificationChannel(normalChannel);
    } catch (_) {}
  }

  static void _listenForeground() {
    if (_foregroundListenerAttached) return;
    _foregroundListenerAttached = true;
    FirebaseMessaging.onMessage.listen((message) async {
      await showLocalNotification(message);
    });
  }

  static void _listenNotificationTap(GlobalKey<NavigatorState> navigatorKey) {
    if (_tapListenerAttached) return;
    _tapListenerAttached = true;
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _routeMessage(message, navigatorKey),
    );
  }

  static Future<void> _handleInitialMessageSafely(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    try {
      final message = await _fcm.getInitialMessage();
      if (message != null) _routeMessage(message, navigatorKey);
    } catch (_) {}
  }

  static void _routeMessage(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final type = message.data['type'];

    switch (type) {
      case 'announcement':
        navigatorKey.currentState?.pushNamed('/announcements');
        break;
      case 'complaint':
        navigatorKey.currentState?.pushNamed('/complaints');
        break;
      case 'bus':
        navigatorKey.currentState?.pushNamed('/bus');
        break;
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();
      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) return;

      final priority = message.data['priority'] ?? 'normal';
      final channel = priority == 'emergency' ? emergencyChannel : normalChannel;

      await localNotifications.show(
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title ?? 'CrowdNav',
        body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: priority == 'emergency' ? Priority.max : Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<void> saveTokenToSupabase() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;
      await SupabaseService.saveDeviceToken(fcmToken: token, platform: 'android');
    } catch (_) {}
  }

  static void _listenTokenRefresh() {
    if (_tokenRefreshListenerAttached) return;
    _tokenRefreshListenerAttached = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        if (newToken.isEmpty) return;
        await SupabaseService.saveDeviceToken(
          fcmToken: newToken,
          platform: 'android',
        );
      } catch (_) {}
    });
  }

  static Future<void> subscribeUserTopics({
    required String department,
    required String program,
  }) async {
    await _subscribeUserTopicsSafely(department: department, program: program);
  }

  static Future<void> _subscribeUserTopicsSafely({
    required String department,
    required String program,
  }) async {
    try {
      await _fcm.subscribeToTopic('crowdnav_all');

      final cleanDepartment = _topicSafe(department);
      final cleanProgram = _topicSafe(program);

      if (cleanDepartment != 'all') {
        await _fcm.subscribeToTopic('dept_$cleanDepartment');
      }
      if (cleanProgram != 'all') {
        await _fcm.subscribeToTopic('program_$cleanProgram');
      }
    } catch (_) {}
  }

  static String _topicSafe(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty ? 'all' : cleaned;
  }
}
