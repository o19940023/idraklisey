import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/app_state.dart';
import '../../teacher/screens/teacher_student_detail_screen.dart';
import '../widgets/edit_student_sheet.dart';
import 'student_registration_screen.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedClass = 'Hamısı';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _belongsToClass(String studentClass, String className) {
    return studentClass.trim().toLowerCase() == className.trim().toLowerCase();
  }

  void _openRegistration(BuildContext context) {
    Navigator.push(
      context,
      appRoute(builder: (_) => const StudentRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final palette = AppPalette.of(context);
    final canAdd = appState.hasPermission('add_students');
    final canEdit = appState.hasPermission('edit_students');

    final students = appState.students.toList()
      ..sort((a, b) {
        final classCompare =
            a.className.toLowerCase().compareTo(b.className.toLowerCase());
        if (classCompare != 0) return classCompare;
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });
    final classes = [...appState.allDistinctClasses]..sort();
    final activeClass =
        classes.contains(_selectedClass) ? _selectedClass : null;
    final classStudents = activeClass == null
        ? students
        : students
            .where(
              (student) => _belongsToClass(student.className, activeClass),
            )
            .toList();

    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? classStudents
        : classStudents.where((student) {
            return student.fullName.toLowerCase().contains(query) ||
                student.studentNumber.toLowerCase().contains(query) ||
                (student.finCode ?? '').toLowerCase().contains(query) ||
                (student.email ?? '').toLowerCase().contains(query) ||
                student.parentName.toLowerCase().contains(query) ||
                student.parentPhone.toLowerCase().contains(query);
          }).toList();

    final subtitle = '${students.length} şagird • ${classes.length} sinif';

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _openRegistration(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
              label: const Text(
                'Şagird əlavə et',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, palette, subtitle, canAdd),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverview(palette, classStudents, classes.length),
                  const SizedBox(height: 12),
                  AppSearchBar(
                    controller: _searchCtrl,
                    hintText: 'Ad, İdrak kodu, FIN, valideyn və ya telefon...',
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() {}),
                  ),
                  if (classes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildClassFilters(
                      palette,
                      classes,
                      students,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (students.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                context,
                palette,
                icon: Icons.school_outlined,
                title: 'Hələ şagird qeydiyyatı yoxdur',
                message:
                    'İlk şagirdi əlavə etməklə kataloqu yaratmağa başlayın.',
                action: canAdd
                    ? FilledButton.icon(
                        onPressed: () => _openRegistration(context),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        label: const Text('Şagird əlavə et'),
                      )
                    : null,
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                context,
                palette,
                icon: Icons.search_off_rounded,
                title: 'Nəticə tapılmadı',
                message:
                    'Axtarış və ya sinif filtrinə uyğun şagird tapılmadı.',
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Şagirdlər',
                      style: AppTypography.title1(context).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: TextStyle(
                          color: palette.brandRoyal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      activeClass ?? 'Bütün siniflər',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStudentCard(
                    context,
                    palette,
                    filtered[index],
                    canEdit,
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    String subtitle,
    bool canAdd,
  ) {
    return SliverAppBar(
      expandedHeight: 132,
      pinned: true,
      elevation: 0,
      backgroundColor: palette.brandNavy,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      actions: [
        if (canAdd)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Yeni şagird qeydiyyatı',
              onPressed: () => _openRegistration(context),
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            final showContent = constraints.maxHeight >= 96;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07152B),
                    Color(0xFF132C5E),
                    Color(0xFF2563EB),
                  ],
                ),
              ),
              child: !showContent
                  ? const SizedBox.expand()
                  : Stack(
                      children: [
                        Positioned(
                          right: -34,
                          top: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.school_rounded,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Şagird İdarəsi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.72),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverview(
    AppPalette palette,
    List<StudentProfile> students,
    int classCount,
  ) {
    final gpas = students
        .where((student) => student.gpa > 0)
        .map((student) => student.gpa)
        .toList();
    final averageGpa = gpas.isEmpty
        ? 0.0
        : gpas.reduce((a, b) => a + b) / gpas.length;

    return StatCardRow(
      columns: 3,
      spacing: 8,
      children: [
        StatCard(
          value: '${students.length}',
          label: 'Şagird',
          icon: Icons.people_alt_rounded,
          color: palette.brandRoyal,
          compact: true,
        ),
        StatCard(
          value: '$classCount',
          label: 'Sinif',
          icon: Icons.class_rounded,
          color: const Color(0xFF0D9488),
          compact: true,
        ),
        StatCard(
          value: gpas.isEmpty ? '—' : averageGpa.toStringAsFixed(2),
          label: 'Orta GPA',
          icon: Icons.auto_graph_rounded,
          color: palette.brandGold,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildClassFilters(
    AppPalette palette,
    List<String> classes,
    List<StudentProfile> students,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final filters = ['Hamısı', ...classes];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final className in filters)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: GestureDetector(
                onTap: () => setState(() => _selectedClass = className),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedClass == className
                        ? palette.brandRoyal
                        : palette.surface1,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _selectedClass == className
                          ? palette.brandRoyal
                          : palette.borderHairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        className,
                        style: TextStyle(
                          color: _selectedClass == className
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                          fontWeight: _selectedClass == className
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedClass == className
                              ? Colors.white.withValues(alpha: 0.18)
                              : palette.surface3,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${className == 'Hamısı' ? students.length : students.where((student) => _belongsToClass(student.className, className)).length}',
                          style: TextStyle(
                            color: _selectedClass == className
                                ? Colors.white
                                : palette.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
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

  Widget _buildStudentCard(
    BuildContext context,
    AppPalette palette,
    StudentProfile student,
    bool canEdit,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasGpa = student.gpa > 0;
    final hasAttendance = student.attendanceRate > 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: () => _openStudent(context, student),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
        child: Row(
          children: [
            ModernAvatar(
              imageUrl: student.photoUrl,
              name: student.fullName,
              size: 54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.brandRoyal.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: palette.brandRoyal.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          student.className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.brandRoyal,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student.studentNumber}${(student.finCode ?? '').isNotEmpty ? ' • FIN ${student.finCode}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniStat(
                        icon: Icons.auto_graph_rounded,
                        label: hasGpa ? student.gpa.toStringAsFixed(2) : 'Yeni',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _miniStat(
                        icon: Icons.fact_check_rounded,
                        label: hasAttendance
                            ? '${student.attendanceRate}%'
                            : 'Yeni',
                        color: palette.brandRoyal,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          student.parentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit)
              IconButton(
                tooltip: 'Redaktə et',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => showEditStudentSheet(context, student),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: palette.brandRoyal,
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _openStudent(BuildContext context, StudentProfile student) {
    Navigator.push(
      context,
      appRoute(
        builder: (_) => TeacherStudentDetailScreen(
          student: student,
          adminMode: true,
          onEdit: (current) => showEditStudentSheet(context, current),
        ),
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppPalette palette, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: palette.brandRoyal.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(icon, size: 34, color: palette.brandRoyal),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
