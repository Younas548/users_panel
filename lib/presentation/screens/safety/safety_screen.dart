import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});
  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool autoShareOnSOS = true;

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmSOS(BuildContext context) async {
    HapticFeedback.selectionClick();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // back tap closes
      builder: (_) => _ResponsiveSOSDialog(autoShareOnSOS: autoShareOnSOS),
    );

    if (ok == true && context.mounted) {
      HapticFeedback.mediumImpact();
      _showSnack(context, 'SOS triggered (demo)');
      if (autoShareOnSOS) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (context.mounted) {
          _showSnack(context, 'Trip link auto-shared to trusted contacts (demo)');
        }
      }
    }
  }

  void _openShareSheet(BuildContext context) {
    const link = 'https://zoomigoo.demo/trip/XYZ123';
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(Icons.link, size: 20),
                SizedBox(width: 8),
                Text('Trip link', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: SelectableText(
                    link,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: link));
                    HapticFeedback.selectionClick();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick share', style: Theme.of(context).textTheme.titleSmall),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ContactChip(
                  name: 'Amir',
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Pretend shared with Amir')));
                  },
                ),
                _ContactChip(
                  name: 'Fatima',
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Pretend shared with Fatima')));
                  },
                ),
                _ContactChip(
                  name: 'Add…',
                  icon: Icons.person_add,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open your add-contact flow here')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.share),
                label: const Text('Share (demo)'),
                onPressed: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Pretend share sent')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Quick access to safety tools', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Use SOS in emergencies and share your trip link with trusted contacts. (Demo only)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),

          // SOS card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.red.withOpacity(0.12),
                  child: const Icon(Icons.sos, color: Colors.red),
                ),
                title: const Text('Emergency SOS'),
                subtitle: Text(
                  autoShareOnSOS ? 'Tap to confirm — auto-share ON (demo)' : 'Tap to confirm (demo)',
                ),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(88, 40),
                  ),
                  onPressed: () => _confirmSOS(context),
                  child: const Text('SOS'),
                ),
                onTap: () => _confirmSOS(context),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Auto-share toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Auto-share trip on SOS'),
            subtitle: const Text('Send your live link to trusted contacts automatically (demo)'),
            value: autoShareOnSOS,
            onChanged: (v) => setState(() => autoShareOnSOS = v),
            secondary: Icon(Icons.auto_awesome_rounded, color: cs.primary),
          ),

          const SizedBox(height: 12),

          // Share card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary.withOpacity(0.12),
                child: Icon(Icons.share, color: cs.primary),
              ),
              title: const Text('Share trip status'),
              subtitle: const Text('Send your trip link to a contact (demo)'),
              trailing: OutlinedButton(
                onPressed: () => _openShareSheet(context),
                child: const Text('Share'),
              ),
              onTap: () => _openShareSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final String name;
  final IconData? icon;
  final VoidCallback onTap;
  const _ContactChip({required this.name, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon ?? Icons.person, size: 18),
      label: Text(name),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// A responsive + split-screen–aware SOS dialog:
/// - Compact single-column for phones
/// - Two-column split with decorative panel on wide layouts
/// - Scroll-safe; buttons stack on narrow widths
class _ResponsiveSOSDialog extends StatelessWidget {
  final bool autoShareOnSOS;
  const _ResponsiveSOSDialog({required this.autoShareOnSOS});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.86;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 360;
        final isTwoCol = w >= 420; // show side panel on wider screens
        final capWidth = w.clamp(0.0, 680.0); // max total width

        // Buttons (stack on very narrow screens)
        final cancelBtn = OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        );
        final sendBtn = FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Send SOS'),
        );

        Widget actions;
        if (isNarrow) {
          actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: double.infinity, child: sendBtn),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: cancelBtn),
            ],
          );
        } else {
          actions = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              cancelBtn,
              const SizedBox(width: 8),
              sendBtn,
            ],
          );
        }

        Widget leftPanel() {
          final scheme = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.error.withOpacity(0.90),
                  scheme.error.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -10,
                  child: Opacity(
                    opacity: 0.12,
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      const Text(
                        'Emergency SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        autoShareOnSOS
                            ? 'Auto-share is ON.\nYour trusted contacts will be notified.'
                            : 'Auto-share is OFF.\nYou can enable it on the Safety screen.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.timer_rounded, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'SOS sends immediately after confirm (demo)',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.link_rounded, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Trip link can be shared from “Share status”',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: Icon(Icons.shield_rounded, color: Colors.white.withOpacity(0.9), size: 48),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget rightPanel() {
          final isTwoCol = w >= 420;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.error, size: isTwoCol ? 26 : 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Send Emergency SOS?',
                          style: isTwoCol
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This is a demo. No real emergency services will be contacted.\n\n'
                    '${autoShareOnSOS ? 'Auto-share is ON: your trusted contacts will be notified.' : 'You can enable Auto-share to notify trusted contacts.'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  actions,
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: capWidth,
              maxHeight: maxHeight,
            ),
            child: Material(
              color: Theme.of(context).dialogBackgroundColor,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: isTwoCol
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(flex: 4, child: leftPanel()),
                        Flexible(flex: 6, child: rightPanel()),
                      ],
                    )
                  : rightPanel(),
            ),
          ),
        );
      },
    );
  }
}
