import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double? maxHeight,
}) {
  final palette = AppPalette.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          constraints: maxHeight != null
              ? BoxConstraints(maxHeight: maxHeight)
              : null,
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(sheetContext).bottom,
            ),
            child: builder(sheetContext),
          ),
        ),
      );
    },
  );
}

Future<T?> showAppDialog<T>(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  final palette = AppPalette.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final confirmColor = isDestructive ? colorScheme.error : palette.brandRoyal;

  return showDialog<T>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: palette.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: title != null
          ? Text(
              title,
              style: AppTypography.h3(dialogContext),
            )
          : null,
      content: message != null
          ? Text(
              message,
              style: AppTypography.body2(dialogContext)
                  .copyWith(color: colorScheme.onSurfaceVariant),
            )
          : null,
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onCancel?.call();
            },
            child: Text(
              cancelLabel,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (confirmLabel != null)
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
              onConfirm?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
      ],
    ),
  );
}
