import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../common/cultural_icon.dart';

class CulturalParticle extends StatelessWidget {
  final double size;
  final Color color;
  final IconData? icon;
  final String? svgPath;
  final double rotation;
  final double opacity;

  const CulturalParticle({
    Key? key,
    required this.size,
    required this.color,
    required this.icon,
    this.svgPath,
    this.rotation = 0.0,
    this.opacity = 1.0,
  }) : super(key: key);

  const CulturalParticle.svg({
    Key? key,
    required this.size,
    required this.color,
    required this.svgPath,
    this.rotation = 0.0,
    this.opacity = 1.0,
  }) : icon = null,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: Opacity(
        opacity: opacity,
        child: svgPath != null
            ? CulturalIcon(
                svgPath: svgPath!,
                size: size,
                color: color,
              )
            : Icon(
                icon,
                size: size,
                color: color,
              ),
      ),
    );
  }
}

class AnimatedCulturalParticle extends StatefulWidget {
  final double initialSize;
  final Color color;
  final IconData? icon;
  final String? svgPath;
  final Duration duration;
  final Curve curve;
  final double startRotation;
  final double endRotation;
  final double startOpacity;
  final double endOpacity;

  const AnimatedCulturalParticle({
    Key? key,
    required this.initialSize,
    required this.color,
    required this.icon,
    this.svgPath,
    required this.duration,
    this.curve = Curves.easeInOut,
    this.startRotation = 0.0,
    this.endRotation = 360.0,
    this.startOpacity = 0.0,
    this.endOpacity = 1.0,
  }) : super(key: key);

  const AnimatedCulturalParticle.withSvg({
    Key? key,
    required this.initialSize,
    required this.color,
    required this.svgPath,
    required this.duration,
    this.curve = Curves.easeInOut,
    this.startRotation = 0.0,
    this.endRotation = 360.0,
    this.startOpacity = 0.0,
    this.endOpacity = 1.0,
  }) : icon = null,
       super(key: key);

  @override
  State<AnimatedCulturalParticle> createState() => _AnimatedCulturalParticleState();
}

class _AnimatedCulturalParticleState extends State<AnimatedCulturalParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: widget.startRotation,
      end: widget.endRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: widget.startOpacity,
      end: widget.endOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return widget.svgPath != null
            ? CulturalParticle.svg(
                size: widget.initialSize,
                color: widget.color,
                svgPath: widget.svgPath!,
                rotation: _rotationAnimation.value,
                opacity: _opacityAnimation.value,
              )
            : CulturalParticle(
                size: widget.initialSize,
                color: widget.color,
                icon: widget.icon!,
                rotation: _rotationAnimation.value,
                opacity: _opacityAnimation.value,
              );
      },
    );
  }
}