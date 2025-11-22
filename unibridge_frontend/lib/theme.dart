import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechTheme {
  // 🎨 Color Palette (2000s Digital Pastel)
  static const Color primaryBlue = Color(0xFF6C8EBF); // Soft Windows-ish Blue
  static const Color secondaryBlue = Color(0xFFDAE8FC); // Very light blue bg
  static const Color borderGrey = Color(0xFF999999); // Classic grey borders
  static const Color backgroundGrey = Color(0xFFF0F0F0); // Classic App BG
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF333333);
  static const Color textSoft = Color(0xFF666666);
  static const Color accentTeal = Color(0xFF82B366); // Soft Green
  static const Color dangerRed = Color(0xFFB85450); // Muted Red

  // ✒️ Typography (Digital + Clean)
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.vt323( // Or Roboto Mono
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textMain,
        letterSpacing: 1.0,
      ),
      displayMedium: GoogleFonts.robotoMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textMain,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textMain,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSoft,
      ),
      labelLarge: GoogleFonts.robotoMono(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textMain,
      ),
    );
  }

  // 🧩 Decorations (Beveled / Boxy)
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(4), // Boxy
    border: Border.all(color: borderGrey, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 0, // Hard shadow for retro feel
        offset: const Offset(3, 3),
      ),
    ],
  );

  static InputDecoration inputDecoration(String hint) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: textSoft),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: borderGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: borderGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: primaryBlue, width: 2),
    ),
  );
}