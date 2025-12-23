import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PrivacyProvider with ChangeNotifier {
  List<FollowRequest> _followRequests = [];
  List<FollowRequest> get followRequests => _followRequests;

  List<Tell> _myTells = [];
  List<Tell> get myTells => _myTells;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchFollowRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getFollowRequests();
      _followRequests = data.map((json) => FollowRequest.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching follow requests: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> respondToRequest(int requestId, String action) async {
    try {
      final response = await ApiService.respondToFollowRequest(requestId, action);
      if (response.statusCode == 200) {
        _followRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error responding to follow request: $e");
    }
    return false;
  }

  Future<bool> toggleBlock(int userId) async {
    try {
      final isBlocked = await ApiService.toggleBlock(userId);
      return isBlocked;
    } catch (e) {
      print("Error toggling block: $e");
    }
    return false;
  }

  Future<void> fetchMyTells() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getMyTells();
      _myTells = data.map((json) => Tell.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching tells: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendTell(int userId, String content) async {
    try {
      await ApiService.sendTell(userId, content);
      return true;
    } catch (e) {
      print("Error sending tell: $e");
      return false;
    }
  }

  Future<void> markTellAsRead(int tellId) async {
    try {
      await ApiService.markTellAsRead(tellId);
      final index = _myTells.indexWhere((t) => t.id == tellId);
      if (index != -1) {
        // We can't mutate the model directly as it's immutable in our class,
        // but for read status we can just refresh or accept that it was read.
        fetchMyTells();
      }
    } catch (e) {
      print("Error marking tell as read: $e");
    }
  }
}
