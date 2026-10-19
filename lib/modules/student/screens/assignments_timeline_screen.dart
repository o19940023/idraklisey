import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../data/models/assignment_model.dart';
import '../../../l10n/app_localizations.dart';
import 'homework_submission_screen.dart';

class AssignmentsTimelineScreen extends StatefulWidget {
  const AssignmentsTimelineScreen({super.key});

  @override
  State<AssignmentsTimelineScreen> createState() => _AssignmentsTimelineScreenState();
}

class _AssignmentsTimelineScreenState extends State<AssignmentsTimelineScreen> {
  AssignmentStatus? _selectedStatus;

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaziyyat') || s.contains('cəbr') || s.contains('həndəsə')) {
      return const Color(0xFF2563EB); // Royal Blue
    } else if (s.contains('fizika')) {
      return const Color(0xFF0284C7); // Ocean Sky
    } else if (s.contains('kimya')) {
      return const Color(0xFF7C3AED); // Vivid Purple
    } else if (s.contains('biologiya') || s.contains('həyat bilgisi') || s.contains('təbiət')) {
      return const Color(0xFF059669); // Emerald Green
    } else if (s.contains('ingilis') || s.contains('rus') || s.contains('alman') || s.contains('xarici dil')) {
      return const Color(0xFFD97706); // Amber Gold
    } else if (s.contains('tarix') || s.contains('zəfər')) {
      return const Color(0xFFE11D48); // Rose Crimson
    } else if (s.contains('azərbaycan') || s.contains('ədəbiyyat')) {
      return const Color(0xFF1D4ED8); // Deep Blue
    } else if (s.contains('informatika') || s.contains('rəqəmsal')) {
      return const Color(0xFF4F46E5); // Indigo
    }
    return const Color(0xFF1E3A8A); // Idrak Navy
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaziyyat') || s.contains('cəbr') || s.contains('həndəsə')) {
      return Icons.calculate_rounded;
    } else if (s.contains('fizika')) {
      return Icons.wb_twilight_rounded;
    } else if (s.contains('kimya')) {
      return Icons.biotech_rounded;
    } else if (s.contains('biologiya') || s.contains('həyat bilgisi') || s.contains('təbiət')) {
      return Icons.eco_rounded;
    } else if (s.contains('ingilis') || s.contains('rus') || s.contains('alman') || s.contains('xarici dil')) {
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
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;
    final allAssignments = appState.assignments;

    // Filter by student target if student/parent is logged in
    final relevantAssignments = allAssignments.where((a) {
      if (appState.currentRole == UserRole.student || appState.currentRole == UserRole.parent) {
        final assignedCls = a.assignedClass?.trim();
        final matchesClass = assignedCls == null ||
            assignedCls.isEmpty ||
            assignedCls.toLowerCase() == 'hamısı' ||
            assignedCls.toLowerCase() == 'bütün siniflər' ||
            assignedCls.toLowerCase() == currentStudent.className.trim().toLowerCase();
        final matchesStudent = a.assignedStudentIds.isEmpty || a.assignedStudentIds.contains(currentStudent.id);
        return matchesClass && matchesStudent;
      }
      return true;
    }).toList();

    final pendingCount = relevantAssignments.where((a) => a.getStatusForStudent(currentStudent.id) == AssignmentStatus.pending).length;
    final submittedCount = relevantAssignments.where((a) => a.getStatusForStudent(currentStudent.id) == AssignmentStatus.submitted).length;
    final gradedCount = relevantAssignments.where((a) => a.getStatusForStudent(currentStudent.id) == AssignmentStatus.graded).length;
    final totalCount = relevantAssignments.length;
    final completedTotal = submittedCount + gradedCount;
    final progressRate = totalCount > 0 ? (completedTotal / totalCount).clamp(0.0, 1.0) : 0.0;

    // Filtered list
    final filtered = _selectedStatus == null
        ? relevantAssignments
        : relevantAssignments.where((a) => a.getStatusForStudent(currentStudent.id) == _selectedStatus).toList();

    // Check for urgent pending assignment (due within 48 hours)
    final now = DateTime.now();
    HomeworkAssignment? urgentAssignment;
    try {
      final pendingOnes = relevantAssignments
          .where((a) => a.getStatusForStudent(currentStudent.id) == AssignmentStatus.pending && a.dueDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (pendingOnes.isNotEmpty && pendingOnes.first.dueDate.difference(now).inHours <= 48) {
        urgentAssignment = pendingOnes.first;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Dark Header with Progress Bar ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0F172A),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
              ),
              onPressed: () => handleBackNavigation(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                      Color(0xFF1E3A8A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withAlpha(25)),
                              ),
                              child: const Icon(Icons.assignment_turned_in_rounded, size: 22, color: Color(0xFF38BDF8)),
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
                                    '${currentStudent.fullName} • ${currentStudent.className} Sinfi',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Progress Indicator Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tapşırıq İcrası: $completedTotal / $totalCount Tamamlandı',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${(progressRate * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressRate,
                                minHeight: 6,
                                backgroundColor: Colors.white.withAlpha(30),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
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
          ),

          // ── Urgent Homework Banner (If any) ──
          if (urgentAssignment != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alarm_on_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'TƏCİLİ TAPŞIRIQ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFB45309),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            urgentAssignment.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          Text(
                            'Son tarix: ${DateFormat("dd.MM.yyyy HH:mm").format(urgentAssignment.dueDate)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeworkSubmissionScreen(assignment: urgentAssignment!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('İndi Göndər', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Stat Tiles ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildStatTile(
                    label: 'Gözləyir',
                    count: pendingCount,
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                  const SizedBox(width: 8),
                  _buildStatTile(
                    label: 'Təhvil Verildi',
                    count: submittedCount,
                    icon: Icons.mark_email_read_rounded,
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFF0F9FF),
                  ),
                  const SizedBox(width: 8),
                  _buildStatTile(
                    label: 'Qiymətləndi',
                    count: gradedCount,
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter Segment Bar ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSegmentFilterChip('Hamısı', totalCount, null),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip('Gözləyir', pendingCount, AssignmentStatus.pending),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip('Təhvil Verilib', submittedCount, AssignmentStatus.submitted),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip('Qiymətləndirilib', gradedCount, AssignmentStatus.graded),
                  ],
                ),
              ),
            ),
          ),

          // ── Empty State ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bu kateqoriyada tapşırıq yoxdur',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bütün tapşırıqlar yerinə yetirilib və ya müəllim hələ yeni tapşırıq əlavə etməyib.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Timeline List ──
          if (filtered.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return _buildModernAssignmentCard(context, item, currentStudent.id);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Stat Tile ──
  Widget _buildStatTile({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter Chip ──
  Widget _buildSegmentFilterChip(String title, int count, AssignmentStatus? status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(30) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Elevated Modern Assignment Card ──
  Widget _buildModernAssignmentCard(BuildContext context, HomeworkAssignment assignment, String studentId) {
    final dateFormat = DateFormat('dd.MM.yyyy • HH:mm');
    final status = assignment.getStatusForStudent(studentId);
    final mySub = assignment.getSubmissionForStudent(studentId);
    final color = _getSubjectColor(assignment.subject);
    final icon = _getSubjectIcon(assignment.subject);

    final now = DateTime.now();
    final isOverdue = now.isAfter(assignment.dueDate) && status != AssignmentStatus.submitted && status != AssignmentStatus.graded;

    final todayDate = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      assignment.dueDate.year,
      assignment.dueDate.month,
      assignment.dueDate.day,
    );
    final dayDiff = dueDay.difference(todayDate).inDays;

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (status) {
      case AssignmentStatus.pending:
        statusColor = isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
        statusTitle = isOverdue ? 'Müddəti Bitib' : 'Gözləyir';
        statusIcon = isOverdue ? Icons.error_outline_rounded : Icons.hourglass_top_rounded;
        break;
      case AssignmentStatus.inProgress:
        statusColor = const Color(0xFF2563EB);
        statusTitle = 'Hazırlanır';
        statusIcon = Icons.edit_note_rounded;
        break;
      case AssignmentStatus.submitted:
        statusColor = const Color(0xFF0284C7);
        statusTitle = 'Təhvil Verilib';
        statusIcon = Icons.mark_email_read_rounded;
        break;
      case AssignmentStatus.graded:
        statusColor = const Color(0xFF10B981);
        statusTitle = 'Qiymətləndi: ${mySub?.score?.toInt()} / 100';
        statusIcon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isOverdue ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeworkSubmissionScreen(assignment: assignment),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top strip indicator
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject + Status Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: color.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, size: 16, color: color),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              assignment.subject,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusTitle,
                                style: TextStyle(
                                  fontSize: 10.5,
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

                    // Title
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),

                    if (assignment.instructions.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        assignment.instructions,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Teacher feedback if graded
                    if (status == AssignmentStatus.graded && mySub?.teacherComment != null && mySub!.teacherComment!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.comment_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Müəllim rəyi: "${mySub.teacherComment}"',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Thin Divider
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Bottom info: Deadline & CTA Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Son tarix: ${dateFormat.format(assignment.dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                fontWeight: isOverdue ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                            if (!isOverdue && dayDiff >= 0 && dayDiff <= 1 && status == AssignmentStatus.pending) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Text(
                                  dayDiff == 0 ? 'Bugün' : 'Sabah',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                status == AssignmentStatus.graded
                                    ? 'Baxış'
                                    : (status == AssignmentStatus.submitted ? 'İşi Yoxla' : 'Təhvil Ver'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.white),
                            ],
                          ),
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
}
