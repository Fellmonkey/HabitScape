import 'package:flutter/material.dart';

/// Semantic color system — nature-inspired, no red/green "good/bad" split.
abstract final class AppColors {
  // ── Light mode backgrounds ──────────────────────────────────
  static const Color lightBackground = Color(0xFFFAF7F2); // Oatmeal
  static const Color lightSurface = Color(0xFFFFFDF9);
  static const Color lightText = Color(0xFF2C2C2C);
  static const Color lightTextSecondary = Color(0xFF7A7A7A);

  // ── Dark mode backgrounds ──────────────────────────────────
  static const Color darkBackground = Color(0xFF0E1A2B); // Midnight Navy
  static const Color darkSurface = Color(0xFF162236);
  static const Color darkText = Color(0xFFF0EDE8);
  static const Color darkTextSecondary = Color(0xFF9AA8BD);

  // ── Accent colors (time-of-day / semantic) ─────────────────
  static const Color sageGreen = Color(0xFF8FAF7A); // Morning / Growth
  static const Color warmAmber = Color(0xFFD4A767); // Afternoon / Activity
  static const Color softLavender = Color(0xFFB8A9D4); // Evening / Sleep
  static const Color mutedTerracotta = Color(0xFFCD7F63); // Alt-afternoon

  // ── Habit feedback colors ──────────────────────────────────
  static const Color emeraldGlow = Color(0xFF3DB87A); // Done
  static const Color coolGreyBlue = Color(0xFF8DA4BF); // Skip (neutral)
  static const Color dustyRose = Color(0xFFB07A8A); // Fail (autumn leaf)
  static const Color fadedPlum = Color(0xFF9B7A9B); // Fail alt

  // ── Bioluminescence glow (Dark mode accents) ───────────────
  static const Color glowCyan = Color(0xFF4DFFD2);
  static const Color glowViolet = Color(0xFFB388FF);
  static const Color glowEmerald = Color(0xFF69F0AE);

  // ── Glass morphism ─────────────────────────────────────────
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x33FFFFFF);
}
