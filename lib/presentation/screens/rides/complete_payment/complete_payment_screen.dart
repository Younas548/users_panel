//import 'dart:math' as math;
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

    return Scaffold(
      // allow body to move when keyboard shows
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: const Text('Trip complete'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f172a), Color(0xFF111827)],
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
                        _SuccessCard(price: price, destination: ride.destination?.name),
                        const SizedBox(height: 16),
                        const _RatingBlock(), // ⭐ starts at 0
                        const SizedBox(height: 24),
                        // Button inside body so it looks part of the page
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22c55e),
                              foregroundColor: Colors.white,
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
  const _SuccessCard({required this.price, this.destination});

  @override
  Widget build(BuildContext context) {
    final dest = destination ?? '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 217, 225, 235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 225, 236, 255), width: 1),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(223, 233, 228, 228), blurRadius: 24, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10b981),
            ),
            child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'PKR ${price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 195, 204, 223),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromARGB(255, 178, 197, 228)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.place_rounded, size: 16, color: Color.fromARGB(255, 224, 235, 255)),
              SizedBox(width: 6),
            ]),
          ),
          const SizedBox(height: 4),
          Text(
            dest,
            style: const TextStyle(color: Color(0xFFd1d5db), fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thanks for riding with Zoomigoo!',
            style: TextStyle(color: Color.fromARGB(255, 225, 225, 250), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RatingBlock extends StatefulWidget {
  const _RatingBlock();
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
    return Semantics(
      label: 'Rate your ride',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate your ride',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Additional feedback (optional)',
              hintStyle: const TextStyle(color: Color.fromARGB(255, 192, 207, 233)),
              filled: true,
              fillColor: const Color(0xFF111827),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color.from(alpha: 1, red: 0.918, green: 0.937, blue: 0.969)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color.fromARGB(255, 203, 214, 231)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF60a5fa)),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 4),
          Text(
            _stars == 0 ? 'Tip: Long-press stars to reset.' : 'Selected: $_stars/5',
            style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 12),
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
  const _StarButton({
    required this.index,
    required this.filled,
    required this.onTap,
    required this.onLongPress,
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
            ? const [BoxShadow(color: Color(0x66f59e0b), blurRadius: 12, offset: Offset(0, 3))]
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
              color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFF9ca3af),
              semanticLabel: '${widget.index} star',
            ),
          ),
        ),
      ),
    );
  }
}
