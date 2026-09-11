import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;

  AuthResult({required this.success, required this.message, this.token});
}

class AuthService {
  String get baseUrl => "${AppConfig.baseUrl}/user";
  final storage = const FlutterSecureStorage();

  // LOGIN
  Future<bool> login(String email, String password) async {
    final result = await loginWithResult(email, password);
    return result.success;
  }

  Future<AuthResult> loginWithResult(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await storage.write(key: 'auth_token', value: data['token']);
        return AuthResult(success: true, message: 'Login successful', token: data['token']);
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Invalid email or password.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error. Check network.');
    }
  }

  // SIGNUP
  Future<bool> register(String username, String email, String password) async {
    final result = await registerWithResult(username, email, password);
    return result.success;
  }

  Future<AuthResult> registerWithResult(String username, String email, String password) async {
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

      final data = json.decode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) && data['token'] != null) {
        await storage.write(key: 'auth_token', value: data['token']);
        return AuthResult(success: true, message: 'Registration successful', token: data['token']);
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Signup failed. Email might be in use.',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Connection error. Check network.');
    }
  }
}
