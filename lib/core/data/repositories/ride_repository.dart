import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/ride_type.dart';

abstract class IRideRepository {
  Future<List<RideType>> getRideTypes();
}

class MockRideRepository implements IRideRepository {
  @override
  Future<List<RideType>> getRideTypes() async {
    final raw = await rootBundle.loadString('lib/core/mocks/mock_rides.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['ride_types'] as List).cast<Map<String, dynamic>>();
    return list.map(RideType.fromJson).toList();
  }
}
