import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Palette
  static const Color crimson = Color(0xFFD00000);
  static const Color golden = Color(0xFFFFBA08);
  static const Color sky = Color(0xFF3F88C5);
  static const Color navy = Color(0xFF032B43);
  static const Color teal = Color(0xFF136F63);

  // Category Color Map
  static const Map<String, Color> categoryColors = {
    'Agriculture': teal,
    'Healthcare': crimson,
    'Energy': golden,
    'Construction': navy,
    'Product Design': sky,
    'Information Technology': Color(0xFF1B4B8A),
  };

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F6FA);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF333333);
  static const Color charcoal = Color(0xFF1A1A2E);
}

