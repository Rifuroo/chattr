import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _explorePosts = [];
  List<Post> _savedPosts = [];
  bool _isLoading = false;

  List<Post> get posts => _posts;
  List<Post> get explorePosts => _explorePosts;
  List<Post> get savedPosts => _savedPosts;
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

  Future<bool> createPost(String content, List<XFile>? files, {
    String? pollQuestion, 
    List<String>? pollOptions, 
    String? spotifyTrackID,
    bool isFlash = false,
    int? expiresIn,
    bool isCollaborative = false,
  }) async {
    try {
      final Map<String, String> fields = {
        'content': content,
        'is_flash': isFlash.toString(),
        'is_collaborative': isCollaborative.toString(),
      };
      if (expiresIn != null) {
        fields['expires_in'] = expiresIn.toString();
      }
      if (pollQuestion != null && pollOptions != null) {
        fields['poll_question'] = pollQuestion;
        fields['poll_options'] = jsonEncode(pollOptions);
      }
      if (spotifyTrackID != null) {
        fields['spotify_track_id'] = spotifyTrackID;
      }
      final response = await ApiService.postMultipart('/posts', fields, files);
      if (response.statusCode == 201) {
        fetchPosts(); // Refresh feed
        return true;
      }
    } catch (e) {
      print("Create post error: $e");
    }
    return false;
  }

  Future<bool> repost(int postId, String content) async {
    try {
      final response = await ApiService.repost(postId, content);
      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPosts();
        return true;
      }
    } catch (e) {
      print("Repost error: $e");
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

  Future<bool> commentPost(int postId, String content, {int? parentId, String? gifUrl}) async {
    try {
      final response = await ApiService.post('/posts/$postId/comment', {
        'content': content,
        'parent_id': parentId,
        'gif_url': gifUrl,
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

  Future<void> fetchExploreFeed() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getExploreFeed();
      _explorePosts = data.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print("Explore error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSavedPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getSavedPosts();
      // SavedPost model in backend wraps Post, so we need to map differently if needed
      // but let's assume getSavedPosts returns list of posts for now or we map it.
      // Based on my backend implementation: config.DB...Find(&savedPosts) where each has a Post.
      _savedPosts = data.map((json) => Post.fromJson(json['post'])).toList();
    } catch (e) {
      print("Fetch saved error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSave(int postId) async {
    try {
      final isSaved = await ApiService.toggleSave(postId);
      // We don't have a 'isSaved' field in Post model yet, but we can verify in lists
      fetchSavedPosts(); // Refresh saved list
      return isSaved;
    } catch (e) {
      print("Toggle save error: $e");
      return false;
    }
  }

  Future<void> votePoll(int postId, int optionIndex) async {
    try {
      final response = await ApiService.votePoll(postId, optionIndex);
      if (response.statusCode == 200) {
        fetchPosts(); // Refresh for new counts
      }
    } catch (e) {
      print("Vote poll error: $e");
    }
  }

  Future<void> viewPost(int postId) async {
    try {
      await ApiService.viewPost(postId);
      // Increment locally for immediate visual feedback if necessary
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        // Since Post is immutable in my logic (fields are final), we just accept it updates on next fetch
        // or we could replace the post object. For views, next fetch is fine.
      }
    } catch (e) {
      print("View post error: $e");
    }
  }

  Future<String?> generateAICaption(String prompt) async {
    try {
      final response = await ApiService.post('/ai/generate-caption', {'prompt': prompt});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['caption'];
      }
    } catch (e) {
      print("AI caption error: $e");
    }
    return null;
  }

  Future<bool> addPollOption(int postId, String option) async {
    try {
      final response = await ApiService.postMultipart('/posts/$postId/poll/options', {'option': option}, null);
      if (response.statusCode == 201) {
        fetchPosts();
        return true;
      }
    } catch (e) {
      print("Add poll option error: $e");
    }
    return false;
  }
}
