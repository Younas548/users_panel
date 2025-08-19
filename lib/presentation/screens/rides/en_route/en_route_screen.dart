import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../state/ride_state.dart';
import '../../../widgets/map/map_stub.dart';

class EnRouteScreen extends StatelessWidget {
  const EnRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver en-route')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Map + ETA chip
              Stack(
                children: [
                  const MapStub(height: 200),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: _etaChip(ride.etaMin, cs),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Glass panel with compact driver card + big CTA
              _GlassPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _DriverCompactCard(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Picked up'),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 2,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.inRide),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etaChip(int eta, ColorScheme cs) {
    final text = eta > 0 ? 'ETA $eta min' : 'ETA —';
    return Chip(
      label: Text(text),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: const StadiumBorder(),
      backgroundColor: cs.surface.withValues(alpha: 0.9),
      side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
    );
  }
}

// ---------- UI bits ----------

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DriverCompactCard extends StatelessWidget {
  const _DriverCompactCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Driver avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary.withAlpha((0.08 * 255).round()),
            backgroundImage:
                const AssetImage('assets/images/map3_stub.PNG'),
            onBackgroundImageError: (_, __) {},
            child: Image.asset(
              'assets/images/map3_stub.PNG',
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.person, color: cs.primary),
            ),
          ),
          const SizedBox(width: 12),

          // Name + car details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arslam Aslam • 4.9★',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Suzuki Alto • White • NRL-123',
                    style: text.bodyMedium?.copyWith(color: cs.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Car image (fixed, neat size) with graceful fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 48,
              child: Image.asset(
                'assets/images/map4_stub.JPEG',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.directions_car, size: 28, color: cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
