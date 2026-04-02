import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // --- Background & Surfaces ---
  static const Color background = Color(0xFF0B0E14); // Deep Space Dark
  static const Color surface = Color(0xFF161B22); // Card/Modal background
  static const Color surfaceLight = Color(
    0xFF21262D,
  ); // Hover/Highlight surface

  // --- Brand Colors (The Neon Trio) ---
  static const Color primary = Color(
    0xFF22D3EE,
  ); // Electric Cyan (Primary Action)
  static const Color secondary = Color(
    0xFFA855F7,
  ); // Cyber Purple (Progress/Nodes)
  static const Color accent = Color(0xFFF472B6); // Neon Pink (Hearts/Alerts)

  // --- Functional Colors ---
  static const Color success = Color(
    0xFF22D3EE,
  ); // We use Cyan for success to stay on brand
  static const Color error = Color(0xFFF472B6); // Pink for errors/losses
  static const Color warning = Color(0xFFFBBF24); // Amber for tips/locked items
  static const Color highlight = Color(0xFFFBBF24); // Gold for Gems/Rewards

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFFE2E8F0); // Main readable text
  static const Color textSecondary = Color(
    0xFF94A3B8,
  ); // Subtitles/Descriptions
  static const Color textInverted = Color(0xFF0B0E14); // Text on bright buttons

  // --- Neon Glow Effects ---
  // Use these in BoxShadows to get that "Cyber" look
  static Color primaryGlow = const Color(0xFF22D3EE).withOpacity(0.3);
  static Color secondaryGlow = const Color(0xFFA855F7).withOpacity(0.3);
  static Color accentGlow = const Color(0xFFF472B6).withOpacity(0.3);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nodeLockedGradient = LinearGradient(
    colors: [Color(0xFF21262D), Color(0xFF0B0E14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
