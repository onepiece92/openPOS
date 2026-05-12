import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos_app/core/theme/tokens.dart';

/// iOS 26 / iPhone 17 "Liquid Glass" inspired theme.
///
/// Key ideas:
///  – Transparent scaffold + global gradient background  → glass feel without
///    wrapping every widget in BackdropFilter.
///  – Cards: semi-transparent surface + subtle white border.
///  – Chips, buttons, inputs: heavily rounded with glass-tinted fills.
///  – Color palette: rich indigo-violet primary, cyan secondary, pink tertiary.
abstract final class AppTheme {
  // ── Brand seed ────────────────────────────────────────────────────────────
  static const _seed = Color(0xFF6B68FF); // iOS 26-style violet

  // ── Background gradients ──────────────────────────────────────────────────

  static Gradient backgroundGradient(Brightness brightness) =>
      brightness == Brightness.dark ? _darkGrad : _lightGrad;

  static const _darkGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF07070E), Color(0xFF0D0C1C), Color(0xFF090914)],
    stops: [0.0, 0.55, 1.0],
  );

  static const _lightGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEECFF), Color(0xFFF8F7FF), Color(0xFFEAE8FF)],
    stops: [0.0, 0.55, 1.0],
  );

  // ── CTA button style (checkout / primary action) ──────────────────────────
  //
  // Use for full-width primary action buttons (e.g. Checkout, Pay, Save).
  // Height should be enforced by a SizedBox(height: 56) at the call site.

  static ButtonStyle ctaButtonStyle(ColorScheme cs) =>
      FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        // Override shape only — textStyle/elevation inherited from filledButtonTheme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      );

  // ── Icon button style (checkout bar) ──────────────────────────────────────

  static ButtonStyle iconButtonStyle(ColorScheme cs, {bool isActive = false}) =>
      OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        side: isActive ? BorderSide(color: cs.primary, width: 2) : null,
      );

  // ── Frosted glass bottom bar decoration ───────────────────────────────────
  //
  // Applied to the container that holds checkout / payment bars at the bottom.
  // Wrap the container in a ClipRect + BackdropFilter for the blur effect.

  static BoxDecoration frostedBar(ColorScheme cs) {
    final dark = cs.brightness == Brightness.dark;
    return BoxDecoration(
      color: dark
          ? const Color(0xFF0E0E1E).withValues(alpha: AppOpacity.heavy)
          : Colors.white.withValues(alpha: 0.80),
      border: Border(
        top: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.09)
              : Colors.black.withValues(alpha: AppOpacity.subtle),
        ),
      ),
    );
  }

  // ── Semantic text-style helpers ───────────────────────────────────────────
  //
  // Pre-composed styles that match recurring patterns (section headers,
  // subtle captions). Prefer these over `textTheme.x.copyWith(...)` at call
  // sites so the look stays consistent across screens.

  static TextStyle sectionLabel(BuildContext ctx) => Theme.of(ctx)
      .textTheme
      .labelSmall!
      .copyWith(
        color: Theme.of(ctx).colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      );

  static TextStyle subtleCaption(BuildContext ctx) => Theme.of(ctx)
      .textTheme
      .bodySmall!
      .copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant);

  // ── Glass decoration helpers ──────────────────────────────────────────────

  static BoxDecoration glassCard(
    ColorScheme cs, {
    double radius = 20,
    EdgeInsets? padding,
  }) {
    final dark = cs.brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [
                const Color(0xFF1E1E34).withValues(alpha: 0.88),
                const Color(0xFF14142A).withValues(alpha: 0.72),
              ]
            : [
                Colors.white.withValues(alpha: 0.82),
                Colors.white.withValues(alpha: 0.60),
              ],
      ),
      border: Border.all(
        color: dark
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.80),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.30 : 0.07),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        if (!dark)
          BoxShadow(
            color: _seed.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
      ],
    );
  }

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData light() {
    final scheme = _lightScheme();
    return _build(scheme, _textTheme(Brightness.light));
  }

  static ColorScheme _lightScheme() =>
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light)
          .copyWith(
        surface: const Color(0xFFF2F1FF),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF0EFFE),
        surfaceContainer: const Color(0xFFE8E7F8),
        surfaceContainerHigh: const Color(0xFFE0DFF4),
        surfaceContainerHighest: const Color(0xFFD8D7F0),
        primary: const Color(0xFF5E5BE8),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE2E0FF),
        onPrimaryContainer: const Color(0xFF1A1880),
        secondary: const Color(0xFF00B8C8),
        onSecondary: Colors.white,
        tertiary: const Color(0xFFE01E6A),
        onTertiary: Colors.white,
        error: const Color(0xFFD93025),
      );

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData dark() {
    final scheme = _darkScheme();
    return _build(scheme, _textTheme(Brightness.dark));
  }

  static ColorScheme _darkScheme() =>
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark)
          .copyWith(
        surface: const Color(0xFF08080E),
        surfaceContainerLowest: const Color(0xFF040408),
        surfaceContainerLow: const Color(0xFF0E0E1C),
        surfaceContainer: const Color(0xFF141428),
        surfaceContainerHigh: const Color(0xFF1C1C34),
        surfaceContainerHighest: const Color(0xFF242440),
        primary: const Color(0xFF8A88FF),
        onPrimary: const Color(0xFF18166A),
        primaryContainer: const Color(0xFF3A38B0),
        onPrimaryContainer: const Color(0xFFDFDEFF),
        secondary: const Color(0xFF2ED8E8),
        onSecondary: const Color(0xFF003840),
        tertiary: const Color(0xFFFF70B4),
        onTertiary: const Color(0xFF5A0030),
        error: const Color(0xFFFF6B6B),
        onSurface: const Color(0xFFF0EFFF),
        onSurfaceVariant: const Color(0xFFAEACC8),
        outline: const Color(0xFF48486A),
        outlineVariant: const Color(0xFF2C2C48),
      );

  // ── Text theme ────────────────────────────────────────────────────────────

  static const _fontFamily = 'JetBrainsMono';

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base.apply(fontFamily: _fontFamily).copyWith(
      displayLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.0,
      ),
      headlineLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  // ── Shared builder ────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme, TextTheme tt) {
    final dark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: tt,
      scaffoldBackgroundColor: Colors.transparent,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: tt.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // ── Cards ──────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark
            ? const Color(0xFF1C1C34).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.84),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.80),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Navigation drawer ───────────────────────────────────────────────
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: dark
            ? const Color(0xFF0C0C1E).withValues(alpha: 0.97)
            : const Color(0xFFF5F4FF).withValues(alpha: 0.97),
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.22 : 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.all(
          tt.labelLarge?.copyWith(color: scheme.onSurface),
        ),
      ),

      // ── Input decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),

      // ── Chips ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.72),
        selectedColor: scheme.primary.withValues(alpha: dark ? 0.28 : 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.10)
                : scheme.primary.withValues(alpha: 0.25),
          ),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      // ── Filled button ───────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
          elevation: 0,
        ),
      ),

      // ── Outlined button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.22)
                : scheme.primary.withValues(alpha: 0.40),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),

      // ── List tile ───────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: scheme.primary,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.07),
        thickness: 1,
        space: 1,
      ),

      // ── Bottom sheet ────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark
            ? const Color(0xFF111126)
            : const Color(0xFFF7F6FF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
        dragHandleColor:
            dark ? Colors.white24 : Colors.black.withValues(alpha: 0.15),
        showDragHandle: true,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF1A1A30) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        titleTextStyle: tt.titleLarge,
        contentTextStyle: tt.bodyMedium,
      ),

      // ── Segmented button ────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          backgroundColor: dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.65),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.09),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── Switch ──────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),

      // ── Popup menu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? const Color(0xFF1E1E36) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),

      // ── Alert dialog ────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFF2A2A46) : const Color(0xFF1A1A2E),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
