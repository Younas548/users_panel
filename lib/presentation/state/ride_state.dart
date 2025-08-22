import 'package:flutter/material.dart';
import '../../core/data/models/place.dart';
import '../../core/data/models/ride_type.dart';

enum RideStatus { idle, finding, enRoute, inRide, complete }

class RideState extends ChangeNotifier {
  Place? pickup;
  Place? destination;
  RideType? selectedType;
  RideStatus status = RideStatus.idle;

  int etaMin = 0;

  /// Legacy estimate (kept for compatibility)
  num estimatedPrice = 0;

  /// Promo preview counters (UI-only until backend is ready)
  int ridesCompleted = 0; // TODO: backend se sync karna

  /// Fare breakdown for current selection (UI-only until backend is ready)
  num subtotal = 0;
  num discount = 0;
  num total = 0;

  void setPickup(Place p) { pickup = p; notifyListeners(); }
  void setDestination(Place d) { destination = d; notifyListeners(); }
  void setRideType(RideType t) { selectedType = t; notifyListeners(); }
  void setEta(int m) { etaMin = m; notifyListeners(); }

  /// Deprecated-ish: ab setFare prefer karo
  void setPrice(num p) { estimatedPrice = p; notifyListeners(); }

  void setFare({required num subtotal, required num discount, required num total}) {
    this.subtotal = subtotal;
    this.discount = discount;
    this.total = total;
    notifyListeners();
  }

  void setRidesCompleted(int v) { ridesCompleted = v; notifyListeners(); }

  void setStatus(RideStatus s) { status = s; notifyListeners(); }

  void reset() {
    pickup = null;
    destination = null;
    selectedType = null;
    etaMin = 0;
    estimatedPrice = 0;
    subtotal = 0;
    discount = 0;
    total = 0;
    status = RideStatus.idle;
    notifyListeners();
  }
}
