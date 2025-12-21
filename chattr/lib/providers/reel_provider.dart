import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ReelProvider with ChangeNotifier {
  List<Reel> _reels = [];
  bool _isLoading = false;

  List<Reel> get reels => _reels;
  bool get isLoading => _isLoading;

  Future<void> fetchReels() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/reels');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _reels = data.map((json) => Reel.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch reels error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReel(XFile? video, String caption) async {
    if (video == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.postMultipart('/reels', {'caption': caption}, video);
      if (response.statusCode == 201) {
        fetchReels();
        return true;
      }
    } catch (e) {
      print("Create reel error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
