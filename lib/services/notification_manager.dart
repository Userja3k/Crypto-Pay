// lib/services/notification_manager.dart
// Gestion des notifications (push, in-app, badges)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/animated_icon_badge.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Demander les permissions
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  /// Affiche une notification push
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required PaymentTech tech,
    String? payload,
  }) async {

    const androidDetails = AndroidNotificationDetails(
      'crypto_pay_channel',
      'Crypto-Pay',
      channelDescription: 'Notifications de paiement Crypto-Pay',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      color: Color(0xFF00D4FF),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Enregistre une notification dans Supabase
  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    required PaymentTech tech,
    String? transactionId,
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': _getNotificationType(tech),
        'metadata': {
          'tech': tech.toString().split('.').last,
          'transaction_id': transactionId,
        },
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Erreur sauvegarde notification: $e');
    }
  }

  String _getNotificationType(PaymentTech tech) {
    switch (tech) {
      case PaymentTech.bluetooth:
        return 'bluetooth_payment';
      case PaymentTech.nfc:
        return 'nfc_payment';
      case PaymentTech.lightning:
        return 'lightning_payment';
      case PaymentTech.qrCode:
        return 'qr_payment';
      case PaymentTech.internal:
        return 'internal_payment';
      case PaymentTech.mobileMoney:
        return 'mobile_money';
    }
  }

  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String()
      }).eq('id', notificationId);
    } catch (e) {
      debugPrint('Erreur marquage notification: $e');
    }
  }

  /// Récupère le badge pour l'icône de notification
  int getBadgeCount(List<Map<String, dynamic>> notifications) {
    return notifications.where((n) => n['is_read'] == false).length;
  }
}
