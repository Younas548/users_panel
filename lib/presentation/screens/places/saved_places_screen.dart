import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/data/models/place.dart';
import '../../state/ride_state.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<Place> saved = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('lib/core/mocks/mock_user.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['saved'] as List).cast<Map<String, dynamic>>();
    setState(() => saved = list.map(Place.fromJson).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: ListView.builder(
        itemCount: saved.length,
        itemBuilder: (_, i) {
          final p = saved[i];
          return ListTile(
            leading: const Icon(Icons.star_border),
            title: Text(p.name),
            subtitle: Text(p.address),
            onTap: () {
              context.read<RideState>().setDestination(p);
              Navigator.pushNamedAndRemoveUntil(context, Routes.home, (r) => r.settings.name == Routes.permissions ? false : true);
            },
          );
        },
      ),
    );
  }
}
