import 'package:flutter/material.dart';

class TechTheme {
  // --- CORE COLORS ---
  static const Color deepPurpleBG = Color(0xFF0B0B1A); // Very dark, almost black purple
  static const Color cardPurple = Color(0xFF15152E);   // Slightly lighter for cards/surfaces
  static const Color neonCyan = Color(0xFF00F0FF);     // Primary accent
  static const Color neonMagenta = Color(0xFFFF003C);  // Secondary/Action accent
  static const Color readableWhite = Color(0xFFEAEAEA);
  static const Color textSoft = Color(0xFFA0A0B0);

  // --- TYPOGRAPHY ---
  // Note: For the web, ensure you have included fonts like 'VT323', 'Press Start 2P', 
  // or 'Inter' in your pubspec.yaml and web/index.html if importing from Google Fonts.
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'VT323', fontSize: 42, fontWeight: FontWeight.bold, color: readableWhite, letterSpacing: 2),
    displayMedium: TextStyle(fontFamily: 'VT323', fontSize: 28, fontWeight: FontWeight.bold, color: neonCyan, letterSpacing: 1.5),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: readableWhite),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: textSoft),
    labelLarge: TextStyle(fontFamily: 'VT323', fontSize: 18, fontWeight: FontWeight.bold, color: neonMagenta, letterSpacing: 1.2),
  );

  // --- DECORATIONS ---
  // Cyberpunk style cards: rigid, sharp borders, faint neon glow
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardPurple,
    border: Border.all(color: neonMagenta, width: 1),
    borderRadius: BorderRadius.zero, // Strict cyberpunk aesthetic dictates sharp edges
    boxShadow: [
      BoxShadow(
        color: neonMagenta.withValues(alpha: 0.15),
        blurRadius: 10,
        spreadRadius: 1,
      )
    ],
  );

  // Cyberpunk style inputs
  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textSoft.withValues(alpha: 0.5)),
      filled: true,
      fillColor: deepPurpleBG,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: neonCyan, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: neonMagenta, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // --- GLOBAL THEME DATA ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: deepPurpleBG,
    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: neonMagenta,
      surface: cardPurple,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: deepPurpleBG,
      elevation: 0,
      iconTheme: IconThemeData(color: neonCyan),
      scrolledUnderElevation: 0, // Prevents color shift when scrolling
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: neonMagenta,
      selectionColor: neonCyan,
      selectionHandleColor: neonCyan,
    ),
  );
}