import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechTheme {
  // 🎨 Color Palette (Neon / Cyberpunk)
  static const Color deepPurpleBG = Color(0xFF0D0221);
  static const Color cardPurple = Color(0xFF261447);
  static const Color darkBoxFill = Color(0xFF1E1136); // Added for the new Auth Screen
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color textSoft = Color(0xFFB57EDC);
  static const Color readableWhite = Color(0xFFF0F0F0);

  // ✒️ Typography (Retro Neon + Clean Sans)
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.pressStart2p( 
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: neonMagenta,
        letterSpacing: 1.5,
      ),
      displayMedium: GoogleFonts.vt323(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: neonCyan,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: readableWhite,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: neonCyan,
      ),
      labelLarge: GoogleFonts.vt323(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: neonMagenta,
      ),
    );
  }

  // 🧩 Decorations (Sharp / Glowing)
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardPurple,
    borderRadius: BorderRadius.circular(0),
    border: Border.all(color: neonCyan, width: 2),
    boxShadow: [
      BoxShadow(
        color: neonMagenta.withValues(alpha: 0.6),
        blurRadius: 10, 
        offset: const Offset(4, 4),
      ),
    ],
  );

  static InputDecoration inputDecoration(String hint) => InputDecoration(
    filled: true,
    fillColor: deepPurpleBG,
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: textSoft),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0),
      borderSide: const BorderSide(color: neonCyan, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0),
      borderSide: const BorderSide(color: neonCyan, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0),
      borderSide: const BorderSide(color: neonMagenta, width: 3),
    ),
  );
}