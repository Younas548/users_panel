import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- ISSUE BOTTOM SHEET (Keyboard-safe) ----------
  void _openIssueSheet(String title) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _IssueSheet(
        title: title,
        onSubmitted: () {
            Navigator.pop(context);
            _snack('Ticket submitted — we’ll get back soon');
        },
      ),
    );
  }

  // ---------- CONTACT OPENERS (visible actions) ----------
  Future<void> _openEmail() async {
    HapticFeedback.selectionClick();
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@zoomigoo.',
      queryParameters: {
        'subject': 'Zoomigoo Support',
        'body': 'Hi team,\n\nI need help with…'
      },
    );
    _snack('Opening email…');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openCall() async {
    HapticFeedback.selectionClick();
    final uri = Uri(scheme: 'tel', path: '+923330480202');
    _snack('Dialing…');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(
        'https://wa.me/923001234567?text=Hi%20Zoomigoo%20Support%2C%20I%20need%20help%20with…');
    _snack('Opening WhatsApp…');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ——— Header (soft gradient) ———
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withOpacity(0.55),
                  cs.primary.withOpacity(0.50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We’re here to help.\nFind answers or contact us.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.18),
                  ),
                  onPressed: () =>
                      _snack('Live chat coming soon'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ——— Quick Actions (chips) ———
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickChip(
                  icon: Icons.receipt_long,
                  label: 'Billing',
                  onTap: () => _openIssueSheet('Billing issue'),
                ),
                _QuickChip(
                  icon: Icons.location_on_outlined,
                  label: 'Driver didn’t arrive',
                  onTap: () => _openIssueSheet('Driver didn’t arrive'),
                ),
                _QuickChip(
                  icon: Icons.back_hand_outlined,
                  label: 'Lost item',
                  onTap: () => _openIssueSheet('Lost item'),
                ),
                _QuickChip(
                  icon: Icons.account_circle_outlined,
                  label: 'Account',
                  onTap: () => _openIssueSheet('Account problem'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ——— Popular issues (pretty cards) ———
          _SectionCard(
            title: 'Popular issues',
            icon: Icons.trending_up_rounded,
            accent: cs.primary,
            child: Column(
              children: [
                _IssueTile(
                  icon: Icons.payments_rounded,
                  color: cs.primary,
                  title: 'I was charged incorrectly',
                  subtitle: 'Review fare breakdown or request a correction',
                  onTap: () => _openIssueSheet('I was charged incorrectly'),
                ),
                const Divider(height: 1),
                _IssueTile(
                  icon: Icons.time_to_leave_rounded,
                  color: cs.secondary,
                  title: 'My driver didn’t arrive',
                  subtitle: 'Report no-show & get help quickly',
                  onTap: () => _openIssueSheet('My driver didn’t arrive'),
                ),
                const Divider(height: 1),
                _IssueTile(
                  icon: Icons.backpack_rounded,
                  color: cs.tertiary,
                  title: 'Lost item',
                  subtitle: 'We’ll help you contact the driver',
                  onTap: () => _openIssueSheet('Lost item'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ——— FAQs (expanders) ———
          _SectionCard(
            title: 'FAQs',
            icon: Icons.help_outline,
            accent: cs.tertiary,
            child: Column(
              children: const [
                _FaqTile(
                  q: 'How do refunds work?',
                  a: 'Refunds for valid claims are processed to your original payment method within 3–5 business days.',
                ),
                Divider(height: 1),
                _FaqTile(
                  q: 'How do I contact my driver?',
                  a: 'From your trip details, tap “Contact driver” to call or message.',
                ),
                Divider(height: 1),
                _FaqTile(
                  q: 'Why is my fare higher than expected?',
                  a: 'Fares can change due to traffic, surge pricing, detours, or wait time .',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ——— Contact options ———
          _SectionCard(
            title: 'Contact us',
            icon: Icons.call_rounded,
            accent: cs.secondary,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondary.withOpacity(0.12),
                    child: Icon(Icons.email_outlined, color: cs.secondary),
                  ),
                  title: const Text('Email support'),
                  subtitle: const Text('support@zoomigoo.com'),
                  trailing: const Icon(Icons.arrow_outward_rounded),
                  onTap: _openEmail,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primary.withOpacity(0.12),
                    child: Icon(Icons.call_outlined, color: cs.primary),
                  ),
                  title: const Text('Call center'),
                  subtitle: const Text('+92 333 0480202'),
                  trailing: const Icon(Icons.arrow_outward_rounded),
                  onTap: _openCall,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.tertiary.withOpacity(0.12),
                    child: Icon(Icons.chat_bubble_rounded, color: cs.tertiary),
                  ),
                  title: const Text('WhatsApp (fastest)'),
                  subtitle: const Text(' 333 0480202'),
                  trailing: const Icon(Icons.arrow_outward_rounded),
                  onTap: _openWhatsApp,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ——————————————————— Bottom Sheet Widget ———————————————————

class _IssueSheet extends StatefulWidget {
  final String title;
  final VoidCallback onSubmitted;
  const _IssueSheet({required this.title, required this.onSubmitted});

  @override
  State<_IssueSheet> createState() => _IssueSheetState();
}

class _IssueSheetState extends State<_IssueSheet> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ctl,
                    focusNode: _focus,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Describe what happened…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                      onPressed: widget.onSubmitted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ——————————————————— Widgets ———————————————————

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      label: Text(label),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _IssueTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _IssueTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.w700)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(a),
        ),
      ],
    );
  }
}

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
