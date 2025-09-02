import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FadeAnimation extends StatefulWidget {
  final double delay;
  final Widget child;
  final bool slideUp;

  const FadeAnimation({
    super.key,
    required this.delay,
    required this.child,
    this.slideUp = true,
  });

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Ajustamos la duración para que sea más rápida en móvil
    final duration = kIsWeb ? 700 : 500;
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Ajustamos la animación de deslizamiento según la plataforma
    final slideDistance = kIsWeb ? 0.15 : 0.1;
    
    _slideAnimation = Tween<Offset>(
      begin: widget.slideUp 
          ? Offset(0, slideDistance) 
          : Offset(slideDistance, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Reducimos el retraso para que las animaciones se sientan más rápidas
    final delayFactor = kIsWeb ? 400 : 300;
    
    Future.delayed(Duration(milliseconds: (widget.delay * delayFactor).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
