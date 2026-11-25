// Exact-arithmetic reference for the cart maths. Everything is in cents held
// as BigInt rationals, so no float error can hide in the oracle. It states
// the rules independently of CartCalculator: tax is worked out once per
// invoice and per rate, on the summed taxable base.
import 'package:pos_app/core/database/app_database.dart' show TaxRate;

class Frac {
  Frac(BigInt n, BigInt d)
      : n = d.isNegative ? -n : n,
        d = d.isNegative ? -d : d;
  Frac.i(int v) : this(BigInt.from(v), BigInt.one);
  final BigInt n;
  final BigInt d;
  Frac operator +(Frac o) => Frac(n * o.d + o.n * d, d * o.d);
  Frac operator -(Frac o) => Frac(n * o.d - o.n * d, d * o.d);
  Frac operator *(Frac o) => Frac(n * o.n, d * o.d);
  Frac operator /(Frac o) => Frac(n * o.d, d * o.n);
  bool get isNeg => n.isNegative;
  BigInt floor() {
    final q = n ~/ d; // truncates toward zero
    return (n.isNegative && q * d != n) ? q - BigInt.one : q;
  }

  /// mode: half_up | half_even | truncate (non-negative values only)
  BigInt round(String mode) {
    final fl = floor();
    final rem = this - Frac(fl, BigInt.one); // in [0,1)
    final twice = rem.n * BigInt.two;
    switch (mode) {
      case 'truncate':
        return fl;
      case 'half_even':
        if (twice == rem.d) return fl.isEven ? fl : fl + BigInt.one;
        return twice > rem.d ? fl + BigInt.one : fl;
      default:
        return twice >= rem.d ? fl + BigInt.one : fl;
    }
  }
}

class RefLine {
  RefLine(this.priceCents, this.qty, this.taxable, [this.discCents = 0]);
  final int priceCents;
  final int qty;
  final bool taxable;
  final int discCents;
  int get sub => priceCents * qty - discCents;
}

class RefRate {
  RefRate(this.id, this.bp, this.inclusive, this.mode);
  final int id;
  final int bp; // basis points: 1300 = 13 %
  final bool inclusive;
  final String mode;
  TaxRate toRate() => TaxRate(
        id: id,
        name: 'T$id',
        rate: bp / 10000.0,
        inclusionType: inclusive ? 'inclusive' : 'exclusive',
        roundingMode: mode,
        isCompound: false,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
}

class RefResult {
  int subtotal = 0, discount = 0, taxAmount = 0, exclusiveTax = 0;
  int loyalty = 0, total = 0, pointsRedeemed = 0, pointsEarn = 0;
  List<int> taxLineAmounts = [];
  List<int> taxables = [];

  /// The exact taxable base sits within a hundred-thousandth of a cent of a
  /// half-cent. `roundMoney` deliberately treats such values as the half
  /// (its float-noise allowance), so either neighbour is acceptable there.
  bool baseOnHalfCent = false;
}

/// The sale rules: order discount prorated over lines, invoice-level tax,
/// loyalty redeemed after tax, points earned on the amount actually paid.
/// [discPermille]: percent discount ×10 (333 = 33.3 %), or null for flat.
RefResult refCompute({
  required List<RefLine> lines,
  required List<RefRate> rates,
  int? discPermille,
  int flatDiscCents = 0,
  bool taxEnabled = true,
  bool loyalty = false,
  bool hasCustomer = false,
  int pvCents = 0,
  int balance = 0,
  int request = 0,
  int earnNum = 0,
  int earnDen = 1, // earn rate = earnNum/earnDen points per currency unit
}) {
  final r = RefResult();
  final s = lines.fold<int>(0, (a, l) => a + l.sub);
  r.subtotal = s;
  var d = 0;
  if (s > 0) {
    if (discPermille != null) {
      d = (Frac.i(s) * Frac.i(discPermille) / Frac.i(1000))
          .round('half_up')
          .toInt();
    } else {
      d = flatDiscCents;
    }
    if (d < 0) d = 0;
    if (d > s) d = s;
  }
  r.discount = d;
  final ds = s - d;
  // The taxable base: what the taxable lines come to after their share of
  // the order discount, summed, then rounded once to cents.
  var base = Frac.i(0);
  if (s > 0) {
    for (final l in lines) {
      if (!l.taxable) continue;
      final net = Frac.i(l.sub) * Frac.i(ds) / Frac.i(s);
      if (net.isNeg) continue;
      base = base + net;
    }
  }
  final g = base.round('half_up');
  final rem = base - Frac(base.floor(), BigInt.one);
  final off = (rem.n * BigInt.two - rem.d).abs();
  r.baseOnHalfCent = off != BigInt.zero && off * BigInt.from(100000) < rem.d;
  for (final rate in rates) {
    var amount = BigInt.zero;
    var taxable = g;
    if (rate.bp > 0 && g > BigInt.zero) {
      final gross = Frac(g, BigInt.one);
      final rr = Frac.i(rate.bp) / Frac.i(10000);
      final raw = rate.inclusive ? gross - gross / (Frac.i(1) + rr) : gross * rr;
      amount = raw.round(rate.mode);
      if (rate.inclusive) taxable = g - amount;
    } else {
      taxable = BigInt.zero;
    }
    r.taxLineAmounts.add(amount.toInt());
    r.taxables.add(taxable.toInt());
  }
  if (taxEnabled) {
    for (var i = 0; i < rates.length; i++) {
      r.taxAmount += r.taxLineAmounts[i];
      if (!rates[i].inclusive) r.exclusiveTax += r.taxLineAmounts[i];
    }
  }
  final due = ds + r.exclusiveTax;
  var maxPts = 0;
  if (loyalty && hasCustomer && pvCents > 0) {
    maxPts = due ~/ pvCents;
    if (balance < maxPts) maxPts = balance;
    if (maxPts < 0) maxPts = 0;
  }
  r.pointsRedeemed = request.clamp(0, maxPts);
  r.loyalty = r.pointsRedeemed * pvCents;
  r.total = due - r.loyalty;
  if (r.total < 0) r.total = 0;
  r.pointsEarn = loyalty
      ? (Frac.i(r.total) * Frac.i(earnNum) / Frac.i(earnDen * 100))
          .floor()
          .toInt()
      : 0;
  return r;
}

int cents(double v) => (v * 100).round();

/// True when [v] is exactly the double nearest to a 2-decimal number.
bool isClean2dp(double v) => v == cents(v) / 100;
