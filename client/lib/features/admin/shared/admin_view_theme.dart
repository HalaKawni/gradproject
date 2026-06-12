import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminViewTheme {
  static const Color background = Color(0xFFF3F0EA);
  static const Color panel = Color(0xFFFFFCF6);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF3288BD);
  static const Color primarySoft = Color(0xFF9ED3DC);
  static const Color accent = Color(0xFFFCC5D2);
  static const Color accentStrong = Color(0xFFE37C9A);
  static const Color highlight = Color(0xFFFFF39B);
  static const Color success = Color(0xFF6DB84A);
  static const Color text = Color(0xFF29404E);
  static const Color mutedText = Color(0xFF6A7A86);
  static const Color border = Color(0xFFE5DDD2);
  static const Color danger = Color(0xFFD95D5D);

  static BoxDecoration pageDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3F0EA), Color(0xFFEAF5F7), Color(0xFFFFF8EF)],
      ),
    );
  }

  static BoxDecoration shellPanelDecoration() {
    return BoxDecoration(
      color: panel.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  static BoxDecoration softCardDecoration([Color? tint]) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: (tint ?? border).withValues(alpha: tint == null ? 1 : 0.28),
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: text,
      displayColor: text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accentStrong,
        surface: surface,
        error: danger,
      ),
      textTheme: textTheme.copyWith(
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: mutedText,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: border,
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: accent,
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: const IconThemeData(color: mutedText),
        selectedLabelTextStyle: GoogleFonts.montserrat(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: GoogleFonts.montserrat(
          color: mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: panel,
        foregroundColor: text,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: text,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentStrong,
          textStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: primarySoft.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: text,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: mutedText,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(18),
        ),
        dividerColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}
