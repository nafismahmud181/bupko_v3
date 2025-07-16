import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        // Primary colors
        primary: Color(0xFF29B6F6),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF4FC3F7),
        onPrimaryContainer: Colors.white,
        
        // Secondary colors
        secondary: Color(0xFF667EEA),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF764BA2),
        onSecondaryContainer: Colors.white,
        
        // Surface colors
        surface: Color(0xFFF8F9FA),
        onSurface: Color(0xFF1A1A2E),
        surfaceVariant: Color(0xFFE3F2FD),
        onSurfaceVariant: Color(0xFF1A1A2E),
        
        // Background colors
        background: Color(0xFFF8F9FA),
        onBackground: Color(0xFF1A1A2E),
        
        // Error colors
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        
        // Other colors
        outline: Color(0xFFBBDEFB),
        shadow: Color(0xFF000000),
        inverseSurface: Color(0xFF1A1A2E),
        onInverseSurface: Colors.white,
        inversePrimary: Color(0xFF4FC3F7),
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Additional theme customizations
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        foregroundColor: Color(0xFF1A1A2E),
        elevation: 0,
      ),
      
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF29B6F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Additional customizations
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: const ColorScheme.dark(
        // Primary colors
        primary: Color(0xFF667EEA),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF764BA2),
        onPrimaryContainer: Colors.white,
        
        // Secondary colors
        secondary: Color(0xFF4FC3F7),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF29B6F6),
        onSecondaryContainer: Colors.white,
        
        // Surface colors
        surface: Color(0xFF1A1A2E),
        onSurface: Colors.white,
        surfaceVariant: Color(0xFF16213E),
        onSurfaceVariant: Colors.white,
        
        // Background colors
        background: Color(0xFF1A1A2E),
        onBackground: Colors.white,
        
        // Error colors
        error: Color(0xFFEF5350),
        onError: Colors.white,
        
        // Other colors
        outline: Color(0xFF0F3460),
        shadow: Color(0xFF000000),
        inverseSurface: Color(0xFFF8F9FA),
        onInverseSurface: Color(0xFF1A1A2E),
        inversePrimary: Color(0xFF667EEA),
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Additional theme customizations
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      cardTheme: CardThemeData(
        color: const Color(0xFF16213E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Additional customizations
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF16213E),
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  // Theme Colors as constants for easy access
  static const Color lightPrimary = Color(0xFF29B6F6);
  static const Color lightSecondary = Color(0xFF667EEA);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFE3F2FD);
  
  static const Color darkPrimary = Color(0xFF667EEA);
  static const Color darkSecondary = Color(0xFF4FC3F7);
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);
}