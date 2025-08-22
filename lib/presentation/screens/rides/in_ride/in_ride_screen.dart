import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard + MissingPluginException
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Share Trip
import 'package:url_launcher/url_launcher.dart'; // dialer fallback
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../app/routes.dart';
import '../../../state/ride_state.dart';
import '../../../widgets/map/map_stub.dart';

class InRideScreen extends StatelessWidget {
  const InRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final theme = Theme.of(context);

    final destination = ride.destination?.name ?? 'Destination';
    const etaText = '~10 min';
    const driverPhone = '+92 333 0480202'; // TODO: RideState se real number pass karein

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('On the way'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Safety',
            icon: const Icon(Icons.health_and_safety_rounded),
            onPressed: () => _showSafetySheet(context, destination, etaText),
          ),
        ],
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ===== Map (minimal overlays) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 12, 16, 12),
            child: _GlassCard(
              radius: 18,
              child: Stack(
                children: [
                  const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: MapStub(height: 240),
                  ),
                  const Positioned(
                    right: 10, top: 10,
                    child: _MiniChip(text: 'ETA $etaText', icon: Icons.timer_outlined),
                  ),
                  Positioned(
                    left: 10, right: 10, bottom: 10,
                    child: _CompactRouteBar(
                      pickup: 'Current location',
                      dropoff: destination,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Driver (compact, overflow-safe) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _GlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                    child: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),

                  // Texts — take remaining space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _titleBold('Arslan Aslam', context, maxLines: 1),
                        const SizedBox(height: 2),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '4.9  •  1,240 trips',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Toyota Corolla • LEA-1234',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: .8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Actions — fixed max width so they never push content
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundIconButton(
                          icon: Icons.call_rounded,
                          tooltip: 'Call',
                          onTap: () => _callDriver(context, driverPhone),
                        ),
                        const SizedBox(width: 8),
                        _RoundIconButton(
                          icon: Icons.ios_share_rounded,
                          tooltip: 'Share trip',
                          onTap: () => _shareTrip(context, destination, etaText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== Progress (simple + airy) =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StepBar(current: 1, total: 3),
                  SizedBox(height: 8),
                  _StepLabels(labels: ['Picked up', 'En route', 'Drop-off']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),

      // ===== Bottom CTA (wrapped to avoid overflow) =====
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.completePayment),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Complete ride',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== ACTIONS (TOP-LEVEL) ===================== */

Future<void> _callDriver(BuildContext context, String phone) async {
  // 1) Try direct call (Android) — asks for CALL_PHONE at runtime
  try {
    final perm = await ph.Permission.phone.request();
    if (perm.isGranted) {
      final ok = await FlutterPhoneDirectCaller.callNumber(phone);
      if (ok == true) return; // direct call placed
    }
  } catch (_) {
    // ignore and fallback
  }

  // 2) Fallback: open dialer (Android/iOS — no extra permission)
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start phone call')),
      );
    }
  }
}

Future<void> _shareTrip(BuildContext context, String destination, String etaText) async {
  final text =
      'I’m on my way to $destination (ETA $etaText). Track my ride: https://zoomigoo.example/track';

  try {
    await Share.share(text, subject: 'Track my ride');
  } on MissingPluginException {
    // Fallback (app still works): copy text to clipboard
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share plugin not ready. Link copied to clipboard.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share: $e')),
      );
    }
  }
}

/* ===================== SAFETY SHEET ===================== */

void _showSafetySheet(BuildContext context, String destination, String etaText) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Safety tools',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SafetyButton(
                  color: Colors.red,
                  icon: Icons.emergency_share_rounded,
                  label: 'Emergency',
                  onTap: () {}, // TODO: emergency flow
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SafetyButton(
                  color: Theme.of(ctx).colorScheme.primary,
                  icon: Icons.shield_moon_rounded,
                  label: 'Share trip',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareTrip(context, destination, etaText);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/* ===================== UI PARTS (minimal) ===================== */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  const _GlassCard({required this.child, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: bg.withValues(alpha: .75),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _MiniChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: .10),
        border: Border.all(color: c.primary.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: c.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRouteBar extends StatelessWidget {
  final String pickup;
  final String dropoff;
  const _CompactRouteBar({required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.near_me_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pickup,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: t.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_right_alt_rounded, color: Colors.white70),
          const SizedBox(width: 8),
          const Icon(Icons.flag_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              dropoff,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: t.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: c.primary),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current; // 1-based
  final int total;
  const _StepBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final idx = i + 1;
        final active = idx <= current;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? c.primary : Colors.grey.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _StepLabels extends StatelessWidget {
  final List<String> labels;
  const _StepLabels({required this.labels});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          overflow: TextOverflow.ellipsis,
        );
    return Row(
      children: labels
          .map(
            (e) => Expanded(
              child: Text(
                e,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SafetyButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SafetyButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/* ===================== TEXT HELPERS ===================== */

Widget _titleBold(String text, BuildContext context, {int maxLines = 1}) =>
    Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
