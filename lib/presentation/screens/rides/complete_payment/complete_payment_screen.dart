// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../state/ride_state.dart';

class CompletePaymentScreen extends StatelessWidget {
  const CompletePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideState>();
    final price = ride.estimatedPrice == 0 ? 280 : ride.estimatedPrice;

    // Theme hooks
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final divider = theme.dividerColor;

    return Scaffold(
      // allow body to move when keyboard shows
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Trip complete', style: tt.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        // Light: subtle top→bottom wash; Dark: very subtle to avoid banding
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bg,
              theme.brightness == Brightness.dark
                  ? bg.withOpacity(.96)
                  : bg.withOpacity(.98),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final kb = MediaQuery.of(context).viewInsets.bottom;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: kb), // ← keyboard safe
                child: SingleChildScrollView(
                  // so it can scroll when keyboard hides space
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SuccessCard(
                          price: price,
                          destination: ride.destination?.name,
                          card: card,
                          divider: divider,
                          cs: cs,
                          tt: tt,
                        ),
                        const SizedBox(height: 16),
                        _RatingBlock(cs: cs, tt: tt, card: card),
                        const SizedBox(height: 24),
                        // Button inside body so it looks part of the page
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              context.read<RideState>().reset();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Routes.home,
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Done',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final num price;
  final String? destination;
  final Color card;
  final Color divider;
  final ColorScheme cs;
  final TextTheme tt;

  const _SuccessCard({
    required this.price,
    this.destination,
    required this.card,
    required this.divider,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final dest = destination ?? '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary,
            ),
            child: Icon(Icons.check_rounded, size: 46, color: cs.onPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'PKR ${price.toStringAsFixed(0)}',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.secondary.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_rounded, size: 16, color: cs.onSurface.withOpacity(.8)),
                const SizedBox(width: 6),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dest,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7), fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Thanks for riding with Zoomigoo!',
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
          ),
        ],
      ),
    );
  }
}

class _RatingBlock extends StatefulWidget {
  const _RatingBlock({required this.cs, required this.tt, required this.card});
  final ColorScheme cs;
  final TextTheme tt;
  final Color card;

  @override
  State<_RatingBlock> createState() => _RatingBlockState();
}

class _RatingBlockState extends State<_RatingBlock> {
  int _stars = 0; // ← start empty
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;

    return Semantics(
      label: 'Rate your ride',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate your ride',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final idx = i + 1;
              final filled = idx <= _stars;
              return _StarButton(
                index: idx,
                filled: filled,
                onTap: () => setState(() => _stars = idx),
                onLongPress: () => setState(() => _stars = 0),
                // theme-aware colors
                filledColor: Colors.amber, // nice on both themes
                emptyColor: cs.onSurface.withOpacity(.45),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Additional feedback (optional)',
              // rely on global InputDecorationTheme; only tweak hint color
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.6)),
              filled: true,
              // fillColor/borders will come from theme.inputDecorationTheme
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 4),
          Text(
            _stars == 0 ? 'Tip: Long-press stars to reset.' : 'Selected: $_stars/5',
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.6)),
          ),
        ],
      ),
    );
  }
}

class _StarButton extends StatefulWidget {
  final int index;
  final bool filled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Color filledColor;
  final Color emptyColor;
  const _StarButton({
    required this.index,
    required this.filled,
    required this.onTap,
    required this.onLongPress,
    required this.filledColor,
    required this.emptyColor,
  });
  @override
  State<_StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<_StarButton> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    final isFilled = widget.filled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isFilled || _hovering
            ? [
                BoxShadow(
                  color: widget.filledColor.withOpacity(.45),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: isFilled || _hovering ? 1.12 : 1.0,
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
              size: 34,
              color: isFilled ? widget.filledColor : widget.emptyColor,
              semanticLabel: '${widget.index} star',
            ),
          ),
        ),
      ),
    );
  }
}
