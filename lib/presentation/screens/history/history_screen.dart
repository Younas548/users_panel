import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _search = TextEditingController();
  final _dateFmt = DateFormat('MMM d, yyyy – h:mm a');

  List<RideHistoryEntry> _all = [];
  List<RideHistoryEntry> _filtered = [];
  HistoryFilter _filter = HistoryFilter.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // TODO: Replace with your repository call.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final data = MockHistoryRepository().fetch();

    setState(() {
      _all = data;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    final q = _search.text.trim().toLowerCase();

    List<RideHistoryEntry> base = switch (_filter) {
      HistoryFilter.completed =>
        _all.where((e) => e.status == RideStatus.completed).toList(),
      HistoryFilter.canceled =>
        _all.where((e) => e.status == RideStatus.canceled).toList(),
      HistoryFilter.all => _all,
    };

    if (q.isNotEmpty) {
      base = base.where((e) {
        return e.pickup.toLowerCase().contains(q) ||
            e.dropoff.toLowerCase().contains(q);
      }).toList();
    }

    // Sort newest first
    base.sort((a, b) => b.start.compareTo(a.start));
    _filtered = base;
  }

  @override
  Widget build(BuildContext context) {
   // final theme = Theme.of(context);
    //final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
      ),
      body: Column(
        children: [
          // Filter + Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _FilterChipTab(
                  label: 'All',
                  selected: _filter == HistoryFilter.all,
                  onTap: () => setState(() {
                    _filter = HistoryFilter.all;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChipTab(
                  label: 'Completed',
                  selected: _filter == HistoryFilter.completed,
                  onTap: () => setState(() {
                    _filter = HistoryFilter.completed;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChipTab(
                  label: 'Canceled',
                  selected: _filter == HistoryFilter.canceled,
                  onTap: () => setState(() {
                    _filter = HistoryFilter.canceled;
                    _applyFilters();
                  }),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(_applyFilters),
              decoration: InputDecoration(
                hintText: 'Search pickup or dropoff',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // List
          Expanded(
            child: _loading
                ? const _HistorySkeleton()
                : _filtered.isEmpty
                    ? _EmptyState(
                        message:
                            'Koi ride history nahi mili.\nNayi ride book karein, yahan dikh jayegi.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 24),
                          itemCount: _groupedByDay(_filtered).length,
                          itemBuilder: (context, index) {
                            final group =
                                _groupedByDay(_filtered).entries.elementAt(index);
                            return _DayGroup(
                              label: group.key,
                              children: group.value
                                  .map((e) => _RideCard(
                                        entry: e,
                                        dateFmt: _dateFmt,
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Groups entries into "Today", "Yesterday", or formatted date.
  Map<String, List<RideHistoryEntry>> _groupedByDay(
      List<RideHistoryEntry> items) {
    final now = DateTime.now();
    final todayKey = DateFormat('yMd').format(now);
    final yestKey =
        DateFormat('yMd').format(now.subtract(const Duration(days: 1)));

    final map = <String, List<RideHistoryEntry>>{};
    for (final e in items) {
      final k = DateFormat('yMd').format(e.start);
      final label = k == todayKey
          ? 'Today'
          : k == yestKey
              ? 'Yesterday'
              : DateFormat('EEE, MMM d').format(e.start);

      (map[label] ??= []).add(e);
    }
    return map;
  }
}

/// ---------- UI PARTS ----------

class _FilterChipTab extends StatelessWidget {
  const _FilterChipTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      shape: StadiumBorder(
        side: BorderSide(color: cs.outlineVariant),
      ),
      selectedColor: cs.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? cs.onPrimaryContainer : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...children.expand((w) sync* {
            yield w;
            yield const SizedBox(height: 10);
          })
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.entry, required this.dateFmt});

  final RideHistoryEntry entry;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusChip = switch (entry.status) {
      RideStatus.completed => _StatusChip(
          label: 'Completed',
          bg: cs.secondaryContainer,
          fg: cs.onSecondaryContainer,
          icon: Icons.check_circle_rounded,
        ),
      RideStatus.canceled => _StatusChip(
          label: 'Canceled',
          bg: cs.errorContainer,
          fg: cs.onErrorContainer,
          icon: Icons.cancel_rounded,
        ),
      RideStatus.ongoing => _StatusChip(
          label: 'Ongoing',
          bg: cs.tertiaryContainer,
          fg: cs.onTertiaryContainer,
          icon: Icons.directions_car_filled,
        ),
    };

    return InkWell(
      onTap: () {
        // TODO: Navigate to ride details page with entry.id
        // Navigator.pushNamed(context, Routes.rideDetails, arguments: entry.id);
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: id + status + fare
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${entry.shortId}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  statusChip,
                  const SizedBox(width: 8),
                  _FarePill(amount: entry.fare),
                ],
              ),
              const SizedBox(height: 12),

              // Route lines
              _PointRow(
                icon: Icons.radio_button_checked,
                color: cs.primary,
                title: entry.pickup,
                subtitle: dateFmt.format(entry.start),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _DashedDivider(color: cs.outlineVariant),
              ),
              _PointRow(
                icon: Icons.location_on_rounded,
                color: cs.tertiary,
                title: entry.dropoff,
                subtitle: entry.end == null
                    ? '—'
                    : dateFmt.format(entry.end!),
              ),

              const SizedBox(height: 12),

              // Meta
              Row(
                children: [
                  _Meta(icon: Icons.timer_outlined, label: '${entry.durationMin} min'),
                  _Dot(),
                  _Meta(icon: Icons.social_distance_outlined, label: '${entry.km.toStringAsFixed(1)} km'),
                  _Dot(),
                  _Meta(icon: Icons.directions_car_filled, label: entry.vehicle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _FarePill extends StatelessWidget {
  const _FarePill({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        'PKR ${amount.toStringAsFixed(0)}',
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final dashWidth = 6.0;
      final dashSpace = 4.0;
      final count = (c.maxWidth / (dashWidth + dashSpace)).floor();
      return Row(
        children: List.generate(
          count,
          (_) => Padding(
            padding: EdgeInsets.only(right: dashSpace),
            child: SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        ),
      );
    });
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget bar() => Container(
          height: 14,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 16,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(),
                const SizedBox(height: 10),
                bar(),
                const SizedBox(height: 10),
                bar(),
              ],
            ),
          )
        ],
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 5,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No rides yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- DATA MODELS (Replace with your actual models) ----------

enum RideStatus { completed, canceled, ongoing }

class RideHistoryEntry {
  RideHistoryEntry({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.start,
    this.end,
    required this.status,
    required this.fare,
    required this.km,
    required this.durationMin,
    required this.vehicle,
  });

  final String id;
  final String pickup;
  final String dropoff;
  final DateTime start;
  final DateTime? end;
  final RideStatus status;
  final double fare;
  final double km;
  final int durationMin;
  final String vehicle;

  String get shortId => id.length <= 6 ? id : id.substring(id.length - 6);
}

class MockHistoryRepository {
  List<RideHistoryEntry> fetch() {
    final now = DateTime.now();
    return [
      RideHistoryEntry(
        id: 'RID-001234',
        pickup: 'DHA Phase 6, Karachi',
        dropoff: 'Tech Park, Shahrah-e-Faisal',
        start: now.subtract(const Duration(minutes: 45)),
        end: now.subtract(const Duration(minutes: 10)),
        status: RideStatus.completed,
        fare: 640,
        km: 8.2,
        durationMin: 32,
        vehicle: 'Car',
      ),
      RideHistoryEntry(
        id: 'RID-001235',
        pickup: 'Narowal Bypass',
        dropoff: 'City Mall',
        start: now.subtract(const Duration(hours: 2, minutes: 10)),
        end: now.subtract(const Duration(hours: 1, minutes: 40)),
        status: RideStatus.canceled,
        fare: 0,
        km: 0.0,
        durationMin: 0,
        vehicle: 'Rickshaw',
      ),
      RideHistoryEntry(
        id: 'RID-001236',
        pickup: 'Sector 4 Market',
        dropoff: 'Railway Station',
        start: now.subtract(const Duration(days: 1, hours: 3)),
        end: now.subtract(const Duration(days: 1, hours: 2, minutes: 20)),
        status: RideStatus.completed,
        fare: 410,
        km: 5.6,
        durationMin: 24,
        vehicle: 'Bike',
      ),
      RideHistoryEntry(
        id: 'RID-001237',
        pickup: 'Hospital Road',
        dropoff: 'University Gate',
        start: now.subtract(const Duration(days: 3, hours: 5)),
        end: null,
        status: RideStatus.ongoing,
        fare: 120,
        km: 2.3,
        durationMin: 8,
        vehicle: 'Car',
      ),
    ];
  }
}

enum HistoryFilter { all, completed, canceled }
