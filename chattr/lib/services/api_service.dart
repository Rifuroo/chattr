import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static String get baseUrl {
    // Production URL (Hugging Face Spaces)
    return "https://rifuro-chattr-backend.hf.space";
  }

  static String get wsUrl {
    // Ensure wss:// is used for production and handle port 0 issues
    String url = baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    // If the URL ends with a colon (e.g. from some misconfiguration), remove it or ensure it's not :0
    if (url.endsWith(':0')) {
      url = url.substring(0, url.length - 2);
    }
    return url;
  }

  static String get giphyApiKey {
    // Current key causing 401. User should replace this with a valid Giphy SDK key.
    return "7R0B1n8lqGvVIBwA6jO6pG7S4oGvQk0e";
  }
  
  static Future<Map<String, String>> getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return headers;
    } catch (e) {
      return {'Content-Type': 'application/json'};
    }
  }

  static Future<http.Response> post(String endpoint, dynamic body) async {
    try {
      final headers = await getHeaders();
      return await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    } catch (e) {
      print("ApiService.post error at $endpoint: $e");
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, dynamic body) async {
    try {
      final headers = await getHeaders();
      return await http.put(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    } catch (e) {
      print("ApiService.put error at $endpoint: $e");
      rethrow;
    }
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      final headers = await getHeaders();
      return await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
      );
    } catch (e) {
      print("ApiService.get error at $endpoint: $e");
      rethrow;
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await getHeaders();
      return await http.delete(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
      );
    } catch (e) {
      print("ApiService.delete error at $endpoint: $e");
      rethrow;
    }
  }

  static Future<http.StreamedResponse> postMultipart(String endpoint, Map<String, String> fields, List<XFile>? files, {String fieldName = 'media'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    fields.forEach((key, value) {
        request.fields[key] = value.toString();
    });
    
    if (files != null) {
      for (var file in files) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            fieldName,
            await file.readAsBytes(),
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
        }
      }
    }
    
    return await request.send();
  }

  static Future<http.Response> repost(int postId, String content) async {
    try {
      final headers = await getHeaders();
      return await http.post(
        Uri.parse("$baseUrl/posts/$postId/repost"),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
    } catch (e) {
      print("ApiService.repost error: $e");
      rethrow;
    }
  }

  static Future<http.StreamedResponse> putMultipart(String endpoint, Map<String, String> fields, XFile? file, {String fieldName = 'image'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    var request = http.MultipartRequest('PUT', Uri.parse("$baseUrl$endpoint"));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token'; // Fixed: using Bearer prefix for consistency
    }
    
    fields.forEach((key, value) {
        request.fields[key] = value.toString();
    });
    
    if (file != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          fieldName,
          await file.readAsBytes(),
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      }
    }
    
    return await request.send();
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final response = await get('/users/search?q=$query');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getExploreFeed() async {
    final response = await get('/posts/explore');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<bool> toggleSave(int postId) async {
    final response = await post('/posts/$postId/save', {});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['saved'] ?? false;
    }
    return false;
  }

  static Future<List<dynamic>> getSavedPosts() async {
    final response = await get('/users/saved');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<http.Response> votePoll(int postId, int optionIndex) async {
    return await post('/posts/$postId/vote', {'option_index': optionIndex});
  }

  // --- Phase 6: Privacy & Blocking ---
  static Future<bool> toggleBlock(int userId) async {
    final response = await post('/users/$userId/block', {});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['blocked'] ?? false;
    }
    return false;
  }

  static Future<List<dynamic>> getFollowRequests() async {
    final response = await get('/users/requests');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<http.Response> respondToFollowRequest(int requestId, String action) async {
    return await post('/users/requests/$requestId/respond', {'action': action});
  }

  // --- Phase 6: Anonymous Tells ---
  static Future<http.Response> sendTell(int userId, String content) async {
    return await post('/users/$userId/tell', {'content': content});
  }

  static Future<List<dynamic>> getMyTells() async {
    final response = await get('/tells');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<http.Response> markTellAsRead(int tellId) async {
    return await put('/tells/$tellId/read', {});
  }

  // --- Phase 6: Post Insights ---
  static Future<void> viewPost(int postId) async {
    // Fire and forget view update
    post('/posts/$postId/view', {});
  }
}
