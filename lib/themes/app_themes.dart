// lib/app_themes.dart
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// سمة الوضع الفاتح
final ThemeData lightTheme = ThemeData(
   fontFamily: 'NotoSansArabic',


  primarySwatch: Colors.teal,
  
  brightness: Brightness.light,
  // ألوان إضافية للوضع الفاتح
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    brightness: Brightness.light,
  ),
);

// سمة الوضع الغامق
final ThemeData darkTheme = ThemeData(
   fontFamily: 'NotoSansArabic',

  primarySwatch: Colors.teal,
  brightness: Brightness.dark,
  // ألوان إضافية للوضع الغامق
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    brightness: Brightness.dark,
  ),
);