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

  static Future<http.StreamedResponse> postMultipart(String endpoint, Map<String, String> fields, XFile? file, {String fieldName = 'image'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Ensure no null values in fields to prevent "Cannot send Null" error
    fields.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
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
}
