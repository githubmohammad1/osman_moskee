import 'package:flutter/material.dart';

// ===============================================
// 1. تعريف الألوان المشتركة والأساسية
// ===============================================

// أخضر داكن (Teal/Mosque Green)
const Color _primaryGreen = Color(0xFF00695C);
// ذهبي/كهرماني للتمييز والأزرار
const Color _accentGold = Color(0xFFFFB300);
// خلفية فاتحة هادئة
const Color _lightBackground = Color(0xFFF5F5F5);
// خلفية غامقة مريحة
const Color _darkBackground = Color(0xFF1A1A1A);
// لون البطاقات الفاتح
const Color _lightCardColor = Colors.white;
// لون البطاقات الداكن
const Color _darkCardColor = Color(0xFF2B2B2B);

// ===============================================
// 2. سمة الوضع الفاتح (LIGHT THEME)
// ===============================================

final ThemeData lightTheme = ThemeData(
  // ⬅️ تم إزالة 'primarySwatch' واستخدام 'colorScheme' لـ Material 3
  fontFamily: 'NotoSansArabic',
  brightness: Brightness.light,
  useMaterial3: true,

  scaffoldBackgroundColor: _lightBackground, // خلفية التطبيق العامة
  cardColor: _lightCardColor, // لون البطاقات

  colorScheme: ColorScheme.light(
    primary: _primaryGreen, // اللون الأساسي (للـ FAB والأيقونات)
    secondary: _accentGold,
    surface: _lightCardColor, // لون الأسطح والبطاقات
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  ),

  // تنسيق الشريط العلوي (AppBar)
  appBarTheme: const AppBarTheme(
    backgroundColor: _primaryGreen,
    foregroundColor: Colors.white, // لون الأيقونات والنص في الـ AppBar
    elevation: 4.0,
    titleTextStyle: TextStyle(
      fontFamily: 'NotoSansArabic',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  // تنسيق الأزرار العائمة
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _accentGold,
    foregroundColor: Colors.black,
    elevation: 6.0,
  ),

  // تنسيق النص
  textTheme: const TextTheme(
    // تنسيق العنوان الكبير (يستخدم افتراضياً للعناوين الرئيسية)
    titleLarge: TextStyle(
      fontFamily: 'NotoSansArabic',
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    // تنسيق الجسم الأساسي
    bodyMedium: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.black87),
  ),
);

// ===============================================
// 3. سمة الوضع الغامق (DARK THEME)
// ===============================================

final ThemeData darkTheme = ThemeData(
  fontFamily: 'NotoSansArabic',
  brightness: Brightness.dark,
  useMaterial3: true,

  scaffoldBackgroundColor: _darkBackground, // خلفية التطبيق العامة
  cardColor: _darkCardColor, // لون البطاقات

  colorScheme: ColorScheme.dark(
    primary: _primaryGreen.withOpacity(0.8), // لون أساسي أفتح قليلاً للوضوح
    secondary: _accentGold,
    surface: _darkCardColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  ),

  // تنسيق الشريط العلوي (AppBar)
  appBarTheme: AppBarTheme(
    backgroundColor: _darkCardColor, // خلفية داكنة متسقة
    foregroundColor: Colors.white,
    elevation: 4.0,
    titleTextStyle: const TextStyle(
      fontFamily: 'NotoSansArabic',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  // تنسيق الأزرار العائمة (نفس لون التمييز)
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blue, // ⬅️ تم تغيير اللون إلى الأزرق
    foregroundColor:
        Colors.white, // تم تغيير لون الأيقونة إلى الأبيض لتباين أفضل
    elevation: 6.0,
  ),

  // تنسيق النص
  textTheme: const TextTheme(
    // العنوان الكبير
    titleLarge: TextStyle(
      fontFamily: 'NotoSansArabic',
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    // الجسم الأساسي
    bodyMedium: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.white70),
  ),
);
