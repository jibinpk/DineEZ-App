import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize time zones
      tz.initializeTimeZones();
      
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true);
      
      // InitializationSettings for both platforms
      const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS);
      
      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          if (kDebugMode) {
            print('Notification tapped with payload: ${response.payload}');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }
  
  // Request notification permissions (for iOS)
  Future<void> requestPermissions() async {
    try {
      final DarwinNotificationDetails iOSDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
    }
  }
  
  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    try {
      // Default notification details if not provided
      notificationDetails ??= NotificationDetails(
        android: AndroidNotificationDetails(
          'dineez_channel',
          'DineEZ Notifications',
          channelDescription: 'Notifications from DineEZ app',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.blue,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }
  
  // Schedule a notification for the future
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    try {
      // Default notification details if not provided
      notificationDetails ??= NotificationDetails(
        android: AndroidNotificationDetails(
          'dineez_scheduled_channel',
          'DineEZ Scheduled Notifications',
          channelDescription: 'Scheduled notifications from DineEZ app',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.blue,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }
  
  // Send an order status notification
  Future<void> sendOrderStatusNotification({
    required String orderId,
    required String status,
    required String restaurantName,
  }) async {
    try {
      String title = 'Order Update';
      String body = '';
      
      switch (status) {
        case 'new':
          body = 'Your order #$orderId has been received by $restaurantName.';
          break;
        case 'preparing':
          body = 'Your order #$orderId is now being prepared at $restaurantName.';
          break;
        case 'ready':
          body = 'Your order #$orderId is ready to be served at $restaurantName.';
          break;
        case 'served':
          body = 'Your order #$orderId has been served. Enjoy your meal!';
          break;
        case 'completed':
          body = 'Your order #$orderId has been completed. Thank you for dining with $restaurantName!';
          break;
        default:
          body = 'There is an update on your order #$orderId at $restaurantName.';
      }
      
      await showNotification(
        id: orderId.hashCode,
        title: title,
        body: body,
        payload: 'order:$orderId',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending order status notification: $e');
      }
    }
  }
  
  // Send a payment notification
  Future<void> sendPaymentNotification({
    required String orderId,
    required bool success,
    required double amount,
    required String restaurantName,
  }) async {
    try {
      String title = success ? 'Payment Successful' : 'Payment Failed';
      String body = success
          ? 'Your payment of \$${amount.toStringAsFixed(2)} for order #$orderId at $restaurantName was successful.'
          : 'Your payment for order #$orderId at $restaurantName failed. Please try again.';
      
      await showNotification(
        id: ('payment:$orderId').hashCode,
        title: title,
        body: body,
        payload: 'payment:$orderId',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending payment notification: $e');
      }
    }
  }
  
  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
} 