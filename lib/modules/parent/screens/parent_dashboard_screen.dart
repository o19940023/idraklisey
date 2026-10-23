import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../admin/widgets/reorderable_module_grid.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/widgets/dashboard_kit.dart';
import '../../student/screens/cafeteria_menu_screen.dart';
import 'attendance_calendar_screen.dart';
import 'grades_analytics_screen.dart';
import 'medical_card_screen.dart';
import 'parent_tickets_screen.dart';
import 'timetable_matrix_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
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
    final appState = context.watch<AppState>();
    final student = appState.student;
    final currentUser = appState.currentUser;
    final loc = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    final todayLessons =
        appState.getClassLessonsForDate(student.className, DateTime.now());
    final pendingHomeworkCount = appState.assignments.where((a) {
      final assignedCls = a.assignedClass?.trim();
      final matchesClass = assignedCls == null ||
          assignedCls.isEmpty ||
          assignedCls.toLowerCase() == 'hamısı' ||
          assignedCls.toLowerCase() == 'bütün siniflər' ||
          assignedCls.toLowerCase() == student.className.trim().toLowerCase();
      final matchesStudent = a.assignedStudentIds.isEmpty ||
          a.assignedStudentIds.contains(student.id);
      return matchesClass &&
          matchesStudent &&
          a.getStatusForStudent(student.id) == AssignmentStatus.pending;
    }).length;

    final canSeeAll = appState.hasPermission('view_all_tickets');
    final myId = currentUser?.id;
    final openTickets = appState.tickets.where((t) {
      final visible = canSeeAll || (t.senderId != null && t.senderId == myId);
      return visible &&
          (t.status == TicketStatus.open || t.status == TicketStatus.inProgress);
    }).length;

    final childGrades =
        appState.grades.where((g) => g.studentId == student.id).toList();
    final lowGrades =
        childGrades.where((g) => g.percentage < 61).toList();

    var entranceIndex = 0;

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            DashboardHeroSliver(
              badge: loc.parentCabinet.toUpperCase(),
              title: loc.parentDashboard,
              subtitle:
                  '${currentUser?.fullName ?? loc.parent} • ${student.fullName}',
              photoUrl: currentUser?.photoUrl,
              avatarName: currentUser?.fullName ?? loc.parent,
              gradient: const [
                Color(0xFF1B1533),
                Color(0xFF312E81),
                Color(0xFF4F46E5),
              ],
              accentColor: const Color(0xFFA78BFA),
              watermarkIcon: Icons.family_restroom_rounded,
              isOnline: appState.isOnline,
              notificationCount: appState.unreadNotificationCount,
              onNotifications: () =>
                  _open(context, const NotificationsScreen()),
              onSettings: () => _open(context, const SettingsScreen()),
              isReorderMode: _isReorderMode,
              onToggleReorder: _toggleReorder,
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
                      if (appState.children.length > 1) ...[
                        _entrance(
                          context,
                          entranceIndex++,
                          _buildChildSelector(
                            context,
                            loc,
                            appState,
                            student,
                            palette,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _entrance(
                        context,
                        entranceIndex++,
                        DashboardOverviewCard(
                          title: 'Övlad icmalı',
                          icon: Icons.family_restroom_rounded,
                          accent: palette.brandRoyal,
                          isOnline: appState.isOnline,
                          kpis: [
                            DashboardKpiData(
                              label: 'Davamiyyət',
                              value: '${student.attendanceRate}%',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              onTap: () => _open(
                                  context, const AttendanceCalendarScreen()),
                            ),
                            DashboardKpiData(
                              label: 'GPA',
                              value: '${student.gpa}',
                              icon: Icons.star_rounded,
                              color: palette.brandGold,
                              onTap: () =>
                                  _open(context, const GradesAnalyticsScreen()),
                            ),
                            DashboardKpiData(
                              label: 'Gözləyən tapşırıq',
                              value: '$pendingHomeworkCount',
                              icon: Icons.assignment_rounded,
                              color: AppColors.warning,
                            ),
                            DashboardKpiData(
                              label: 'Aktiv müraciət',
                              value: '$openTickets',
                              icon: Icons.confirmation_number_rounded,
                              color: palette.brandRoyal,
                              onTap: () =>
                                  _open(context, const ParentTicketsScreen()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _entrance(
                        context,
                        entranceIndex++,
                        DashboardQuickActions(
                          actions: [
                            DashboardQuickActionData(
                              label: 'Qiymətlər',
                              icon: Icons.star_rounded,
                              color: palette.brandGold,
                              onTap: () =>
                                  _open(context, const GradesAnalyticsScreen()),
                            ),
                            DashboardQuickActionData(
                              label: 'Davamiyyət',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              onTap: () => _open(
                                  context, const AttendanceCalendarScreen()),
                            ),
                            DashboardQuickActionData(
                              label: 'Müraciət',
                              icon: Icons.confirmation_number_rounded,
                              color: palette.brandRoyal,
                              onTap: () =>
                                  _open(context, const ParentTicketsScreen()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _entrance(
                        context,
                        entranceIndex++,
                        _buildTodaySummary(
                          context,
                          loc,
                          student,
                          todayLessons.length,
                          todayLessons.isEmpty
                              ? ''
                              : '${todayLessons.first.subject} (${todayLessons.first.time})',
                          pendingHomeworkCount,
                          openTickets,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _entrance(
                        context,
                        entranceIndex++,
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildAttentionCard(
                                  context,
                                  loc,
                                  palette,
                                  attendanceLow: student.attendanceRate < 85,
                                  attendanceRate: student.attendanceRate,
                                  lowGradeCount: lowGrades.length,
                                  openTickets: openTickets,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMedicalCard(
                                  context,
                                  loc,
                                  palette,
                                  student,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _entrance(
                        context,
                        entranceIndex++,
                        DashboardModuleHeader(
                          title: loc.monitoringModules,
                          subtitle: loc.monitoringModulesDesc,
                          count: appState.getOrderedModules().length,
                          isReorderMode: _isReorderMode,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _entrance(
                        context,
                        entranceIndex++,
                        ReorderableModuleGrid(
                          modules: appState.getOrderedModules(),
                          isReorderMode: _isReorderMode,
                          allowTwoLineTitle: true,
                          dynamicData: {
                            'parent_timetable': loc.timetableDesc,
                            'parent_grades': loc.gradesDesc,
                            'parent_attendance': loc.attendanceDesc,
                            'parent_medical': loc.medicalCard,
                            'parent_tickets': loc.helpdeskDesc,
                            'parent_cafeteria': loc.cafeteriaDesc,
                          },
                          onReorder: (newOrder) {
                            appState.updateModuleOrder(newOrder);
                          },
                          onModuleTap: (moduleId, ctx) {
                            switch (moduleId) {
                              case 'parent_timetable':
                                _open(ctx, const TimetableMatrixScreen());
                                break;
                              case 'parent_grades':
                                _open(ctx, const GradesAnalyticsScreen());
                                break;
                              case 'parent_attendance':
                                _open(ctx, const AttendanceCalendarScreen());
                                break;
                              case 'parent_medical':
                                _open(ctx, const MedicalCardScreen());
                                break;
                              case 'parent_tickets':
                                _open(ctx, const ParentTicketsScreen());
                                break;
                              case 'parent_cafeteria':
                                _open(ctx, const CafeteriaMenuScreen());
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
      ),
    );
  }

  Widget _buildChildSelector(
    BuildContext context,
    AppLocalizations loc,
    AppState appState,
    StudentProfile student,
    AppPalette palette,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.diversity_3_rounded,
              color: palette.brandRoyal,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${loc.yourChildren} (${appState.children.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.resolve(
                  context,
                  AppTypography.label2(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: appState.children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final child = appState.children[index];
              final isActive = child.id == student.id;
              return Semantics(
                button: true,
                selected: isActive,
                label: '${child.fullName} • ${child.className}',
                child: InkWell(
                  onTap: () => appState.setActiveChild(child.id),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isActive ? palette.brandRoyal : palette.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? palette.brandRoyal
                            : palette.borderHairline,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: palette.brandRoyal.withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.child_care_rounded
                              : Icons.child_care_outlined,
                          size: 16,
                          color: isActive
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            '${child.fullName.split(' ').first} • ${child.className}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary(
    BuildContext context,
    AppLocalizations loc,
    StudentProfile student,
    int todayLessonCount,
    String firstLessonInfo,
    int pendingHomeworkCount,
    int openTickets,
  ) {
    final palette = AppPalette.of(context);
    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.resolve(
              context,
              AppTypography.title1(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${loc.classLabel}: ${student.className} • ${loc.today}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1(context),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: palette.borderHairline),
          _buildSummaryRow(
            context: context,
            icon: Icons.calendar_month_rounded,
            accent: palette.brandRoyal,
            title: loc.todayLessons,
            subtitle: todayLessonCount > 0 ? firstLessonInfo : loc.noLessonsToday,
            value: '$todayLessonCount',
          ),
          Container(height: 1, color: palette.borderHairline),
          _buildSummaryRow(
            context: context,
            icon: pendingHomeworkCount > 0
                ? Icons.alarm_rounded
                : Icons.check_circle_rounded,
            accent: pendingHomeworkCount > 0
                ? AppColors.warning
                : AppColors.success,
            title: loc.homework,
            subtitle: pendingHomeworkCount > 0 ? loc.pending : loc.completed,
            value: '$pendingHomeworkCount',
          ),
          Container(height: 1, color: palette.borderHairline),
          _buildSummaryRow(
            context: context,
            icon: Icons.help_outline_rounded,
            accent: openTickets > 0 ? AppColors.warning : AppColors.success,
            title: loc.helpdesk,
            subtitle: openTickets > 0 ? loc.pending : loc.completed,
            value: '$openTickets',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required IconData icon,
    required Color accent,
    required String title,
    String? subtitle,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.resolve(
                    context,
                    AppTypography.title2(context),
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1(context)
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.resolve(
                context,
                AppTypography.metricSm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(
    BuildContext context,
    AppLocalizations loc,
    AppPalette palette, {
    required bool attendanceLow,
    required int attendanceRate,
    required int lowGradeCount,
    required int openTickets,
  }) {
    final needsAttention =
        attendanceLow || lowGradeCount > 0 || openTickets > 0;

    if (!needsAttention) {
      return AppCard(
        variant: AppCardVariant.tonal,
        color: palette.successContainer,
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              Text(
                loc.success,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.resolve(
                  context,
                  AppTypography.body3(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.tonal,
      color: palette.warningContainer,
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.warning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.resolve(
                      context,
                      AppTypography.title2(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (attendanceLow)
              _buildAttentionRow(
                context: context,
                icon: Icons.event_busy_rounded,
                iconColor: AppColors.danger,
                text: '$attendanceRate% ${loc.attendance}',
              ),
            if (lowGradeCount > 0)
              _buildAttentionRow(
                context: context,
                icon: Icons.trending_down_rounded,
                iconColor: AppColors.warning,
                text: '$lowGradeCount ${loc.grades}',
              ),
            if (openTickets > 0)
              _buildAttentionRow(
                context: context,
                icon: Icons.help_outline_rounded,
                iconColor: palette.brandRoyal,
                text: '$openTickets ${loc.activeTicketsCount}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body3(context)
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard(
    BuildContext context,
    AppLocalizations loc,
    AppPalette palette,
    StudentProfile student,
  ) {
    return Semantics(
      button: true,
      label: loc.medicalCard,
      child: AppCard(
        variant: AppCardVariant.elevated,
        onTap: () => _open(context, const MedicalCardScreen()),
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                loc.medicalCard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.resolve(
                  context,
                  AppTypography.title2(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${loc.bloodGroup}: ${student.bloodGroup ?? '—'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption1(context),
              ),
            ],
          ),
        ),
      ),
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
