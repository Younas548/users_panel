import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool push = true;

  void _toggleDark(BuildContext context, bool value) {
    context.read<AppState>().setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    HapticFeedback.selectionClick();
  }

  void _openColorPicker(BuildContext context) {
    final app = context.read<AppState>();
    final options = <Color>[
      const Color(0xFF2563EB), // Ocean Blue (default)
      const Color(0xFF22C55E), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFE11D48), // Rose
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFDC2626), // Red
      const Color(0xFF0891B2), // Teal-ish
    ];

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose app color', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in options)
                    _ColorDot(
                      color: c,
                      selected: app.primarySeed.value == c.value,
                      onTap: () {
                        app.setPrimarySeed(c);
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final isDark = app.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('App color'),
                  subtitle: Text(_colorName(app.primarySeed)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openColorPicker(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Notifications
          _SectionCard(
            title: 'Notifications',
            icon: Icons.notifications_active_rounded,
            accent: cs.tertiary,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: push,
                  onChanged: (v) {
                    setState(() => push = v);
                    HapticFeedback.selectionClick();
                  },
                  title: const Text('Push notifications'),
                  subtitle: Text(push ? 'Enabled' : 'Disabled'),
                  secondary: const Icon(Icons.notifications_outlined),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.do_not_disturb_on_outlined),
                  title: const Text('Quiet hours'),
                  subtitle: const Text('No sounds 10:00 pm – 7:00 am'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _soon(context),
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
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Version'),
                  subtitle: Text('1.0.0 (demo)'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.article_outlined),
                  title: Text('Terms of Service'),
                  subtitle: Text('Tap to view (demo)'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _colorName(Color c) {
    if (c.value == const Color(0xFF2563EB).value) return 'Ocean Blue';
    if (c.value == const Color(0xFF22C55E).value) return 'Green';
    if (c.value == const Color(0xFFF59E0B).value) return 'Amber';
    if (c.value == const Color(0xFFE11D48).value) return 'Rose';
    if (c.value == const Color(0xFF8B5CF6).value) return 'Purple';
    if (c.value == const Color(0xFF06B6D4).value) return 'Cyan';
    if (c.value == const Color(0xFFDC2626).value) return 'Red';
    if (c.value == const Color(0xFF0891B2).value) return 'Teal';
    return '#${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This option will be available soon (demo)')),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check, color: Colors.white, size: 22),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [cs.surfaceVariant.withOpacity(0.16), cs.primary.withOpacity(0.18)]
              : [cs.primaryContainer.withOpacity(0.45), cs.primary.withOpacity(0.40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
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
                    ? Colors.white.withOpacity(0.18)
                    : Colors.white.withOpacity(0.10),
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
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface.withOpacity(0.8);

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
                  backgroundColor: accent.withOpacity(0.12),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
