import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.31), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
