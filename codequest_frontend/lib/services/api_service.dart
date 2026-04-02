import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/quest_models.dart';
import '../models/user_model.dart';

class ApiService {
  // iOS Simulator: localhost | Android emulator: 10.0.2.2 | Physical: LAN IP
  final String baseUrl = "http://localhost:5050/api";
  final storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── AUTH ───────────────────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim().toLowerCase(), 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] as String?;
        if (token != null) await storage.write(key: 'auth_token', value: token);
        return token;
      }
    } catch (e) {
      debugPrint("Login API Error: $e");
    }
    return null;
  }

  Future<String?> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/signup"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': name, 'email': email.trim().toLowerCase(), 'password': password}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] as String?;
        if (token != null) await storage.write(key: 'auth_token', value: token);
        return token;
      }
    } catch (e) {
      debugPrint("Signup API Error: $e");
    }
    return null;
  }

  // ── COURSE MAP ─────────────────────────────────────────────────────────────
  Future<FullChapterModel?> getChapter(String courseSlug, int chapterNumber) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/learning/courses/$courseSlug/map"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chapters = data['chapters'] as List? ?? [];
        final chapter = chapters.firstWhere(
          (c) => c['chapter_number'] == chapterNumber,
          orElse: () => null,
        );
        if (chapter == null) return null;
        return FullChapterModel.fromJson({
          'course': data['course']['title'],
          'chapter': chapter['chapter_number'],
          'chapter_name': chapter['chapter_name'],
          'subtopics': chapter['subtopics'] ?? [],
        });
      }
    } catch (e) {
      debugPrint("Map Fetch Error: $e");
    }
    return null;
  }

  // ── SUBTOPIC QUESTIONS ─────────────────────────────────────────────────────
  // Returns all questions for a subtopic node, limited to 7 by the provider
  Future<List<QuizQuestion>> getSubtopicQuestions(String subtopicId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/learning/subtopics/$subtopicId/questions"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List rawQuestions = data['questions'] ?? [];
        return rawQuestions.map((q) => QuizQuestion.fromJson(q)).toList();
      }
    } catch (e) {
      debugPrint("Subtopic Questions Fetch Error: $e");
    }
    return [];
  }

  // ── USER PROFILE ───────────────────────────────────────────────────────────
  Future<UserModel?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/profile"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data['user']);
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
    }
    return null;
  }

  // ── SYNC STATS (XP + Streak → DB) ─────────────────────────────────────────
  Future<void> syncStats(int xp, int streak) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/user/sync"),
        headers: await _getHeaders(),
        body: json.encode({'xp': xp, 'streak': streak}),
      );
    } catch (e) {
      debugPrint("Stats Sync Error: $e");
    }
  }

  // ── SYNC PROGRESS (subtopic completion → DB) ───────────────────────────────
  // subtopicId is a String (MongoDB ObjectId)
  Future<void> syncProgress(String subtopicId, bool isCorrect) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/user/progress"),
        headers: await _getHeaders(),
        body: json.encode({
          'question_id': subtopicId,
          'status': isCorrect ? 'completed' : 'failed',
          'is_correct': isCorrect,
        }),
      );
    } catch (e) {
      debugPrint("Progress Sync Error: $e");
    }
  }
}
