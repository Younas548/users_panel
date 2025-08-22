import 'package:flutter/material.dart';

/// COLOR PALETTE (base)
class ZColors {
  // Brand
  static const emerald = Color(0xFF10B981);
  static const sky     = Color(0xFF38BDF8);
  static const amber   = Color(0xFFF59E0B);

  // Light surfaces
  static const bgLight      = Color(0xFFF8FAFC); // slate-50-ish
  static const cardLight    = Color(0xFFFFFFFF);
  static const strokeLight  = Color(0xFFE2E8F0);

  // Dark surfaces
  static const bgDark       = Color(0xFF0F172A); // slate-900
  static const cardDark     = Color(0xFF111827); // slate-800
  static const strokeDark   = Color(0xFF1F2937); // slate-700

  // Text
  static const textPrimary  = Color(0xFF0F172A);
  static const textMuted    = Color(0xFF64748B);
  static const textOnDark   = Color(0xFFE5E7EB);
}

/// SPACING & RADII (use everywhere)
class Insets {
  static const x = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class Corners {
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r14 = Radius.circular(14);
  static const r16 = Radius.circular(16);
  static const r20 = Radius.circular(20);
}

class Gaps {
  static const g8  = SizedBox(height: 8);
  static const g12 = SizedBox(height: 12);
  static const g16 = SizedBox(height: 16);
  static const g24 = SizedBox(height: 24);
  static const g32 = SizedBox(height: 32);
}

/// TEXT THEME (light & dark variants)
TextTheme buildTextTheme({required bool dark}) {
  final onBg = dark ? ZColors.textOnDark : ZColors.textPrimary;
  final muted = dark ? ZColors.textOnDark.withValues(alpha: .72) : ZColors.textMuted;

  return TextTheme(
    headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: onBg),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: onBg),
    headlineSmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onBg),

    titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onBg),
    titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onBg),
    titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onBg),

    bodyLarge:      TextStyle(fontSize: 16, height: 1.4, color: onBg),
    bodyMedium:     TextStyle(fontSize: 14, height: 1.4, color: onBg),
    bodySmall:      TextStyle(fontSize: 12, color: muted),

    labelLarge:     const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    labelMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onBg),
  );
}

/// COMMON COMPONENT THEMES (re-used in both themes)
ElevatedButtonThemeData zElevatedButtonTheme(Color bg, Color fg) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Corners.r16)),
    ),
  );
}

InputDecorationTheme zInputDecorationTheme({required bool dark}) {
  final fill = dark ? ZColors.cardDark : ZColors.cardLight;
  final stroke = dark ? ZColors.strokeDark : ZColors.strokeLight;

  return InputDecorationTheme(
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Corners.r14),
      borderSide: BorderSide(color: stroke),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Corners.r14),
      borderSide: BorderSide(color: stroke),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Corners.r14),
      borderSide: BorderSide(color: ZColors.sky),
    ),
  );
}
