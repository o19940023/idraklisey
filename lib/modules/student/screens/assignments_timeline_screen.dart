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
import '../../../core/widgets/rich_html_view.dart';
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
  bool _isGridView = true; // Default: Web Google Classroom style Bento Subject Grid
  String? _selectedSubjectFilter;
  AssignmentStatus? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto sync from backend on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshAssignmentsOverview();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('riyaziyyat') || s.contains('cəbr') || s.contains('həndəsə')) {
      return const Color(0xFFAD1457);
    } else if (s.contains('fizika')) {
      return const Color(0xFF0284C7);
    } else if (s.contains('kimya')) {
      return const Color(0xFF7C3AED);
    } else if (s.contains('biologiya') || s.contains('həyat bilgisi') || s.contains('təbiət')) {
      return const Color(0xFF37474F);
    } else if (s.contains('rus') || s.contains('tədris dili')) {
      return const Color(0xFFF57F17);
    } else if (s.contains('ingilis') || s.contains('xarici dil')) {
      return const Color(0xFF0277BD);
    } else if (s.contains('tarix') || s.contains('zəfər')) {
      return const Color(0xFFC62828);
    } else if (s.contains('azərbaycan') || s.contains('dövlət dili')) {
      return const Color(0xFF1565C0);
    } else if (s.contains('informatika') || s.contains('rəqəmsal')) {
      return const Color(0xFF6A1B9A);
    } else if (s.contains('fiziki tərbiyə')) {
      return const Color(0xFF00695C);
    } else if (s.contains('təsviri') || s.contains('incəsənət')) {
      return const Color(0xFF2E7D32);
    } else if (s.contains('musiqi')) {
      return const Color(0xFF4527A0);
    } else if (s.contains('şahmat') || s.contains('sahmat')) {
      return const Color(0xFFC62828);
    } else if (s.contains('ritmika')) {
      return const Color(0xFFE65100);
    } else if (s.contains('texnologiya')) {
      return const Color(0xFF4E342E);
    }
    return const Color(0xFF1E3A8A);
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
    } else if (s.contains('ingilis') || s.contains('rus') || s.contains('xarici dil') || s.contains('tədris dili')) {
      return Icons.translate_rounded;
    } else if (s.contains('tarix') || s.contains('zəfər')) {
      return Icons.history_edu_rounded;
    } else if (s.contains('azərbaycan') || s.contains('dövlət dili')) {
      return Icons.menu_book_rounded;
    } else if (s.contains('informatika') || s.contains('rəqəmsal')) {
      return Icons.computer_rounded;
    } else if (s.contains('fiziki tərbiyə')) {
      return Icons.sports_tennis_rounded;
    } else if (s.contains('təsviri') || s.contains('incəsənət')) {
      return Icons.brush_rounded;
    } else if (s.contains('musiqi')) {
      return Icons.music_note_rounded;
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

    // 1-to-1 Web Statistics Calculation
    final now = DateTime.now();
    final overviewStats = appState.assignmentOverviewStats;
    int totalCount = relevantAssignments.length;
    int submittedCount = 0;
    int pendingCount = 0;
    int overdueCount = 0;
    String avgGradeDisplay = '-';

    if (overviewStats != null && overviewStats['cards'] is List) {
      final cards = overviewStats['cards'] as List;
      for (final card in cards) {
        if (card is Map) {
          final label = card['label']?.toString().toLowerCase() ?? '';
          final val = card['value'];
          if (label.contains('cəmi')) {
            totalCount = int.tryParse(val.toString()) ?? totalCount;
          } else if (label.contains('təhvil')) {
            submittedCount = int.tryParse(val.toString()) ?? submittedCount;
          } else if (label.contains('gözləyən')) {
            pendingCount = int.tryParse(val.toString()) ?? pendingCount;
          } else if (label.contains('keçmiş') || label.contains('gecikən')) {
            overdueCount = int.tryParse(val.toString()) ?? overdueCount;
          } else if (label.contains('orta bal')) {
            avgGradeDisplay = val?.toString() ?? '-';
          }
        }
      }
    } else {
      for (final a in relevantAssignments) {
        final st = a.getStatusForStudent(currentStudent.id);
        if (st == AssignmentStatus.submitted || st == AssignmentStatus.graded) {
          submittedCount++;
        } else if (a.dueDate.isBefore(now)) {
          overdueCount++;
        } else {
          pendingCount++;
        }
      }
    }

    final completedTotal = submittedCount;
    final progressRate = totalCount > 0 ? (completedTotal / totalCount).clamp(0.0, 1.0) : 0.0;

    // Filter assignments for Siyahı (List) View
    final filteredAssignments = relevantAssignments.where((a) {
      if (_selectedSubjectFilter != null && _selectedSubjectFilter!.isNotEmpty) {
        if (!a.subject.toLowerCase().contains(_selectedSubjectFilter!.toLowerCase()) &&
            !_selectedSubjectFilter!.toLowerCase().contains(a.subject.toLowerCase())) {
          return false;
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchTitle = a.title.toLowerCase().contains(q);
        final matchSubj = a.subject.toLowerCase().contains(q);
        final matchTeacher = a.teacherName.toLowerCase().contains(q);
        if (!matchTitle && !matchSubj && !matchTeacher) {
          return false;
        }
      }

      if (_selectedStatus != null) {
        final st = a.getStatusForStudent(currentStudent.id);
        if (st != _selectedStatus) return false;
      }

      return true;
    }).toList();

    // Subject Grid Data from AppState or fallback grouping
    final List<Map<String, dynamic>> subjectGridData = appState.assignmentSubjectGrid.isNotEmpty
        ? appState.assignmentSubjectGrid
        : _buildFallbackSubjectGrid(relevantAssignments, currentStudent);

    // Filter subject grid by search query
    final filteredSubjectGrid = subjectGridData.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final name = (s['subject_name'] ?? '').toString().toLowerCase();
      final teacher = (s['teacher_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || teacher.contains(q);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: RefreshIndicator(
          onRefresh: () => appState.refreshAssignmentsOverview(),
          color: palette.brandAzure,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                    padding: responsivePadding(context).copyWith(top: 14, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TOP 5 BENTO STATS CARDS (Exact Web Parity)
                        _buildWebBentoStats(
                          context,
                          total: totalCount,
                          submitted: submittedCount,
                          pending: pendingCount,
                          overdue: overdueCount,
                          avgGrade: avgGradeDisplay,
                        ),
                        const SizedBox(height: 16),

                        // 2. VIEW SWITCHER & SEARCH
                        _buildControlsBar(context, currentStudent, filteredSubjectGrid.length),
                        const SizedBox(height: 14),

                        // 3. MAIN CONTENT: SUBJECT BENTO GRID vs LIST VIEW
                        if (_isGridView) ...[
                          _buildSubjectBentoGrid(filteredSubjectGrid, currentStudent),
                        ] else ...[
                          _buildListView(filteredAssignments, currentStudent, totalCount, pendingCount, submittedCount),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. TOP 5 BENTO STATS (Mirrors Web Exactly) ---
  Widget _buildWebBentoStats(
    BuildContext context, {
    required int total,
    required int submitted,
    required int pending,
    required int overdue,
    required String avgGrade,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _StatBentoCard(
            value: '$total',
            label: 'Cəmi tapşırıq',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF1A73E8),
            bgColor: const Color(0xFFE8F0FE),
          ),
          const SizedBox(width: 8),
          _StatBentoCard(
            value: '$submitted',
            label: 'Təhvil verilmiş',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF137333),
            bgColor: const Color(0xFFE6F4EA),
          ),
          const SizedBox(width: 8),
          _StatBentoCard(
            value: '$pending',
            label: 'Gözləyən (Aktiv)',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFE37400),
            bgColor: const Color(0xFFFEF7E0),
          ),
          const SizedBox(width: 8),
          _StatBentoCard(
            value: '$overdue',
            label: 'Müddəti keçmiş',
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFC5221F),
            bgColor: const Color(0xFFFCE8E6),
          ),
          const SizedBox(width: 8),
          _StatBentoCard(
            value: avgGrade,
            label: 'Orta bal',
            icon: Icons.star_outline_rounded,
            color: const Color(0xFF9334E6),
            bgColor: const Color(0xFFF3E8FD),
          ),
        ],
      ),
    );
  }

  // --- 2. CONTROLS BAR: VIEW SWITCHER + SEARCH ---
  Widget _buildControlsBar(BuildContext context, StudentProfile student, int subjectCount) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View Switcher Buttons (Grid vs List)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: palette.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isGridView = true),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 7.5),
                          decoration: BoxDecoration(
                            color: _isGridView ? const Color(0xFF1A73E8) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _isGridView
                                ? [BoxShadow(color: const Color(0xFF1A73E8).withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 14,
                                color: _isGridView ? Colors.white : palette.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Fənlər üzrə (Grid)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _isGridView ? FontWeight.w800 : FontWeight.w600,
                                  color: _isGridView ? Colors.white : palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isGridView = false),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 7.5),
                          decoration: BoxDecoration(
                            color: !_isGridView ? const Color(0xFF1A73E8) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !_isGridView
                                ? [BoxShadow(color: const Color(0xFF1A73E8).withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 15,
                                color: !_isGridView ? Colors.white : palette.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bütün tapşırıqlar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: !_isGridView ? FontWeight.w800 : FontWeight.w600,
                                  color: !_isGridView ? Colors.white : palette.textSecondary,
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
            ),
          ],
        ),
        const SizedBox(height: 11),

        // Search Input
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.borderHairline),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Sinif, fənn və ya müəllim axtar...',
              hintStyle: TextStyle(fontSize: 12.5, color: palette.textTertiary),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: palette.textTertiary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subheader: Class & Subject Count (Google Classroom style)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF1A73E8)),
                      const SizedBox(width: 4),
                      Text(
                        student.className,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$subjectCount fənn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            if (!_isGridView && _selectedSubjectFilter != null)
              InkWell(
                onTap: () => setState(() => _selectedSubjectFilter = null),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Hamısını göstər',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.brandAzure),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.close_rounded, size: 13, color: palette.brandAzure),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- 3. SUBJECT BENTO GRID (Google Classroom View) ---
  Widget _buildSubjectBentoGrid(List<Map<String, dynamic>> subjectList, StudentProfile student) {
    if (subjectList.isEmpty) {
      return const AppEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'Fənn tapılmadı',
        message: 'Axtarışa uyğun fənn tapşırıqları mövcud deyil.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjectList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = subjectList[index];
        final subjectName = item['subject_name']?.toString() ?? 'Fənn';
        final teacherName = item['teacher_name']?.toString() ?? 'Təyin edilməyib';
        final teacherInitial = item['teacher_initial']?.toString() ??
            (teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'M');
        final className = item['class_name']?.toString() ?? student.className;
        final colorHex = item['color']?.toString() ?? '#1565C0';
        final cardColor = _parseColor(colorHex);

        final latestAssignments = (item['latest_assignments'] is List)
            ? (item['latest_assignments'] as List)
            : [];

        return _SubjectBentoCard(
          subjectName: subjectName,
          teacherName: teacherName,
          teacherInitial: teacherInitial,
          className: className,
          color: cardColor,
          latestAssignments: latestAssignments,
          onViewAll: () {
            setState(() {
              _selectedSubjectFilter = subjectName;
              _isGridView = false;
            });
          },
          onTapAssignment: (asgMap) {
            _openAssignmentById(asgMap['id']?.toString() ?? '');
          },
        ).animate().fadeIn(duration: 250.ms, delay: (index * 35).ms);
      },
    );
  }

  // --- 4. LIST VIEW (Full Assignments Timeline) ---
  Widget _buildListView(
    List<HomeworkAssignment> assignments,
    StudentProfile student,
    int totalCount,
    int pendingCount,
    int submittedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedSubjectFilter != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_rounded, size: 15, color: Color(0xFF1A73E8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seçilmiş fənn: $_selectedSubjectFilter',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A73E8)),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedSubjectFilter = null),
                  child: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF1A73E8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Status Filter Chips
        SingleChildScrollView(
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
                onTap: () => setState(() => _selectedStatus = AssignmentStatus.pending),
              ),
              const SizedBox(width: 7),
              _FilterChip(
                label: 'Təhvil verilib',
                count: submittedCount,
                selected: _selectedStatus == AssignmentStatus.submitted,
                onTap: () => setState(() => _selectedStatus = AssignmentStatus.submitted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (assignments.isEmpty)
          const AppEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Bu kateqoriyada tapşırıq yoxdur',
            message: 'Axtarışınıza və ya filtrlərə uyğun tapşırıq tapılmadı.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assignments.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _AssignmentCard(
                  assignment: assignments[i],
                  studentId: student.id,
                  subjectColor: _getSubjectColor(assignments[i].subject),
                  subjectIcon: _getSubjectIcon(assignments[i].subject),
                  onTap: () => _openSubmission(assignments[i]),
                ).animate().fadeIn(duration: 250.ms, delay: (i * 25).ms),
              );
            },
          ),
      ],
    );
  }

  // --- APP BAR ---
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
                            backgroundColor: Colors.white.withValues(alpha: 0.14),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.azure),
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

  void _openSubmission(HomeworkAssignment assignment) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isParent = appState.currentUser?.role == UserRole.parent || appState.currentRole == UserRole.parent;
    if (isParent) {
      _showAssignmentDetailSheet(assignment);
      return;
    }
    Navigator.push(
      context,
      appRoute(
        builder: (_) => HomeworkSubmissionScreen(assignment: assignment),
      ),
    );
  }

  void _openAssignmentById(String rawId) {
    final appState = Provider.of<AppState>(context, listen: false);
    final found = appState.assignments.firstWhere(
      (a) => a.id == rawId || a.id == 'api-asg-$rawId' || a.rawBackendId == int.tryParse(rawId),
      orElse: () => appState.assignments.first,
    );
    _openSubmission(found);
  }

  void _showAssignmentDetailSheet(HomeworkAssignment assignment) {
    final appState = Provider.of<AppState>(context, listen: false);
    final palette = AppPalette.of(context);
    final student = appState.student;
    final status = assignment.getStatusForStudent(student.id);
    final submission = assignment.getSubmissionForStudent(student.id);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: _getSubjectColor(assignment.subject).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assignment.subject,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _getSubjectColor(assignment.subject),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                assignment.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Müəllim: ${assignment.teacherName}',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
              Text(
                'Son təhvil: ${dateFormat.format(assignment.dueDate)}',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${status == AssignmentStatus.graded ? "Qiymətləndirildi" : (status == AssignmentStatus.submitted ? "Təhvil verilib" : "Gözləyir")}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        if (submission?.score != null)
                          Text(
                            'Qiymət: ${submission!.score!.toInt()} / 100',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.emerald),
                          ),
                      ],
                    ),
                    if (submission?.teacherComment != null && submission!.teacherComment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Müəllim rəyi: "${submission.teacherComment}"',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.emerald),
                      ),
                    ],
                    if (submission?.submittedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Təhvil verildi: ${dateFormat.format(submission!.submittedAt)}',
                        style: TextStyle(fontSize: 11, color: palette.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildFallbackSubjectGrid(
    List<HomeworkAssignment> assignments,
    StudentProfile student,
  ) {
    final Map<String, List<HomeworkAssignment>> grouped = {};
    for (final a in assignments) {
      grouped.putIfAbsent(a.subject, () => []).add(a);
    }

    final list = <Map<String, dynamic>>[];
    for (final entry in grouped.entries) {
      final subAssignments = entry.value;
      final first = subAssignments.first;
      list.add({
        'class_name': student.className,
        'subject_name': entry.key,
        'teacher_name': first.teacherName,
        'teacher_initial': first.teacherName.isNotEmpty ? first.teacherName[0].toUpperCase() : 'M',
        'color': '#1565C0',
        'latest_assignments': subAssignments.take(3).map((a) {
          return {
            'id': a.rawBackendId?.toString() ?? a.id,
            'title': a.title,
            'due_date': DateFormat('dd.MM.yyyy').format(a.dueDate),
          };
        }).toList(),
      });
    }
    return list;
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return const Color(0xFF1565C0);
  }
}

// ==========================================
// 1. TOP BENTO STAT CARD
// ==========================================
class _StatBentoCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatBentoCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. GOOGLE CLASSROOM SUBJECT BENTO CARD
// ==========================================
class _SubjectBentoCard extends StatelessWidget {
  final String subjectName;
  final String teacherName;
  final String teacherInitial;
  final String className;
  final Color color;
  final List<dynamic> latestAssignments;
  final VoidCallback onViewAll;
  final ValueChanged<Map<String, dynamic>> onTapAssignment;

  const _SubjectBentoCard({
    required this.subjectName,
    required this.teacherName,
    required this.teacherInitial,
    required this.className,
    required this.color,
    required this.latestAssignments,
    required this.onViewAll,
    required this.onTapAssignment,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner (Color Gradient + Subject + Teacher)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              className,
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              teacherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Teacher Circular Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      teacherInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: SON TAPŞIRIQLAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SON TAPŞIRIQLAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: palette.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                if (latestAssignments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.coffee_rounded, size: 14, color: palette.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          'Son tapşırıq yoxdur',
                          style: TextStyle(fontSize: 12, color: palette.textTertiary, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  )
                else
                  for (final asg in latestAssignments) ...[
                    InkWell(
                      onTap: () {
                        if (asg is Map) {
                          onTapAssignment(Map<String, dynamic>.from(asg));
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.5),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 14, color: palette.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                asg['title']?.toString() ?? 'Tapşırıq',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              asg['due_date']?.toString() ?? '',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: palette.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),

          // Footer: HAMISI BUTTON
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: palette.borderHairline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.format_list_bulleted_rounded, size: 13, color: Color(0xFF1A73E8)),
                        const SizedBox(width: 5),
                        const Text(
                          'Hamısı',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A73E8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF1A73E8)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. FILTER CHIP
// ==========================================
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A73E8) : palette.surface1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1A73E8) : palette.borderHairline,
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
              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.22) : palette.surface3,
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

// ==========================================
// 4. DETAILED TIMELINE ASSIGNMENT CARD
// ==========================================
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
      borderRadius: 16,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3.5,
            decoration: BoxDecoration(
              color: subjectColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(subjectIcon, size: 16, color: subjectColor),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                const SizedBox(height: 9),
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
                    _stripHtml(assignment.instructions),
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
                  const SizedBox(height: 8),
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
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(height: 1, color: palette.borderHairline),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isOverdue ? AppColors.danger : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Son tarix: ${DateFormat('dd.MM.yyyy • HH:mm').format(assignment.dueDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isOverdue ? AppColors.danger : colorScheme.onSurfaceVariant,
                          fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (assignment.attachments.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.surface2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file_rounded, size: 10, color: palette.textSecondary),
                            const SizedBox(width: 2),
                            Text(
                              '${assignment.attachments.length}',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
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

String _stripHtml(String text) {
  return RichHtmlView.stripToPlain(text);
}
