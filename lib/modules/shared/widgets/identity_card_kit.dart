import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/motion.dart';

class IdentityCardShell extends StatelessWidget {
  const IdentityCardShell({
    super.key,
    required this.child,
    required this.accent,
    required this.gradient,
  });

  final Widget child;
  final Color accent;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          const BoxShadow(
            color: Color(0x73000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

class IdentityCardPhoto extends StatelessWidget {
  const IdentityCardPhoto({
    super.key,
    required this.name,
    required this.accent,
    this.photoUrl,
    this.width = 62,
    this.height = 78,
  });

  final String name;
  final Color accent;
  final String? photoUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: url.isEmpty
            ? _PhotoFallback(name: name, accent: accent)
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                    ? child
                    : _PhotoFallback(name: name, accent: accent),
                errorBuilder: (_, _, _) =>
                    _PhotoFallback(name: name, accent: accent),
              ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2B4C), Color(0xFF0B1226)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initialsOf(name),
        style: TextStyle(
          color: accent.withValues(alpha: 0.95),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

String _initialsOf(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'İ';
  if (parts.length == 1) {
    final first = parts.first;
    return first.substring(0, first.length > 2 ? 2 : 1).toUpperCase();
  }
  return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
}

class IdentityCardField extends StatelessWidget {
  const IdentityCardField({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.accent,
  });

  final String label;
  final String value;
  final int maxLines;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final codeAccent = accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.54),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: codeAccent ?? Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: codeAccent == null ? 0.1 : 0.4,
            fontFamily: codeAccent == null ? null : 'monospace',
          ),
        ),
      ],
    );
  }
}

class IdentityCardInfoRow extends StatelessWidget {
  const IdentityCardInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.54),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IdentityCardQrTile extends StatelessWidget {
  const IdentityCardQrTile({
    super.key,
    required this.data,
    required this.onTap,
    this.size = 56,
    this.tooltip = 'QR kodu göstər',
  });

  final String data;
  final VoidCallback onTap;
  final double size;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size - 10,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class IdentityCardAction extends StatelessWidget {
  const IdentityCardAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? accent;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final tint = accent ?? palette.brandRoyal;

    return PressableScale(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: palette.surface1,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: busy
                        ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tint,
                            ),
                          )
                        : Icon(icon, size: 16, color: tint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showIdentityQrSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String displayName,
  required String code,
  required Color accent,
}) async {
  HapticFeedback.selectionClick();
  final copied = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _IdentityQrSheet(
      title: title,
      subtitle: subtitle,
      displayName: displayName,
      code: code,
      accent: accent,
    ),
  );

  if (copied != true || !context.mounted) return;

  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(Icons.copy_rounded, size: 14, color: colorScheme.onInverseSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kod kopyalandı • $code',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onInverseSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _IdentityQrSheet extends StatelessWidget {
  const _IdentityQrSheet({
    required this.title,
    required this.subtitle,
    required this.displayName,
    required this.code,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String displayName;
  final String code;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetAccent =
        isDark ? accent : (Color.lerp(accent, Colors.black, 0.35) ?? accent);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: AppRadius.bottomSheetRadius,
        boxShadow: AppShadows.adaptiveModal(context),
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 24, 22 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sheetAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 19,
                    color: sheetAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 212,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: sheetAccent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Semantics(
                button: true,
                label: 'Kodu kopyala',
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sheetAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sheetAccent.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 15, color: sheetAccent),
                        const SizedBox(width: 7),
                        Text(
                          'Kodu kopyala',
                          style: TextStyle(
                            color: sheetAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
