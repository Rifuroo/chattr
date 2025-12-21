import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MemoryLaneProvider with ChangeNotifier {
  List<Post> _memoryPosts = [];
  bool _isLoading = false;

  List<Post> get memoryPosts => _memoryPosts;
  bool get isLoading => _isLoading;

  Future<void> fetchMemoryLane() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/users/memory-lane');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _memoryPosts = data.map((json) => Post.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch memory lane error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
