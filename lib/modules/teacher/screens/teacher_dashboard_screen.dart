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
import '../../../data/models/timetable_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../admin/widgets/reorderable_module_grid.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../shared/widgets/dashboard_kit.dart';
import '../../student/screens/library_screen.dart';
import '../../student/screens/meet_idrak_screen.dart';
import 'create_assignment_screen.dart';
import 'qr_inventory_ticket_screen.dart';
import 'quick_grading_screen.dart';
import 'review_submissions_screen.dart';
import 'teacher_id_card_screen.dart';
import 'teacher_students_screen.dart';
import 'teacher_timetable_view_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
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
    final currentUser = appState.currentUser;
    final loc = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    final teacherName = currentUser?.fullName ?? loc.teacher;
    final teacherSubject = currentUser?.subject ?? 'Tədris Şöbəsi';
    final assignedClasses = currentUser?.assignedClasses ?? const <String>[];
    final normalizedAssignedClasses = assignedClasses
        .map((c) => c.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet();
    final scopedStudents = appState.students
        .where(
          (s) => normalizedAssignedClasses.contains(
            s.className.trim().toLowerCase(),
          ),
        )
        .toList();

    final assignments = appState.currentTeacherAssignments;
    final pendingReviews =
        assignments.where((a) => a.submittedCount > 0).toList();
    final todayLessons = currentUser == null
        ? const <LessonSlot>[]
        : appState.getTeacherLessonsForDate(currentUser.id, DateTime.now());

    final classStats = <String, ({int students, double avgGpa})>{};
    for (final cls in assignedClasses) {
      final normalized = cls.trim().toLowerCase();
      final classStudents = appState.students
          .where(
            (s) =>
                normalized.isNotEmpty &&
                s.className.trim().toLowerCase() == normalized,
          )
          .toList();
      final graded = classStudents.where((s) => s.gpa > 0).toList();
      final avg = graded.isEmpty
          ? 0.0
          : graded.map((s) => s.gpa).reduce((a, b) => a + b) / graded.length;
      classStats[cls] = (students: classStudents.length, avgGpa: avg);
    }

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            DashboardHeroSliver(
              badge: loc.teacher.toUpperCase(),
              title: loc.teacherDashboard,
              subtitle: '$teacherName • $teacherSubject',
              photoUrl: currentUser?.photoUrl,
              avatarName: teacherName,
              gradient: const [
                Color(0xFF0F172A),
                Color(0xFF1E1F30),
                Color(0xFF141724),
              ],
              accentColor: AppColors.gold,
              watermarkIcon: Icons.psychology_rounded,
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
                          title: 'Dərs icmalı',
                          icon: Icons.insights_rounded,
                          accent: palette.brandRoyal,
                          isOnline: appState.isOnline,
                          onRefresh: appState.initFirebaseData,
                          kpis: [
                            DashboardKpiData(
                              label: 'Siniflər',
                              value: '${assignedClasses.length}',
                              icon: Icons.class_rounded,
                              color: palette.brandRoyal,
                              onTap: () =>
                                  _open(context, const TeacherStudentsScreen()),
                            ),
                            DashboardKpiData(
                              label: 'Şagirdlər',
                              value: '${scopedStudents.length}',
                              icon: Icons.groups_rounded,
                              color: palette.brandAzure,
                              onTap: () =>
                                  _open(context, const TeacherStudentsScreen()),
                            ),
                            DashboardKpiData(
                              label: 'Gözləyən',
                              value: '${pendingReviews.length}',
                              icon: Icons.assignment_turned_in_rounded,
                              color: palette.brandGold,
                              onTap: () => _open(
                                  context, const ReviewSubmissionsScreen()),
                            ),
                            DashboardKpiData(
                              label: 'Bugünkü dərs',
                              value: '${todayLessons.length}',
                              icon: Icons.schedule_rounded,
                              color: palette.brandAzure,
                              onTap: () => _open(
                                  context, const TeacherTimetableViewScreen()),
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
                              label: 'Tapşırıq yarat',
                              icon: Icons.add_task_rounded,
                              color: palette.brandRoyal,
                              onTap: () =>
                                  _open(context, const CreateAssignmentScreen()),
                            ),
                            DashboardQuickActionData(
                              label: 'Qiymət yaz',
                              icon: Icons.rate_review_rounded,
                              color: palette.brandGold,
                              onTap: () =>
                                  _open(context, const QuickGradingScreen()),
                            ),
                            DashboardQuickActionData(
                              label: 'Şagirdlər',
                              icon: Icons.groups_rounded,
                              color: palette.brandAzure,
                              onTap: () =>
                                  _open(context, const TeacherStudentsScreen()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _entrance(
                        context,
                        2,
                        _ClassAnalyticsCard(
                          classes: assignedClasses,
                          stats: classStats,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _entrance(
                        context,
                        3,
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildTodayLessonsCard(
                                  context,
                                  todayLessons: todayLessons,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGradingQueueCard(
                                  context,
                                  queue: pendingReviews,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _entrance(
                        context,
                        4,
                        _buildIdPassCard(context, loc),
                      ),
                      const SizedBox(height: 18),
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
                            'teacher_timetable': loc.timetableDesc,
                            'teacher_meet': loc.meetIdrakDesc,
                            'teacher_students':
                                '${scopedStudents.length} ${loc.student}',
                            'teacher_assignments':
                                '${assignments.length} ${loc.assignments}',
                            'teacher_grading': loc.voiceToTextReview,
                            'teacher_library':
                                '${appState.books.length} ${loc.booksCount}',
                            'teacher_notifications': loc.notificationsDesc,
                            'teacher_inventory': loc.inventoryDesc,
                          },
                          onReorder: (newOrder) {
                            appState.updateModuleOrder(newOrder);
                          },
                          onModuleTap: (moduleId, ctx) {
                            switch (moduleId) {
                              case 'teacher_timetable':
                                _open(ctx, const TeacherTimetableViewScreen());
                                break;
                              case 'teacher_meet':
                                _open(ctx, const MeetIdrakScreen());
                                break;
                              case 'teacher_students':
                                _open(ctx, const TeacherStudentsScreen());
                                break;
                              case 'teacher_assignments':
                                _open(ctx, const ReviewSubmissionsScreen());
                                break;
                              case 'teacher_grading':
                                _open(ctx, const QuickGradingScreen());
                                break;
                              case 'teacher_library':
                                _open(ctx, const LibraryScreen(
                                  isTeacherView: true,
                                ));
                                break;
                              case 'teacher_notifications':
                                _open(ctx, const NotificationsScreen());
                                break;
                              case 'teacher_inventory':
                                _open(ctx, const QrInventoryTicketScreen());
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

  Widget _buildIdPassCard(BuildContext context, AppLocalizations loc) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final gold = palette.brandGold;

    return Semantics(
      button: true,
      child: AppCard(
        onTap: () => _open(context, const TeacherIdCardScreen()),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gold, gold.withAlpha(170)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.badge_rounded,
                color: colorScheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          loc.teacherIdCard,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.threed_rotation_rounded,
                          size: 11,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loc.teacherIdCardDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: gold.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.view,
                    style: TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: gold,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLessonsCard(
    BuildContext context, {
    required List<LessonSlot> todayLessons,
  }) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.brandAzure.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: palette.brandAzure,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).todayLessons,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (todayLessons.isEmpty)
              Text(
                AppLocalizations.of(context).noLessonsToday,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body3(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...[
                for (final slot in todayLessons.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            slot.time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption1(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (todayLessons.length > 3)
                  Text(
                    '+${todayLessons.length - 3}',
                    style: AppTypography.caption1(context).copyWith(
                      color: palette.brandRoyal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradingQueueCard(
    BuildContext context, {
    required List<HomeworkAssignment> queue,
  }) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: AppCard(
        onTap: () => _open(context, const ReviewSubmissionsScreen()),
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: palette.brandGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.rate_review_rounded,
                      size: 16,
                      color: palette.brandGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).pending,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (queue.isEmpty)
                Text(
                  AppLocalizations.of(context).noDataAvailable,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body3(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...[
                  for (final item in queue.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${AppLocalizations.of(context).submitted}: ${item.submittedCount}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption1(context)
                                      .copyWith(
                                    color: palette.brandGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (item.assignedClass != null &&
                                  item.assignedClass!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    item.assignedClass!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption1(context)
                                        .copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (queue.length > 2)
                    Text(
                      '+${queue.length - 2}',
                      style: AppTypography.caption1(context).copyWith(
                        color: palette.brandRoyal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
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

class _ClassAnalyticsCard extends StatefulWidget {
  final List<String> classes;
  final Map<String, ({int students, double avgGpa})> stats;

  const _ClassAnalyticsCard({
    required this.classes,
    required this.stats,
  });

  @override
  State<_ClassAnalyticsCard> createState() => _ClassAnalyticsCardState();
}

class _ClassAnalyticsCardState extends State<_ClassAnalyticsCard> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final classes = widget.classes;
    if (_selected >= classes.length) _selected = 0;
    final selectedClass = classes.isEmpty ? null : classes[_selected];
    final stats = selectedClass == null ? null : widget.stats[selectedClass];
    final gpa = stats?.avgGpa ?? 0.0;
    final progress = (gpa / 5).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: palette.brandRoyal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.analytics,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (classes.isEmpty)
            Text(
              loc.selectClass,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body3(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...[
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final (i, cls) in classes.indexed)
                        Padding(
                          padding: EdgeInsets.only(
                            right: i == classes.length - 1 ? 0 : 8,
                          ),
                          child: ChoiceChip(
                            label: Text(
                              cls,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: _selected == i,
                            onSelected: (_) =>
                                setState(() => _selected = i),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (stats != null && stats.students > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: palette.brandRoyal,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${stats.students}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.metricSm(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              loc.studentsCount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption1(context).copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 18,
                            color: palette.brandGold,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              stats.avgGpa > 0
                                  ? stats.avgGpa.toStringAsFixed(2)
                                  : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.metricSm(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              loc.gpaScore,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption1(context).copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: palette.surface3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      palette.brandRoyal,
                    ),
                  ),
                ),
              ] else
                Text(
                  loc.noDataAvailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body3(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
        ],
      ),
    );
  }
}
