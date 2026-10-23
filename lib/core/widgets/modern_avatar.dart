import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_palette.dart';
import 'shimmer_box.dart';

/// Modern avatar component with network image support and fallback.
class ModernAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final IconData? fallbackIcon;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ModernAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.fallbackIcon,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final avatarRadius = BorderRadius.circular(AppRadius.avatar);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primaryContainer,
        borderRadius: avatarRadius,
        border: Border.all(
          color: palette.borderHairline,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: avatarRadius,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: (size * devicePixelRatio).round(),
                errorBuilder: (_, _, _) => _buildFallback(context),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return ShimmerBox(
                    width: size,
                    height: size,
                    borderRadius: AppRadius.avatar,
                  );
                },
              )
            : _buildFallback(context),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: avatarRadius,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(BuildContext context) {
    final contentColor = Theme.of(context).colorScheme.onPrimaryContainer;

    if (fallbackIcon != null) {
      return Icon(
        fallbackIcon,
        size: size * 0.5,
        color: contentColor,
      );
    }

    if (name != null && name!.isNotEmpty) {
      final initials = _getInitials(name!);
      return Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: contentColor,
          ),
        ),
      );
    }

    return Icon(
      Icons.person_rounded,
      size: size * 0.5,
      color: contentColor,
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}

/// Avatar with online status indicator.
class AvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isOnline;

  const AvatarWithStatus({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Stack(
      children: [
        ModernAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
        ),
        if (isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.surface1,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
