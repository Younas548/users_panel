import 'package:flutter/material.dart';

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    this.name = 'Arslam Aslam',
    this.rating = 4.9,
    this.carModel = 'Suzuki Alto',
    this.carColor = 'White',
    this.plate = 'NRL-123',

    // 👉 apne asset names yahan set kar lo
    this.driverImage = 'assets/images/map3_stub.PNG',
    this.carImage = 'assets/images/map4_stub.JPEG',
  });

  final String name;
  final double rating;
  final String carModel;
  final String carColor;
  final String plate;
  final String driverImage;
  final String carImage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: cs.surface.withOpacity(0.96),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar (bigger)
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: AssetImage(driverImage),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),

            // Middle: name + rating + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + rating in one row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RatingPill(rating: rating),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$carModel • $carColor • $plate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right: car preview box (fixed size so layout stable rahe)
            Container(
              width: 96,
              height: 68,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.25)),
              ),
              child: Image.asset(
                carImage,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.directions_car, color: cs.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
