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
  num estimatedPrice = 0;

  void setPickup(Place p) { pickup = p; notifyListeners(); }
  void setDestination(Place d) { destination = d; notifyListeners(); }
  void setRideType(RideType t) { selectedType = t; notifyListeners(); }
  void setEta(int m) { etaMin = m; notifyListeners(); }
  void setPrice(num p) { estimatedPrice = p; notifyListeners(); }
  void setStatus(RideStatus s) { status = s; notifyListeners(); }

  void reset() {
    pickup = null; destination = null; selectedType = null;
    etaMin = 0; estimatedPrice = 0; status = RideStatus.idle;
    notifyListeners();
  }
}
