import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class MentionProvider with ChangeNotifier {
  List<User> _suggestions = [];
  bool _isLoading = false;

  List<User> get suggestions => _suggestions;
  bool get isLoading => _isLoading;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/search/users?q=$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _suggestions = data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error searching users for mentions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }
}
