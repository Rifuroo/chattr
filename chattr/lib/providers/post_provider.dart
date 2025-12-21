import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;

  Future<void> fetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/posts');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _posts = data.map((json) => Post.fromJson(json)).toList();
      }
    } catch (e) {
      print("Fetch posts error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPost(String content, XFile? file) async {
    try {
      final response = await ApiService.postMultipart('/posts', {'content': content}, file);
      if (response.statusCode == 201) {
        fetchPosts(); // Refresh feed
        return true;
      }
    } catch (e) {
      print("Create post error: $e");
    }
    return false;
  }

  Future<void> likePost(int postId) async {
    try {
      final response = await ApiService.post('/posts/$postId/like', {});
      if (response.statusCode == 200) {
        // Toggle like locally for instant feedback if possible, or just refresh
        fetchPosts(); 
      }
    } catch (e) {
      print("Like post error: $e");
    }
  }

  Future<bool> commentPost(int postId, String content, {int? parentId}) async {
    try {
      final response = await ApiService.post('/posts/$postId/comment', {
        'content': content,
        'parent_id': parentId,
      });
      if (response.statusCode == 201) {
        fetchPosts();
        return true;
      }
    } catch (e) {
      print("Comment post error: $e");
    }
    return false;
  }

  Future<void> likeComment(int commentId) async {
    try {
      final response = await ApiService.post('/comments/$commentId/like', {});
      if (response.statusCode == 200) {
        fetchPosts();
      }
    } catch (e) {
      print("Like comment error: $e");
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      final response = await ApiService.delete('/posts/$postId');
      if (response.statusCode == 200) {
        _posts.removeWhere((p) => p.id == postId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Delete post error: $e");
    }
    return false;
  }
}
