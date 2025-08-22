import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
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

    // Fare (fallback agar user direct aajaye):
    final subtotal = (ride.subtotal == 0 ? ride.estimatedPrice : ride.subtotal).toDouble();
    final discount = ride.discount.toDouble();
    final total    = (ride.total == 0 ? subtotal : ride.total).toDouble();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

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

          const SizedBox(height: 16),

          // ===== Fare breakdown (Est.) =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _line(context, 'Subtotal', 'PKR ${subtotal.toStringAsFixed(0)}'),
                if (discount > 0)
                  _line(context, 'Promo (WELCOME20)', '- PKR ${discount.toStringAsFixed(0)}', muted: true),
                const Divider(height: 18),
                _lineBold(context, 'Total (Est.)', 'PKR ${total.toStringAsFixed(0)}'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // NOTE OPTIONAL
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
              // optional: no validator
            ),
          ),
        ],
      ),

      // Bottom CTA
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Find a driver'),
              onPressed: () {
                // context.read<RideState>().setNote(_note.text.trim()); // if you add notes later
                Navigator.pushNamed(context, Routes.findingDriver);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String l, String r, {bool muted = false}) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(l, style: tt.bodyMedium?.copyWith(color: muted ? cs.onSurfaceVariant : null))),
          Text(r, style: tt.bodyMedium?.copyWith(color: muted ? cs.onSurfaceVariant : null)),
        ],
      ),
    );
  }

  Widget _lineBold(BuildContext context, String l, String r) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(l, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          Text(r, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
