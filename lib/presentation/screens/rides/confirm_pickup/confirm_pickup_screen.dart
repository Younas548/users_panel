import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
// validators import hata diya kyun ke ab use nahi ho raha
import '../../../state/ride_state.dart';
import '../../../widgets/map/map_stub.dart';

class ConfirmPickupScreen extends StatefulWidget {
  const ConfirmPickupScreen({super.key});

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();

    final destName = ride.destination?.name ?? '—';
    final destAddr = ride.destination?.address ?? 'No address selected';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm pickup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MapStub(height: 220, overlay: SizedBox()),
          const SizedBox(height: 12),

          // Pickup / Destination summary
          const ListTile(
            leading: Icon(Icons.my_location),
            title: Text('Pickup'),
            subtitle: Text('Your current location (mock)'),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Destination'),
            subtitle: Text('$destName\n$destAddr'),
          ),

          const SizedBox(height: 12),

          Text(
            'Destination: $destName',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          // NOTE OPTIONAL: validator hata diya, label me (optional) add
          Form(
            key: _form,
            child: TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Note to driver (e.g., Gate no. 3)',
                labelText: 'Note to driver (optional)',
                border: OutlineInputBorder(),
              ),
              // <- koi validator nahi, is liye optional
            ),
          ),
        ],
      ),

      // Bottom CTA: bina validate kiye next page
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Find a driver'),
              onPressed: () {
                // Agar future me note save karna ho to yahan se ride state me bhej dein (optional)
                // context.read<RideState>().setNote(_note.text.trim());
                Navigator.pushNamed(context, Routes.findingDriver);
              },
            ),
          ),
        ),
      ),
    );
  }
}
