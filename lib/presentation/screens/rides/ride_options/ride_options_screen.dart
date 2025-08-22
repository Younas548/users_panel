import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/data/models/ride_type.dart';
import '../../../../core/constants/flags.dart';
import '../../../../core/utils/promo_preview.dart';
import '../../../state/ride_state.dart';

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

  static const double _kTopHeight = 260;
  static const double _kHaloOuter = 220;
  static const double _kHaloInner = 170;
  static const double _kTopImage  = 170;

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

    // Subtotal rule (abhi simple): base + 120
    final subtotal = (sel.base + 120).toDouble();

    // Promo preview apply (UI-only)
    final rc = ride.ridesCompleted; // TODO: backend se sync
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
    // THEME HOOKS (sirf yahan se colors lo)
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

    // --- Selected card ke liye live totals ---
    final rc = ride.ridesCompleted;
    final selectedSubtotal = (selected.base + 120).toDouble();
    final selHasPromo = AppFlags.welcomePromoPreview && PromoPreview.eligible(rc);
    final selectedDiscount = selHasPromo ? PromoPreview.discount(selectedSubtotal, rc) : 0.0;
    final selectedTotal    = selHasPromo ? PromoPreview.total(selectedSubtotal, rc)    : selectedSubtotal;

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
          _RouteCard(pickup: pickup, destination: dst, card: card, divider: divider, textStyle: tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: onBg)),
          const SizedBox(height: 18),

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
                    shadowColor: Colors.black.withOpacity(0.05),
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
          const SizedBox(height: 8),

          // ======= OPTIONS LIST =======
          SizedBox(
            height: 160,
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

                // Per-card subtotal/discount/total
                final subtotal = (opt.base + 120).toDouble();
                final hasPromo = AppFlags.welcomePromoPreview && PromoPreview.eligible(rc);
                final discount = hasPromo ? PromoPreview.discount(subtotal, rc) : 0.0;
                final total    = hasPromo ? PromoPreview.total(subtotal, rc)    : subtotal;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 150,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? cs.primary : divider,
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

                        // Price showing: strike-through + final
                        if (hasPromo) ...[
                          Text(
                            'PKR ${subtotal.toStringAsFixed(0)}',
                            style: tt.bodyMedium!.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '-20% Est.',
                                  style: tt.labelSmall!.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PKR ${total.toStringAsFixed(0)}',
                                style: tt.titleMedium!.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'PKR ${subtotal.toStringAsFixed(0)}',
                            style: tt.titleMedium!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onBg.withOpacity(.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          _ConfirmCard(
            priceText: 'PKR ${selectedTotal.toStringAsFixed(0)}',
            enabled: true,
            onPressed: _onConfirm,
            cs: cs,
            card: card,
            banner: selHasPromo
                ? 'WELCOME20 • ${PromoPreview.remaining(rc)} ride(s) left • Applied at checkout'
                : null,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
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

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.priceText,
    required this.enabled,
    required this.onPressed,
    required this.cs,
    required this.card,
    this.banner,
  });
  final String priceText;
  final bool enabled;
  final VoidCallback onPressed;
  final ColorScheme cs;
  final Color card;
  final String? banner;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner != null) ...[
            Row(
              children: [
                Icon(Icons.local_offer, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(banner!, style: tt.bodySmall)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(28)),
                  child: Text(
                    priceText,
                    style: tt.titleLarge!.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: enabled ? cs.primary : Theme.of(context).disabledColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: enabled ? onPressed : null,
                  child: Icon(Icons.check, color: cs.onPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
