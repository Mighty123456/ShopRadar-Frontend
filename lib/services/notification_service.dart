import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static const String _notificationsKey = 'user_notifications';
  static const String _preferencesKey = 'notification_preferences';

  /// Get all notifications for the user
  static Future<List<AppNotification>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);
      
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        return notificationsList
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Add a new notification
  static Future<void> addNotification(AppNotification notification) async {
    try {
      final notifications = await getNotifications();
      notifications.insert(0, notification); // Add to beginning
      
      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        
        final prefs = await SharedPreferences.getInstance();
        final notificationsJson = jsonEncode(
          notifications.map((n) => n.toJson()).toList(),
        );
        await prefs.setString(_notificationsKey, notificationsJson);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final notifications = await getNotifications();
      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Get notification preferences
  static Future<NotificationPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      if (preferencesJson != null) {
        return NotificationPreferences.fromJson(jsonDecode(preferencesJson));
      }
      
      return NotificationPreferences(); // Default preferences
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return NotificationPreferences();
    }
  }

  /// Update notification preferences
  static Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(preferences.toJson());
      await prefs.setString(_preferencesKey, preferencesJson);
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? shopId;
  final String? shopName;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.shopId,
    this.shopName,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.general,
      ),
      shopId: json['shopId'],
      shopName: json['shopName'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'shopId': shopId,
      'shopName': shopName,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? shopId,
    String? shopName,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.priceDrop:
        return Icons.trending_down;
      case NotificationType.newOffer:
        return Icons.local_offer;
      case NotificationType.reviewReminder:
        return Icons.rate_review;
      case NotificationType.shopUpdate:
        return Icons.store;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.priceDrop:
        return Colors.green;
      case NotificationType.newOffer:
        return Colors.orange;
      case NotificationType.reviewReminder:
        return Colors.blue;
      case NotificationType.shopUpdate:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }
}

enum NotificationType {
  priceDrop,
  newOffer,
  reviewReminder,
  shopUpdate,
  general,
}

class NotificationPreferences {
  final bool priceDropAlerts;
  final bool newOfferAlerts;
  final bool reviewReminders;
  final bool shopUpdates;
  final bool pushNotifications;
  final bool emailNotifications;
  final double maxDistance; // in kilometers

  NotificationPreferences({
    this.priceDropAlerts = true,
    this.newOfferAlerts = true,
    this.reviewReminders = true,
    this.shopUpdates = false,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.maxDistance = 5.0,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      priceDropAlerts: json['priceDropAlerts'] ?? true,
      newOfferAlerts: json['newOfferAlerts'] ?? true,
      reviewReminders: json['reviewReminders'] ?? true,
      shopUpdates: json['shopUpdates'] ?? false,
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? false,
      maxDistance: (json['maxDistance'] ?? 5.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priceDropAlerts': priceDropAlerts,
      'newOfferAlerts': newOfferAlerts,
      'reviewReminders': reviewReminders,
      'shopUpdates': shopUpdates,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'maxDistance': maxDistance,
    };
  }
}
