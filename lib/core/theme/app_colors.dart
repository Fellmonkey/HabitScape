import 'package:flutter/material.dart';

/// Semantic color system — nature-inspired, no red/green "good/bad" split.
///
/// Light values are the canonical palette. Dark counterparts live in
/// [AppPalette] (`core/theme/app_palette.dart`) — a ThemeExtension registered
/// on both themes — so the same meaning renders in the right ink per theme.
abstract final class AppColors {
  // ── Light mode backgrounds ──────────────────────────────────
  static const Color lightBackground = Color(0xFFFAF7F2); // Oatmeal
  static const Color lightSurface = Color(0xFFFFFDF9);
  static const Color lightText = Color(0xFF2C2C2C);
  static const Color lightTextSecondary = Color(0xFF7A7A7A);

  // ── Dark mode backgrounds (Ink & candlelight) ──────────────
  static const Color darkBackground = Color(0xFF16130F); // Warm ink espresso
  static const Color darkSurface = Color(0xFF201C15); // Warm charcoal
  static const Color darkText = Color(0xFFF1EBDF); // Ivory
  static const Color darkTextSecondary = Color(0xFFAAA294); // Taupe

  // ── Accent colors (time-of-day / semantic) ─────────────────
  static const Color sageGreen = Color(0xFF8FAF7A); // Morning / Growth
  static const Color warmAmber = Color(0xFFD4A767); // Afternoon / Activity
  static const Color softLavender = Color(0xFFB8A9D4); // Evening / Sleep
  static const Color mutedTerracotta = Color(0xFFCD7F63); // Alt-afternoon

  // ── Dark-mode accents (same meanings, tuned for dark ink) ──
  static const Color darkSage = Color(0xFFAAC29A); // Moss
  static const Color darkAmber = Color(0xFFE1B679); // Candlelight gold
  static const Color darkLavender = Color(0xFFBCA7D5); // Dusk lilac
  static const Color darkTerracotta = Color(0xFFCF8D72); // Ember

  // ── Habit feedback colors ──────────────────────────────────
  static const Color emeraldGlow = Color(0xFF3DB87A); // Done
  static const Color coolGreyBlue = Color(0xFF8DA4BF); // Skip (neutral)
  static const Color dustyRose = Color(0xFFB07A8A); // Fail (autumn leaf)
  static const Color fadedPlum = Color(0xFF9B7A9B); // Fail alt

  // ── Dark-mode feedback ─────────────────────────────────────
  static const Color darkEmerald = Color(0xFF80CC9A); // Jade
  static const Color darkGreyBlue = Color(0xFF96A6B8); // Mist slate
  static const Color darkRose = Color(0xFFC68595); // Rosewood
  static const Color darkPlum = Color(0xFFA78CB0);

  // ── Glass morphism ─────────────────────────────────────────
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x2EFFF2E0);
}
