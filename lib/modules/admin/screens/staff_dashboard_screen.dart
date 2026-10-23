import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/ticket_model.dart';
import '../../../providers/app_state.dart';
import '../../parent/screens/grades_analytics_screen.dart';
import '../../parent/screens/parent_tickets_screen.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/widgets/dashboard_kit.dart';
import '../../student/screens/cafeteria_menu_screen.dart';
import '../../student/screens/library_screen.dart';
import '../widgets/reorderable_module_grid.dart';
import 'admin_timetable_management_screen.dart';
import 'admin_users_screen.dart';
import 'class_management_screen.dart';
import 'qr_inventory_management_screen.dart';
import 'role_management_screen.dart';
import 'student_management_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  bool _isReorderMode = false;

  void _toggleReorder() {
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
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, appRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser!;
    final assignedRole = appState.getRoleById(currentUser.assignedRoleId);
    final cyan = const Color(0xFF22D3EE);
    final orderedModules = appState.getOrderedModules();
    final canViewTickets = appState.hasPermission('view_tickets');

    final openTickets = appState.tickets
        .where(
          (t) =>
              t.status == TicketStatus.open ||
              t.status == TicketStatus.inProgress,
        )
        .length;

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          DashboardHeroSliver(
            badge: (assignedRole?.name ?? 'İşçi').toUpperCase(),
            title: assignedRole?.name ?? 'İşçi Paneli',
            subtitle: currentUser.fullName,
            photoUrl: currentUser.photoUrl,
            avatarName: currentUser.fullName,
            gradient: const [
              Color(0xFF071A2B),
              Color(0xFF0E4A5C),
              Color(0xFF0E7490),
            ],
            accentColor: cyan,
            watermarkIcon: Icons.work_rounded,
            isOnline: appState.isOnline,
            notificationCount: appState.unreadNotificationCount,
            onNotifications: () => _open(context, const NotificationsScreen()),
            onSettings: () => _open(context, const SettingsScreen()),
            isReorderMode: _isReorderMode,
            onToggleReorder: _toggleReorder,
          ),
          SliverToBoxAdapter(
            child: ResponsiveCenter(
              horizontalPadding: 0,
              child: Padding(
                padding: responsivePadding(
                  context,
                ).copyWith(top: 14, bottom: 108),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _entrance(
                      context,
                      0,
                      DashboardOverviewCard(
                        title: 'İş masası',
                        icon: Icons.work_outline_rounded,
                        accent: cyan,
                        isOnline: appState.isOnline,
                        kpis: [
                          if (canViewTickets)
                            DashboardKpiData(
                              label: 'Açıq müraciət',
                              value: '$openTickets',
                              icon: Icons.support_agent_rounded,
                              color: cyan,
                              onTap: () =>
                                  _open(context, const ParentTicketsScreen()),
                            ),
                          DashboardKpiData(
                            label: 'Oxunmamış',
                            value: '${appState.unreadNotificationCount}',
                            icon: Icons.notifications_rounded,
                            color: palette.brandGold,
                            onTap: () =>
                                _open(context, const NotificationsScreen()),
                          ),
                          DashboardKpiData(
                            label: 'Modul',
                            value: '${orderedModules.length}',
                            icon: Icons.grid_view_rounded,
                            color: palette.brandRoyal,
                          ),
                          DashboardKpiData(
                            label: 'Səlahiyyət',
                            value: '${assignedRole?.permissionIds.length ?? 0}',
                            icon: Icons.verified_user_rounded,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _entrance(
                      context,
                      1,
                      DashboardQuickActions(actions: _buildQuickActions()),
                    ),
                    const SizedBox(height: 18),
                    _entrance(
                      context,
                      2,
                      DashboardModuleHeader(
                        title: 'İş alətləri',
                        subtitle: 'Səlahiyyətlərinizə uyğun modullar',
                        count: orderedModules.length,
                        isReorderMode: _isReorderMode,
                        accent: cyan,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _entrance(
                      context,
                      3,
                      ReorderableModuleGrid(
                        modules: orderedModules,
                        isReorderMode: _isReorderMode,
                        allowTwoLineTitle: true,
                        onReorder: (newOrder) {
                          appState.updateModuleOrder(newOrder);
                        },
                        onModuleTap: (moduleId, ctx) {
                          if (!appState.hasPermission(moduleId)) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bu modula giriş icazəniz yoxdur.',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          switch (moduleId) {
                            case 'view_students':
                              _open(ctx, const StudentManagementScreen());
                              break;
                            case 'view_classes':
                              _open(ctx, const ClassManagementScreen());
                              break;
                            case 'view_timetable':
                              _open(
                                ctx,
                                const AdminTimetableManagementScreen(),
                              );
                              break;
                            case 'view_users':
                              _open(ctx, const AdminUsersScreen());
                              break;
                            case 'view_roles':
                              _open(ctx, const RoleManagementScreen());
                              break;
                            case 'view_tickets':
                              _open(ctx, const ParentTicketsScreen());
                              break;
                            case 'view_reports':
                              _open(ctx, const GradesAnalyticsScreen());
                              break;
                            case 'view_cafeteria':
                              _open(ctx, const CafeteriaMenuScreen());
                              break;
                            case 'view_settings':
                              _open(ctx, const NotificationsScreen());
                              break;
                            case 'view_inventory':
                              _open(ctx, const QrInventoryManagementScreen());
                              break;
                            case 'view_library':
                              _open(ctx, const LibraryScreen());
                              break;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DashboardQuickActionData> _buildQuickActions() {
    final appState = context.read<AppState>();
    final palette = AppPalette.of(context);
    final cyan = const Color(0xFF22D3EE);
    final actions = <DashboardQuickActionData>[];

    if (appState.hasPermission('view_tickets') ||
        appState.hasPermission('manage_tickets')) {
      actions.add(
        DashboardQuickActionData(
          label: 'Müraciətlər',
          icon: Icons.support_agent_rounded,
          color: cyan,
          onTap: () => _open(context, const ParentTicketsScreen()),
        ),
      );
    }
    if (appState.hasPermission('view_inventory') ||
        appState.hasPermission('manage_inventory')) {
      actions.add(
        DashboardQuickActionData(
          label: 'İnventar',
          icon: Icons.qr_code_rounded,
          color: palette.brandAzure,
          onTap: () => _open(context, const QrInventoryManagementScreen()),
        ),
      );
    }
    if (appState.hasPermission('view_library')) {
      actions.add(
        DashboardQuickActionData(
          label: 'Kitabxana',
          icon: Icons.menu_book_rounded,
          color: palette.brandGold,
          onTap: () => _open(context, const LibraryScreen()),
        ),
      );
    }
    if (appState.hasPermission('view_users')) {
      actions.add(
        DashboardQuickActionData(
          label: 'İstifadəçilər',
          icon: Icons.manage_accounts_rounded,
          color: palette.brandRoyal,
          onTap: () => _open(context, const AdminUsersScreen()),
        ),
      );
    }
    if (appState.hasPermission('view_settings')) {
      actions.add(
        DashboardQuickActionData(
          label: 'Toplu Elan',
          icon: Icons.campaign_rounded,
          color: AppColors.danger,
          onTap: () => _open(context, const NotificationsScreen()),
        ),
      );
    }

    if (actions.length < 2) {
      actions.add(
        DashboardQuickActionData(
          label: 'Bildirişlər',
          icon: Icons.notifications_rounded,
          color: AppColors.warning,
          onTap: () => _open(context, const NotificationsScreen()),
        ),
      );
    }
    if (actions.length < 2) {
      actions.add(
        DashboardQuickActionData(
          label: 'Ayarlar',
          icon: Icons.settings_outlined,
          color: palette.textMuted,
          onTap: () => _open(context, const SettingsScreen()),
        ),
      );
    }

    return actions.take(3).toList();
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
