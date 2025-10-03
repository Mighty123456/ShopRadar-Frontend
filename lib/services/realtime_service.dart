import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'network_config.dart';
import 'notification_service.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  IO.Socket? _socket;
  StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> initialize() async {
    try {
      final base = NetworkConfig.baseUrl; // e.g. http(s)://host:port
      final uri = Uri.parse(base);
      final wsOrigin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      final endpoint = '$wsOrigin/public';

      _socket?.dispose();
      _socket = IO.io(
        endpoint,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('🔌 Realtime connected to $endpoint');
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 Realtime disconnected');
      });

      // Listen for new shops
      _socket!.on('new_shop', (payload) async {
        try {
          if (payload is Map) {
            final data = Map<String, dynamic>.from(payload['data'] ?? {});
            final shop = Map<String, dynamic>.from(data['shop'] ?? {});

            final bool shouldNotify = await _shouldNotifyForShop(shop);
            if (shouldNotify) {
              final title = 'New shop in your area';
              final message = shop['name'] != null
                  ? '${shop['name']} just joined ShopRadar'
                  : 'A new shop just joined near you';

              final notification = AppNotification(
                id: UniqueKey().toString(),
                title: title,
                message: message,
                type: NotificationType.shopUpdate,
                shopId: shop['id']?.toString(),
                shopName: shop['name']?.toString(),
                isRead: false,
                createdAt: DateTime.now(),
                data: {
                  'address': shop['address'],
                  'gpsAddress': shop['gpsAddress'],
                  'state': shop['state'],
                  'location': shop['location'],
                },
              );

              await NotificationService.addNotification(notification);
              _eventController.add({'type': 'new_shop_notification', 'notification': notification});
            }
          }
        } catch (e) {
          debugPrint('Realtime new_shop handling error: $e');
        }
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('Realtime initialization error: $e');
    }
  }

  Future<bool> _shouldNotifyForShop(Map<String, dynamic> shop) async {
    try {
      // Get device city
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      final deviceCity = placemarks.isNotEmpty ? placemarks.first.locality?.toLowerCase().trim() : null;

      // Derive shop city from gpsAddress/address if present
      String? shopCity;
      final gpsAddress = (shop['gpsAddress'] ?? shop['address'] ?? '')?.toString();
      if (gpsAddress != null && gpsAddress.isNotEmpty) {
        // naive parse: take token before state or last comma token
        final parts = gpsAddress.split(',');
        if (parts.isNotEmpty) {
          shopCity = parts.length >= 2 ? parts[parts.length - 2].toLowerCase().trim() : parts.last.toLowerCase().trim();
        }
      }

      if (deviceCity == null || shopCity == null) {
        return false;
      }

      // Basic city match
      if (deviceCity == shopCity) return true;

      // Fallback: distance check if coordinates available
      final loc = shop['location'];
      if (loc != null && loc is Map && loc['lat'] != null && loc['lng'] != null) {
        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );
        return distanceMeters <= 10000; // 10km radius fallback
      }

      return false;
    } catch (e) {
      debugPrint('City/distance evaluation failed: $e');
      return false;
    }
  }
}


