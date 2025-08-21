import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/data/models/ride_type.dart';
import '../../../state/ride_state.dart';

// ----- Fixed three options -----
class _Option {
  final String code;
  final String label;
  final String asset;
  final int base;
  final int etaMin;
  const _Option({
    required this.code,
    required this.label,
    required this.asset,
    required this.base,
    required this.etaMin,
  });

  RideType toRideType() => RideType(
        code: code,
        label: label,
        base: base,
        etaMin: etaMin,
        perKm: 0,
      );
}

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key, this.initialIndex});
  final int? initialIndex;

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen>
    with SingleTickerProviderStateMixin {
  final List<_Option> _options = const [
    _Option(code: 'rickshaw', label: 'Rickshaw', asset: 'assets/images/rikshaws.png', base: 132, etaMin: 2),
    _Option(code: 'every',    label: 'Every',    asset: 'assets/images/copy.png',      base: 231, etaMin: 1),
    _Option(code: 'bike',     label: 'Bike',     asset: 'assets/images/gari.png', base: 88,  etaMin: 3),
  ];

  late int _selectedIdx;

  // preview scale polish
  late final AnimationController _carCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _carScale =
      Tween(begin: 0.95, end: 1.10).animate(CurvedAnimation(parent: _carCtrl, curve: Curves.easeOut));

  // ---- sizes you asked to change ----
  static const double _kTopHeight = 260;   // overall preview box height
  static const double _kHaloOuter = 220;   // outer circle
  static const double _kHaloInner = 170;   // inner circle
  static const double _kTopImage  = 170;   // BIG image size

  @override
  void initState() {
    super.initState();
    _selectedIdx = widget.initialIndex ?? 1; // default Every
  }

  void _onSelect(int idx) {
    if (_selectedIdx == idx) return;
    HapticFeedback.selectionClick();
    _carCtrl.forward(from: 0);

    // keep Hero effect from previous message (optional)
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => RideOptionsScreen(initialIndex: idx),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
    ));
  }

  void _onConfirm() {
    final sel = _options[_selectedIdx];
    final rideType = sel.toRideType();
    context.read<RideState>()
      ..setRideType(rideType)
      ..setEta(sel.etaMin)
      ..setPrice(sel.base + 120);
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
    final pickup = ride.pickup?.name ?? 'Near your location';
    final dst = ride.destination?.name ?? 'Select destination';
    final selected = _options[_selectedIdx];
    const pageBg = Color(0xFFF4FAFD);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Choose your ride'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          _RouteCard(pickup: pickup, destination: dst),
          const SizedBox(height: 18),

          // ======= TOP PREVIEW — smaller halo, bigger image =======
          SizedBox(
            height: _kTopHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: _kHaloOuter,
                  height: _kHaloOuter,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE7F2FB)),
                ),
                Container(
                  width: _kHaloInner,
                  height: _kHaloInner,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEDF6FF)),
                ),
                Positioned(
                  left: 20,
                  top: 8,
                  child: _EtaChip(text: '${selected.etaMin} min'),
                ),
                Hero(
                  tag: 'veh-${selected.code}',
                  child: ScaleTransition(
                    scale: _carScale,
                    child: _VehicleImage(assetPath: selected.asset, size: _kTopImage),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ======= 3 cards: image + price number =======
          SizedBox(
            height: 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final isSelected = _selectedIdx == i;
                final opt = _options[i];

                final img = Hero(
                  tag: 'veh-${opt.code}',
                  child: _VehicleImage(assetPath: opt.asset, size: 56),
                );

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _onSelect(i),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) HeroMode(enabled: false, child: img) else img,
                        const SizedBox(height: 10),
                        Text(
                          '${opt.base}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          _ConfirmCard(
            priceText: 'Rs. ${selected.base + 120}',
            enabled: true,
            onPressed: _onConfirm,
          ),
        ],
      ),
    );
  }
}

/* =================== UI PIECES (unchanged) =================== */

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.pickup, required this.destination});
  final String pickup;
  final String destination;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Column(children: [
            _Dot(color: const Color(0xFF21C06B), outlined: true),
            Container(width: 2, height: 16, color: const Color(0xFFE6EEF4)),
            _Dot(color: const Color(0xFF6D74FF)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Line(text: pickup),
              const SizedBox(height: 6),
              _Line(text: destination),
            ]),
          ),
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
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Icon(Icons.timer_outlined, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({required this.assetPath, this.size = 60});
  final String assetPath;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath, width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({required this.priceText, required this.enabled, required this.onPressed});
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: const Color(0xFF20C06C), borderRadius: BorderRadius.circular(28)),
              child: Text(priceText, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64, height: 56,
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
