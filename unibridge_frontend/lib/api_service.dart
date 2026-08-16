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
  // Set by restoreSession(): whether this restored user already finished the
  // quiz, so the caller can route straight to results instead of always
  // dropping them back into the quiz.
  bool? lastRestoredQuizCompleted;

  static const String _keyUserId = 'unibridge_user_id';
  static const String _keyUsername = 'unibridge_username';

  // Pulls a human-readable message out of a FastAPI error response.
  // FastAPI's own validation errors (422) return `detail` as a LIST of
  // objects, while HTTPException(detail=...) returns it as a plain STRING.
  String _extractError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      final detail = body is Map ? body['detail'] : null;
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final messages = detail
            .map((e) => e is Map && e['msg'] != null ? e['msg'].toString() : e.toString())
            .join(' ');
        if (messages.isNotEmpty) return messages;
      }
      return "$fallback (HTTP ${response.statusCode})";
    } catch (e) {
      debugPrint("Could not parse error body: $e | raw: ${response.body}");
      return "$fallback (HTTP ${response.statusCode})";
    }
  }

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
        try {
          final data = jsonDecode(response.body);
          lastRestoredQuizCompleted = data['quiz_completed'] == true;
        } catch (_) {
          lastRestoredQuizCompleted = false;
        }
        return true;
      }
      debugPrint("Session restore failed: ${_extractError(response, 'Session invalid')}");
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

  Future<bool> initializeUser(Map<String, dynamic> userData) async {
    try {
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

  Future<String?> signup(String username, String email, String password) async {
    try {
      final Map<String, dynamic> payload = {
        'username': username.trim(),
        'email': email.trim(),
        'password': password
      };
      
      if (currentUserId != null && currentUserId!.isNotEmpty) {
        payload['user_id'] = currentUserId!;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      debugPrint("Signup response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveLocalSession(data['user_id'] ?? currentUserId ?? 'temp_id', username.trim());
        return null;
      }
      return _extractError(response, "Signup failed");
    } catch (e) {
      debugPrint("Signup error: $e");
      return "Network error while signing up: $e";
    }
  }

  Future<String?> login(String identifier, String password) async {
    try {
      final cleanIdentifier = identifier.trim();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        // Send both keys so FastAPI validation succeeds regardless of schema version
        body: jsonEncode({
          'email': cleanIdentifier,
          'username_or_email': cleanIdentifier,
          'password': password
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint("Login response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveLocalSession(data['user_id'], data['username']);
        return null;
      }
      return _extractError(response, "Login failed. Please verify credentials.");
    } catch (e) {
      debugPrint("Login error: $e");
      return "Network error while logging in: $e";
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

  Future<List<dynamic>> getResults() async {
    if (currentUserId == null) {
      throw Exception("NO_ACTIVE_SESSION");
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/results/results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUserId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception("GUEST_AUTH_REQUIRED");
      } else {
        throw Exception(_extractError(response, "Backend failed to calculate results"));
      }
    } catch (e) {
      debugPrint("Error Results: $e");
      rethrow; 
    }
  }
}