import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final ValueNotifier<int> badgeCount = ValueNotifier<int>(0);

  // Stream for internal app consumption (Inbox)
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification => _controller.stream;

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'orders_channel',
      'Orders',
      channelDescription: 'Order status updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details, payload: payload);
    badgeCount.value = badgeCount.value + 1;

    // Broadcast to app
    _controller.add({
      'id': id,
      'title': title,
      'message': body,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
      'source': 'REALTIME',
      'isRead': false,
    });
  }
}
