import 'package:flutter/material.dart';

/// CivicSight AI Color Palette
class AppColors {
  AppColors._();

  // ─── Brand Colors ───
  static const Color primaryBlue = Color(0xFF1A4D94);
  static const Color primaryOrange = Color(0xFFF28C38);
  static const Color darkText = Color(0xFF1A2B47);

  // ─── Light Theme ───
  static const Color lightBg1 = Color(0xFFD6E4F0);
  static const Color lightBg2 = Color(0xFFF9D1B7);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;

  // ─── Dark Theme ───
  static const Color darkBg1 = Color(0xFF1A1A2E);
  static const Color darkBg2 = Color(0xFF16213E);
  static const Color darkSurface = Color(0xFF1E1E30);
  static const Color darkCard = Color(0xFF252540);
  static const Color darkText2 = Color(0xFFE0E0E0);

  // ─── Status Colors ───
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // ─── Gradients ───
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBg1, lightBg2],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBg1, darkBg2],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryBlue, primaryOrange],
  );
}
