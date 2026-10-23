import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/idrak_logo.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/animated_button.dart';
import '../../core/utils/haptic_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_preferences_model.dart';
import '../../providers/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_update_service.dart';
import '../../services/push_notification_service.dart';
import '../auth/screens/login_screen.dart';
import '../shared/screens/notifications_screen.dart';
import '../shared/widgets/app_update_banner.dart';

// Admin Screens
import '../admin/screens/admin_dashboard_screen.dart';
import '../admin/screens/admin_users_screen.dart';
import '../admin/screens/staff_dashboard_screen.dart';
import '../admin/screens/student_management_screen.dart';
import '../admin/screens/class_management_screen.dart';
import '../admin/screens/admin_timetable_management_screen.dart';
import '../admin/screens/role_management_screen.dart';
import '../admin/screens/qr_inventory_management_screen.dart';

// Parent Screens
import '../parent/screens/parent_dashboard_screen.dart';
import '../parent/screens/timetable_matrix_screen.dart';
import '../parent/screens/grades_analytics_screen.dart';
import '../parent/screens/attendance_calendar_screen.dart';
import '../parent/screens/medical_card_screen.dart';
import '../parent/screens/parent_tickets_screen.dart';

// Student Screens
import '../student/screens/student_dashboard_screen.dart';
import '../student/screens/digital_id_card_screen.dart';
import '../student/screens/assignments_timeline_screen.dart';
import '../student/screens/meet_idrak_screen.dart';
import '../student/screens/library_screen.dart';
import '../student/screens/cafeteria_menu_screen.dart';

// Teacher Screens
import '../teacher/screens/teacher_dashboard_screen.dart';
import '../teacher/screens/teacher_students_screen.dart';
import '../teacher/screens/teacher_timetable_view_screen.dart';
import '../teacher/screens/quick_grading_screen.dart';
import '../teacher/screens/qr_inventory_ticket_screen.dart';
import '../teacher/screens/review_submissions_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// Plays a quick fade-and-rise whenever the selected tab changes, while
/// keeping the [IndexedStack] (and therefore every tab's state) alive.
class _TabTransition extends StatefulWidget {
  final int index;
  final List<Widget> screens;

  const _TabTransition({required this.index, required this.screens});

  @override
  State<_TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<_TabTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1, // fully visible on first build
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(_TabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(_curve),
        child: IndexedStack(index: widget.index, children: widget.screens),
      ),
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  bool _isDragHoveredOnDock = false;

  @override
  void initState() {
    super.initState();
    // Bildirişə toxunaraq açılan tətbiq (cold-start / arxa plan) —
    // ilk kadrdan sonra bildirişlər səhifəsinə yönləndir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final opened = PushNotificationService.instance.consumePendingOpen();
      if (opened != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    });
  }

  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'dashboard_outlined': Icons.dashboard_outlined,
      'dashboard_rounded': Icons.dashboard_rounded,
      'manage_accounts_outlined': Icons.manage_accounts_outlined,
      'manage_accounts_rounded': Icons.manage_accounts_rounded,
      'support_agent_outlined': Icons.support_agent_outlined,
      'support_agent_rounded': Icons.support_agent_rounded,
      'analytics_outlined': Icons.analytics_outlined,
      'analytics_rounded': Icons.analytics_rounded,
      'grid_view_outlined': Icons.grid_view_outlined,
      'grid_view_rounded': Icons.grid_view_rounded,
      'insights_outlined': Icons.insights_outlined,
      'insights_rounded': Icons.insights_rounded,
      'calendar_month_outlined': Icons.calendar_month_outlined,
      'calendar_month_rounded': Icons.calendar_month_rounded,
      'favorite_outline_rounded': Icons.favorite_outline_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'badge_outlined': Icons.badge_outlined,
      'badge_rounded': Icons.badge_rounded,
      'assignment_outlined': Icons.assignment_outlined,
      'assignment_rounded': Icons.assignment_rounded,
      'video_camera_front_outlined': Icons.video_camera_front_outlined,
      'video_camera_front_rounded': Icons.video_camera_front_rounded,
      'local_library_outlined': Icons.local_library_outlined,
      'local_library_rounded': Icons.local_library_rounded,
      'groups_outlined': Icons.groups_outlined,
      'groups_rounded': Icons.groups_rounded,
      'edit_note_outlined': Icons.edit_note_outlined,
      'edit_note_rounded': Icons.edit_note_rounded,
      'qr_code_scanner_outlined': Icons.qr_code_scanner_outlined,
      'qr_code_scanner_rounded': Icons.qr_code_scanner_rounded,
      'school_outlined': Icons.school_outlined,
      'school_rounded': Icons.school_rounded,
      'class_outlined': Icons.class_outlined,
      'class_rounded': Icons.class_rounded,
      'admin_panel_settings_outlined': Icons.admin_panel_settings_outlined,
      'admin_panel_settings_rounded': Icons.admin_panel_settings_rounded,
      'restaurant_menu_outlined': Icons.restaurant_menu_outlined,
      'restaurant_menu_rounded': Icons.restaurant_menu_rounded,
      'campaign_outlined': Icons.campaign_outlined,
      'campaign_rounded': Icons.campaign_rounded,
      'mic_external_on_outlined': Icons.mic_external_on_outlined,
      'mic_external_on_rounded': Icons.mic_external_on_rounded,
      'mic_outlined': Icons.mic_outlined,
      'mic_rounded': Icons.mic_rounded,
      'notifications_active_outlined': Icons.notifications_active_outlined,
      'notifications_active_rounded': Icons.notifications_active_rounded,
      'assignment_turned_in_outlined': Icons.assignment_turned_in_outlined,
      'assignment_turned_in_rounded': Icons.assignment_turned_in_rounded,
    };
    return iconMap[iconName] ?? Icons.dashboard_outlined;
  }

  String _adminPermissionForNav(String navId) {
    switch (navId) {
      case 'users':
        return 'view_users';
      case 'tickets':
        return 'view_tickets';
      case 'analytics':
        return 'view_reports';
      case 'library':
        return 'view_library';
      case 'inventory':
        return 'view_inventory';
      case 'settings':
        return 'view_settings';
      default:
        return navId;
    }
  }

  Widget _getScreenForNavItem(String navId, UserRole role, AppState appState) {
    // Alt menyu filtrlənsə də, birbaşa naviqasiya/keçid ehtimalına qarşı
    // admin panellərində ikinci qat icazə yoxlaması.
    if (role == UserRole.admin &&
        navId != 'dashboard' &&
        !appState.hasPermission(_adminPermissionForNav(navId))) {
      return const StaffDashboardScreen();
    }

    final isStaff =
        appState.currentUser?.role == UserRole.admin &&
        !appState.isPrimaryAdmin;
    switch (role) {
      case UserRole.admin:
        switch (navId) {
          case 'dashboard':
            return isStaff
                ? const StaffDashboardScreen()
                : const AdminDashboardScreen();
          case 'view_students':
            return const StudentManagementScreen();
          case 'view_classes':
            return const ClassManagementScreen();
          case 'view_timetable':
            return const AdminTimetableManagementScreen();
          case 'view_users':
          case 'users':
            return const AdminUsersScreen();
          case 'view_roles':
            return const RoleManagementScreen();
          case 'view_tickets':
          case 'tickets':
            return const ParentTicketsScreen();
          case 'view_reports':
          case 'analytics':
            return const GradesAnalyticsScreen();
          case 'view_cafeteria':
            return const CafeteriaMenuScreen();
          case 'view_settings':
            return const NotificationsScreen();
          case 'view_inventory':
            return const QrInventoryManagementScreen();
          case 'view_library':
          case 'library':
            return const LibraryScreen();
          default:
            return isStaff
                ? const StaffDashboardScreen()
                : const AdminDashboardScreen();
        }

      case UserRole.teacher:
        switch (navId) {
          case 'dashboard':
            return const TeacherDashboardScreen();
          case 'teacher_students':
          case 'students':
            return const TeacherStudentsScreen();
          case 'teacher_timetable':
          case 'attendance':
            return const TeacherTimetableViewScreen();
          case 'teacher_grading':
          case 'grading':
            return const QuickGradingScreen();
          case 'teacher_inventory':
          case 'inventory':
            return const QrInventoryTicketScreen();
          case 'teacher_meet':
          case 'meet':
            return const MeetIdrakScreen();
          case 'teacher_assignments':
          case 'assignments':
            return const ReviewSubmissionsScreen();
          case 'teacher_library':
          case 'library':
            return const LibraryScreen(isTeacherView: true);
          case 'teacher_medical':
          case 'medical':
            return const MedicalCardScreen();
          case 'teacher_notifications':
            return const NotificationsScreen();
          default:
            return const TeacherDashboardScreen();
        }

      case UserRole.student:
        switch (navId) {
          case 'dashboard':
            return const StudentDashboardScreen();
          case 'student_id':
          case 'digital_id':
            return const DigitalIdCardScreen();
          case 'student_assignments':
          case 'assignments':
            return const AssignmentsTimelineScreen();
          case 'student_meet':
          case 'meet':
            return const MeetIdrakScreen();
          case 'student_library':
          case 'library':
            return const LibraryScreen();
          case 'student_timetable':
          case 'timetable':
            return const TimetableMatrixScreen();
          case 'student_grades':
          case 'grades':
            return const GradesAnalyticsScreen();
          case 'student_cafeteria':
          case 'cafeteria':
            return const CafeteriaMenuScreen();
          default:
            return const StudentDashboardScreen();
        }

      case UserRole.parent:
        switch (navId) {
          case 'dashboard':
            return const ParentDashboardScreen();
          case 'parent_timetable':
          case 'timetable':
            return const TimetableMatrixScreen();
          case 'parent_grades':
          case 'grades':
            return const GradesAnalyticsScreen();
          case 'parent_attendance':
          case 'attendance':
            return const AttendanceCalendarScreen();
          case 'parent_medical':
          case 'medical':
            return const MedicalCardScreen();
          case 'parent_tickets':
          case 'tickets':
            return const ParentTicketsScreen();
          case 'parent_cafeteria':
          case 'cafeteria':
            return const CafeteriaMenuScreen();
          default:
            return const ParentDashboardScreen();
        }
    }
  }

  void _showCustomizeNavSheet(BuildContext context, AppState appState) {
    final availableModules = appState.getAvailableModulesForRole();
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final activeNav = appState.getOrderedNavigation();

            return GlassModalSheet(
              borderRadius: 28,
              blur: 25,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.bottomNavCustomizeTitle,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.bottomNavCustomizeSubtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          AnimatedButton(
                            onTap: () async {
                              await HapticHelper.medium();
                              await appState.resetUserPreferences();
                              setModalState(() {});
                              if (mounted) setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                loc.reset,
                                style: const TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Content Tabs List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          // Currently pinned
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withAlpha(12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primaryAccent.withAlpha(40),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: AppColors.primaryAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${loc.activeTabs}: ${activeNav.length} / 5',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            loc.allAvailableModules,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          for (final module in availableModules) ...[
                            Builder(
                              builder: (context) {
                                final isPinned = activeNav.any(
                                  (n) => n.id == module.id,
                                );
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isPinned
                                        ? AppColors.surface
                                        : AppColors.cardBorder.withAlpha(20),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isPinned
                                          ? AppColors.primaryAccent.withAlpha(
                                              60,
                                            )
                                          : AppColors.cardBorder,
                                      width: isPinned ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 2,
                                    ),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isPinned
                                            ? AppColors.primaryAccent.withAlpha(
                                                20,
                                              )
                                            : Colors.grey.withAlpha(25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getIconFromString(module.icon),
                                        color: isPinned
                                            ? AppColors.primaryAccent
                                            : AppColors.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      module.getLocalizedTitle(loc),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isPinned
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isPinned
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      module.getLocalizedSubtitle(loc),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        isPinned
                                            ? Icons.check_circle_rounded
                                            : Icons.add_circle_outline_rounded,
                                        color: isPinned
                                            ? AppColors.primaryAccent
                                            : AppColors.textMuted,
                                        size: 22,
                                      ),
                                      onPressed: () async {
                                        if (isPinned) {
                                          await appState.removeNavigationItem(
                                            module.id,
                                          );
                                        } else {
                                          final success = await appState
                                              .pinModuleToNavigation(module);
                                          if (!success && context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  loc.maxNavLimitReached,
                                                ),
                                                backgroundColor:
                                                    AppColors.warning,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                        setModalState(() {});
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bottom Button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.done,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final updateService = Provider.of<AppUpdateService>(context);
    final loc = AppLocalizations.of(context);

    if (!appState.isAuthenticated) {
      return const LoginScreen();
    }

    // iOS FIX: currentUser null ise loading göster (beyaz ekran donma fix)
    if (appState.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IdrakLogo(size: 72, showText: false, isLightText: true),
              const SizedBox(height: 24),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 2.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.loading,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = appState.currentUser!;
    final currentRole = currentUser.role;

    // İstifadəçi seçimlərindən sıralı navigation items
    final orderedNavItems = appState.getOrderedNavigation();

    final screens = orderedNavItems.isNotEmpty
        ? orderedNavItems
              .map(
                (navItem) =>
                    _getScreenForNavItem(navItem.id, currentRole, appState),
              )
              .toList()
        // Fallback
        : <Widget>[_getScreenForNavItem('dashboard', currentRole, appState)];

    final activeTabIndex = appState.currentTabIndex >= screens.length
        ? 0
        : appState.currentTabIndex;
    final isDark = appState.isDarkMode;

    return PopScope(
      canPop: activeTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (activeTabIndex != 0) {
          appState.resetToDashboard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            // İmza hero qradienti — obsidian → indigo (ID kartı kimliyi)
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Center(child: IdrakLogo(size: 32)),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'İDRAK LİSEYİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                currentUser.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: const [],
        ),
        body: Stack(
          children: [
            _TabTransition(index: activeTabIndex, screens: screens),
            // 🆕 Yeni versiya banner-i — alt tarəfdə, aşağı menyunun üstündə;
            // mağazadan yenilənənə qədər hər açılışda göstərilir.
            if (updateService.updateAvailable)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: AppUpdateBanner(updateService: updateService),
              ),
          ],
        ),
        // 🆕 iOS Liquid Glass Sürüşən / Üzən Alt Menyu Dok Hədəfi (Dock DragTarget)
        bottomNavigationBar: _buildBottomNavBar(appState, isDark, loc),
      ),
    );
  }

  /// Build iPhone-style liquid glass bottom navigation with drag-drop support
  Widget _buildBottomNavBar(
    AppState appState,
    bool isDark,
    AppLocalizations loc,
  ) {
    final orderedNavItems = appState.orderedNavigationItems;
    final activeTabIndex = appState.currentTabIndex;
    final palette = AppPalette.of(context);
    final idleColor = isDark
        ? Colors.white.withValues(alpha: 0.64)
        : palette.brandNavy.withValues(alpha: 0.58);
    final activeColor = isDark ? Colors.white : palette.brandRoyal;

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 6),
      child: DragTarget<ModuleItem>(
        onWillAcceptWithDetails: (details) {
          setState(() {
            _isDragHoveredOnDock = true;
          });
          HapticFeedback.selectionClick();
          return true;
        },
        onLeave: (data) {
          setState(() {
            _isDragHoveredOnDock = false;
          });
        },
        onAcceptWithDetails: (details) async {
          setState(() {
            _isDragHoveredOnDock = false;
          });
          final module = details.data;
          final success = await appState.pinModuleToNavigation(module);
          if (success) {
            HapticFeedback.heavyImpact();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '✓ "${module.getLocalizedTitle(loc)}" ${loc.pinnedToBottomNav}',
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.maxNavLimitReached),
                  backgroundColor: AppColors.warning,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        },
        builder: (context, candidateData, rejectedData) {
          // Custom iPhone-style liquid glass bottom navigation
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
                  blurRadius: 30,
                  spreadRadius: -6,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: palette.brandRoyal.withValues(
                    alpha: isDark ? 0.10 : 0.14,
                  ),
                  blurRadius: 24,
                  spreadRadius: -10,
                  offset: const Offset(0, 4),
                ),
                if (_isDragHoveredOnDock)
                  BoxShadow(
                    color: AppColors.primaryAccent.withAlpha(120),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [Color(0xE60B1224), Color(0xCC0D1628)]
                          : [
                              Colors.white.withValues(alpha: 0.86),
                              const Color(0xFFEAF1FF).withValues(alpha: 0.66),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _isDragHoveredOnDock
                          ? AppColors.primaryAccent
                          : isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.94),
                      width: _isDragHoveredOnDock ? 2.0 : 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0, 0.52, 1],
                                colors: isDark
                                    ? [
                                        Colors.white.withValues(alpha: 0.06),
                                        Colors.transparent,
                                        palette.brandRoyal.withValues(
                                          alpha: 0.08,
                                        ),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.34),
                                        Colors.transparent,
                                        palette.brandAzure.withValues(
                                          alpha: 0.10,
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _LiquidGlassRimPainter(isDark: isDark),
                          ),
                        ),
                      ),
                      // iOS Liquid Glass top highlight line
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            widthFactor: 0.55,
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.85),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag hover indicator
                          if (_isDragHoveredOnDock)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.push_pin_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Alt menyuya bərkitmək üçün buraxın',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Navigation items
                          if (orderedNavItems.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(orderedNavItems.length, (
                                index,
                              ) {
                                final item = orderedNavItems[index];
                                final isSelected = activeTabIndex == index;
                                final iconData = isSelected
                                    ? _getIconFromString(item.activeIcon)
                                    : _getIconFromString(item.icon);

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticHelper.light();
                                      appState.setCurrentTabIndex(index);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 2,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 240,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 7,
                                          horizontal: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: isDark
                                                      ? [
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.18,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.05,
                                                              ),
                                                        ]
                                                      : [
                                                          palette.brandRoyal
                                                              .withValues(
                                                                alpha: 0.14,
                                                              ),
                                                          palette.brandAzure
                                                              .withValues(
                                                                alpha: 0.10,
                                                              ),
                                                        ],
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: isSelected
                                              ? Border.all(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.24,
                                                        )
                                                      : palette.brandRoyal
                                                            .withValues(
                                                              alpha: 0.20,
                                                            ),
                                                  width: 1.0,
                                                )
                                              : null,
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        (isDark
                                                                ? Colors.black
                                                                : palette
                                                                      .brandRoyal)
                                                            .withValues(
                                                              alpha: isDark
                                                                  ? 0.18
                                                                  : 0.10,
                                                            ),
                                                    blurRadius: 14,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnimatedScale(
                                              scale: isSelected ? 1.10 : 1.0,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Icon(
                                                iconData,
                                                size: 20.5,
                                                color: isSelected
                                                    ? activeColor
                                                    : idleColor,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? activeColor
                                                    : idleColor,
                                                letterSpacing: isSelected
                                                    ? -0.15
                                                    : 0,
                                              ),
                                              child: Text(
                                                item.getLocalizedLabel(loc),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiquidGlassRimPainter extends CustomPainter {
  const _LiquidGlassRimPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.7),
      const Radius.circular(27.3),
    );
    final warm = isDark ? const Color(0x66FF6B8A) : const Color(0x59FF6B8A);
    final cool = isDark ? const Color(0x6638BDF8) : const Color(0x5938BDF8);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 0.26, 0.50, 0.74, 1],
        colors: [
          warm,
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.42 : 0.90),
          Colors.transparent,
          cool,
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, rim);

    final bloom = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 0.28, 0.52, 0.76, 1],
        colors: [
          warm.withValues(alpha: 0.26),
          Colors.transparent,
          Colors.transparent,
          Colors.transparent,
          cool.withValues(alpha: 0.26),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bloom);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
