import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_radius.dart';
import 'app_palette.dart';
import '../widgets/motion.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: AppColors.primaryAccent.withAlpha(20),
      extensions: const <ThemeExtension<dynamic>>[
        AppPalette.light(),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF2563EB),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF2563EB),
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.lightTextPrimary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerLow: AppColors.lightSurface,
        surfaceContainer: AppColors.lightSurface2,
        surfaceContainerHigh: AppColors.lightSurface3,
        surfaceContainerHighest: AppColors.lightSurface3,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorderStrong,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: TextStyle(
          color: AppColors.lightTextMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialogRadius,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextSecondary,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.bottomSheetRadius,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        deleteIconColor: AppColors.lightTextSecondary,
        disabledColor: AppColors.lightBorder,
        selectedColor: const Color(0xFF2563EB),
        secondarySelectedColor: AppColors.primaryLight,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipRadius,
          side: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightSurface2,
        contentTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
        displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.lightTextPrimary),
        bodyMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.lightTextSecondary),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      ),
    );
  }

  /// Dark variant of the school theme.
  ///
  /// Adaptive neutral values in [AppColors] are kept in sync by
  /// `AppColors.applyDark(true)` whenever this theme is active, so screens
  /// reading `AppColors.*` statics render correctly on the dark palette too.
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3B82F6),
      scaffoldBackgroundColor: AppColors.darkBackground,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: AppColors.primaryAccent.withAlpha(30),
      extensions: const <ThemeExtension<dynamic>>[
        AppPalette.dark(),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF2563EB),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF3B82F6),
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.gold,
        onSecondary: Colors.black,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurface2,
        surfaceContainerHigh: AppColors.darkSurface3,
        surfaceContainerHighest: AppColors.darkSurface3,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderStrong,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingH,
            vertical: AppSpacing.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF60A5FA),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF60A5FA),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface2,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialogRadius,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface2,
        modalBackgroundColor: AppColors.darkSurface2,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.bottomSheetRadius,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface2,
        deleteIconColor: const Color(0xFF94A3B8),
        disabledColor: AppColors.darkBorder,
        selectedColor: const Color(0xFF3B82F6),
        secondarySelectedColor: AppColors.primary,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipRadius,
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface2,
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkTextPrimary),
        displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.darkTextPrimary),
        bodyMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      ),
    );
  }
}
