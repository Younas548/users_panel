import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 110),
    this.curve = Curves.easeOut,
    this.enableHaptics = true,
  });

  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    if (v && widget.enableHaptics) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent, // child's onPressed still works
      onPointerDown: (_) => _setDown(true),
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

// (optional) sugar for quick wrapping: anyWidget.press()
extension PressX on Widget {
  Widget press({double scale = 0.97}) => Pressable(scale: scale, child: this);
}
