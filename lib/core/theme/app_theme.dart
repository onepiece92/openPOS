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
///  – Colour: the brand's 60/30/10 split. Storm-grey tints for surfaces,
///    matte black for text, the side nav and dark surfaces, and safety
///    orange only for the main action and active/selected states.
///
/// Safety orange (#FF6600) fails AA as text or a thin line on every brand
/// surface (2.2–4.3:1), so it is only used as a FILL with matte-black on it
/// ([brandOrange] / [onBrandOrange]: main buttons, FAB, selected nav item,
/// segmented selection, switches). `colorScheme.primary` is an orange "ink"
/// tuned per brightness so text, icons and focus rings in orange pass AA.
abstract final class AppTheme {
  // ── Brand palette ─────────────────────────────────────────────────────────
  /// Safety orange: fills for the primary action / selected state only.
  static const brandOrange = Color(0xFFFF6600);

  /// Text and icons on [brandOrange] (5.00:1). Never white on orange.
  static const onBrandOrange = Color(0xFF28282B);

  /// Matte black: text, side nav, dark surfaces.
  static const matteBlack = Color(0xFF28282B);

  /// Storm grey (mid). Low contrast: borders/decoration, not body text.
  static const stormGrey = Color(0xFF717486);

  // ── Background gradients ──────────────────────────────────────────────────

  static Gradient backgroundGradient(Brightness brightness) =>
      brightness == Brightness.dark ? _darkGrad : _lightGrad;

  static const _darkGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E2F36), Color(0xFF32333B), Color(0xFF2F3037)],
    stops: [0.0, 0.55, 1.0],
  );

  static const _lightGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0F0F4), Color(0xFFF5F5F8), Color(0xFFEEEEF2)],
    stops: [0.0, 0.55, 1.0],
  );

  // ── CTA button style (checkout / primary action) ──────────────────────────
  //
  // Use for full-width primary action buttons (e.g. Checkout, Pay, Save).
  // Height should be enforced by a SizedBox(height: 56) at the call site.

  static ButtonStyle ctaButtonStyle(ColorScheme cs) =>
      FilledButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: onBrandOrange,
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
  // No blur: these bars sit in the bottomNavigationBar slot over the static
  // background gradient, where a BackdropFilter costs a pass per frame and
  // changes nothing visible. Only add one if content really scrolls behind.

  static BoxDecoration frostedBar(ColorScheme cs) {
    final dark = cs.brightness == Brightness.dark;
    return BoxDecoration(
      color: dark
          ? const Color(0xFF3C3D47).withValues(alpha: AppOpacity.heavy)
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
                const Color(0xFF3C3D47).withValues(alpha: 0.88),
                const Color(0xFF383942).withValues(alpha: 0.72),
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
            color: stormGrey.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
      ],
    );
  }

  // ── Light theme ───────────────────────────────────────────────────────────

  // Both themes depend on nothing at runtime, so each is built once and
  // reused: POSApp.build asks for them on every rebuild.
  static final ThemeData _light =
      _build(_lightScheme(), _textTheme(Brightness.light));
  static final ThemeData _dark =
      _build(_darkScheme(), _textTheme(Brightness.dark));

  static ThemeData light() => _light;

  /// Colours-only light theme for the bare open-failure screen, which runs
  /// before the app (and its fonts/background) is set up. Default text.
  static final ThemeData plainLight = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme(),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: onBrandOrange,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: matteBlack),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: matteBlack),
    ),
  );


  static ColorScheme _lightScheme() => const ColorScheme(
        brightness: Brightness.light,
        // Orange ink: 5.0:1 on tint #E8E9EE, 6.1:1 on white.
        primary: Color(0xFFA84300),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFDCDDE4),
        onPrimaryContainer: Color(0xFF28282B),
        // Storm-grey ink (held tickets, orders, secondary data).
        secondary: Color(0xFF4F5162),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE8E9EE),
        onSecondaryContainer: Color(0xFF28282B),
        // Violet: refunds, VAT, favourites; distinct from orange and red.
        tertiary: Color(0xFF6D35A0),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFEDE3F7),
        onTertiaryContainer: Color(0xFF3B1D57),
        // Crimson, kept away from the orange accent's hue.
        error: Color(0xFFB0103A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFADBE1),
        onErrorContainer: Color(0xFF5C0B1F),
        surface: Color(0xFFF5F5F8),
        onSurface: Color(0xFF28282B),
        onSurfaceVariant: Color(0xFF4F5162),
        surfaceDim: Color(0xFFDCDDE4),
        surfaceBright: Color(0xFFFFFFFF),
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF0F0F4),
        surfaceContainer: Color(0xFFE8E9EE),
        surfaceContainerHigh: Color(0xFFE2E3E9),
        surfaceContainerHighest: Color(0xFFDCDDE4),
        outline: Color(0xFF717486),
        outlineVariant: Color(0xFFC9CAD3),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF28282B),
        onInverseSurface: Color(0xFFF1F1F4),
        inversePrimary: Color(0xFFFFA366),
        surfaceTint: Color(0x00000000),
      );

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData dark() => _dark;

  static ColorScheme _darkScheme() => const ColorScheme(
        brightness: Brightness.dark,
        // Light orange ink: 4.7:1 on tint #464754, 5.5:1 on card.
        primary: Color(0xFFFFA366),
        onPrimary: Color(0xFF28282B),
        primaryContainer: Color(0xFF505261),
        onPrimaryContainer: Color(0xFFF1F1F4),
        secondary: Color(0xFFC6C8D2),
        onSecondary: Color(0xFF28282B),
        secondaryContainer: Color(0xFF464754),
        onSecondaryContainer: Color(0xFFF1F1F4),
        tertiary: Color(0xFFD0B3F5),
        onTertiary: Color(0xFF28282B),
        tertiaryContainer: Color(0xFF4A3D5E),
        onTertiaryContainer: Color(0xFFEDE3F7),
        error: Color(0xFFFFB3C1),
        onError: Color(0xFF28282B),
        errorContainer: Color(0xFF5C1A2A),
        onErrorContainer: Color(0xFFFFDAE0),
        surface: Color(0xFF32333B),
        onSurface: Color(0xFFF1F1F4),
        onSurfaceVariant: Color(0xFFC6C8D2),
        surfaceDim: Color(0xFF2E2F36),
        surfaceBright: Color(0xFF505261),
        surfaceContainerLowest: Color(0xFF2B2C33),
        surfaceContainerLow: Color(0xFF373841),
        surfaceContainer: Color(0xFF3C3D47),
        surfaceContainerHigh: Color(0xFF41424E),
        surfaceContainerHighest: Color(0xFF464754),
        outline: Color(0xFF9A9CAC),
        outlineVariant: Color(0xFF505261),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFF1F1F4),
        onInverseSurface: Color(0xFF28282B),
        inversePrimary: Color(0xFFA84300),
        surfaceTint: Color(0x00000000),
      );

  // ── Text theme ────────────────────────────────────────────────────────────

  static const _fontFamily = AppFonts.mono;
  static const _fontFallback = AppFonts.monoFallback;

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base
        .apply(fontFamily: _fontFamily, fontFamilyFallback: _fontFallback)
        .copyWith(
      displayLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.0,
      ),
      headlineLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: const TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: const TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
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
      fontFamilyFallback: _fontFallback,
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
            ? const Color(0xFF3C3D47).withValues(alpha: 0.85)
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
      // The side nav is matte black in both modes: PosDrawer renders it
      // with the dark theme, so this is what shows.
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: matteBlack.withValues(alpha: 0.97),
        elevation: 0,
        indicatorColor: brandOrange,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => tt.labelLarge?.copyWith(
            color: s.contains(WidgetState.selected)
                ? onBrandOrange
                : scheme.onSurface,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? onBrandOrange
                : scheme.onSurfaceVariant,
          ),
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
                : stormGrey.withValues(alpha: 0.35),
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
          backgroundColor: brandOrange,
          foregroundColor: onBrandOrange,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
          elevation: 0,
        ),
      ),

      // ── Text button ─────────────────────────────────────────────────────
      // Secondary actions stay matte black / light grey so orange stays
      // reserved for the main action.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
      ),

      // ── Outlined button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.22)
                : stormGrey.withValues(alpha: 0.60),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: brandOrange,
        foregroundColor: onBrandOrange,
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
        iconColor: scheme.onSurfaceVariant,
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
            ? const Color(0xFF3C3D47)
            : const Color(0xFFF5F5F8),
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
        backgroundColor: dark ? const Color(0xFF3C3D47) : Colors.white,
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
          selectedBackgroundColor: brandOrange,
          selectedForegroundColor: onBrandOrange,
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
          (s) => s.contains(WidgetState.selected) ? onBrandOrange : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brandOrange : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brandOrange : null,
        ),
      ),

      // ── Popup menu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? const Color(0xFF3C3D47) : Colors.white,
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
        backgroundColor: dark ? const Color(0xFF505261) : matteBlack,
        contentTextStyle: const TextStyle(color: Color(0xFFF1F1F4)),
        actionTextColor:
            dark ? const Color(0xFFFFBE8F) : const Color(0xFFFFA366),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Status colours that are not in [ColorScheme]. Hues are kept clearly
/// apart from the orange accent (#FF6600, hue 24°) so orange never reads as
/// a warning: success is green, warning / low stock is yellow-gold (hue ~46°),
/// errors are crimson and refunds use the scheme's violet tertiary.
abstract final class StatusColors {
  /// Success / profit. 5.3:1 (light, on tint-2) and 5.3:1 (dark, on tint).
  static Color success(ColorScheme cs) => cs.brightness == Brightness.dark
      ? const Color(0xFF4ADE80)
      : const Color(0xFF166534);

  /// Warning / low stock. 5.0:1 (light, on tint) and 6.0:1 (dark, on tint).
  static Color warning(ColorScheme cs) => cs.brightness == Brightness.dark
      ? const Color(0xFFEFD13A)
      : const Color(0xFF7A5E00);
}
