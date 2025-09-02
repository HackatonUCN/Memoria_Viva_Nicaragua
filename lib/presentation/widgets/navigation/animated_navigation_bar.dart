import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import '../../../core/theme/app_colors.dart';

class AnimatedNavigationBar extends StatefulWidget {
  final int currentIndex;
  final List<CurvedNavigationBarItem> items;
  final ValueChanged<int> onTap;

  const AnimatedNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<AnimatedNavigationBar> createState() => _AnimatedNavigationBarState();
}

class _AnimatedNavigationBarState extends State<AnimatedNavigationBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AnimatedNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.currentIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: _currentIndex,
      color: AppColors.surface,
      buttonBackgroundColor: AppColors.primary,
      backgroundColor: AppColors.background,
      animationCurve: Curves.easeOut,
      animationDuration: const Duration(milliseconds: 400),
      items: widget.items,
      onTap: widget.onTap,
    );
  }
}
