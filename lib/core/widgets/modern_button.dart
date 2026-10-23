import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_palette.dart';
import 'motion.dart';

/// Modern primary button component (2026 style).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final royal = palette.brandRoyal;

    Widget buttonChild = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppSpacing.iconMd),
                  SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: royal,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            royal.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.45),
        minimumSize: Size(fullWidth ? double.infinity : 120, 48),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingH,
          vertical: AppSpacing.buttonPaddingV,
        ),
      ),
      child: buttonChild,
    );

    // Press feedback stays subtle and never intercepts the button's own taps.
    final pressable = PressableScale(
      pressedScale: 0.97,
      enabled: !isLoading && onPressed != null,
      child: button,
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: pressable)
        : pressable;
  }
}

/// Modern secondary/outlined button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final royal = _royal(context);

    Widget buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSpacing.iconMd),
              SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          )
        : Text(label);

    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: royal,
        side: BorderSide(color: royal, width: 1.5),
        minimumSize: Size(fullWidth ? double.infinity : 120, 48),
      ),
      child: buttonChild,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Text-only button for subtle actions.
class TextOnlyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const TextOnlyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final royal = _royal(context);

    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSpacing.iconMd),
              SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          )
        : Text(label);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: royal),
      child: child,
    );
  }
}

/// Borderless tonal action button with a soft royal highlight on press.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final royal = _royal(context);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: royal),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: royal,
          ),
        ),
      ],
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        highlightColor: palette.brandRoyal.withValues(alpha: 0.06),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Icon button with modern styling.
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const ModernIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? palette.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.borderHairline),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: AppSpacing.iconMd),
          color: color ?? colorScheme.onSurface,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

Color _royal(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return const Color(0xFF60A5FA);
  }
  return AppPalette.of(context).brandRoyal;
}
