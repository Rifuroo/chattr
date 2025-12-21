import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HighlightProvider with ChangeNotifier {
  List<Highlight> _userHighlights = [];
  bool _isLoading = false;

  List<Highlight> get userHighlights => _userHighlights;
  bool get isLoading => _isLoading;

  Future<void> fetchUserHighlights(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/highlights/user/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _userHighlights = data.map((json) => Highlight.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch highlights error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createHighlight(String title, {String? coverImage, bool isShared = false}) async {
    try {
      final response = await ApiService.post('/highlights', {
        'title': title,
        'cover_image': coverImage,
        'is_shared': isShared,
      });
      if (response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print("Create highlight error: $e");
    }
    return false;
  }

  Future<bool> addMember(int highlightID, int userId) async {
    try {
      final response = await ApiService.post('/highlights/$highlightID/members', {
        'user_id': userId,
      });
      return response.statusCode == 201;
    } catch (e) {
      print("Add highlight member error: $e");
    }
    return false;
  }

  Future<bool> addItem(int highlightID, int storyId) async {
    try {
      final response = await ApiService.post('/highlights/$highlightID/items', {
        'story_id': storyId,
      });
      return response.statusCode == 201;
    } catch (e) {
      print("Add highlight item error: $e");
    }
    return false;
  }
}
