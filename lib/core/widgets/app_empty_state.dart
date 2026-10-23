import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import 'modern_button.dart';
import 'motion.dart';
import '../theme/app_palette.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorSchema = Theme.of(context).colorScheme;
    final accentColor = accent ?? palette.brandRoyal;

    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: accentColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.h3(context),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.body3(context).copyWith(
                  color: colorSchema.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                PrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: onRetry != null ? retryLabel ?? 'Yenidən cəhd et' : null,
      onAction: onRetry,
      accent: Theme.of(context).colorScheme.error,
    );
  }
}
