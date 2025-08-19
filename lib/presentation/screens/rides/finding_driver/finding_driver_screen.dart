import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/routes.dart';
import '../../../state/ride_state.dart';

class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    // UI state: finding
    context.read<RideState>().setStatus(RideStatus.finding);

    // Auto-progress after 2s
    _t = Timer(const Duration(seconds: 2), _goEnRoute);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _goEnRoute() {
    if (!mounted) return;
    context.read<RideState>().setStatus(RideStatus.enRoute);
    // aapke routes.dart me constant ka naam enRoute hai
    Navigator.pushReplacementNamed(context, Routes.enRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finding driver…')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie with graceful fallback
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'assets/lottie/matching.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Looking for nearby drivers…'),
              const SizedBox(height: 20),

              // Manual advance (optional)
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _goEnRoute,
                  child: const Text('Simulate: Driver found'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
