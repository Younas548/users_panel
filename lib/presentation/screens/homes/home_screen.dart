import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/flags.dart'; // <- AppFlags.enablePhase2
import '../../state/ride_state.dart';
import '../../widgets/map/map_stub.dart';

// ✅ Single source of truth (Geolocator-based service) + permission dialog
import '../../../presentation/screens/permissions/location_permission_service.dart' as loc_perm;
import '../../../presentation/screens/permissions/location_permission_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // 🔒 Static guards: same app run me widget recreate ho to bhi dialog dubara na khule
  static bool _askedThisRun = false;
  static bool _grantedThisRun = false;
  static bool _requestedAfterResume = false; // resume ke baad sirf 1 dafa

  bool _dialogOpen = false; // prevent stacking
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // UI render ke baad permission check
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _afterResumeCheck();
  }

  Future<void> _afterResumeCheck() async {
    if (!mounted || _dialogOpen || _grantedThisRun || _requesting || _requestedAfterResume) return;

    await Future.delayed(const Duration(milliseconds: 300)); // OS ko settle ka time
    final s = await loc_perm.LocationPermissionService.check();
    if (!mounted) return;

    // GPS ON hai par app permission pending ho to sheet 1 dafa dikhao
    if (s != loc_perm.LocPerm.granted && s != loc_perm.LocPerm.serviceDisabled) {
      _requestedAfterResume = true;
      _requesting = true;
      final r = await loc_perm.LocationPermissionService.request();
      _requesting = false;
      if (r == loc_perm.LocPerm.granted) _grantedThisRun = true;
    }
  }

  Future<void> _maybeAskPermission() async {
    if (_dialogOpen || _grantedThisRun || _requesting) return;

    // 1) Quick check
    var s = await loc_perm.LocationPermissionService.check();
    if (!mounted) return;
    if (s == loc_perm.LocPerm.granted) { _grantedThisRun = true; return; }

    // 2) Small debounce
    await Future.delayed(const Duration(milliseconds: 250));
    s = await loc_perm.LocationPermissionService.check();
    if (!mounted) return;
    if (s == loc_perm.LocPerm.granted) { _grantedThisRun = true; return; }

    // 3) Same run me sirf 1 martaba
    if (_askedThisRun) return;

    _askedThisRun = true;
    _dialogOpen = true;
    try {
      // Dialog sirf signal dega: askNow == true => ab request chalao
      final askNow = await showLocationPermissionDialog(context) ?? false;

      if (askNow) {
        _requesting = true;
        final res = await loc_perm.LocationPermissionService.request();
        _requesting = false;

        if (res == loc_perm.LocPerm.granted) {
          _grantedThisRun = true;
        } else if (res == loc_perm.LocPerm.permanentlyDenied) {
          await loc_perm.LocationPermissionService.openAppSettings();
        }
      }
    } finally {
      _dialogOpen = false;
    }

    // 4) Gentle nudge
    final again = await loc_perm.LocationPermissionService.check();
    if (mounted && again != loc_perm.LocPerm.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required for accurate pickup')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final theme = Theme.of(context);

    return Scaffold(
      // Right-side drawer with all top-right items moved here
      endDrawerEnableOpenDragGesture: true,
      endDrawer: const _TopRightDrawer(),

      // Map ko app bar ke neeche tak extend karne ke liye:
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        automaticallyImplyLeading: false, // left burger/Back ko hide
        title: const SizedBox.shrink(),   // "Zoomigoo" text removed
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Prominent Menu button (icon + label + colored pill)
          Builder(
            builder: (ctx) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _ProminentMenuButton(
                onTap: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ),
        ],
      ),

      // --- FULLSCREEN MAP + OVERLAYS ---
      body: Stack(
        children: [
          // 1) Fullscreen map
          Positioned.fill(
            child: MapStub(
              height: MediaQuery.of(context).size.height,
              overlay: const SizedBox.shrink(),
            ),
          ),

          // 2) Center pin overlay
          IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.location_pin,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // 3) Bottom floating blurred panel (Where to + Home/Work buttons)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _GlassPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---- WHERE TO (search bar) ----
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pushNamed(context, Routes.placeSearch),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.whereTo,
                                  style: theme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),

                      // Destination summary (agar selected ho to)
                      if (ride.destination != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destination: ${ride.destination!.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ride.destination!.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),

                              // >>> UPDATED CTA (matches the red-circled style)
                              _PrimaryCTA(
                                label: 'Pick Your Ride',
                                icon: Icons.local_taxi_rounded,
                                onTap: () => Navigator.pushNamed(context, Routes.rideOptions),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // ---- Home / Work buttons ----
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, Routes.savedPlaces),
                              icon: const Icon(Icons.home),
                              label: const Text('Home'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: BorderSide(color: Colors.white.withOpacity(0.35)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, Routes.savedPlaces),
                              icon: const Icon(Icons.work),
                              label: const Text('Work'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: BorderSide(color: Colors.white.withOpacity(0.35)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent pill-style button for opening the right drawer
class _ProminentMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ProminentMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Circular icon background
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,                     // solid, high-contrast
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(                     // subtle pop
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Menu',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Right drawer content (all previous top-right actions moved here)
class _TopRightDrawer extends StatelessWidget {
  const _TopRightDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Profile header (optional)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
              title: const Text('Your Profile'),
              subtitle: const Text('Manage your account'),
              onTap: () {
                Navigator.pop(context);
                if (AppFlags.enablePhase2) {
                  Navigator.pushNamed(context, Routes.profile);
                }
              },
            ),
            const Divider(),

            // History
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ride History'),
              onTap: () {
                Navigator.pop(context);
                if (AppFlags.enablePhase2) {
                  Navigator.pushNamed(context, Routes.history);
                }
              },
            ),

            // Settings
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.settings);
              },
            ),

            // Support
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.support);
              },
            ),

            // Safety
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Safety'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.safety);
              },
            ),

            const Spacer(),

            // Logout / About etc (optional)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('About Zoomigoo'),
                onPressed: () {
                  Navigator.pop(context);
                  // e.g., Navigator.pushNamed(context, Routes.about);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chota helper widget jo blur/glass effect deta hai
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.55), // glassy
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// BIG rounded pill CTA used for “See options”
class _PrimaryCTA extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryCTA({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PrimaryCTA> createState() => _PrimaryCTAState();
}

class _PrimaryCTAState extends State<_PrimaryCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressed ? 0.98 : 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base,
                base.withOpacity(0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: base.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_filled, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
