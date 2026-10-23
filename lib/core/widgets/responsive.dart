import 'package:flutter/material.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 840;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 840;

  static int columns(
    BuildContext context, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
  }) =>
      isExpanded(context) ? expanded : isMedium(context) ? medium : compact;
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double horizontalPadding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

EdgeInsets responsivePadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 840) return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
  if (width >= 600) return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  return const EdgeInsets.all(16);
}
