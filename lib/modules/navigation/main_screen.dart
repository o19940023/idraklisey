import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/idrak_logo.dart';
import '../../data/models/user_preferences_model.dart';
import '../../providers/app_state.dart';
import '../../services/app_update_service.dart';
import '../auth/screens/login_screen.dart';
import '../shared/screens/notifications_screen.dart';
import '../shared/widgets/app_update_banner.dart';

// Admin Screens
import '../admin/screens/admin_dashboard_screen.dart';
import '../admin/screens/admin_users_screen.dart';
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

class _MainScreenState extends State<MainScreen> {
  bool _isDragHoveredOnDock = false;

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

  Widget _getScreenForNavItem(String navId, UserRole role) {
    switch (role) {
      case UserRole.admin:
        switch (navId) {
          case 'dashboard':
            return const AdminDashboardScreen();
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
          default:
            return const AdminDashboardScreen();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final activeNav = appState.getOrderedNavigation();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: AppShadows.lg,
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
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
                              'Alt Menyu və Sürətli Tablar',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aşağıda görünəcək düymələri seçin və sıralayın',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            await appState.resetUserPreferences();
                            setModalState(() {});
                            if (mounted) setState(() {});
                          },
                          child: const Text(
                            'Sıfırla',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
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
                                  'Aktiv tablar: ${activeNav.length} / 5 (Dəyişmək üçün modulları seçin)',
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
                          'Mövcud Bütün Modullar',
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
                                        ? AppColors.primaryAccent.withAlpha(60)
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
                                    module.title,
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
                                    module.subtitle,
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
                                            const SnackBar(
                                              content: Text(
                                                'Maksimum 5 alt menyu tabı seçilə bilər.',
                                              ),
                                              backgroundColor:
                                                  AppColors.warning,
                                              duration: Duration(seconds: 2),
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
                          child: const Text(
                            'Tamamla',
                            style: TextStyle(
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
            children: const [
              CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              SizedBox(height: 20),
              Text(
                'Yuklenir...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // iOS FIX: currentUser null ise loading göster (beyaz ekran donma fix)
    if (appState.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              SizedBox(height: 20),
              Text(
                'Yuklenir...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
              .map((navItem) => _getScreenForNavItem(navItem.id, currentRole))
              .toList()
        // Fallback
        : <Widget>[_getScreenForNavItem('dashboard', currentRole)];

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
          toolbarHeight: 56,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
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
          actions: [
            // Alt menyunu fərdiləşdir düyməsi
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white70,
                size: 20,
              ),
              tooltip: 'Alt Menyunu Fərdiləşdir',
              onPressed: () => _showCustomizeNavSheet(context, appState),
            ),
            IconButton(
              icon: Icon(
                appState.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: Colors.white,
                size: 20,
              ),
              tooltip: appState.isDarkMode ? 'Açıq rejim' : 'Tünd rejim',
              onPressed: () => appState.toggleTheme(),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Bildirişlər & Elanlar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (appState.unreadNotificationCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        '${appState.unreadNotificationCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.white70,
                size: 20,
              ),
              tooltip: 'Hesabdan Çıxış',
              onPressed: () => appState.logout(),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            IndexedStack(index: activeTabIndex, children: screens),
            // 🆕 Yeni versiya banner-i — tətbiq işləməyə davam edir,
            // amma banner mağazadan yenilənənə qədər hər açılışda göstərilir.
            if (updateService.updateAvailable)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: AppUpdateBanner(updateService: updateService),
              ),
          ],
        ),
        // 🆕 iOS Liquid Glass Sürüşən / Üzən Alt Menyu Dok Hədəfi (Dock DragTarget)
        bottomNavigationBar: Padding(
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
                          Text('✓ "${module.title}" alt menyuya bərkidildi!'),
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
                      content: const Text(
                        'Bu modul artıq alt menyudadır və ya limit (5 tab) dolub.',
                      ),
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isDark
                              ? const Color(0xFF10172A).withValues(alpha: 0.75)
                              : Colors.black.withValues(alpha: 0.65),
                          isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.70)
                              : Colors.black.withValues(alpha: 0.60),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _isDragHoveredOnDock
                            ? AppColors.primaryAccent
                            : Colors.white.withValues(alpha: 0.5),
                        width: _isDragHoveredOnDock ? 2.2 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        if (_isDragHoveredOnDock)
                          BoxShadow(
                            color: AppColors.primaryAccent.withAlpha(120),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // iOS Liquid Glass ust parlama cizgisi
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
                            if (_isDragHoveredOnDock)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
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
                                      '📌 Alt menyuya bərkitmək üçün buraxın',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (orderedNavItems.isNotEmpty)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: List.generate(
                                  orderedNavItems.length,
                                  (index) {
                                    final item = orderedNavItems[index];
                                    final isSelected = activeTabIndex == index;
                                    final iconData = isSelected
                                        ? _getIconFromString(item.activeIcon)
                                        : _getIconFromString(item.icon);

                                    return Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          appState.setCurrentTabIndex(index);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 2,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primaryAccent
                                                        .withAlpha(
                                                          isDark ? 35 : 22,
                                                        )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: isSelected
                                                  ? Border.all(
                                                      color: AppColors
                                                          .primaryAccent
                                                          .withAlpha(
                                                            isDark ? 70 : 45,
                                                          ),
                                                      width: 1.0,
                                                    )
                                                  : null,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                AnimatedScale(
                                                  scale: isSelected
                                                      ? 1.15
                                                      : 1.0,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: Icon(
                                                    iconData,
                                                    size: 20,
                                                    color: isSelected
                                                        ? AppColors
                                                              .primaryAccent
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.85,
                                                              ),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                AnimatedDefaultTextStyle(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w900
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? AppColors
                                                              .primaryAccent
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.85,
                                                              ),
                                                    letterSpacing: isSelected
                                                        ? -0.2
                                                        : 0,
                                                  ),
                                                  child: Text(
                                                    item.label,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
