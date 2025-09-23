import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedLogo extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedLogo({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _hasNotifiedCompletion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNotifiedCompletion) {
        _hasNotifiedCompletion = true;
        widget.onAnimationComplete();
      }
    });

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
        final size = MediaQuery.of(context).size;
        // Más grande: hasta 80% del ancho y 50% del alto (mínimo entre ambos), con límites
        final widthBound = (size.width * 1.5).clamp(200.0, 560.0).toDouble();
        final heightBound = (size.height * 1.2).clamp(180.0, 520.0).toDouble();
        final dimension = widthBound < heightBound ? widthBound : heightBound;
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: SvgPicture.asset(
              'assets/icons/logotipo (vertical).svg',
              width: dimension,
              height: dimension,
              fit: BoxFit.contain,
              semanticsLabel: 'Logotipo Memoria Viva - vertical',
            ),
          ),
        );
      },
    );
  }
}