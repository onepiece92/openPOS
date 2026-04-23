/// Design tokens for spacing, radius, and opacity.
///
/// Replaces magic numbers scattered across presentation widgets. Values align
/// with the defaults already baked into [AppTheme] so migration is mechanical.
library;

abstract final class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

abstract final class Radii {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
}

abstract final class AppOpacity {
  static const double subtle = 0.07;
  static const double soft = 0.10;
  static const double medium = 0.15;
  static const double strong = 0.30;
  static const double heavy = 0.82;
}

/// Font families registered in pubspec.yaml's `fonts:` block.
///
/// Use [AppFonts.mono] for anything numeric / column-aligned: totals,
/// KPIs, prices, currency amounts, receipt lines. Labels and prose stay
/// on the default theme font.
abstract final class AppFonts {
  /// JetBrains Mono — monospaced, good for numbers + receipts.
  static const String mono = 'JetBrainsMono';
}
