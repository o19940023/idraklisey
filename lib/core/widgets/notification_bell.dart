import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final Color color;
  final double size;

  const NotificationBell({
    super.key,
    this.count = 0,
    this.onTap,
    this.color = Colors.white,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeText = count > 99 ? '99+' : '$count';

    final badge = Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.error,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.surface,
          width: 1.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          badgeText,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1,
            color: colorScheme.onError,
          ),
        ),
      ),
    );

    Widget badgeAnimated;
    if (MediaQuery.disableAnimationsOf(context) || count == 0) {
      badgeAnimated = count == 0 ? const SizedBox.shrink() : badge;
    } else {
      badgeAnimated = badge
          .animate()
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 180.ms,
            curve: Curves.easeOutBack,
          );
    }

    return Semantics(
      button: true,
      label: count > 0 ? 'Bildirimlər, $count oxunmamış' : 'Bildirimlər',
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: size * 0.58,
                color: color,
              ),
              if (count > 0)
                Positioned(
                  top: 4,
                  right: 3,
                  child: badgeAnimated,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
