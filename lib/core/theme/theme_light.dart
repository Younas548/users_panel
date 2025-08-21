import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildLightTheme(Color seed) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: ZColors.emerald,
    secondary: ZColors.sky,
    background: ZColors.bgLight,
    surface: ZColors.cardLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ZColors.bgLight,
    textTheme: buildTextTheme(dark: false),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: ZColors.textPrimary,
    ),

    elevatedButtonTheme: zElevatedButtonTheme(ZColors.emerald, Colors.white),
    inputDecorationTheme: zInputDecorationTheme(dark: false),

    cardTheme: CardThemeData(
      color: ZColors.cardLight,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: const Color(0x14343A40),
      elevation: 0, // visual border/shadow we control manually per card
    ),

    dividerColor: ZColors.strokeLight,
    iconTheme: const IconThemeData(color: ZColors.textPrimary),
  );
}
