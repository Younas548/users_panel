import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../app/routes.dart';
import '../../state/permission_state.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PermissionState>();
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // --- Bottom fixed CTA (always visible) ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: p.allGood
                  ? () async {
                      final ok = await _ensureLocationReady(context, showUI: true);
                      if (!ok) return;
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, Routes.home);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  p.allGood ? 'All set · Continue' : 'Allow required permissions',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // ---- App-themed background (no odd colors) ----
          Container(decoration: _appGradient(context)),
          // subtle blobs using theme colors (very low opacity)
          Positioned(top: -60, left: -40, child: _blob(180, c.primary.withOpacity(0.06))),
          Positioned(bottom: -50, right: -30, child: _blob(220, c.secondary.withOpacity(0.05))),

          // ---- Single screen content (no scroll) ----
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const _Header(),
                  const SizedBox(height: 12),
                  _ProgressStrip(
                    steps: [
                      (p.location == PermissionStatus.allowed),
                      (p.notifications == PermissionStatus.allowed),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _PermRow(
                    icon: Icons.my_location_rounded,
                    title: 'Location',
                    description: 'Precise pickups & live ETA.',
                    status: p.location,
                    onAllow: () async => _handleLocationAllow(context),
                    onDeny: () => context.read<PermissionState>().setLocation(PermissionStatus.denied),
                  ),
                  const SizedBox(height: 10),
                  _PermRow(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifications',
                    description: 'Arrival alerts & trip updates.',
                    status: p.notifications,
                    onAllow: () async => _handleNotificationsAllow(context),
                    onDeny: () => context.read<PermissionState>().setNotifications(PermissionStatus.denied),
                  ),

                  const SizedBox(height: 14),

                  _InfoGlass(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: c.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Change anytime in Settings. We never share your data without consent.',
                            style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ LOCATION FLOW ------------------

  static Future<void> _handleLocationAllow(BuildContext context) async {
    final ok = await _ensureLocationReady(context, showUI: true);
    final state = context.read<PermissionState>();
    if (ok) {
      state.setLocation(PermissionStatus.allowed);
      _showSnack(context, 'Location enabled ✔');
    } else {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        state.setLocation(PermissionStatus.denied);
      }
    }
  }

  /// Returns true if (GPS on + permission granted)
  static Future<bool> _ensureLocationReady(BuildContext context, {bool showUI = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showUI) {
        final turnedOn = await _askToEnableGps(context);
        if (!turnedOn) return false;
      } else {
        return false;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (showUI) _showSnack(context, 'Location permission required to continue.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (showUI) {
        final open = await _openAppSettingsSheet(context);
        if (!open) return false;
        return await _ensureLocationReady(context, showUI: showUI);
      } else {
        return false;
      }
    }

    return true; // whileInUse or always
  }

  static Future<bool> _askToEnableGps(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 40),
              const SizedBox(height: 8),
              const Text('GPS is off', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('To book rides, please turn on Location Services.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        final enabled = await Geolocator.isLocationServiceEnabled();
                        if (ctx.mounted) Navigator.pop(ctx, enabled);
                      },
                      child: const Text('Turn on GPS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  static Future<bool> _openAppSettingsSheet(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission permanently denied'),
        content: const Text('Open App Settings and allow Location access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final opened = await Geolocator.openAppSettings();
              if (ctx.mounted) Navigator.pop(ctx, opened);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ------------------ NOTIFICATION FLOW ------------------

  static Future<void> _handleNotificationsAllow(BuildContext context) async {
    final state = context.read<PermissionState>();

    final status = await ph.Permission.notification.status;

    if (status.isGranted) {
      state.setNotifications(PermissionStatus.allowed);
      _showSnack(context, 'Notifications enabled ✔');
      return;
    }

    if (status.isPermanentlyDenied) {
      final open = await _openNotifSettingsSheet(context);
      if (!open) return;
      final again = await ph.Permission.notification.status;
      if (again.isGranted) {
        state.setNotifications(PermissionStatus.allowed);
        _showSnack(context, 'Notifications enabled ✔');
      }
      return;
    }

    final req = await ph.Permission.notification.request();
    if (req.isGranted) {
      state.setNotifications(PermissionStatus.allowed);
      _showSnack(context, 'Notifications enabled ✔');
    } else if (req.isPermanentlyDenied) {
      state.setNotifications(PermissionStatus.denied);
      await _openNotifSettingsSheet(context);
    } else {
      state.setNotifications(PermissionStatus.denied);
    }
  }

  static Future<bool> _openNotifSettingsSheet(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifications blocked'),
        content: const Text('Open App Settings to enable notifications for ride updates.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final ok = await ph.openAppSettings();
              if (ctx.mounted) Navigator.pop(ctx, ok);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ------------------ helpers ------------------

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/* ===================== THEMED UI PARTS ===================== */

BoxDecoration _appGradient(BuildContext context) {
  final c = Theme.of(context).colorScheme;
  // Very subtle gradient based on app theme
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        c.surface,
        Color.alphaBlend(c.primary.withOpacity(0.04), c.surfaceVariant),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withOpacity(0.12),
            ),
            child: Icon(Icons.security_rounded, color: c.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart permissions',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: c.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'Allow required access so we can pick you up precisely and keep you updated.',
                  style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final List<bool> steps;
  const _ProgressStrip({required this.steps});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final done = steps.where((s) => s).length;
    final total = steps.length;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$done of $total completed',
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(total, (i) {
              final active = steps[i];
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: active ? c.primary : c.outlineVariant.withOpacity(.6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;
  final FutureOr<void> Function()? onAllow;
  final FutureOr<void> Function()? onDeny;

  const _PermRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onAllow,
    required this.onDeny,
  });

  Color _statusColor(BuildContext context, PermissionStatus s) {
    final c = Theme.of(context).colorScheme;
    switch (s) {
      case PermissionStatus.allowed:
        return c.primary;             // success = primary (fits brand)
      case PermissionStatus.denied:
        return c.error;               // error color from theme
      default:
        return c.outline;             // neutral
    }
  }

  String _statusText(PermissionStatus s) {
    switch (s) {
      case PermissionStatus.allowed:
        return 'Allowed';
      case PermissionStatus.denied:
        return 'Denied';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final statusColor = _statusColor(context, status);
    final statusText  = _statusText(status);

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          // Icon tile
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: c.onPrimaryContainer),
          ),
          const SizedBox(width: 10),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: c.onSurface)),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: statusColor.withOpacity(.30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == PermissionStatus.allowed
                            ? Icons.check_circle_rounded
                            : (status == PermissionStatus.denied
                                ? Icons.cancel_rounded
                                : Icons.help_outline_rounded),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(statusText,
                          style: t.labelLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Actions
          Column(
            children: [
              _TinyAction(label: 'Allow', filled: true, onTap: onAllow),
              const SizedBox(height: 8),
              _TinyAction(label: 'Deny', filled: false, onTap: onDeny),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  final String label;
  final FutureOr<void> Function()? onTap;
  final bool filled;
  const _TinyAction({required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return SizedBox(
      width: 88,
      child: ElevatedButton(
        onPressed: onTap == null ? null : () async => await Future.sync(onTap!),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? c.primary : Colors.transparent,
          foregroundColor: filled ? c.onPrimary : c.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: filled ? Colors.transparent : c.outlineVariant,
              width: 1.1,
            ),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _InfoGlass extends StatelessWidget {
  final Widget child;
  const _InfoGlass({required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _GlassCard extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final Widget child;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

Widget _blob(double size, Color color) {
  return ClipOval(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}
