/// Money helpers. All amounts in this app are `double`s in store-currency
/// units; the rule is that anything persisted or displayed has passed
/// through [roundMoney] so binary-float noise (0.1 + 0.2, 10 − 33 %, …)
/// never reaches the DB, receipts, or reports.
library;

enum RoundingMode { halfUp, halfEven, truncate }

/// Rounds [value] to 2 decimal places.
///
/// Corrects for the float representation error that makes naive
/// `(v * 100).round() / 100` misround half-cents:
///   0.145 → 0.15   (naive gives 0.14, because 0.145 * 100 = 14.499999…)
///   0.29  → 0.29 under truncate (naive gives 0.28, 0.29 * 100 = 28.999999…)
///   6.699999999999999 → 6.70
double roundMoney(double value, [RoundingMode mode = RoundingMode.halfUp]) {
  if (value.isNaN || value.isInfinite) return value;
  const eps = 1e-6; // far below any real cent fraction, above float noise
  final scaled = value * 100;
  final nudged = scaled + (scaled.isNegative ? -eps : eps);
  switch (mode) {
    case RoundingMode.halfUp:
      return nudged.roundToDouble() / 100;
    case RoundingMode.truncate:
      return nudged.truncateToDouble() / 100;
    case RoundingMode.halfEven:
      final floor = nudged.floorToDouble();
      final fraction = scaled - floor;
      if ((fraction - 0.5).abs() < eps) {
        // Exactly half a cent: go to the even neighbour.
        return (floor.toInt().isEven ? floor : floor + 1) / 100;
      }
      return nudged.roundToDouble() / 100;
  }
}
