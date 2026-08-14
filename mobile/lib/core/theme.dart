import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/auth_widgets.dart';

class AppTheme {
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color emergencyDark = Color(0xFFB71C1C);
  static const Color successGreen = Color(0xFF43A047);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = _scheme(isDark);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: isDark ? kAuthInk : kAuthBg,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? kAuthInk : kAuthCard,
        foregroundColor: isDark ? scheme.onSurface : kAuthText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: isDark ? scheme.onSurface : kAuthText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _solidButtonStyle(scheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _solidButtonStyle(scheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: scheme.outline),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          overlayColor: scheme.secondaryContainer.withValues(alpha: 0.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? const Color(0xFFF2A3A2)
              : kAuthRedLink,
          overlayColor:
              scheme.primaryContainer.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAuthRed, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAuthRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAuthRed, width: 1.4),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? scheme.onSurfaceVariant : kAuthMuted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: scheme.outline,
        ),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: kAuthRedDark),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? kAuthInk : kAuthCard,
        elevation: 0,
        height: 68,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? const Color(0xFFF2A3A2) : kAuthRedLink,
              size: 22,
            );
          }
          return IconThemeData(color: kAuthIcon, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF2A3A2) : kAuthRedLink,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: kAuthIcon,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? kAuthBg : kAuthText,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13.5,
          color: isDark ? kAuthText : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(12),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primaryContainer.withValues(alpha: 0.6);
          }
          return scheme.surfaceContainerHighest.withValues(alpha: 0.5);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: scheme.primary,
        labelColor: isDark ? const Color(0xFFF2A3A2) : kAuthRedLink,
        unselectedLabelColor: kAuthFaint,
        dividerColor: scheme.outline,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13.5,
          color: isDark ? scheme.onSurfaceVariant : kAuthMuted,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13.5,
          color: scheme.onSurface,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(scheme.primary),
      ),
    );
  }

  static ColorScheme _scheme(bool isDark) {
    if (isDark) {
      return ColorScheme(
        brightness: Brightness.dark,
        primary: const Color(0xFFF07271),
        onPrimary: const Color(0xFF40100F),
        primaryContainer: const Color(0xFF4A1413),
        onPrimaryContainer: const Color(0xFFF9DADA),
        secondary: const Color(0xFFB9B8B2),
        onSecondary: const Color(0xFF2A2A27),
        secondaryContainer: const Color(0xFF33332E),
        onSecondaryContainer: const Color(0xFFE8E7E0),
        tertiary: const Color(0xFF8FB1F2),
        onTertiary: const Color(0xFF16284A),
        tertiaryContainer: const Color(0xFF1C3A66),
        onTertiaryContainer: const Color(0xFFDCE8FF),
        error: const Color(0xFFF26B6A),
        onError: const Color(0xFF2E0A0A),
        errorContainer: const Color(0xFF4A1413),
        onErrorContainer: const Color(0xFFF9DADA),
        surface: kAuthInk,
        onSurface: const Color(0xFFF2F1ED),
        surfaceContainerLowest: const Color(0xFF141412),
        surfaceContainerLow: const Color(0xFF1E1E1B),
        surfaceContainer: const Color(0xFF24241F),
        surfaceContainerHigh: const Color(0xFF2B2B26),
        surfaceContainerHighest: const Color(0xFF32322C),
        onSurfaceVariant: const Color(0xFFA3A29B),
        outline: const Color(0xFF3F3E39),
        outlineVariant: const Color(0xFF2E2D29),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFFF2F1ED),
        onInverseSurface: const Color(0xFF2A2A27),
        inversePrimary: const Color(0xFFFFB4B2),
        surfaceTint: Colors.transparent,
      );
    }
    return ColorScheme(
      brightness: Brightness.light,
      primary: kAuthRed,
      onPrimary: Colors.white,
      primaryContainer: kAuthRedBadgeBg,
      onPrimaryContainer: kAuthRedBadgeText,
      secondary: kAuthMuted,
      onSecondary: Colors.white,
      secondaryContainer: kAuthNeutralTint,
      onSecondaryContainer: const Color(0xFF3A3935),
      tertiary: kAuthBlue,
      onTertiary: Colors.white,
      tertiaryContainer: kAuthBlueTint,
      onTertiaryContainer: const Color(0xFF16396F),
      error: kAuthRed,
      onError: Colors.white,
      errorContainer: kAuthRedBadgeBg,
      onErrorContainer: kAuthRedBadgeText,
      surface: kAuthCard,
      onSurface: kAuthText,
      surfaceContainerLowest: kAuthCard,
      surfaceContainerLow: const Color(0xFFFCFCFB),
      surfaceContainer: kAuthBg,
      surfaceContainerHigh: kAuthNeutralTint,
      surfaceContainerHighest: const Color(0xFFEDECE7),
      onSurfaceVariant: kAuthMuted,
      outline: kAuthBorder,
      outlineVariant: const Color(0xFFE4E2DA),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: kAuthText,
      onInverseSurface: kAuthBg,
      inversePrimary: const Color(0xFFFFB4B2),
      surfaceTint: Colors.transparent,
    );
  }

  static ButtonStyle _solidButtonStyle(ColorScheme scheme) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest.withValues(alpha: 0.6);
        }
        if (states.contains(WidgetState.pressed)) return kAuthRedPressed;
        if (states.contains(WidgetState.hovered)) return kAuthRedDark;
        return kAuthRed;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.4);
        }
        return Colors.white;
      }),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      overlayColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}