import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/models/place.dart';

abstract class IPlaceRepository {
  Future<List<Place>> getAll();
}

class MockPlaceRepository implements IPlaceRepository {
  @override
  Future<List<Place>> getAll() async {
    final raw = await rootBundle.loadString('lib/core/mocks/mock_places.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Place.fromJson).toList();
    }
}
