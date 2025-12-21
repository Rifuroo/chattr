import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  final Set<int> _notifiedIds = {}; // Track IDs to avoid double show on Flushbar

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> setupFCM() async {
    if (kIsWeb) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        _updateTokenOnBackend(token);
      }
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    messaging.onTokenRefresh.listen((newToken) {
      _updateTokenOnBackend(newToken);
    });
  }

  Future<void> _updateTokenOnBackend(String token) async {
    try {
      await ApiService.post('/users/fcm-token', {'token': token});
      print("FCM Token updated on backend: $token");
    } catch (e) {
      print("Error updating FCM token: $e");
    }
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) return;

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await ApiService.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((n) => NotificationModel.fromJson(n)).toList();
      }
    } catch (e) {
      print("Fetch notifications error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await ApiService.put('/notifications/$id/read', {});
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          final n = _notifications[index];
          _notifications[index] = NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print("Mark notification as read error: $e");
    }
  }

  bool isNew(int id) {
    if (_notifiedIds.contains(id)) return false;
    _notifiedIds.add(id);
    return true;
  }
}
