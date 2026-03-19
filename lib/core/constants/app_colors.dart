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
    'Agri-Aqua and Forestry': teal,
    'Food Processing and Nutrition': Color(0xFFFF8C42),
    'Health and Medical Sciences': crimson,
    'Energy, Utilities, and Environment': golden,
    'Information and Communications Technology (ICT)': Color(0xFF1B4B8A),
    'Advanced Manufacturing and Engineering': navy,
    'Creative Industries and Product Design': sky,
  };

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F6FA);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF333333);
  static const Color charcoal = Color(0xFF1A1A2E);

  // Cinematic Extensions
  static const Color deepVoid = Color(0xFF050A12);
  static const Color midnight = Color(0xFF0D1117);
  static const Color richNavy = Color(0xFF061A2E);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color goldSheen = Color(0xFFFFD700);
  static const Color warmEmber = Color(0xFFFF6B35);
  static const Color darkSurface = Color(0xFF0F1923);
  static const Color borderDark = Color(0xFF1E2D3D);
}

