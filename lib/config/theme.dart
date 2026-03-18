import 'package:flutter/material.dart';

/// 앱 테마 — 프리미엄 다크 신비로운 스타일
class AppTheme {
  AppTheme._();

  // ── 배경 ──
  static const Color bgDark = Color(0xFF0B0D1F);
  static const Color bgCard = Color(0xFF141833);
  static const Color bgElevated = Color(0xFF1C2045);

  // ── 악센트 ──
  static const Color gold = Color(0xFFC9A86C);
  static const Color goldBright = Color(0xFFE8D5A8);
  static const Color purple = Color(0xFF8B7EC8);

  // ── 텍스트 ──
  static const Color textPrimary = Color(0xFFEEEEF0);
  static const Color textSecondary = Color(0xFF7E7E9A);
  static const Color textMuted = Color(0xFF4A4A64);

  // ── 손금 선 (네온 톤) ──
  static const Color lifeLine = Color(0xFFFF6B6B);
  static const Color heartLine = Color(0xFFFF8EC8);
  static const Color fateLine = Color(0xFFA78BFA);
  static const Color headLine = Color(0xFF60A5FA);

  // ── 운세 ──
  static const Color loveFortune = Color(0xFFFF6B9D);
  static const Color wealthFortune = Color(0xFFFFD700);
  static const Color healthFortune = Color(0xFF4ADE80);
  static const Color careerFortune = Color(0xFF38BDF8);
  static const Color academicFortune = Color(0xFFC084FC);

  // ── 그라데이션 ──
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDark, Color(0xFF12102E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1E42), Color(0xFF141833)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC9A86C), Color(0xFFE0C88A)],
  );

  // ── 카드 데코레이션 (글라스모피즘) ──
  static BoxDecoration get glassCard => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );

  static BoxDecoration get glassCardGold => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withValues(alpha: 0.15),
        ),
      );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: purple,
        surface: bgCard,
        onPrimary: bgDark,
        onSurface: textPrimary,
      ),
      fontFamily: null,
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
    );
  }
}
