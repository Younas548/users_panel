import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/data/models/ride_type.dart'; // <- we will pass a RideType to state
import '../../../state/ride_state.dart';

// ----- Fixed three options -----
class _Option {
  final String code;      // 'rickshaw' | 'every' | 'bike'
  final String label;     // human readable for RideType
  final String asset;     // asset path
  final int base;         // base fare (for summary)
  final int etaMin;       // ETA minutes
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
        perKm: 0, // TODO: Replace 0 with the correct perKm value if needed
      );
}

class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key});

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen>
    with SingleTickerProviderStateMixin {
  // FIXED: Rickshaw, Every (car/van), Bike
  final List<_Option> _options = const [
    _Option(
      code: 'rickshaw',
      label: 'Rickshaw',
      asset: 'assets/images/rikshaw.JPEG',
      base: 132,
      etaMin: 2,
    ),
    _Option(
      code: 'every',
      label: 'Every',
      asset: 'assets/images/copy.png',
      base: 231,
      etaMin: 1,
    ),
    _Option(
      code: 'bike',
      label: 'Bike',
      asset: 'assets/images/copy1.png',
      base: 88,
      etaMin: 3,
    ),
  ];

  int _selectedIdx = 0;

  // top preview scale animation
  late final AnimationController _carCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _carScale =
      Tween(begin: 0.95, end: 1.12).animate(
        CurvedAnimation(parent: _carCtrl, curve: Curves.easeOut),
      );

  void _onSelect(int idx) {
    if (_selectedIdx != idx) {
      HapticFeedback.selectionClick();
      _carCtrl.forward(from: 0);
      setState(() => _selectedIdx = idx);
    }
  }

  void _onConfirm() {
    final sel = _options[_selectedIdx];
    final rideType = sel.toRideType(); // convert to your RideType model

    // Use your existing RideState methods (no setRideTypeCode)
    context.read<RideState>()
      ..setRideType(rideType)
      ..setEta(sel.etaMin)
      ..setPrice(sel.base + 120); // sample calc; adjust as needed

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
          // Top route summary (no "Change" button)
          _RouteCard(pickup: pickup, destination: dst),
          const SizedBox(height: 18),

          // ======= Big vehicle + ETA chip =======
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE7F2FB),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEDF6FF),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 28,
                  child: _EtaChip(text: '${selected.etaMin} min'),
                ),
                ScaleTransition(
                  scale: _carScale,
                  child: _VehicleImage(
                    assetPath: selected.asset,
                    size: 100,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ======= Three cards with ONLY images =======
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final isSelected = _selectedIdx == i;
                final opt = _options[i];
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
                        color: isSelected
                            ? const Color(0xFF2B6BEA)
                            : const Color(0xFFE7EEF5),
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
                    // Only the image (no labels, no PKR)
                    child: Center(child: _VehicleImage(assetPath: opt.asset, size: 60)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ======= Green price bar + confirm =======
          _ConfirmCard(
            priceText: 'Rs. ${selected.base + 120}', // show final total
            enabled: true,
            onPressed: _onConfirm,
          ),
        ],
      ),
    );
  }
}

/* =================== UI PIECES =================== */

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.pickup,
    required this.destination,
  });

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      width: 16,
      height: 16,
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
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
    );
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
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({required this.assetPath, this.size = 80});
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
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
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
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
