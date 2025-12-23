import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  List<Message> _messages = [];
  bool _isLoading = false;

  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  int get totalUnreadCount => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);

  Future<void> fetchChats() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/chats');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _chats = data.map((json) => Chat.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch chats error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(int chatId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) return;

    try {
      final response = await ApiService.get('/chats/$chatId/messages');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _messages = data.map((json) => Message.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Fetch messages error: $e");
    }
  }

  Future<Chat?> startChat(int otherUserId) async {
    try {
      final response = await ApiService.post('/chats/start', {'other_user_id': otherUserId});
      if (response.statusCode == 200) {
        final chat = Chat.fromJson(jsonDecode(response.body));
        fetchChats();
        return chat;
      }
    } catch (e) {
      print("Start chat error: $e");
    }
    return null;
  }

  Future<bool> sendMessage(int chatId, String message, {String type = 'text', String? gifUrl, bool isSecret = false, int? expiresIn}) async {
    try {
      final Map<String, dynamic> body = {
        'message': message,
        'type': type,
        'is_secret': isSecret,
      };
      if (gifUrl != null) body['gif_url'] = gifUrl;
      if (expiresIn != null) body['expires_in'] = expiresIn;
      
      final response = await ApiService.post('/chats/$chatId/messages', body);
      if (response.statusCode == 201) {
        fetchMessages(chatId);
        return true;
      }
    } catch (e) {
      print("Send message error: $e");
    }
    return false;
  }

  Future<bool> sendMediaMessage(int chatId, XFile file, String type, {bool isSecret = false, int? expiresIn}) async {
    try {
      final Map<String, String> fields = {'type': type, 'is_secret': isSecret.toString()};
      if (expiresIn != null) fields['expires_in'] = expiresIn.toString();
      
      final response = await ApiService.postMultipart(
        '/chats/$chatId/messages',
        fields,
        [file],
      );
      if (response.statusCode == 201) {
        fetchMessages(chatId);
        return true;
      }
    } catch (e) {
      print("Send media message error: $e");
    }
    return false;
  }

  Future<bool> editMessage(int chatId, int messageId, String newMessage) async {
    try {
      final response = await ApiService.put('/chats/messages/$messageId', {'message': newMessage});
      if (response.statusCode == 200) {
        fetchMessages(chatId);
        return true;
      }
    } catch (e) {
      print("Edit message error: $e");
    }
    return false;
  }

  Future<bool> deleteMessage(int chatId, int messageId) async {
    try {
      final response = await ApiService.delete('/chats/messages/$messageId');
      if (response.statusCode == 200) {
        fetchMessages(chatId);
        return true;
      }
    } catch (e) {
      print("Delete message error: $e");
    }
    return false;
  }

  Future<void> markAsRead(int chatId) async {
    try {
      final response = await ApiService.post('/chats/$chatId/read', {});
      if (response.statusCode == 200) {
        // Clear locally for instant feedback
        final index = _chats.indexWhere((c) => c.id == chatId);
        if (index != -1) {
          final chat = _chats[index];
          _chats[index] = Chat(
            id: chat.id,
            user1Id: chat.user1Id,
            user2Id: chat.user2Id,
            user1: chat.user1,
            user2: chat.user2,
            updatedAt: chat.updatedAt,
            unreadCount: 0,
            lastMessage: chat.lastMessage,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print("Mark as read error: $e");
    }
  }
}
