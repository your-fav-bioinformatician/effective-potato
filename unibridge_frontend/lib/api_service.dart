import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UniBridgeApi extends ChangeNotifier {
  // Update this to your actual backend URL (e.g., your local network IP or deployed domain)
  static const String baseUrl = 'https://effective-potato-production.up.railway.app'; 
  
  String? _currentUserId;
  String? _currentUsername;
  String? _token;

  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;
  bool get isAuthenticated => _token != null;

  // --- HEADERS ---
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- SESSION MANAGEMENT ---
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final username = prefs.getString('username');
      final userId = prefs.getString('user_id');

      if (token != null && token.isNotEmpty) {
        _token = token;
        _currentUsername = username;
        _currentUserId = userId;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
    return false;
  }

  Future<void> _saveSession(String token, String username, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('username', username);
    await prefs.setString('user_id', userId);
    
    _token = token;
    _currentUsername = username;
    _currentUserId = userId;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _token = null;
    _currentUsername = null;
    _currentUserId = null;
    notifyListeners();
  }

  // --- AUTHENTICATION ---
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], username, data['user_id'] ?? username);
        return true;
      } else {
        debugPrint('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signup(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Auto-login after successful registration
        return await login(username, password);
      } else {
        debugPrint('Signup failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      return false;
    }
  }

  // --- ASSESSMENT FLOW ---
  Future<bool> initializeUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assessment/init'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Init user failed: ${response.body}');
        throw Exception('Failed to initialize profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Init user error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getNextQuestion() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assessment/question'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming API returns { "status": "active", "layer": 1, "question_data": {...} }
        // or { "status": "completed" }
        return data;
      } else {
        debugPrint('Get question failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Get question error: $e');
      return null;
    }
  }

  Future<void> processAnswer(int answerValue) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assessment/answer'),
        headers: _headers,
        body: jsonEncode({
          'answer_value': answerValue,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Process answer failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Process answer error: $e');
    }
  }

  // --- RESULTS ---
  Future<List<dynamic>> getResults(String username, String queryParam) async {
    try {
      // Allow passing a specific username or default to current session
      final targetUser = username.isNotEmpty ? username : _currentUsername;
      
      final response = await http.get(
        Uri.parse('$baseUrl/results?user=$targetUser&q=$queryParam'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('matches')) {
          return data['matches'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
        return [];
      } else {
        debugPrint('Get results failed: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Get results error: $e');
      return [];
    }
  }
}