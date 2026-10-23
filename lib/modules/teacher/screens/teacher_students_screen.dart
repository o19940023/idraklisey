import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/app_state.dart';
import 'create_assignment_screen.dart';
import 'teacher_student_detail_screen.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedClass = 'Hamısı';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _belongsToClass(String studentClass, String assignedClass) {
    return studentClass.trim().toLowerCase() ==
        assignedClass.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final palette = AppPalette.of(context);

    final teacherClasses = appState.currentTeacherClasses
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final scopedStudents = appState.students
        .where(
          (student) => teacherClasses.any(
            (className) => _belongsToClass(student.className, className),
          ),
        )
        .toList()
      ..sort((a, b) {
        final classCompare =
            a.className.toLowerCase().compareTo(b.className.toLowerCase());
        if (classCompare != 0) return classCompare;
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });

    final activeClass = teacherClasses.length <= 1
        ? (teacherClasses.isEmpty ? null : teacherClasses.first)
        : (teacherClasses.contains(_selectedClass) ? _selectedClass : null);

    final classStudents = activeClass == null
        ? scopedStudents
        : scopedStudents
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
                student.parentName.toLowerCase().contains(query);
          }).toList();

    final subtitle = teacherClasses.isEmpty
        ? 'Sinif təyinatı gözlənilir'
        : teacherClasses.length == 1
            ? '${teacherClasses.first} • ${scopedStudents.length} şagird'
            : '${teacherClasses.length} sinif • ${scopedStudents.length} şagird';

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, palette, subtitle),
          if (teacherClasses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                context,
                palette,
                icon: Icons.class_outlined,
                title: 'Sizə sinif təyin edilməyib',
                message:
                    'Şagird kataloqu yalnız sizə təyin olunmuş siniflər üçün açılır.\n'
                    'Sinif təyinatı üçün məktəb rəhbərliyinə müraciət edin.',
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverview(
                      context,
                      palette,
                      classStudents,
                    ),
                    const SizedBox(height: 12),
                    AppSearchBar(
                      controller: _searchCtrl,
                      hintText: 'Ad, İdrak kodu, FIN və ya valideyn axtar...',
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                    if (teacherClasses.length > 1) ...[
                      const SizedBox(height: 12),
                      _buildClassFilters(
                        context,
                        palette,
                        teacherClasses,
                        scopedStudents,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (scopedStudents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(
                  context,
                  palette,
                  icon: Icons.groups_2_outlined,
                  title: 'Təyin olunmuş sinifdə şagird yoxdur',
                  message:
                      'Şagird ${teacherClasses.join(', ')} sinfinə əlavə edildikdə\n'
                      'bu kataloqda avtomatik görünəcək.',
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
                      'Axtarışa uyğun şagird yoxdur. Fərqli ad, kod və ya FIN yoxlayın.',
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStudentCard(
                      context,
                      palette,
                      filtered[index],
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    String subtitle,
  ) {
    return SliverAppBar(
      expandedHeight: 132,
      pinned: true,
      elevation: 0,
      backgroundColor: palette.brandNavy,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Tapşırıq ver',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateAssignmentScreen(),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Icon(
                Icons.add_task_rounded,
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
                                        Icons.groups_rounded,
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
                                          'Şagirdlər Kataloqu',
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
                                            fontSize: 12,
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
    BuildContext context,
    AppPalette palette,
    List<StudentProfile> students,
  ) {
    final gpaValues =
        students.where((student) => student.gpa > 0).map((s) => s.gpa).toList();
    final attendanceValues = students
        .where((student) => student.attendanceRate > 0)
        .map((student) => student.attendanceRate)
        .toList();

    final averageGpa = gpaValues.isEmpty
        ? 0.0
        : gpaValues.reduce((a, b) => a + b) / gpaValues.length;
    final averageAttendance = attendanceValues.isEmpty
        ? 0
        : (attendanceValues.reduce((a, b) => a + b) /
                attendanceValues.length)
            .round();

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
          value: gpaValues.isEmpty ? '—' : averageGpa.toStringAsFixed(2),
          label: 'Orta GPA',
          icon: Icons.auto_graph_rounded,
          color: AppColors.success,
          compact: true,
        ),
        StatCard(
          value: attendanceValues.isEmpty ? '—' : '$averageAttendance%',
          label: 'Davamiyyət',
          icon: Icons.fact_check_rounded,
          color: palette.brandGold,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildClassFilters(
    BuildContext context,
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
        children: filters.map((className) {
          final isSelected = className == 'Hamısı'
              ? !classes.contains(_selectedClass)
              : _selectedClass == className;
          final count = className == 'Hamısı'
              ? students.length
              : students
                  .where(
                    (student) => _belongsToClass(student.className, className),
                  )
                  .length;

          return Padding(
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
                  color: isSelected ? palette.brandRoyal : palette.surface1,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
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
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : palette.surface3,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.white : palette.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    AppPalette palette,
    StudentProfile student,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasGpa = student.gpa > 0;
    final hasAttendance = student.attendanceRate > 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherStudentDetailScreen(student: student),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            ModernAvatar(
              imageUrl: student.photoUrl,
              name: student.fullName,
              size: 56,
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 7),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
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
          ],
        ),
      ),
    );
  }
}
