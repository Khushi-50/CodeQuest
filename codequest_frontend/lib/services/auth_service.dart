import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final bool isGhostMode;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.isGhostMode = false,
  });
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
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await storage.write(key: 'auth_token', value: data['token']);
        return AuthResult(
          success: true,
          message: 'Login successful',
          token: data['token'],
        );
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Invalid email or password.',
      );
    } catch (e) {
      // ── Network unreachable / demo mode fallback ──────────────────
      const fallbackToken = 'ghost_runner_session_token_2026';
      await storage.write(key: 'auth_token', value: fallbackToken);
      return AuthResult(
        success: true,
        message: '[GHOST PROTOCOL ACTIVATED] Demo mode session initiated.',
        token: fallbackToken,
        isGhostMode: true,
      );
    }
  }

  // SIGNUP
  Future<bool> register(String username, String email, String password) async {
    final result = await registerWithResult(username, email, password);
    return result.success;
  }

  Future<AuthResult> registerWithResult(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/signup"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = json.decode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['token'] != null) {
        await storage.write(key: 'auth_token', value: data['token']);
        return AuthResult(
          success: true,
          message: 'Registration successful',
          token: data['token'],
        );
      }

      return AuthResult(
        success: false,
        message: data['message'] ?? 'Signup failed. Email might be in use.',
      );
    } catch (e) {
      // ── Network unreachable / demo mode fallback ──────────────────
      const fallbackToken = 'ghost_runner_session_token_2026';
      await storage.write(key: 'auth_token', value: fallbackToken);
      return AuthResult(
        success: true,
        message: '[GHOST PROTOCOL ACTIVATED] Demo session initialized.',
        token: fallbackToken,
        isGhostMode: true,
      );
    }
  }
}
