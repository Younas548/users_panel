import 'dart:math';

/// UI-only helper: first 2 rides par 20% OFF (optional cap = 150)
class PromoPreview {
  static const double pct = 0.20;         // 20%
  static const double cap = 150.0;        // PKR cap (optional)
  static const int eligibleRides = 2;     // first 2 completed rides

  static bool eligible(int ridesCompleted) => ridesCompleted < eligibleRides;

  static double discount(double subtotal, int ridesCompleted) {
    if (!eligible(ridesCompleted)) return 0;
    final d = subtotal * pct;
    return min(d, cap);
  }

  static double total(double subtotal, int ridesCompleted) {
    final t = subtotal - discount(subtotal, ridesCompleted);
    return t < 0 ? 0 : t;
  }

  static int remaining(int ridesCompleted) =>
      (eligibleRides - ridesCompleted).clamp(0, eligibleRides);
}
