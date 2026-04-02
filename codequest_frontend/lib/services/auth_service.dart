import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // iOS Simulator uses localhost perfectly
  final String baseUrl = "http://localhost:5050/api/user";
  final storage = const FlutterSecureStorage();

  // LOGIN: Returns true if token is saved, else false
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await storage.write(key: 'auth_token', value: data['token']);
          return true;
        }
      }
      print("Login Server Error: ${response.body}");
      return false;
    } catch (e) {
      print("Login Network Error: $e");
      return false;
    }
  }

  // SIGNUP: Returns true if account created and token saved
  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await storage.write(key: 'auth_token', value: data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
