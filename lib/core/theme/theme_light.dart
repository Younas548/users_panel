import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildLightTheme(Color seed) {
  // Base + dynamic color scheme from the chosen seed
  final base = ThemeData.light(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: GoogleFonts.interTextTheme(base.textTheme),

    // Surfaces
    scaffoldBackgroundColor: Colors.white,

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

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    ),
  );
}
