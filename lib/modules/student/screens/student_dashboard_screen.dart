import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../admin/widgets/reorderable_module_grid.dart';
import '../../parent/screens/grades_analytics_screen.dart';
import '../../parent/screens/timetable_matrix_screen.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/widgets/dashboard_kit.dart';
import 'assignments_timeline_screen.dart';
import 'cafeteria_menu_screen.dart';
import 'digital_id_card_screen.dart';
import 'library_screen.dart';
import 'meet_idrak_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
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
    final loc = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    final todayLessons =
        appState.getClassLessonsForDate(student.className, DateTime.now());
    final pendingAssignments = _pendingAssignments(appState, student);

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            DashboardHeroSliver(
              badge: loc.student.toUpperCase(),
              title: loc.studentDashboard,
              subtitle: '${student.fullName} • ${student.className}',
              photoUrl: student.photoUrl,
              avatarName: student.fullName,
              gradient: AppColors.heroGradient.colors,
              accentColor: AppColors.azure,
              watermarkIcon: Icons.school_rounded,
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
                      _entrance(
                        context,
                        0,
                        DashboardOverviewCard(
                          title: 'Akademik icmal',
                          icon: Icons.auto_graph_rounded,
                          accent: palette.brandRoyal,
                          isOnline: appState.isOnline,
                          kpis: [
                            DashboardKpiData(
                              label: 'GPA',
                              value: '${student.gpa}',
                              icon: Icons.star_rounded,
                              color: palette.brandGold,
                              onTap: () =>
                                  _open(context, const GradesAnalyticsScreen()),
                            ),
                            DashboardKpiData(
                              label: 'Davamiyyət',
                              value: '${student.attendanceRate}%',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                            DashboardKpiData(
                              label: 'Gözləyən tapşırıq',
                              value: '${pendingAssignments.length}',
                              icon: Icons.assignment_rounded,
                              color: palette.brandRoyal,
                              onTap: () => _open(
                                  context, const AssignmentsTimelineScreen()),
                            ),
                            DashboardKpiData(
                              label: 'Bugünkü dərs',
                              value: '${todayLessons.length}',
                              icon: Icons.schedule_rounded,
                              color: palette.brandAzure,
                              onTap: () =>
                                  _open(context, const TimetableMatrixScreen()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _entrance(
                        context,
                        1,
                        DashboardQuickActions(
                          actions: [
                            DashboardQuickActionData(
                              label: 'İD kart',
                              icon: Icons.badge_rounded,
                              color: palette.brandRoyal,
                              onTap: () =>
                                  _open(context, const DigitalIdCardScreen()),
                            ),
                            DashboardQuickActionData(
                              label: 'Tapşırıqlar',
                              icon: Icons.assignment_rounded,
                              color: palette.brandGold,
                              onTap: () => _open(
                                  context, const AssignmentsTimelineScreen()),
                            ),
                            DashboardQuickActionData(
                              label: 'Cədvəl',
                              icon: Icons.calendar_month_rounded,
                              color: palette.brandAzure,
                              onTap: () =>
                                  _open(context, const TimetableMatrixScreen()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _entrance(
                        context,
                        2,
                        _buildDayPlan(
                          context,
                          loc,
                          student,
                          todayLessons,
                          pendingAssignments.length,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _entrance(
                        context,
                        3,
                        _buildLessonsSection(context, loc, todayLessons),
                      ),
                      const SizedBox(height: 2),
                      _entrance(
                        context,
                        4,
                        _buildAssignmentsSection(
                          context,
                          loc,
                          pendingAssignments,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _entrance(
                        context,
                        5,
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
                        6,
                        ReorderableModuleGrid(
                          modules: appState.getOrderedModules(),
                          isReorderMode: _isReorderMode,
                          allowTwoLineTitle: true,
                          dynamicData: {
                            'student_timetable': todayLessons.isEmpty
                                ? loc.noLessonsToday
                                : '${todayLessons.length} ${loc.lessons}',
                            'student_assignments':
                                '${pendingAssignments.length} ${loc.pending}',
                            'student_meet': loc.meetIdrakDesc,
                            'student_library': loc.libraryDesc,
                            'student_cafeteria': loc.cafeteriaDesc,
                            'student_id': loc.digitalIdDesc,
                            'student_grades': 'GPA ${student.gpa}',
                          },
                          onReorder: (newOrder) {
                            appState.updateModuleOrder(newOrder);
                          },
                          onModuleTap: (moduleId, ctx) {
                            switch (moduleId) {
                              case 'student_timetable':
                                _open(ctx, const TimetableMatrixScreen());
                                break;
                              case 'student_assignments':
                                _open(ctx, const AssignmentsTimelineScreen());
                                break;
                              case 'student_meet':
                                _open(ctx, const MeetIdrakScreen());
                                break;
                              case 'student_library':
                                _open(ctx, const LibraryScreen());
                                break;
                              case 'student_cafeteria':
                                _open(ctx, const CafeteriaMenuScreen());
                                break;
                              case 'student_id':
                                _open(ctx, const DigitalIdCardScreen());
                                break;
                              case 'student_grades':
                                _open(ctx, const GradesAnalyticsScreen());
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

  Widget _buildDayPlan(
    BuildContext context,
    AppLocalizations loc,
    StudentProfile student,
    List<LessonSlot> lessons,
    int pendingCount,
  ) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final firstLesson = lessons.isNotEmpty ? lessons.first : null;

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 20,
                  color: palette.brandRoyal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.today,
                      style: AppTypography.title1(context),
                    ),
                    Text(
                      '${_weekdayName(DateTime.now().weekday)}, '
                      '${DateFormat('d MMMM').format(DateTime.now())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption1(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAttendanceRing(context, loc, student),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: palette.borderHairline),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPlanStat(
                  context,
                  icon: Icons.calendar_month_rounded,
                  accent: palette.brandRoyal,
                  label: loc.todayLessons,
                  value: lessons.isEmpty
                      ? loc.noLessonsToday
                      : '${lessons.length} ${loc.lessons}',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: palette.borderHairline,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildPlanStat(
                  context,
                  icon: Icons.alarm_rounded,
                  accent: pendingCount > 0
                      ? AppColors.warning
                      : AppColors.success,
                  label: loc.homework,
                  value: pendingCount > 0
                      ? '$pendingCount ${loc.pending}'
                      : loc.completed,
                ),
              ),
            ],
          ),
          if (firstLesson != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.brandRoyal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      firstLesson.time.split(' - ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstLesson.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title2(context),
                        ),
                        Text(
                          '${firstLesson.room} • ${firstLesson.teacher}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption1(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: palette.brandRoyal,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceRing(
    BuildContext context,
    AppLocalizations loc,
    StudentProfile student,
  ) {
    final palette = AppPalette.of(context);
    return Semantics(
      label: '${student.attendanceRate}% ${loc.attendance}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: student.attendanceRate / 100,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  color: palette.brandRoyal,
                  backgroundColor: palette.borderHairline,
                ),
              ),
              Text(
                '${student.attendanceRate}',
                style: AppTypography.caption2(context).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStat(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption1(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title2(context).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsSection(
    BuildContext context,
    AppLocalizations loc,
    List<LessonSlot> lessons,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: loc.todayLessons,
          subtitle: loc.timetableDesc,
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          trailing: _SectionAction(
            label: loc.view,
            onTap: () => _open(context, const TimetableMatrixScreen()),
          ),
        ),
        const SizedBox(height: 10),
        if (lessons.isEmpty)
          AppCard(
            variant: AppCardVariant.outline,
            child: Row(
              children: [
                Icon(
                  Icons.free_breakfast_rounded,
                  size: 20,
                  color: AppPalette.of(context).textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.noLessonsToday,
                    style: AppTypography.body3(context),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _LessonCard(
                  lesson: lessons[index],
                  index: index,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentsSection(
    BuildContext context,
    AppLocalizations loc,
    List<HomeworkAssignment> assignments,
  ) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: loc.assignments,
          subtitle: loc.assignmentsDesc,
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
          trailing: _SectionAction(
            label: loc.view,
            onTap: () => _open(context, const AssignmentsTimelineScreen()),
          ),
        ),
        const SizedBox(height: 10),
        if (assignments.isEmpty)
          AppCard(
            variant: AppCardVariant.tonal,
            color: palette.successContainer,
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bütün tapşırıqlar tamamdır',
                    style: AppTypography.body3(context),
                  ),
                ),
              ],
            ),
          )
        else
          for (final assignment in assignments.take(2)) ...[
            _AssignmentTile(assignment: assignment),
            const SizedBox(height: 9),
          ],
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

  List<HomeworkAssignment> _pendingAssignments(
    AppState appState,
    StudentProfile student,
  ) {
    final matchesClassAndStudent = appState.assignments.where((a) {
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
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return matchesClassAndStudent;
  }

  String _weekdayName(int weekday) {
    const names = [
      'Bazar',
      'Bazar ertəsi',
      'Çərşənbə axşamı',
      'Çərşənbə',
      'Cümə axşamı',
      'Cümə',
      'Şənbə',
    ];
    return names[weekday % 7];
  }
}

class _SectionAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SectionAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: palette.brandRoyal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonSlot lesson;
  final int index;

  const _LessonCard({required this.lesson, required this.index});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _subjectColor(lesson.subject);

    return Container(
      width: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  lesson.time.split(' - ').first,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            lesson.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title2(context).copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.meeting_room_outlined,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  lesson.room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption2(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaz') || s.contains('math')) return const Color(0xFF2563EB);
    if (s.contains('fizika') || s.contains('phys')) return const Color(0xFF7C3AED);
    if (s.contains('kimya') || s.contains('chem')) return const Color(0xFF059669);
    if (s.contains('biolog')) return const Color(0xFF0D9488);
    if (s.contains('tarix') || s.contains('history')) return const Color(0xFFD97706);
    if (s.contains('azərbaycan') || s.contains('dil') || s.contains('ədad')) {
      return const Color(0xFFE11D48);
    }
    if (s.contains('informat') || s.contains('it')) return const Color(0xFF0284C7);
    return const Color(0xFF1E3A8A);
  }
}

class _AssignmentTile extends StatelessWidget {
  final HomeworkAssignment assignment;

  const _AssignmentTile({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _subjectColor(assignment.subject);
    final overdue = assignment.dueDate.isBefore(DateTime.now());

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: EdgeInsets.zero,
      borderRadius: 16,
      onTap: () => Navigator.push(
        context,
        appRoute(builder: (_) => const AssignmentsTimelineScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title2(context).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${assignment.subject} • ${assignment.teacherName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (overdue ? AppColors.danger : accent)
                    .withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _dueLabel(assignment.dueDate),
                style: TextStyle(
                  color: overdue ? AppColors.danger : accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaz') || s.contains('math')) return const Color(0xFF2563EB);
    if (s.contains('fizika') || s.contains('phys')) return const Color(0xFF7C3AED);
    if (s.contains('kimya') || s.contains('chem')) return const Color(0xFF059669);
    if (s.contains('biolog')) return const Color(0xFF0D9488);
    if (s.contains('tarix') || s.contains('history')) return const Color(0xFFD97706);
    if (s.contains('azərbaycan') || s.contains('dil') || s.contains('ədad')) {
      return const Color(0xFFE11D48);
    }
    if (s.contains('informat') || s.contains('it')) return const Color(0xFF0284C7);
    return const Color(0xFF1E3A8A);
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now).inDays;
    if (due.isBefore(now)) return 'Gecikib';
    if (diff == 0) return 'Bu gün';
    if (diff == 1) return 'Sabah';
    return DateFormat('d MMM').format(due);
  }
}
