import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFFDF7F2);
  static const Color backgroundSecondary = Color(0xFFF8EFE9);
  static const Color cardSurface = Colors.white;
  
  // Brand Accent (Coral / Warm Terracotta)
  static const Color primary = Color(0xFFE85A42);
  static const Color primaryLight = Color(0xFFFDECE8);
  static const Color primaryHover = Color(0xFFD54B33);
  
  // Typography
  static const Color textPrimary = Color(0xFF2E1A14);
  static const Color textSecondary = Color(0xFF755E57);
  static const Color textMuted = Color(0xFFAFA09A);
  static const Color stepLabel = Color(0xFFB87860);

  // Borders & Dividers
  static const Color border = Color(0xFFF0E5DE);
  static const Color borderSubtle = Color(0xFFF5ECE6);

  // Avatar Colors
  static const Color avatarBlueBg = Color(0xFFD9E2F7);
  static const Color avatarBlueText = Color(0xFF385388);
  static const Color avatarPinkBg = Color(0xFFFCDCE4);
  static const Color avatarPinkText = Color(0xFFBD4967);

  // Tags & Status
  static const Color tagSelectedBg = Color(0xFFFDEAE5);
  static const Color tagSelectedBorder = Color(0xFFF7CEBE);
  static const Color tagSelectedText = Color(0xFFD34830);

  static const Color tagUnselectedBg = Colors.white;
  static const Color tagUnselectedBorder = Color(0xFFEFE8E2);
  static const Color tagUnselectedText = Color(0xFF5A4943);

  // Badges
  static const Color sharedBadgeBg = Color(0xFFE8F5E9);
  static const Color sharedBadgeText = Color(0xFF2E7D32);
  static const Color privateBadgeBg = Color(0xFFFFF3E0);
  static const Color privateBadgeText = Color(0xFFE65100);
  static const Color surpriseBadgeBg = Color(0xFFF3E5F5);
  static const Color surpriseBadgeText = Color(0xFF7B1FA2);
}

class AppShadows {
  // 3D Embossed Card Shadow (Nổi khối 3D cho các Card, Container lớn)
  static List<BoxShadow> get card3D => [
    BoxShadow(
      color: const Color(0xFFE85A42).withValues(alpha: 0.09),
      offset: const Offset(0, 10),
      blurRadius: 26,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 10,
      spreadRadius: -1,
    ),
    const BoxShadow(
      color: Colors.white,
      offset: Offset(-1.5, -1.5),
      blurRadius: 3,
      spreadRadius: 1,
    ),
  ];

  // 3D Input Container Shadow (Nổi khối 3D cho ô nhập liệu)
  static List<BoxShadow> get input3D => [
    BoxShadow(
      color: const Color(0xFF522818).withValues(alpha: 0.06),
      offset: const Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Colors.white,
      offset: Offset(-1, -1),
      blurRadius: 2,
      spreadRadius: 1,
    ),
  ];

  // 3D Button Shadow (Nổi khối 3D rực rỡ cho các nút bấm chính)
  static List<BoxShadow> get button3D => [
    BoxShadow(
      color: const Color(0xFFE85A42).withValues(alpha: 0.45),
      offset: const Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFFE85A42).withValues(alpha: 0.28),
      offset: const Offset(0, 3),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.4),
      offset: const Offset(0, -2),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  // 3D Pill / Chip Shadow (Nổi khối 3D cho avatar, thẻ tag, nút nhỏ)
  static List<BoxShadow> get pill3D => [
    BoxShadow(
      color: const Color(0xFFE85A42).withValues(alpha: 0.12),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Colors.white,
      offset: Offset(-1, -1),
      blurRadius: 2,
      spreadRadius: 0.5,
    ),
  ];

  // 3D Subtle Badge / Icon Shadow
  static List<BoxShadow> get subtle3D => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  // 3D Floating Bubble Shadow (Cho tin nhắn AI, popups)
  static List<BoxShadow> get floating3D => [
    BoxShadow(
      color: const Color(0xFFE85A42).withValues(alpha: 0.1),
      offset: const Offset(0, 8),
      blurRadius: 22,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 3),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Colors.white,
      offset: Offset(-1, -1),
      blurRadius: 2,
      spreadRadius: 1,
    ),
  ];
}

class AppTypography {
  /// Handwriting cursive script style matching reference ("Love Advisor" in Caveat)
  static TextStyle script({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? 0.2,
      height: height,
      fontStyle: fontStyle,
      textStyle: TextStyle(
        fontFamilyFallback: [
          GoogleFonts.sriracha().fontFamily!,
          GoogleFonts.plusJakartaSans().fontFamily!,
        ],
      ),
    );
  }
}
