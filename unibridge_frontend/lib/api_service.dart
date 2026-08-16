import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UniBridgeApi {
  static String get baseUrl {
    return 'https://effective-potato-production.up.railway.app';
  }

  String? currentUserId; 
  String? currentUsername;

  static const String _keyUserId = 'unibridge_user_id';
  static const String _keyUsername = 'unibridge_username';

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString(_keyUserId);
    if (storedUserId == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify/$storedUserId'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        currentUserId = storedUserId;
        currentUsername = prefs.getString(_keyUsername);
        return true;
      }
    } catch (e) {
      debugPrint("Session restore error: $e");
    }
    
    await clearLocalSession();
    return false;
  }

  Future<void> _saveLocalSession(String userId, [String? username]) async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = userId;
    await prefs.setString(_keyUserId, userId);
    if (username != null) {
      currentUsername = username;
      await prefs.setString(_keyUsername, username);
    }
  }

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    currentUserId = null;
    currentUsername = null;
  }

  // Adjusted to handle guest or authenticated flow
  Future<bool> initializeUser(Map<String, dynamic> userData) async {
    try {
      // If already logged in, attach their ID to the initialization payload
      if (currentUserId != null) {
        userData['user_id'] = currentUserId;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/quiz/init'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final id = data['user_id'].toString();
        // Only save session if it's a new ID to avoid overwriting existing auth
        if (currentUserId == null) {
           await _saveLocalSession(id);
        }
        return true;
      } else {
        throw Exception("Server [${response.statusCode}]: ${response.body}");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  Future<bool> signup(String username, String email, String password) async {
    try {
      final payload = {
        'username': username,
        'email': email,
        'password': password
      };
      
      // If they are a guest upgrading, send their current ID
      if (currentUserId != null) {
        payload['user_id'] = currentUserId!;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveLocalSession(data['user_id'] ?? currentUserId ?? 'temp_id', username);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Signup error: $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveLocalSession(data['user_id'], data['username']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    if (currentUserId != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': currentUserId}),
        );
      } catch (e) {
        debugPrint("Logout server sync error: $e");
      }
    }
    await clearLocalSession();
  }

  Future<Map<String, dynamic>?> getNextQuestion() async {
    if (currentUserId == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quiz/next_q?user_id=$currentUserId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint("Error NextQ: $e");
      return null;
    }
  }

  Future<bool> processAnswer(int answer) async {
    if (currentUserId == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quiz/process_a'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUserId, 'answer': answer}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error ProcessA: $e");
      return false;
    }
  }

  // ✅ Replace your existing getResults with this exactly:
  Future<List<dynamic>> getResults() async {
    if (currentUserId == null) return [];
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/results/results'),
        headers: {'Content-Type': 'application/json'},
        // The backend now securely checks DB using just the user_id
        body: jsonEncode({'user_id': currentUserId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        // Triggers the post-quiz guest signup form
        throw Exception("GUEST_AUTH_REQUIRED");
      }
      return [];
    } catch (e) {
      debugPrint("Error Results: $e");
      rethrow; 
    }
  }
}