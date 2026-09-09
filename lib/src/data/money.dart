/// Egyptian pound minor units: 1 pound (جنيه) = 100 piastres (قروش).
const int piastresPerPound = 100;

/// Max distance from a true halfway (.5) treated as a tie after `* 100`.
/// Absorbs binary float noise (e.g. `1.005 * 100 == 100.49999999999999`).
const double _halfTieEpsilon = 1e-8;

/// Converts pound amounts to integer piastres.
///
/// Rounding rule (fixed): nearest piastre; halfway cases move **away from
/// zero**. The v1→v2 SQLite migration applies this same function per cell.
int poundsToPiastres(num pounds) {
  final scaled = pounds.toDouble() * piastresPerPound;
  if (scaled.isNaN || scaled.isInfinite) {
    throw ArgumentError.value(pounds, 'pounds', 'قيمة مالية غير صالحة');
  }
  return _roundHalfAwayFromZero(scaled);
}

/// Converts integer piastres to pounds for display and JSON export.
double piastresToPounds(int piastres) => piastres / piastresPerPound;

/// Formats piastres as a pounds string suitable for text fields.
String formatPoundsForInput(int piastres) {
  final pounds = piastresToPounds(piastres);
  if (pounds == pounds.roundToDouble()) {
    return pounds.toInt().toString();
  }
  return pounds.toStringAsFixed(2);
}

/// Converts a legacy REAL pound value with the declared piastre rounding rule.
int migrateRealPoundsToPiastres(num realPounds) => poundsToPiastres(realPounds);

int _roundHalfAwayFromZero(double value) {
  final sign = value.isNegative ? -1 : 1;
  final abs = value.abs();
  final whole = abs.floor();
  final fraction = abs - whole;
  if (fraction > 0.5 || (fraction - 0.5).abs() <= _halfTieEpsilon) {
    return sign * (whole + 1);
  }
  return sign * whole;
}
