import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildDarkTheme(Color seed) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    primary: ZColors.emerald,
    secondary: ZColors.sky,
    background: ZColors.bgDark,
    surface: ZColors.cardDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ZColors.bgDark,
    textTheme: buildTextTheme(dark: true),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: ZColors.textOnDark,
    ),

    elevatedButtonTheme: zElevatedButtonTheme(ZColors.emerald, Colors.white),
    inputDecorationTheme: zInputDecorationTheme(dark: true),

    cardTheme: CardThemeData(
      color: ZColors.cardDark,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withOpacity(.25),
      elevation: 0,
    ),

    dividerColor: ZColors.strokeDark,
    iconTheme: const IconThemeData(color: ZColors.textOnDark),
  );
}
