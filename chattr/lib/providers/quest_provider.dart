import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class QuestProvider with ChangeNotifier {
  List<UserQuest> _userQuests = [];
  bool _isLoading = false;

  List<UserQuest> get userQuests => _userQuests;
  bool get isLoading => _isLoading;

  Future<void> fetchQuests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/quests');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _userQuests = data.map((json) => UserQuest.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch quests error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> claimQuest(int questId) async {
    try {
      final response = await ApiService.post('/quests/$questId/claim', {});
      if (response.statusCode == 200) {
        await fetchQuests(); // Refresh
        return true;
      }
    } catch (e) {
      print("Claim quest error: $e");
    }
    return false;
  }
}
