import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_preferences_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../parent/screens/grades_analytics_screen.dart';
import '../../parent/screens/parent_tickets_screen.dart';
import '../../shared/dialogs/send_notification_dialog.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../student/screens/cafeteria_menu_screen.dart';
import '../../student/screens/library_screen.dart';
import '../widgets/reorderable_module_grid.dart';
import 'admin_timetable_management_screen.dart';
import 'admin_users_screen.dart';
import 'class_management_screen.dart';
import 'create_employee_screen.dart';
import 'qr_inventory_management_screen.dart';
import 'role_management_screen.dart';
import 'student_management_screen.dart';
import 'student_registration_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isReorderMode = false;

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();

    final users = appState.users;
    final studentCount = users.where((u) => u.role == UserRole.student).length;
    final teacherCount = users.where((u) => u.role == UserRole.teacher).length;
    final parentCount = users.where((u) => u.role == UserRole.parent).length;
    final activeTickets = appState.tickets.length;
    final currentUser = appState.currentUser;

    final assignedRole = appState.getRoleById(currentUser?.assignedRoleId);
    final headerTitle = assignedRole?.name ??
        currentUser?.position ??
        loc.adminDashboard;
    final headerBadge = (assignedRole?.name ??
            currentUser?.position ??
            loc.admin)
        .toUpperCase();

    final orderedModules = appState.getOrderedModules();

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHero(
            context: context,
            appState: appState,
            loc: loc,
            headerTitle: headerTitle,
            headerBadge: headerBadge,
          ),
          SliverToBoxAdapter(
            child: ResponsiveCenter(
              horizontalPadding: 0,
              child: Padding(
                padding: responsivePadding(context).copyWith(
                  top: 14,
                  bottom: 108,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _entrance(
                      context,
                      0,
                      _buildOverview(
                        context,
                        appState: appState,
                        studentCount: studentCount,
                        teacherCount: teacherCount,
                        parentCount: parentCount,
                        activeTickets: activeTickets,
                        loc: loc,
                      ),
                    ),
                    if (appState.hasPermission('add_users')) ...[
                      const SizedBox(height: 12),
                      _entrance(context, 1, _buildQuickActions(context)),
                    ],
                    const SizedBox(height: 18),
                    _entrance(
                      context,
                      2,
                      _buildModuleSection(
                        context,
                        appState,
                        orderedModules,
                        studentCount: studentCount,
                        teacherCount: teacherCount,
                        activeTickets: activeTickets,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _entrance(context, 3, _buildBirthdaysCard(appState)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero({
    required BuildContext context,
    required AppState appState,
    required AppLocalizations loc,
    required String headerTitle,
    required String headerBadge,
  }) {
    final currentUser = appState.currentUser;
    final now = DateTime.now();
    final dateLabel =
        '${now.day} ${_monthNames[now.month - 1]} ${now.year}, ${_weekdayNames[now.weekday - 1]}';

    return SliverAppBar(
      expandedHeight: 210,
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
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1428),
                Color(0xFF101D36),
                Color(0xFF172554),
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -45,
                top: -55,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryAccent.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 26,
                bottom: 8,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 118,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 14, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            headerBadge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _heroAction(
                          icon: _isReorderMode
                              ? Icons.check_rounded
                              : Icons.drag_indicator_rounded,
                          active: _isReorderMode,
                          tooltip: _isReorderMode
                              ? 'Sıralamanı tamamla'
                              : 'Modul sıralaması',
                          onTap: () {
                            setState(() => _isReorderMode = !_isReorderMode);
                            if (!_isReorderMode) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Modul sıralaması saxlanıldı'),
                                  backgroundColor: AppColors.success,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 7),
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
                            count: appState.unreadNotificationCount,
                            size: 30,
                            onTap: () => Navigator.push(
                              context,
                              appRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _heroAction(
                          icon: Icons.settings_outlined,
                          tooltip: loc.settings,
                          onTap: () => Navigator.push(
                            context,
                            appRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildAvatar(currentUser),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headerTitle,
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
                                currentUser?.fullName ?? '',
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
                          icon: appState.isOnline
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          label: appState.isOnline ? 'Onlayn' : 'Oflayn',
                          color: appState.isOnline
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFCA5A5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser? currentUser) {
    final photo = currentUser?.photoUrl?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;
    final name = currentUser?.fullName ?? '';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photo,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initials(initials),
              )
            : _initials(initials),
      ),
    );
  }

  Widget _initials(String initials) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : 'İD',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _heroAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
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
                ? AppColors.gold.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.goldLight : Colors.white,
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

  Widget _buildOverview(
    BuildContext context, {
    required AppState appState,
    required int studentCount,
    required int teacherCount,
    required int parentCount,
    required int activeTickets,
    required AppLocalizations loc,
  }) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

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
                  color: palette.brandRoyal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 15,
                  color: palette.brandRoyal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ümumi baxış',
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
                  color: (appState.isOnline
                          ? const Color(0xFF10B981)
                          : colorScheme.error)
                      .withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: appState.isOnline
                            ? const Color(0xFF10B981)
                            : colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appState.isOnline ? 'Canlı' : 'Oflayn',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: appState.isOnline
                            ? const Color(0xFF059669)
                            : colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Firebase ilə sinxronlaşdır',
                icon: Icon(
                  Icons.sync_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
                onPressed: () async {
                  await appState.initFirebaseData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Məlumatlar Firebase ilə sinxronlaşdırıldı'),
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
              _kpi(
                context,
                label: loc.students,
                value: studentCount,
                icon: Icons.school_rounded,
                color: palette.brandRoyal,
                onTap: () => Navigator.push(
                  context,
                  appRoute(builder: (_) => const StudentManagementScreen()),
                ),
              ),
              _kpiDivider(palette),
              _kpi(
                context,
                label: loc.teachers,
                value: teacherCount,
                icon: Icons.psychology_rounded,
                color: palette.brandAzure,
                onTap: () => Navigator.push(
                  context,
                  appRoute(builder: (_) => const AdminUsersScreen()),
                ),
              ),
              _kpiDivider(palette),
              _kpi(
                context,
                label: loc.parents,
                value: parentCount,
                icon: Icons.family_restroom_rounded,
                color: palette.brandGold,
                onTap: () => Navigator.push(
                  context,
                  appRoute(builder: (_) => const AdminUsersScreen()),
                ),
              ),
              _kpiDivider(palette),
              _kpi(
                context,
                label: loc.helpdesk,
                value: activeTickets,
                icon: Icons.support_agent_rounded,
                color: colorScheme.error,
                onTap: () => Navigator.push(
                  context,
                  appRoute(builder: (_) => const ParentTicketsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
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
              const SizedBox(height: 5),
              Text(
                '$value',
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
                label,
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
        ),
      ),
    );
  }

  Widget _kpiDivider(AppPalette palette) {
    return Container(
      width: 1,
      height: 50,
      color: palette.borderHairline,
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final actions = <(String, IconData, Color, VoidCallback)>[
      (
        'Yeni əməkdaş',
        Icons.person_add_alt_1_rounded,
        palette.brandRoyal,
        () => Navigator.push(
          context,
          appRoute(builder: (_) => const CreateEmployeeScreen()),
        ),
      ),
      (
        'Şagird qeydi',
        Icons.school_rounded,
        palette.brandAzure,
        () => Navigator.push(
          context,
          appRoute(builder: (_) => const StudentRegistrationScreen()),
        ),
      ),
      (
        'Toplu elan',
        Icons.campaign_rounded,
        colorScheme.error,
        () => showDialog(
          context: context,
          builder: (_) => const SendNotificationDialog(),
        ),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickActionPill(
              label: actions[i].$1,
              icon: actions[i].$2,
              color: actions[i].$3,
              onTap: actions[i].$4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModuleSection(
    BuildContext context,
    AppState appState,
    List<ModuleItem> orderedModules, {
    required int studentCount,
    required int teacherCount,
    required int activeTickets,
  }) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'İdarəetmə modulları',
          subtitle: _isReorderMode
              ? 'Sürüşdürərək sıralayın'
              : 'Bütün alətlər bir yerdə',
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
          trailing: _buildModuleCountChip(orderedModules.length),
        ),
        const SizedBox(height: 10),
        if (_isReorderMode)
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
        ReorderableModuleGrid(
          modules: orderedModules,
          isReorderMode: _isReorderMode,
          allowTwoLineTitle: true,
          dynamicData: {
            'view_students': '$studentCount şagird',
            'view_users': '${teacherCount + 1} heyət',
            'view_tickets': '$activeTickets müraciət',
            'view_roles': '${appState.roles.length} rol',
            'view_classes': '${appState.allDistinctClasses.length} sinif',
          },
          onReorder: (newOrder) {
            appState.updateModuleOrder(newOrder);
          },
          onModuleTap: (moduleId, ctx) {
            switch (moduleId) {
              case 'view_students':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const StudentManagementScreen()),
                );
                break;
              case 'view_classes':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const ClassManagementScreen()),
                );
                break;
              case 'view_timetable':
                Navigator.push(
                  ctx,
                  appRoute(
                    builder: (_) => const AdminTimetableManagementScreen(),
                  ),
                );
                break;
              case 'view_users':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const AdminUsersScreen()),
                );
                break;
              case 'view_roles':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const RoleManagementScreen()),
                );
                break;
              case 'view_tickets':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const ParentTicketsScreen()),
                );
                break;
              case 'view_reports':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const GradesAnalyticsScreen()),
                );
                break;
              case 'view_cafeteria':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const CafeteriaMenuScreen()),
                );
                break;
              case 'view_settings':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const SettingsScreen()),
                );
                break;
              case 'view_inventory':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const QrInventoryManagementScreen()),
                );
                break;
              case 'view_library':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const LibraryScreen()),
                );
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildModuleCountChip(int count) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.brandRoyal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.brandRoyal.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 11,
            color: palette.brandRoyal,
          ),
          const SizedBox(width: 4),
          Text(
            '$count modul',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: palette.brandRoyal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdaysCard(AppState appState) {
    const shortMonths = [
      'Yan',
      'Fev',
      'Mar',
      'Apr',
      'May',
      'İyn',
      'İyl',
      'Avq',
      'Sen',
      'Okt',
      'Noy',
      'Dek',
    ];
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final entries = <({String name, String role, DateTime date, int days})>[];
    for (final user in appState.users) {
      final birth = user.birthDate;
      if (birth == null) continue;
      var next = DateTime(now.year, birth.month, birth.day);
      if (next.isBefore(today)) next = DateTime(now.year + 1, birth.month, birth.day);
      final days = next.difference(today).inDays;
      if (days > 30) continue;
      final roleLabel = switch (user.role) {
        UserRole.student => 'Şagird',
        UserRole.parent => 'Valideyn',
        UserRole.teacher => 'Müəllim',
        UserRole.admin => 'İşçi',
      };
      entries.add((name: user.fullName, role: roleLabel, date: next, days: days));
    }
    entries.sort((a, b) => a.days.compareTo(b.days));
    final upcoming = entries.take(4).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        SectionHeader(
          title: 'Yaxınlaşan doğum günləri',
          subtitle: 'Növbəti 30 gün',
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
          trailing: entries.length > 4
              ? Text(
                  '+${entries.length - 4}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: palette.textMuted,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 18,
          child: Column(
            children: [
              for (var i = 0; i < upcoming.length; i++) ...[
                if (i > 0)
                  Divider(
                    color: palette.borderHairline,
                    height: 14,
                  ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: upcoming[i].days == 0
                            ? colorScheme.error.withValues(alpha: 0.10)
                            : palette.brandRoyal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '${upcoming[i].date.day}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: upcoming[i].days == 0
                              ? colorScheme.error
                              : palette.brandRoyal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcoming[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            upcoming[i].role,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${upcoming[i].date.day} ${shortMonths[upcoming[i].date.month - 1]}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          upcoming[i].days == 0
                              ? 'Bugün!'
                              : '${upcoming[i].days} gün sonra',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: upcoming[i].days == 0
                                ? colorScheme.error
                                : palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _entrance(BuildContext context, int index, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate()
        .fadeIn(
          duration: 420.ms,
          delay: staggerDelay(index),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.04,
          duration: 420.ms,
          delay: staggerDelay(index),
          curve: Curves.easeOutCubic,
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
