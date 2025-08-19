import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildDarkTheme(Color seed) {
  final base = ThemeData.dark(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: GoogleFonts.interTextTheme(base.textTheme),

    // Dark background
    scaffoldBackgroundColor: const Color(0xFF101114),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
  );
}
