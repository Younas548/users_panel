import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart'; // for openAppSettings()
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/notification_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Quiet hours state (local UI only)
  bool quietEnabled = true;
  TimeOfDay quietFrom = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay quietTo   = const TimeOfDay(hour: 7,  minute: 0); // 07:00 AM

  void _toggleDark(BuildContext context, bool value) {
    context.read<AppState>().setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    HapticFeedback.selectionClick();
  }

  Future<void> _pickQuietTime({required bool isStart}) async {
    final theme = Theme.of(context);
    final initial = isStart ? quietFrom : quietTo;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.surface,
              hourMinuteTextColor: theme.colorScheme.onSurface,
              dialHandColor: theme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          quietFrom = picked;
        } else {
          quietTo = picked;
        }
      });
    }
  }

  String _fmt(TimeOfDay t) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(t, alwaysUse24HourFormat: false);
  }

  void _showTerms() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terms of Service', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  "These Terms govern your use of Zoomigoo. By using the app, you agree to these Terms. "
                  "You are responsible for the accuracy of your information and compliance with all applicable laws. "
                  "Rides are provided by independent drivers. Zoomigoo is not liable for delays or service issues "
                  "beyond its control. Please review our Privacy Policy for details on data usage.\n\n"
                  "1) Use of Service • 2) Account & Security • 3) Payments & Refunds • "
                  "4) Prohibited Conduct • 5) Limitation of Liability • 6) Dispute Resolution.",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppState>();
    final notif = context.watch<NotificationState>(); // ✅ persisted + OS-sync
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final isDark = app.isDark;

    // Quiet-hours controls ko parent toggle ke hisaab se disable dikhao
    final quietControlsEnabled = notif.enabled && quietEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Pretty header with quick dark toggle
          _Header(
            isDark: isDark,
            onToggle: (v) => _toggleDark(context, v),
          ),
          const SizedBox(height: 12),

          // Appearance
          _SectionCard(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            accent: cs.primary,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: isDark,
                  onChanged: (v) => _toggleDark(context, v),
                  title: const Text('Dark mode'),
                  subtitle: Text(isDark ? 'On' : 'Off'),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Notifications (persisted + OS permission aware)
          _SectionCard(
            title: 'Notifications',
            icon: Icons.notifications_active_rounded,
            accent: cs.tertiary,
            child: Column(
              children: [
                // MASTER TOGGLE
                SwitchListTile.adaptive(
                  value: notif.enabled,
                  onChanged: (v) async {
                    await context.read<NotificationState>().setEnabled(v);
                    HapticFeedback.selectionClick();

                    // User tried to enable but OS still blocked → guide to Settings
                    if (v && !context.read<NotificationState>().enabled && context.mounted) {
                      await showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => const _NotifFixSheet(),
                      );

                      // Wapas aake OS se sync
                      if (context.mounted) {
                        await context.read<NotificationState>().refreshFromOS();
                      }
                    }
                  },
                  title: const Text('Push notifications'),
                  subtitle: Text(notif.enabled ? 'Enabled' : 'Disabled'),
                  secondary: const Icon(Icons.notifications_outlined),
                ),

                const Divider(height: 1),

                // Quiet hours (local demo) — disabled if notifications off
                SwitchListTile.adaptive(
                  value: quietEnabled,
                  onChanged: notif.enabled
                      ? (v) {
                          setState(() => quietEnabled = v);
                          HapticFeedback.selectionClick();
                        }
                      : null,
                  title: const Text('Quiet hours'),
                  subtitle: Text(
                    quietEnabled
                        ? 'No sounds ${_fmt(quietFrom)} – ${_fmt(quietTo)}'
                        : 'Off',
                  ),
                  secondary: const Icon(Icons.do_not_disturb_on_outlined),
                ),

                if (quietEnabled) const Divider(height: 1),

                if (quietEnabled)
                  ListTile(
                    enabled: quietControlsEnabled,
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Start time'),
                    subtitle: Text(_fmt(quietFrom)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: quietControlsEnabled ? () => _pickQuietTime(isStart: true) : null,
                  ),

                if (quietEnabled) const Divider(height: 1),

                if (quietEnabled)
                  ListTile(
                    enabled: quietControlsEnabled,
                    leading: const Icon(Icons.alarm_on_outlined),
                    title: const Text('End time'),
                    subtitle: Text(_fmt(quietTo)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: quietControlsEnabled ? () => _pickQuietTime(isStart: false) : null,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // About
          _SectionCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            accent: cs.secondary,
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Terms of Service
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showTerms,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Terms of Service',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------- Pretty header ----------
class _Header extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onToggle;
  const _Header({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [cs.surfaceContainerHighest.withValues(alpha:0.16), cs.primary.withValues(alpha:0.20)]
              : [cs.primaryContainer.withValues(alpha:0.45), cs.primary.withValues(alpha:0.40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Make the app yours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.light_mode, size: 18)),
              ButtonSegment(value: true, icon: Icon(Icons.dark_mode, size: 18)),
            ],
            selected: {isDark},
            onSelectionChanged: (s) => onToggle(s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,

              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white.withValues(alpha:0.22)
                    : Colors.white.withValues(alpha:0.12),
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Section card ----------
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface.withValues(alpha:0.9);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha:0.12),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

// ---------- Bottom sheet to guide user to OS settings ----------
class _NotifFixSheet extends StatelessWidget {
  const _NotifFixSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Turn on notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Allow notifications from system settings to get ride updates and driver status.'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Not now'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings(); // permission_handler
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
