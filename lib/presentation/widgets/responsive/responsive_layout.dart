import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget webBody;
  final double breakpoint;

  const ResponsiveLayout({
    Key? key,
    required this.mobileBody,
    required this.webBody,
    this.breakpoint = 600,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return mobileBody;
        }
        return webBody;
      },
    );
  }
}
