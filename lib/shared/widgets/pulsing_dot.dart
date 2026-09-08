import 'package:flutter/material.dart';

/// An animated pulsating beacon dot used to indicate active selections
/// such as current sheet number, selected card, or active preview elements.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool isPulsing;

  const PulsingDot({
    super.key,
    this.color = const Color(0xFF0284C7),
    this.size = 7.0,
    this.isPulsing = true,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        final auraSize = widget.size + (5.0 * t);

        return SizedBox(
          width: widget.size + 6,
          height: widget.size + 6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding / fading halo
              Container(
                width: auraSize,
                height: auraSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (0.45 * (1.0 - t * 0.5)).clamp(0.0, 1.0)),
                ),
              ),
              // Inner solid glowing dot
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: (0.6 + 0.4 * t).clamp(0.0, 1.0)),
                      blurRadius: 3.5 + (3.0 * t),
                      spreadRadius: 0.5 + (1.0 * t),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
