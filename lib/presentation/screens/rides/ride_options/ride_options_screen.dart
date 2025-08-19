import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/data/models/ride_type.dart';
import '../../../../core/data/repositories/ride_repository.dart';
import '../../../state/ride_state.dart';

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key});

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = MockRideRepository();

  List<RideType> _types = [];
  RideType? _selected;

  bool _loading = true;
  String? _error;

  // local override for destination text (changed via bottom sheet)
  String? _dstOverride;

  // top car “enlarge” animation
  late final AnimationController _carCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _carScale =
      Tween(begin: 0.95, end: 1.12).animate(CurvedAnimation(parent: _carCtrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _repo.getRideTypes();
      if (!mounted) return;
      setState(() {
        _types = t;
        _selected = t.isNotEmpty ? t.first : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load rides. Pull to retry.';
        _loading = false;
      });
    }
  }

  void _onSelect(RideType t) {
    if (_selected?.code != t.code) {
      HapticFeedback.selectionClick();
      // animate the big icon
      _carCtrl.forward(from: 0);
    }
    setState(() => _selected = t);
  }

  Future<void> _changeDestination() async {
    // If you already have a search route, you can simply do:
    // final result = await Navigator.pushNamed(context, Routes.search);
    // if (result is Place) context.read<RideState>().setDestination(result);
    // else if (result is String) setState(() => _dstOverride = result);

    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DestinationSheet(),
    );

    if (text != null && text.trim().isNotEmpty) {
      setState(() => _dstOverride = text.trim());
    }
  }

  void _onConfirm() {
    if (_selected == null) return;
    final total = _selected!.base + 120; // keep your sample calc
    context.read<RideState>()
      ..setRideType(_selected!)
      ..setEta(_selected!.etaMin)
      ..setPrice(total);
    Navigator.pushNamed(context, Routes.confirmPickup);
  }

  @override
  void dispose() {
    _carCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final dst = _dstOverride ?? (ride.destination?.name ?? 'Select destination');
    final pickup = ride.pickup?.name ?? 'Near your location';
    final eta = _selected?.etaMin ?? 1;

    const pageBg = Color(0xFFF4FAFD);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Choose your ride'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            _RouteCard(
              pickup: pickup,
              destination: dst,
              onChangeDestination: _changeDestination,
            ),
            const SizedBox(height: 18),

            // ======= Big vehicle + ETA chip (like your pic 2) =======
            SizedBox(
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // outer halo
                  Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE7F2FB),
                    ),
                  ),
                  // inner halo
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEDF6FF),
                    ),
                  ),
                  // ETA chip
                  Positioned(
                    left: 24,
                    top: 28,
                    child: _EtaChip(text: '$eta min'),
                  ),
                  // big car icon — scales slightly when you select a tile
                  ScaleTransition(
                    scale: _carScale,
                    child: const Icon(Icons.directions_car_filled, size: 78, color: Color.fromARGB(255, 224, 10, 135)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ======= Horizontal ride options =======
            if (_loading)
              const _LoadingRow()
            else if (_error != null)
              _ErrorBox(message: _error!, onRetry: _load)
            else if (_types.isEmpty)
              const _EmptyBox()
            else
              _RideSelector(
                types: _types,
                selected: _selected,
                onSelect: _onSelect,
              ),

            const SizedBox(height: 18),

            // ======= Green price bar + confirm =======
            _ConfirmCard(
              priceText: _selected == null
                  ? 'Select a ride'
                  : Formatters.currency(_selected!.base + 120),
              enabled: _selected != null,
              onPressed: _onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

/* =================== UI PIECES =================== */

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.pickup,
    required this.destination,
    required this.onChangeDestination,
  });

  final String pickup;
  final String destination;
  final VoidCallback onChangeDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              _Dot(color: const Color(0xFF21C06B), outlined: true),
              Container(width: 2, height: 16, color: const Color(0xFFE6EEF4)),
              _Dot(color: const Color(0xFF6D74FF)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(text: pickup),
                const SizedBox(height: 6),
                _Line(text: destination),
              ],
            ),
          ),
          TextButton(onPressed: onChangeDestination, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.outlined = false});
  final Color color;
  final bool outlined;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16, height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: const Color(0xFF21C06B), width: 2) : null,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600));
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2B6BEA), width: 1.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RideSelector extends StatelessWidget {
  const _RideSelector({
    required this.types,
    required this.selected,
    required this.onSelect,
  });

  final List<RideType> types;
  final RideType? selected;
  final void Function(RideType) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final t = types[i];
          final isSelected = selected?.code == t.code;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelect(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 130,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2B6BEA) : const Color(0xFFE7EEF5),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled, size: 30, color: const Color.fromARGB(255, 43, 234, 75)),
                  const SizedBox(height: 10),
                  Text(t.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    // “PKR 180” style like your screenshot
                    Formatters.currency(t.base).replaceAll('Rs.', 'PKR'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.priceText,
    required this.enabled,
    required this.onPressed,
  });

  final String priceText;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF20C06C),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                priceText,
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: enabled ? const Color(0xFF20C06C) : Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: enabled ? onPressed : null,
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) {
    Widget skel() => Container(
          width: 130,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        );
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          skel(), const SizedBox(width: 12), skel(), const SizedBox(width: 12), skel(),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: const Text('No rides available. Pull to refresh.'),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/* ===== bottom sheet to change destination (inline & simple) ===== */

class _DestinationSheet extends StatefulWidget {
  const _DestinationSheet();

  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(
              color: const Color(0xFFE1E6EC), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            const Text('Change destination',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _c,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter destination…',
                prefixIcon: const Icon(Icons.place_outlined),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B6BEA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, _c.text),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
