import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
  'crowdnav_emergency',
  'Emergency Alerts',
  description: 'Emergency announcements',
  importance: Importance.max,
);

const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
  'crowdnav_normal',
  'CrowdNav Notifications',
  description: 'General notifications',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _createChannels();
    await saveTokenToSupabase();
    _listenForeground();
    _listenNotificationTap(navigatorKey);
    await _handleInitialMessage(navigatorKey);
    _listenTokenRefresh();
  }

  static Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await localNotifications.initialize(settings);
  }

  static Future<void> _createChannels() async {
    final androidPlugin = localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(emergencyChannel);
    await androidPlugin?.createNotificationChannel(normalChannel);
  }

  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) async {
      await showLocalNotification(message);
    });
  }

  static void _listenNotificationTap(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeMessage(message, navigatorKey);
    });
  }

  static Future<void> _handleInitialMessage(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      _routeMessage(message, navigatorKey);
    }
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
      default:
        break;
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    final priority = message.data['priority'] ?? 'normal';
    final channel = priority == 'emergency' ? emergencyChannel : normalChannel;

    await localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      payload: message.data['type'],
    );
  }

  static Future<void> saveTokenToSupabase() async {
    final token = await _fcm.getToken();
    final user = Supabase.instance.client.auth.currentUser;

    if (token == null || user == null) return;

    Map<String, dynamic>? profile;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role, department, program, office_section')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) profile = Map<String, dynamic>.from(data);
    } catch (_) {
      profile = null;
    }

    await Supabase.instance.client.from('device_tokens').upsert({
      'user_id': user.id,
      'fcm_token': token,
      'platform': 'android',
      'role': profile?['role'] ?? 'student',
      'department': profile?['department'],
      'program': profile?['program'],
      'office_section': profile?['office_section'],
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'fcm_token');
  }

  static Future<void> subscribeUserTopics({
    String department = 'all',
    String program = 'all',
  }) async {
    await _fcm.subscribeToTopic('crowdnav_all');

    final departmentTopic = _topicName('department', department);
    final programTopic = _topicName('program', program);

    if (departmentTopic != null) {
      await _fcm.subscribeToTopic(departmentTopic);
    }
    if (programTopic != null) {
      await _fcm.subscribeToTopic(programTopic);
    }
  }

  static String? _topicName(String prefix, String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (cleaned.isEmpty || cleaned == 'all') return null;
    return 'crowdnav_${prefix}_$cleaned';
  }

  static void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'fcm_token': newToken,
        'platform': 'android',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');
    });
  }
}
