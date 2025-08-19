import 'dart:math';

class LocationService {
  bool locationAllowed = false;

  void setAllowed(bool v) => locationAllowed = v;

  // Fake current location around Narowal
  (double lat, double lng) current() {
    final rnd = Random(1);
    return (32.105 + rnd.nextDouble() * 0.005, 74.873 + rnd.nextDouble() * 0.005);
  }
}
