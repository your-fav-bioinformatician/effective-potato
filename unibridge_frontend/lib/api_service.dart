import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // for kIsWeb

class UniBridgeApi {
  static String get baseUrl {
    if (kIsWeb) {
      // FIX: Use 127.0.0.1 instead of localhost to avoid IPv6 resolution issues on Windows
      return 'http://127.0.0.1:8080'; 
    }
    if (Platform.isAndroid) {
      // Android Emulator Loopback
      return 'http://10.0.2.2:8080';
    }
    // iOS / Desktop Native
    return 'http://127.0.0.1:8080';
  }
  
  int? currentUserId;

  Future<bool> initializeUser(Map<String, dynamic> userData) async {
    print("Connecting to $baseUrl/quiz/init..."); 
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quiz/init'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['user_id'];
        return true;
      }
      return false;
    } catch (e) {
      print("Error Init: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getNextQuestion() async {
    if (currentUserId == null) return null;
    try {
      final response = await http.get(Uri.parse('$baseUrl/quiz/next_q?user_id=$currentUserId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print("Error NextQ: $e");
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
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error ProcessA: $e");
      return false;
    }
  }

  Future<List<dynamic>> getResults(String username, String password) async {
    if (currentUserId == null) return [];
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/results/results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUserId, 'username': username, 'password': password}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
      return [];
    } catch (e) {
      print("Error Results: $e");
      return [];
    }
  }
}