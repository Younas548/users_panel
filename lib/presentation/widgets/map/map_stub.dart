import 'package:flutter/material.dart';
import '../../../core/data/services/map_service.dart';

class MapStub extends StatelessWidget {
  final double height;
  final Widget? overlay;
  const MapStub({super.key, this.height = 260, this.overlay});

  @override
  Widget build(BuildContext context) {
    final asset = MapService().getStubTileAsset();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
