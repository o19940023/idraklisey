import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/section_header.dart';
import '../../../providers/app_state.dart';
import 'school_hero_background.dart';

Future<void> showEmployeeRoleSwitcherSheet(BuildContext context) async {
  final session = context.read<SessionController>();
  final profile = session.profile;
  if (profile == null || (profile.roles.length <= 1 && !profile.canSwitchGuard)) return;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      var switchingRole = '';
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentActive =
              session.profile?.activeRole ?? profile.roles.first;
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primaryAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rol və Səlahiyyət Keçidi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aktiv rolu dəyişdikdə menyu və icazələr həmin rola uyğun yenilənir',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final roleName in profile.roles) ...[
                    Builder(
                      builder: (_) {
                        final isSelected = roleName == currentActive;
                        final isLoading = switchingRole == roleName;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: switchingRole.isNotEmpty
                                ? null
                                : () async {
                                    if (isSelected) {
                                      Navigator.pop(sheetCtx);
                                      return;
                                    }
                                    setSheetState(() => switchingRole = roleName);
                                    final ok = await context
                                        .read<AppState>()
                                        .switchEmployeeRole(context, roleName);
                                    if (!sheetCtx.mounted) return;
                                    Navigator.pop(sheetCtx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? 'Aktiv rol dəyişdirildi: $roleName'
                                                : 'Rol dəyişdirilə bilmədi',
                                          ),
                                          backgroundColor: ok
                                              ? AppColors.success
                                              : AppColors.danger,
                                        ),
                                      );
                                    }
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryAccent
                                        .withValues(alpha: 0.10)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryAccent
                                      : AppColors.cardBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.verified_user_rounded
                                        : Icons.badge_outlined,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.primaryAccent
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      roleName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primaryAccent
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isLoading)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryAccent,
                                      ),
                                    )
                                  else if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'AKTİV',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  if (profile.canSwitchGuard) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: switchingRole.isNotEmpty
                          ? null
                          : () async {
                              setSheetState(() => switchingRole = 'guard_switch');
                              final targetLabel = profile.linkedGuardLabel ?? 'Digər profil';
                              final ok = await context.read<AppState>().switchGuard(context);
                              if (!sheetCtx.mounted) return;
                              Navigator.pop(sheetCtx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? '$targetLabel rejiminə keçid edildi' : 'Rejim dəyişdirilə bilmədi'),
                                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3E62).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E3E62).withValues(alpha: 0.3), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF1E3E62),
                              child: Icon(Icons.switch_account_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${profile.linkedGuardLabel ?? "Hesab"} rejiminə keçid',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3E62)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.linkedGuardName ?? '',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (switchingRole == 'guard_switch')
                              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF1E3E62)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class DashboardHeroSliver extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String? photoUrl;
  final String avatarName;
  final List<Color> gradient;
  final Color accentColor;
  final IconData watermarkIcon;
  final bool isOnline;
  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onSettings;
  final bool isReorderMode;
  final VoidCallback? onToggleReorder;

  static const _monthNames = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'İyun',
    'İyul',
    'Avqust',
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
  ];

  static const _weekdayNames = [
    'Bazar ertəsi',
    'Çərşənbə axşamı',
    'Çərşənbə',
    'Cümə axşamı',
    'Cümə',
    'Şənbə',
    'Bazar',
  ];

  const DashboardHeroSliver({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.avatarName,
    required this.gradient,
    required this.accentColor,
    required this.watermarkIcon,
    required this.isOnline,
    required this.notificationCount,
    required this.onNotifications,
    required this.onSettings,
    this.isReorderMode = false,
    this.onToggleReorder,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day} ${_monthNames[now.month - 1]} ${now.year}, ${_weekdayNames[now.weekday - 1]}';
    final session = context.watch<SessionController>();
    final profile = session.profile;
    final hasMultipleRoles = (profile?.roles.length ?? 0) > 1;
    final activeRoleLabel = profile?.activeRole ?? badge;

    return SliverAppBar(
      expandedHeight: 242,
      toolbarHeight: 0,
      pinned: false,
      floating: false,
      stretch: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: SchoolHeroBackground(
          accentColor: accentColor,
          child: Stack(
            children: [
              Positioned(
                right: 26,
                bottom: 8,
                child: Icon(
                  watermarkIcon,
                  size: 118,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 14, 16),
                  child: Column(
                    children: [
                      // Top Branding Row (School Logo + Title + Role)
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.school_rounded,
                              color: AppColors.gold,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'İDRAK LİSEYİ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                activeRoleLabel,
                                style: TextStyle(
                                  color: accentColor.withValues(alpha: 0.9),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Menu & Actions Row
                      Row(
                        children: [
                          if (Scaffold.maybeOf(context)?.hasDrawer == true) ...[
                            _heroAction(
                              icon: Icons.menu_rounded,
                              tooltip: 'Menyu',
                              color: accentColor,
                              onTap: () => Scaffold.of(context).openDrawer(),
                            ),
                            const SizedBox(width: 8),
                          ],
                        Expanded(
                          child: InkWell(
                            onTap: hasMultipleRoles
                                ? () => showEmployeeRoleSwitcherSheet(context)
                                : null,
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      hasMultipleRoles
                                          ? (profile != null && profile.canSwitchGuard && profile.roles.length <= 1 ? (profile.linkedGuardLabel != null ? 'Rejim: ${profile.activeRole ?? badge} ⇄' : activeRoleLabel.toUpperCase()) : activeRoleLabel.toUpperCase())
                                          : badge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ),
                                  if (hasMultipleRoles) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 12,
                                      color: accentColor,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (onToggleReorder != null) ...[
                          _heroAction(
                            icon: isReorderMode
                                ? Icons.check_rounded
                                : Icons.drag_indicator_rounded,
                            active: isReorderMode,
                            tooltip: isReorderMode
                                ? 'Sıralamanı tamamla'
                                : 'Modul sıralaması',
                            color: accentColor,
                            onTap: onToggleReorder!,
                          ),
                          const SizedBox(width: 7),
                        ],
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.09),
                            ),
                          ),
                          child: NotificationBell(
                            count: notificationCount,
                            size: 30,
                            onTap: onNotifications,
                          ),
                        ),
                        const SizedBox(width: 7),
                        _heroAction(
                          icon: Icons.settings_outlined,
                          tooltip: 'Ayarlar',
                          color: accentColor,
                          onTap: onSettings ?? () {},
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accentColor, AppColors.primaryAccent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.30),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ModernAvatar(
                            imageUrl: photoUrl,
                            name: avatarName,
                            size: 51,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _heroPill(
                          icon: Icons.calendar_today_rounded,
                          label: dateLabel,
                        ),
                        const SizedBox(width: 7),
                        _heroPill(
                          icon: isOnline
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          label: isOnline ? 'Onlayn' : 'Oflayn',
                          color: isOnline
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFCA5A5),
                        ),
                        if (hasMultipleRoles) ...[
                          const SizedBox(width: 7),
                          InkWell(
                            onTap: () => showEmployeeRoleSwitcherSheet(context),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rol dəyiş (${profile!.roles.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _heroAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? color : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: color ?? Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color ?? Colors.white.withValues(alpha: 0.62),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardKpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardKpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class DashboardOverviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<DashboardKpiData> kpis;
  final bool isOnline;
  final Future<void> Function()? onRefresh;

  const DashboardOverviewCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.kpis,
    required this.isOnline,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor =
        isOnline ? const Color(0xFF10B981) : colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.035,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Canlı' : 'Oflayn',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Məlumatları yenilə',
                  icon: Icon(
                    Icons.sync_rounded,
                    size: 16,
                    color: palette.textMuted,
                  ),
                  onPressed: () async {
                    await onRefresh!();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Məlumatlar server ilə sinxronlaşdırıldı'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: palette.borderHairline),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[
                if (i > 0) _kpiDivider(palette),
                _kpi(context, kpis[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(BuildContext context, DashboardKpiData kpi) {
    final palette = AppPalette.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(kpi.icon, size: 16, color: kpi.color),
          ),
          const SizedBox(height: 5),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );

    if (kpi.onTap == null) return Expanded(child: content);
    return Expanded(
      child: InkWell(
        onTap: kpi.onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  Widget _kpiDivider(AppPalette palette) {
    return Container(width: 1, height: 50, color: palette.borderHairline);
  }
}

class DashboardQuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardQuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class DashboardQuickActions extends StatelessWidget {
  final List<DashboardQuickActionData> actions;

  const DashboardQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final visible = actions.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickActionPill(
              label: visible[i].label,
              icon: visible[i].icon,
              color: visible[i].color,
              onTap: visible[i].onTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardModuleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final bool isReorderMode;
  final Color? accent;

  const DashboardModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.count,
    this.isReorderMode = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accentColor = accent ?? palette.brandRoyal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 11,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '$count modul',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (isReorderMode)
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: palette.brandGold.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: palette.brandGold.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: palette.brandGold,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Modulları istədiyiniz sıraya sürükləyin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.brandGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
