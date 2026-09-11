import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class UserService {
  String get baseUrl => AppConfig.baseUrl;

  final storage = const FlutterSecureStorage();

  // Key must match exactly what AuthService writes after login
  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // POST /api/user/update-language
  Future<bool> updateSelectedLanguage(String languageId) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('UserService.updateSelectedLanguage: no token found');
      return false;
    }
    try {
      final uri = Uri.parse('$baseUrl/user/update-language');
      debugPrint('UserService → POST $uri  body: {language: $languageId}');
      final response = await http
          .post(
            uri,
            headers: await _authHeaders(),
            body: jsonEncode({'language': languageId}),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
        'updateSelectedLanguage ← ${response.statusCode}: ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updateSelectedLanguage error: $e');
      return false;
    }
  }

  // POST /api/user/set-level
  Future<bool> setManualLevel(String level) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('UserService.setManualLevel: no token found');
      return false;
    }
    try {
      final uri = Uri.parse('$baseUrl/user/set-level');
      debugPrint('UserService → POST $uri  body: {level: $level}');
      final response = await http
          .post(
            uri,
            headers: await _authHeaders(),
            body: jsonEncode({'level': level}),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('setManualLevel ← ${response.statusCode}: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('setManualLevel error: $e');
      return false;
    }
  }

  // POST /api/user/evaluate-level
  Future<Map<String, dynamic>?> evaluatePlacement(
    List<Map<String, dynamic>> results,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/user/evaluate-level');
      debugPrint('UserService → POST $uri  answers count: ${results.length}');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'answers': results}),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
        'evaluatePlacement ← ${response.statusCode}: ${response.body}',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('evaluatePlacement error: $e');
      return null;
    }
  }
}
