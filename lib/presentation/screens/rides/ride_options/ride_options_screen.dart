import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/data/models/ride_type.dart';
import '../../../../core/constants/flags.dart';
import '../../../../core/utils/promo_preview.dart';
import '../../../state/ride_state.dart';

// ⬇️ Add: pressable wrapper for CTA buttons
import '../../../widgets/pressable.dart';

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
    _Option(code: 'bike',     label: 'Bike',     asset: 'assets/images/gari.png',      base: 88,  etaMin: 3),
  ];

  late int _selectedIdx;

  late final AnimationController _carCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _carScale =
      Tween(begin: 0.95, end: 1.10).animate(CurvedAnimation(parent: _carCtrl, curve: Curves.easeOut));

  // Top preview sizes
  static const double _kTopHeight = 260;
  static const double _kHaloOuter = 220;
  static const double _kHaloInner = 170;
  static const double _kTopImage  = 170;

  // Compact option-card sizing (smaller & safe)
  static const double _kOptionsHeight = 132;
  static const double _kCardWidth     = 120;
  static const double _kThumbSize     = 44;

  @override
  void initState() {
    super.initState();
    _selectedIdx = widget.initialIndex ?? 1; // default Every
  }

  void _onSelect(int idx) {
    if (_selectedIdx == idx) return;
    HapticFeedback.selectionClick();
    _carCtrl.forward(from: 0);

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => RideOptionsScreen(initialIndex: idx),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
    ));
  }

  void _onConfirm() {
    final ride = context.read<RideState>();
    final sel = _options[_selectedIdx];
    final rideType = sel.toRideType();

    // Subtotal rule (simple): base + 120
    final subtotal = (sel.base + 120).toDouble();

    // Promo preview apply (UI-only)
    final rc = ride.ridesCompleted;
    final hasPromo = AppFlags.welcomePromoPreview && PromoPreview.eligible(rc);
    final discount = hasPromo ? PromoPreview.discount(subtotal, rc) : 0.0;
    final total    = hasPromo ? PromoPreview.total(subtotal, rc)    : subtotal;

    ride
      ..setRideType(rideType)
      ..setEta(sel.etaMin)
      ..setFare(subtotal: subtotal, discount: discount, total: total);

    Navigator.pushNamed(context, Routes.confirmPickup);
  }

  @override
  void dispose() {
    _carCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // THEME HOOKS
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final tt      = theme.textTheme;
    final bg      = theme.scaffoldBackgroundColor;
    final card    = theme.cardColor;
    final divider = theme.dividerColor;
    final onBg    = cs.onSurface;

    final ride = context.watch<RideState>();
    final pickup = ride.pickup?.name ?? 'Near your location';
    final dst = ride.destination?.name ?? 'Select destination';
    final selected = _options[_selectedIdx];

    // halos
    final haloOuter = cs.secondary.withOpacity(theme.brightness == Brightness.dark ? .15 : .18);
    final haloInner = cs.secondary.withOpacity(theme.brightness == Brightness.dark ? .08 : .12);
    // --- live totals for selected card ---
    final rc = ride.ridesCompleted;
    final selectedSubtotal = (selected.base + 120).toDouble();
    final selHasPromo = AppFlags.welcomePromoPreview && PromoPreview.eligible(rc);
    final selectedTotal    = selHasPromo ? PromoPreview.total(selectedSubtotal, rc) : selectedSubtotal;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.appBarTheme.foregroundColor ?? onBg,
        elevation: 0,
        title: Text('Choose your ride', style: tt.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          _RouteCard(
            pickup: pickup,
            destination: dst,
            card: card,
            divider: divider,
            textStyle: tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: onBg),
          ),
          const SizedBox(height: 12),

          // ======= TOP PREVIEW =======
          SizedBox(
            height: _kTopHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: _kHaloOuter,
                  height: _kHaloOuter,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: haloOuter),
                ),
                Container(
                  width: _kHaloInner,
                  height: _kHaloInner,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: haloInner),
                ),
                Positioned(
                  left: 20,
                  top: 8,
                  child: _EtaChip(
                    text: '${selected.etaMin} min',
                    card: card,
                    borderColor: cs.primary,
                    iconColor: onBg,
                    textStyle: tt.labelMedium!,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                  ),
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
          const SizedBox(height: 6),

          // ======= OPTIONS LIST (more compact, overflow-proof) =======
          SizedBox(
            height: _kOptionsHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final isSelected = _selectedIdx == i;
                final opt = _options[i];

                final img = Hero(
                  tag: 'veh-${opt.code}',
                  child: _VehicleImage(assetPath: opt.asset, size: _kThumbSize),
                );

                // Per-card subtotal/total
                final subtotal = (opt.base + 120).toDouble();
                final hasPromo = AppFlags.welcomePromoPreview && PromoPreview.eligible(rc);
                final total    = hasPromo ? PromoPreview.total(subtotal, rc) : subtotal;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _kCardWidth,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? cs.primary : divider,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) HeroMode(enabled: false, child: img) else img,
                        const SizedBox(height: 6),

                        // Price area (wrapped so it NEVER overflows)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: hasPromo
                              ? Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: cs.secondaryContainer,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '-20% Est.',
                                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSecondaryContainer,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      total.toStringAsFixed(0), // no PKR
                                      style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                )
                              : Text(
                                  subtotal.toStringAsFixed(0), // no PKR
                                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .90),
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ======= BOTTOM CONFIRM (new layout + CTA Pressable) =======
          _ConfirmCard(
            price: selectedTotal.toStringAsFixed(0),
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
    required this.card,
    required this.divider,
    required this.textStyle,
  });
  final String pickup;
  final String destination;
  final Color card;
  final Color divider;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Column(children: [
            _Dot(color: const Color(0xFF21C06B), outlined: true),
            Container(width: 2, height: 16, color: divider),
            _Dot(color: const Color(0xFF6D74FF)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Line(text: pickup, style: textStyle),
              const SizedBox(height: 6),
              _Line(text: destination, style: textStyle),
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
  const _Line({required this.text, required this.style});
  final String text;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({
    required this.text,
    required this.card,
    required this.borderColor,
    required this.iconColor,
    required this.textStyle,
    required this.shadowColor,
  });
  final String text;
  final Color card;
  final Color borderColor;
  final Color iconColor;
  final TextStyle textStyle;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borderColor, width: 1.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(Icons.timer_outlined, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(text, style: textStyle.copyWith(fontWeight: FontWeight.w700)),
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

/// NEW confirm area (price chip + Pressable circular ✓)
class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.price,
    required this.enabled,
    required this.onPressed,
  });
  final String price;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          // Price pill (auto width, secondary -> only theme overlay)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cs.primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  price, // no PKR
                  style: tt.titleMedium!.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          const Spacer(),

          // PRIMARY CTA: circular ✓ — with Pressable scale + haptics
          Pressable(
            child: GestureDetector(
              onTap: enabled ? onPressed : null,
              child: Opacity(
                opacity: enabled ? 1 : .5,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: .85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha:.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.check_rounded, color: cs.onPrimary, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
