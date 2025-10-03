import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DealAlert {
  final String id;
  final String title;
  final String description;
  final String category;
  final double minDiscount;
  final double maxDiscount;
  final int maxDistance; // in km
  final bool isActive;
  final DateTime createdAt;

  DealAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.minDiscount,
    required this.maxDiscount,
    required this.maxDistance,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'minDiscount': minDiscount,
      'maxDiscount': maxDiscount,
      'maxDistance': maxDistance,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DealAlert.fromJson(Map<String, dynamic> json) {
    return DealAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      minDiscount: json['minDiscount'].toDouble(),
      maxDiscount: json['maxDiscount'].toDouble(),
      maxDistance: json['maxDistance'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class DealAlertsService {
  static const String _alertsKey = 'deal_alerts';
  static Timer? _checkTimer;
  static final List<DealAlert> _alerts = [];

  // Initialize the service
  static Future<void> initialize() async {
    await _loadAlerts();
    _startPeriodicCheck();
  }

  // Load saved alerts from storage
  static Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getStringList(_alertsKey) ?? [];
      
      _alerts.clear();
      for (final alertJson in alertsJson) {
        final alert = DealAlert.fromJson(
          Map<String, dynamic>.from(
            Uri.splitQueryString(alertJson)
          )
        );
        _alerts.add(alert);
      }
      
      debugPrint('📱 Loaded ${_alerts.length} deal alerts');
    } catch (e) {
      debugPrint('❌ Error loading deal alerts: $e');
    }
  }

  // Save alerts to storage
  static Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _alerts
          .map((alert) => Uri(queryParameters: alert.toJson()).query)
          .toList();
      
      await prefs.setStringList(_alertsKey, alertsJson);
      debugPrint('💾 Saved ${_alerts.length} deal alerts');
    } catch (e) {
      debugPrint('❌ Error saving deal alerts: $e');
    }
  }

  // Create a new deal alert
  static Future<String> createAlert({
    required String title,
    required String description,
    required String category,
    required double minDiscount,
    required double maxDiscount,
    required int maxDistance,
  }) async {
    final alert = DealAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      minDiscount: minDiscount,
      maxDiscount: maxDiscount,
      maxDistance: maxDistance,
      isActive: true,
      createdAt: DateTime.now(),
    );

    _alerts.add(alert);
    await _saveAlerts();
    
    debugPrint('🔔 Created deal alert: ${alert.title}');
    return alert.id;
  }

  // Get all alerts
  static List<DealAlert> getAllAlerts() {
    return List.unmodifiable(_alerts);
  }

  // Get active alerts
  static List<DealAlert> getActiveAlerts() {
    return _alerts.where((alert) => alert.isActive).toList();
  }

  // Update alert status
  static Future<void> updateAlertStatus(String alertId, bool isActive) async {
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _alerts[alertIndex] = DealAlert(
        id: _alerts[alertIndex].id,
        title: _alerts[alertIndex].title,
        description: _alerts[alertIndex].description,
        category: _alerts[alertIndex].category,
        minDiscount: _alerts[alertIndex].minDiscount,
        maxDiscount: _alerts[alertIndex].maxDiscount,
        maxDistance: _alerts[alertIndex].maxDistance,
        isActive: isActive,
        createdAt: _alerts[alertIndex].createdAt,
      );
      await _saveAlerts();
    }
  }

  // Delete alert
  static Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((alert) => alert.id == alertId);
    await _saveAlerts();
    debugPrint('🗑️ Deleted deal alert: $alertId');
  }

  // Start periodic checking for deals
  static void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkForDeals();
    });
  }

  // Check for deals matching alerts
  static Future<void> _checkForDeals() async {
    final activeAlerts = getActiveAlerts();
    if (activeAlerts.isEmpty) return;

    debugPrint('🔍 Checking for deals matching ${activeAlerts.length} alerts...');

    for (final alert in activeAlerts) {
      try {
        // This would need to be implemented with actual shop data
        // For now, we'll simulate checking
        await _checkAlertAgainstOffers(alert);
      } catch (e) {
        debugPrint('❌ Error checking alert ${alert.id}: $e');
      }
    }
  }

  // Check if any offers match the alert criteria
  static Future<void> _checkAlertAgainstOffers(DealAlert alert) async {
    // This is a placeholder - in a real implementation, you would:
    // 1. Get nearby shops within maxDistance
    // 2. Fetch offers from those shops
    // 3. Filter offers by category and discount range
    // 4. Send notification if matches found
    
    debugPrint('🔍 Checking alert: ${alert.title}');
    debugPrint('   Category: ${alert.category}');
    debugPrint('   Discount: ${alert.minDiscount}% - ${alert.maxDiscount}%');
    debugPrint('   Distance: ${alert.maxDistance}km');
  }

  // Manual check for deals (can be called from UI)
  static Future<List<Map<String, dynamic>>> checkForDealsNow() async {
    final results = <Map<String, dynamic>>[];
    final activeAlerts = getActiveAlerts();

    for (final alert in activeAlerts) {
      // Simulate finding matching deals
      // In real implementation, this would query actual offers
      final matchingDeals = await _simulateDealSearch(alert);
      
      if (matchingDeals.isNotEmpty) {
        results.add({
          'alert': alert,
          'deals': matchingDeals,
          'timestamp': DateTime.now(),
        });
      }
    }

    return results;
  }

  // Simulate finding deals (replace with real implementation)
  static Future<List<Map<String, dynamic>>> _simulateDealSearch(DealAlert alert) async {
    // This is a placeholder - replace with actual offer search
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate some results occasionally
    if (DateTime.now().millisecondsSinceEpoch % 3 == 0) {
      return [
        {
          'shopName': 'Sample Store',
          'offerTitle': 'Great Deal on ${alert.category}',
          'discount': '${alert.minDiscount.toInt()}% OFF',
          'distance': '${(alert.maxDistance * 0.5).toInt()}km away',
        }
      ];
    }
    
    return [];
  }

  // Get alert statistics
  static Map<String, dynamic> getAlertStats() {
    final total = _alerts.length;
    final active = _alerts.where((alert) => alert.isActive).length;
    final inactive = total - active;

    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'categories': _alerts.map((alert) => alert.category).toSet().length,
    };
  }

  // Cleanup
  static void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}
