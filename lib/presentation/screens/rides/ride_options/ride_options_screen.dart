import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/data/models/ride_type.dart';
import '../../../../core/data/repositories/ride_repository.dart';
import '../../../state/ride_state.dart';
import '../../../widgets/ride/fare_tile.dart';

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key});

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  final _repo = MockRideRepository();
  List<RideType> _types = [];
  RideType? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await _repo.getRideTypes();
    setState(() {
      _types = t;
      _selected = t.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final dst = ride.destination?.name ?? 'Select destination';
    return Scaffold(
      appBar: AppBar(title: const Text('Ride options')),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(dst),
            subtitle: Text('Pickup: Current Location'),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _types.length,
              itemBuilder: (_, i) {
                final t = _types[i];
                return FareTile(
                  type: t,
                  selected: _selected?.code == t.code,
                  onTap: () => setState(() => _selected = t),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: _selected == null ? null : () {
              context.read<RideState>()
                ..setRideType(_selected!)
                ..setEta(_selected!.etaMin)
                ..setPrice(_selected!.base + 120); // sample calc
              Navigator.pushNamed(context, Routes.confirmPickup);
            },
            child: Text(_selected == null ? 'Select ride' : 'Select ${_selected!.label} • ${Formatters.currency(_selected!.base + 120)}'),
          ),
        ),
      ),
    );
  }
}
