import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  List<User> _searchResults = [];
  User? _selectedUser;
  bool _isFollowing = false;
  bool _isLoading = false;

  List<User> get searchResults => _searchResults;
  User? get selectedUser => _selectedUser;
  bool get isFollowing => _isFollowing;
  bool get isLoading => _isLoading;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/search/users?q=$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _searchResults = data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      print("Search users error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserProfile(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/users/$userId');
      if (response.statusCode == 200) {
        _selectedUser = User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        // Handle private account
        final data = jsonDecode(response.body);
        _selectedUser = User.fromJson(data['user']);
      }
    } catch (e) {
      print("Fetch profile error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> followUser(int userId) async {
    try {
      final response = await ApiService.post('/users/$userId/follow', {});
      if (response.statusCode == 200) {
        _isFollowing = true;
        fetchUserProfile(userId);
        return true;
      }
    } catch (e) {
      print("Follow error: $e");
    }
    return false;
  }

  Future<bool> unfollowUser(int userId) async {
    try {
      final response = await ApiService.delete('/users/$userId/unfollow');
      if (response.statusCode == 200) {
        _isFollowing = false;
        fetchUserProfile(userId);
        return true;
      }
    } catch (e) {
      print("Unfollow error: $e");
    }
    return false;
  }

  Future<bool> updatePrivacySettings(bool isPrivate) async {
    try {
      final response = await ApiService.put('/settings/privacy', {'is_private': isPrivate});
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("Update privacy error: $e");
    }
    return false;
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
    String? moodEmoji,
    String? moodText,
    bool? isGhostMode,
    String? profileTheme,
    XFile? avatarFile,
  }) async {
    try {
      Map<String, String> fields = {
        'name': name,
        'bio': bio,
      };
      if (moodEmoji != null) fields['mood_emoji'] = moodEmoji;
      if (moodText != null) fields['mood_text'] = moodText;
      if (isGhostMode != null) fields['is_ghost_mode'] = isGhostMode.toString();
      if (profileTheme != null) fields['profile_theme'] = profileTheme;
      
      final responseStream = await ApiService.putMultipart('/users/profile', fields, avatarFile, fieldName: 'avatar');
      final response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Update profile failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Update profile error: $e");
    }
    return false;
  }
}
