import 'package:flutter/material.dart';
// ✅ Use the core service (single source of truth)
import '../../../presentation/screens/permissions/location_permission_service.dart';

/// Returns `true` if HomeScreen should now trigger the app-permission request,
/// `false/null` otherwise.
Future<bool?> showLocationPermissionDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'Location permission',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final scale = Tween<double>(begin: .9, end: 1.0)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
      final fade  = CurvedAnimation(parent: anim, curve: Curves.easeOut);

      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      final tt = theme.textTheme;

      return Opacity(
        opacity: fade.value,
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: _DialogContent(cs: cs, tt: tt),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DialogContent extends StatefulWidget {
  const _DialogContent({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> {
  String _statusText = '';

  /// IMPORTANT:
  /// - Yahan **permission request** NAHIN chalate.
  /// - Sirf GPS (location service) check karte hain:
  ///   - Agar OFF ho to settings kholo aur dialog close (false).
  ///   - Agar ON ho to dialog close (true) — HomeScreen request chalaye.
  Future<void> _onAllow() async {
    setState(() => _statusText = 'Checking…');
    final check = await LocationPermissionService.check();
    if (!mounted) return;

    if (check == LocPerm.serviceDisabled) {
      // GPS OFF → settings khol do, aur dialog band kar do
      setState(() => _statusText = 'Opening location settings…');
      await LocationPermissionService.openLocationSettings();
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    // GPS ON → app permission sheet HomeScreen se trigger hogi
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 90, width: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha:.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Icon(Icons.my_location, size: 42, color: cs.primary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Enable your location', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'We use your location for accurate pickups and nearby drivers.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_statusText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_statusText, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not now'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_searching),
                label: const Text('Allow'),
                onPressed: _onAllow,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
