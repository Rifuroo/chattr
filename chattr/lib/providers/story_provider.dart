import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StoryProvider with ChangeNotifier {
  List<Story> _stories = [];
  bool _isLoading = false;

  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;

  Future<void> fetchStories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/stories');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _stories = data.map((json) => Story.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch stories error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createStory(XFile? media) async {
    if (media == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.postMultipart('/stories', {}, media, fieldName: 'media');
      if (response.statusCode == 201) {
        fetchStories();
        return true;
      }
    } catch (e) {
      print("Create story error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> viewStory(int storyId) async {
    try {
      await ApiService.post('/stories/$storyId/view', {});
    } catch (e) {
      print("View story error: $e");
    }
  }
}
