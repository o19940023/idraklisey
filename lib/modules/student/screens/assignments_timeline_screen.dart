import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/models/student_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import 'homework_submission_screen.dart';

class AssignmentsTimelineScreen extends StatefulWidget {
  const AssignmentsTimelineScreen({super.key});

  @override
  State<AssignmentsTimelineScreen> createState() =>
      _AssignmentsTimelineScreenState();
}

class _AssignmentsTimelineScreenState extends State<AssignmentsTimelineScreen> {
  AssignmentStatus? _selectedStatus;

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaziyyat') ||
        s.contains('cəbr') ||
        s.contains('həndəsə')) {
      return const Color(0xFF2563EB);
    } else if (s.contains('fizika')) {
      return const Color(0xFF0284C7);
    } else if (s.contains('kimya')) {
      return const Color(0xFF7C3AED);
    } else if (s.contains('biologiya') ||
        s.contains('həyat bilgisi') ||
        s.contains('təbiət')) {
      return const Color(0xFF059669);
    } else if (s.contains('ingilis') ||
        s.contains('rus') ||
        s.contains('alman') ||
        s.contains('xarici dil')) {
      return const Color(0xFFD97706);
    } else if (s.contains('tarix') || s.contains('zəfər')) {
      return const Color(0xFFE11D48);
    } else if (s.contains('azərbaycan') || s.contains('ədəbiyyat')) {
      return const Color(0xFF1D4ED8);
    } else if (s.contains('informatika') || s.contains('rəqəmsal')) {
      return const Color(0xFF4F46E5);
    }
    return const Color(0xFF1E3A8A);
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaziyyat') ||
        s.contains('cəbr') ||
        s.contains('həndəsə')) {
      return Icons.calculate_rounded;
    } else if (s.contains('fizika')) {
      return Icons.wb_twilight_rounded;
    } else if (s.contains('kimya')) {
      return Icons.biotech_rounded;
    } else if (s.contains('biologiya') ||
        s.contains('həyat bilgisi') ||
        s.contains('təbiət')) {
      return Icons.eco_rounded;
    } else if (s.contains('ingilis') ||
        s.contains('rus') ||
        s.contains('alman') ||
        s.contains('xarici dil')) {
      return Icons.translate_rounded;
    } else if (s.contains('tarix') || s.contains('zəfər')) {
      return Icons.history_edu_rounded;
    } else if (s.contains('azərbaycan') || s.contains('ədəbiyyat')) {
      return Icons.menu_book_rounded;
    } else if (s.contains('informatika') || s.contains('rəqəmsal')) {
      return Icons.computer_rounded;
    }
    return Icons.assignment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();
    final currentStudent = appState.student;
    final allAssignments = appState.assignments;

    final relevantAssignments = allAssignments.where((a) {
      if (appState.currentRole == UserRole.student ||
          appState.currentRole == UserRole.parent) {
        final assignedCls = a.assignedClass?.trim();
        final matchesClass = assignedCls == null ||
            assignedCls.isEmpty ||
            assignedCls.toLowerCase() == 'hamısı' ||
            assignedCls.toLowerCase() == 'bütün siniflər' ||
            assignedCls.toLowerCase() ==
                currentStudent.className.trim().toLowerCase();
        final matchesStudent = a.assignedStudentIds.isEmpty ||
            a.assignedStudentIds.contains(currentStudent.id);
        return matchesClass && matchesStudent;
      }
      return true;
    }).toList();

    final pendingCount = relevantAssignments
        .where((a) =>
            a.getStatusForStudent(currentStudent.id) ==
            AssignmentStatus.pending)
        .length;
    final submittedCount = relevantAssignments
        .where((a) =>
            a.getStatusForStudent(currentStudent.id) ==
            AssignmentStatus.submitted)
        .length;
    final gradedCount = relevantAssignments
        .where((a) =>
            a.getStatusForStudent(currentStudent.id) ==
            AssignmentStatus.graded)
        .length;
    final totalCount = relevantAssignments.length;
    final completedTotal = submittedCount + gradedCount;
    final progressRate =
        totalCount > 0 ? (completedTotal / totalCount).clamp(0.0, 1.0) : 0.0;

    final filtered = _selectedStatus == null
        ? relevantAssignments
        : relevantAssignments
            .where((a) =>
                a.getStatusForStudent(currentStudent.id) == _selectedStatus)
            .toList();

    final now = DateTime.now();
    HomeworkAssignment? urgentAssignment;
    final pendingOnes = relevantAssignments
        .where((a) =>
            a.getStatusForStudent(currentStudent.id) ==
                AssignmentStatus.pending &&
            a.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (pendingOnes.isNotEmpty &&
        pendingOnes.first.dueDate.difference(now).inHours <= 48) {
      urgentAssignment = pendingOnes.first;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(
              context,
              loc,
              currentStudent,
              completedTotal,
              totalCount,
              progressRate,
            ),
            SliverToBoxAdapter(
              child: ResponsiveCenter(
                horizontalPadding: 0,
                child: Padding(
                  padding: responsivePadding(context).copyWith(
                    top: 16,
                    bottom: 36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatCardRow(
                        spacing: 9,
                        columns: 3,
                        children: [
                          StatCard(
                            compact: true,
                            value: '$pendingCount',
                            label: 'Gözləyir',
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.warning,
                          ),
                          StatCard(
                            compact: true,
                            value: '$submittedCount',
                            label: 'Təhvil verilib',
                            icon: Icons.mark_email_read_rounded,
                            color: palette.brandAzure,
                          ),
                          StatCard(
                            compact: true,
                            value: '$gradedCount',
                            label: 'Qiymətləndi',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildFilterBar(context, totalCount, pendingCount,
                          submittedCount, gradedCount),
                      if (urgentAssignment != null) ...[
                        const SizedBox(height: 12),
                        _UrgentAssignmentBanner(
                          assignment: urgentAssignment,
                          onOpen: () => _openSubmission(urgentAssignment!),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        AppEmptyState(
                          icon: Icons.task_alt_rounded,
                          title: 'Bu kateqoriyada tapşırıq yoxdur',
                          message:
                              'Bütün tapşırıqlar yerinə yetirilib və ya müəllim hələ yeni tapşırıq əlavə etməyib.',
                        )
                      else
                        for (var i = 0; i < filtered.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _AssignmentCard(
                              assignment: filtered[i],
                              studentId: currentStudent.id,
                              subjectColor:
                                  _getSubjectColor(filtered[i].subject),
                              subjectIcon:
                                  _getSubjectIcon(filtered[i].subject),
                              onTap: () =>
                                  _openSubmission(filtered[i]),
                            )
                                .animate()
                                .fadeIn(
                                  duration: 360.ms,
                                  delay: (i * 45).ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .slideY(
                                  begin: 0.03,
                                  duration: 360.ms,
                                  delay: (i * 45).ms,
                                  curve: Curves.easeOutCubic,
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

  SliverAppBar _buildAppBar(
    BuildContext context,
    AppLocalizations loc,
    StudentProfile currentStudent,
    int completedTotal,
    int totalCount,
    double progressRate,
  ) {
    final palette = AppPalette.of(context);
    return SliverAppBar(
      expandedHeight: 164,
      pinned: true,
      stretch: true,
      backgroundColor: palette.brandNavy,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: Colors.white,
          ),
        ),
        onPressed: () => handleBackNavigation(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 22,
                          color: AppColors.azure,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.assignments,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentStudent.fullName} • ${currentStudent.className}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressRate,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.14),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.azure,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$completedTotal / $totalCount tamam',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    int totalCount,
    int pendingCount,
    int submittedCount,
    int gradedCount,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: 'Hamısı',
            count: totalCount,
            selected: _selectedStatus == null,
            onTap: () => setState(() => _selectedStatus = null),
          ),
          const SizedBox(width: 7),
          _FilterChip(
            label: 'Gözləyir',
            count: pendingCount,
            selected: _selectedStatus == AssignmentStatus.pending,
            onTap: () =>
                setState(() => _selectedStatus = AssignmentStatus.pending),
          ),
          const SizedBox(width: 7),
          _FilterChip(
            label: 'Təhvil verilib',
            count: submittedCount,
            selected: _selectedStatus == AssignmentStatus.submitted,
            onTap: () =>
                setState(() => _selectedStatus = AssignmentStatus.submitted),
          ),
          const SizedBox(width: 7),
          _FilterChip(
            label: 'Qiymətləndi',
            count: gradedCount,
            selected: _selectedStatus == AssignmentStatus.graded,
            onTap: () =>
                setState(() => _selectedStatus = AssignmentStatus.graded),
          ),
        ],
      ),
    );
  }

  void _openSubmission(HomeworkAssignment assignment) {
    Navigator.push(
      context,
      appRoute(
        builder: (_) => HomeworkSubmissionScreen(assignment: assignment),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.brandRoyal : palette.surface1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.brandRoyal : palette.borderHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : colorScheme.onSurface,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : palette.surface3,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : palette.textMuted,
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
}

class _UrgentAssignmentBanner extends StatelessWidget {
  final HomeworkAssignment assignment;
  final VoidCallback onOpen;

  const _UrgentAssignmentBanner({
    required this.assignment,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.tonal,
      color: palette.warningContainer,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.alarm_on_rounded,
              size: 20,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TƏCİLİ TAPŞIRIQ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  assignment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title2(context).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Son tarix: ${DateFormat('dd.MM.yyyy HH:mm').format(assignment.dueDate)}',
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
          TextButton(
            onPressed: onOpen,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Göndər',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final HomeworkAssignment assignment;
  final String studentId;
  final Color subjectColor;
  final IconData subjectIcon;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.studentId,
    required this.subjectColor,
    required this.subjectIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final status = assignment.getStatusForStudent(studentId);
    final submission = assignment.getSubmissionForStudent(studentId);
    final now = DateTime.now();
    final isOverdue = now.isAfter(assignment.dueDate) &&
        status != AssignmentStatus.submitted &&
        status != AssignmentStatus.graded;

    final (statusColor, statusTitle, statusIcon) = switch (status) {
      AssignmentStatus.pending => isOverdue
          ? (
              AppColors.danger,
              'Müddəti bitib',
              Icons.error_outline_rounded,
            )
          : (
              AppColors.warning,
              'Gözləyir',
              Icons.hourglass_top_rounded,
            ),
      AssignmentStatus.inProgress => (
          palette.brandRoyal,
          'Hazırlanır',
          Icons.edit_note_rounded,
        ),
      AssignmentStatus.submitted => (
          palette.brandAzure,
          'Təhvil verilib',
          Icons.mark_email_read_rounded,
        ),
      AssignmentStatus.graded => (
          AppColors.success,
          'Qiymət: ${submission?.score?.toInt() ?? '—'} / 100',
          Icons.check_circle_rounded,
        ),
    };

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: subjectColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(subjectIcon, size: 17, color: subjectColor),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        assignment.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: subjectColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusTitle,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  assignment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title2(context).copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (assignment.instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    assignment.instructions,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body3(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                if (status == AssignmentStatus.graded &&
                    submission?.teacherComment != null &&
                    submission!.teacherComment!.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: palette.successContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Müəllim rəyi: "${submission.teacherComment}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                Container(height: 1, color: palette.borderHairline),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isOverdue
                          ? AppColors.danger
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Son tarix: ${DateFormat('dd.MM.yyyy • HH:mm').format(assignment.dueDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isOverdue
                              ? AppColors.danger
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isOverdue ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: subjectColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
