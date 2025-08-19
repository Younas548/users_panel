import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../state/ride_state.dart';

class CompletePaymentScreen extends StatelessWidget {
  const CompletePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final price = ride.estimatedPrice == 0 ? 280 : ride.estimatedPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip complete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 84),
            const SizedBox(height: 12),
            Text(
              'PKR ${price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              ride.destination?.name ?? '—',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            const _RatingBlock(),

            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // reset UI-only ride state
                context.read<RideState>().reset();
                // clear stack → go Home
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (route) => false,
                );
              },
              child: const Text('Done'),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingBlock extends StatefulWidget {
  const _RatingBlock();

  @override
  State<_RatingBlock> createState() => _RatingBlockState();
}

class _RatingBlockState extends State<_RatingBlock> {
  int stars = 5;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate your ride'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final idx = i + 1;
            final filled = idx <= stars;
            return IconButton(
              onPressed: () => setState(() => stars = idx),
              icon: Icon(filled ? Icons.star : Icons.star_border),
              color: filled ? Colors.amber : null,
              tooltip: '$idx',
            );
          }),
        ),
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            hintText: 'Additional feedback (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
