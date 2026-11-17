import '../../journal/screens/api_journal_screen.dart';
import '../../navigation/widgets/gopanel_drawer.dart';
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
import '../../shared/screens/notifications_hub_screen.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/widgets/dashboard_kit.dart';
import '../../../core/session/session_controller.dart';
import '../../student/screens/cafeteria_menu_screen.dart';
import '../../student/screens/library_screen.dart';
import '../widgets/reorderable_module_grid.dart';
import 'admin_timetable_management_screen.dart';
import 'admin_users_screen.dart';
import 'class_management_screen.dart';
import '../../hr/screens/employee_store_screen.dart';
import 'qr_inventory_management_screen.dart';
import 'role_management_screen.dart';
import 'student_management_screen.dart';
import 'student_registration_screen.dart';

import '../../hr/screens/employees_screen.dart';
import '../../hr/screens/contracts_screen.dart';
import '../../hr/screens/salary_calculator_screen.dart';
import '../../hr/screens/employee_documents_screen.dart';
import '../../hr/screens/employee_attendance_screen.dart';
import '../../finance/screens/student_invoices_screen.dart';
import '../../finance/screens/payroll_screen.dart';
import '../../finance/screens/general_ledger_screen.dart';
import '../../finance/screens/finance_dictionary_screen.dart';
import '../../exams/screens/exams_screen.dart';
import '../../exams/screens/exam_results_screen.dart';
import '../../exams/screens/exam_categories_screen.dart';
import '../../exams/screens/student_applications_screen.dart';
import '../../academic_ops/screens/parents_management_screen.dart';
import '../../academic_ops/screens/curriculums_screen.dart';
import '../../academic_ops/screens/clubs_screen.dart';
import '../../academic_ops/screens/excused_absences_screen.dart';
import '../../academic_ops/screens/graduations_screen.dart';
import '../../academic_ops/screens/academic_years_screen.dart';
import '../../academic_ops/screens/rooms_screen.dart';
import '../../academic_ops/screens/time_slots_screen.dart';
import '../../library_ops/screens/book_loans_screen.dart';
import '../../library_ops/screens/book_reservations_screen.dart';
import '../../warehouse_ops/screens/inventorizations_screen.dart';
import '../../warehouse_ops/screens/canteen_supply_screen.dart';
import '../../statistics/screens/quality_control_screen.dart';
import '../../statistics/screens/workload_report_screen.dart';
import '../../statistics/screens/school_attendance_stats_screen.dart';
import '../../medical_ops/screens/medical_journal_screen.dart';
import '../../psicology_ops/screens/psychology_evaluation_screen.dart';
import '../../structure_ops/screens/organizational_structure_screen.dart';
import '../../system_logs/screens/activity_logs_screen.dart';
import '../../shared/widgets/school_hero_background.dart';
import '../../../services/network/api_client.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int? _liveStudentCount;
  int? _liveTeacherCount;
  int? _liveEmployeeCount;
  int? _liveParentCount;
  int? _liveTicketCount;

  @override
  void initState() {
    super.initState();
    _fetchLiveStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.syncEmployeesFromApi();
      appState.syncStudentsFromApi();
      appState.syncBooksFromApi();
      appState.loadRoles();
    });
  }

  Future<void> _fetchLiveStats() async {
    try {
      final res = await ApiClient.instance.get('dashboard');
      if (res is Map && mounted) {
        final data = res['data'] ?? res;
        final stations = data['stations'] is Map ? (data['stations'] as Map) : null;
        final stats = data['stats'] is Map ? (data['stats'] as Map) : null;
        setState(() {
          if (stations != null) {
            if (stations['students'] is Map && stations['students']['active'] != null) {
              _liveStudentCount = int.tryParse(stations['students']['active'].toString());
            }
            if (stations['employees'] is Map) {
              final empMap = stations['employees'] as Map;
              if (empMap['active'] != null) {
                _liveEmployeeCount = int.tryParse(empMap['active'].toString());
              }
              if (empMap['teachers'] != null) {
                _liveTeacherCount = int.tryParse(empMap['teachers'].toString());
              } else if (empMap['active'] != null) {
                _liveTeacherCount = int.tryParse(empMap['active'].toString());
              }
            }
            if (stations['parents'] is Map && stations['parents']['active'] != null) {
              _liveParentCount = int.tryParse(stations['parents']['active'].toString());
            }
            if (stations['tickets'] is Map && stations['tickets']['open'] != null) {
              _liveTicketCount = int.tryParse(stations['tickets']['open'].toString());
            }
          }
          if (stats != null) {
            if (stats['students_count'] != null) {
              _liveStudentCount = int.tryParse(stats['students_count'].toString());
            }
            if (stats['teachers_count'] != null) {
              _liveTeacherCount = int.tryParse(stats['teachers_count'].toString());
            }
            if (stats['tickets_count'] != null) {
              _liveTicketCount = int.tryParse(stats['tickets_count'].toString());
            }
          }
        });
      }
    } catch (_) {}
  }

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
    final currentYearStudentsCount = appState.students.where((s) => s.isCurrentYear).length;
    final studentCount = _liveStudentCount ?? (currentYearStudentsCount > 0 ? currentYearStudentsCount : 560);
    final teacherCount = _liveTeacherCount ?? (users.any((u) => u.role == UserRole.teacher && u.isActive) ? users.where((u) => u.role == UserRole.teacher && u.isActive).length : 139);
    final parentCount = _liveParentCount ?? 563;
    final activeTickets = _liveTicketCount ?? appState.tickets.length;
    final currentUser = appState.currentUser;

    final assignedRole = appState.getRoleById(currentUser?.assignedRoleId);
    final headerTitle = assignedRole?.name ??
        currentUser?.position ??
        loc.adminDashboard;
    final headerBadge = (assignedRole?.name ??
            currentUser?.position ??
            loc.admin)
        .toUpperCase();

    final orderedModules = appState.getOrderedModules().take(8).toList();

    return Scaffold(
      backgroundColor: palette.bgBase,
      drawer: const GoPanelDrawer(),
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
          accentColor: AppColors.primaryAccent,
          child: Stack(
            children: [
              Positioned(
                right: 26,
                bottom: 8,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
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
                                headerBadge,
                                style: const TextStyle(
                                  color: AppColors.primaryAccent,
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
                          Builder(
                            builder: (menuCtx) => _heroAction(
                              icon: Icons.menu_rounded,
                              tooltip: 'Menyu (Sidebar)',
                              onTap: () => Scaffold.of(menuCtx).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        Builder(
                          builder: (ctx) {
                            final session = ctx.watch<SessionController>();
                            final roles = session.profile?.roles ?? const <String>[];
                            final canSwitch = roles.length > 1 || session.canSwitchGuard;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: canSwitch ? () => showEmployeeRoleSwitcherSheet(ctx) : null,
                                  child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
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
                                    if (canSwitch) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 13,
                                        color: AppColors.goldLight,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (session.canSwitchGuard) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final ok = await ctx.read<AppState>().switchGuard(ctx);
                                  if (!ok && ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Rejim dəyişdirilə bilmədi')),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF10B981)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.swap_horiz_rounded, color: Color(0xFF34D399), size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        ' rejimi',
                                        style: const TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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
                        _fetchLiveStats();
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
                                builder: (_) => const NotificationsHubScreen(),
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
                                (currentUser?.fullName.isNotEmpty ?? false)
                                    ? currentUser!.fullName
                                    : headerTitle,
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
                                headerTitle,
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
          appRoute(builder: (_) => const EmployeeStoreScreen()),
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
            'student_360': '$studentCount şagird',
            'view_students': '$studentCount şagird',
            'parents': '${_liveParentCount ?? 563} valideyn',
            'view_users': '${_liveEmployeeCount ?? 213} heyət',
            'view_tickets': '$activeTickets müraciət',
            'view_roles': '${appState.roles.length} rol',
            'view_classes': '${appState.allDistinctClasses.length} sinif',
          },
          onReorder: (newOrder) {
            appState.updateModuleOrder(newOrder);
          },
          onModuleTap: (moduleId, ctx) {
            switch (moduleId) {
              case 'view_journal':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const ApiJournalScreen()),
                );
                break;
              case 'student_360':
              case 'view_students':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const StudentManagementScreen()),
                );
                break;
              case 'parents':
                Navigator.push(
                  ctx,
                  appRoute(builder: (_) => const ParentsManagementScreen()),
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
                  appRoute(builder: (_) => const NotificationsScreen()),
                );
                break;
case 'view_employees':
                Navigator.push(ctx, appRoute(builder: (_) => const EmployeesScreen()));
                break;
              case 'view_contracts':
                Navigator.push(ctx, appRoute(builder: (_) => const ContractsScreen()));
                break;
              case 'salary_calculator':
                Navigator.push(ctx, appRoute(builder: (_) => const SalaryCalculatorScreen()));
                break;
              case 'employee_documents':
                Navigator.push(ctx, appRoute(builder: (_) => const EmployeeDocumentsScreen()));
                break;
              case 'employee_attendance':
                Navigator.push(ctx, appRoute(builder: (_) => const EmployeeAttendanceScreen()));
                break;
              case 'student_invoices':
                Navigator.push(ctx, appRoute(builder: (_) => const StudentInvoicesScreen()));
                break;
              case 'payroll':
                Navigator.push(ctx, appRoute(builder: (_) => const PayrollScreen()));
                break;
              case 'general_ledger':
                Navigator.push(ctx, appRoute(builder: (_) => const GeneralLedgerScreen()));
                break;
              case 'finance_dictionary':
                Navigator.push(ctx, appRoute(builder: (_) => const FinanceDictionaryScreen()));
                break;
              case 'view_exams':
                Navigator.push(ctx, appRoute(builder: (_) => const ExamsScreen()));
                break;
              case 'exam_results':
                Navigator.push(ctx, appRoute(builder: (_) => const ExamResultsScreen()));
                break;
              case 'exam_categories':
                Navigator.push(ctx, appRoute(builder: (_) => const ExamCategoriesScreen()));
                break;
              case 'student_applications':
                Navigator.push(ctx, appRoute(builder: (_) => const StudentApplicationsScreen()));
                break;
              case 'curriculums':
                Navigator.push(ctx, appRoute(builder: (_) => const CurriculumsScreen()));
                break;
              case 'clubs':
                Navigator.push(ctx, appRoute(builder: (_) => const ClubsScreen()));
                break;
              case 'excused_absences':
                Navigator.push(ctx, appRoute(builder: (_) => const ExcusedAbsencesScreen()));
                break;
              case 'graduations':
                Navigator.push(ctx, appRoute(builder: (_) => const GraduationsScreen()));
                break;
              case 'academic_years':
                Navigator.push(ctx, appRoute(builder: (_) => const AcademicYearsScreen()));
                break;
              case 'rooms':
                Navigator.push(ctx, appRoute(builder: (_) => const RoomsScreen()));
                break;
              case 'time_slots':
                Navigator.push(ctx, appRoute(builder: (_) => const TimeSlotsScreen()));
                break;
              case 'book_loans':
                Navigator.push(ctx, appRoute(builder: (_) => const BookLoansScreen()));
                break;
              case 'book_reservations':
                Navigator.push(ctx, appRoute(builder: (_) => const BookReservationsScreen()));
                break;
              case 'warehouse_inventory':
                Navigator.push(ctx, appRoute(builder: (_) => const InventorizationsScreen()));
                break;
              case 'canteen_supply':
                Navigator.push(ctx, appRoute(builder: (_) => const CanteenSupplyScreen()));
                break;
              case 'quality_control':
                Navigator.push(ctx, appRoute(builder: (_) => const QualityControlScreen()));
                break;
              case 'workload_report':
                Navigator.push(ctx, appRoute(builder: (_) => const WorkloadReportScreen()));
                break;
              case 'school_attendance_stats':
                Navigator.push(ctx, appRoute(builder: (_) => const SchoolAttendanceStatsScreen()));
                break;
              case 'medical_journal':
                Navigator.push(ctx, appRoute(builder: (_) => const MedicalJournalScreen()));
                break;
              case 'psychology_evaluation':
                Navigator.push(ctx, appRoute(builder: (_) => const PsychologyEvaluationScreen()));
                break;
              case 'organizational_structure':
                Navigator.push(ctx, appRoute(builder: (_) => const OrganizationalStructureScreen()));
                break;
              case 'activity_logs':
                Navigator.push(ctx, appRoute(builder: (_) => const ActivityLogsScreen()));
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

