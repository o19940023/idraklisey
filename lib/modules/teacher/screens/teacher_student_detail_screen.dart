import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/grade_model.dart';
import '../../../data/models/medical_model.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/app_state.dart';
import '../../shared/dialogs/send_notification_dialog.dart';
import 'create_assignment_screen.dart';
import 'quick_grading_screen.dart';

class TeacherStudentDetailScreen extends StatefulWidget {
  final StudentProfile student;
  final bool adminMode;
  final Future<void> Function(StudentProfile student)? onEdit;

  const TeacherStudentDetailScreen({
    super.key,
    required this.student,
    this.adminMode = false,
    this.onEdit,
  });

  @override
  State<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState extends State<TeacherStudentDetailScreen> {
  late StudentProfile _student;

  StudentProfile get student => _student;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  @override
  void didUpdateWidget(covariant TeacherStudentDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.id != widget.student.id) {
      _student = widget.student;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _student = appState.students.firstWhere(
      (item) => item.id == widget.student.id,
      orElse: () => widget.student,
    );
    final palette = AppPalette.of(context);
    final medical = appState.getMedicalCardForStudent(student.id);
    final canEditMedical = appState.hasPermission('manage_medical');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildHeader(context, palette, medical),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabHeaderDelegate(
                background: palette.surface1,
                borderColor: palette.borderHairline,
                tabBar: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: palette.brandRoyal,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  labelColor: palette.brandRoyal,
                  unselectedLabelColor: palette.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Profil'),
                    Tab(text: 'Akademik'),
                    Tab(text: 'Sağlamlıq'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildProfileTab(context, appState, palette),
              _buildAcademicTab(context, appState, palette),
              _buildHealthTab(
                context,
                appState,
                palette,
                medical,
                canEditMedical,
              ),
            ],
          ),
        ),
        bottomNavigationBar: widget.adminMode
            ? _buildAdminActionBar(context, palette)
            : _buildActionBar(context, palette),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    StudentMedicalCard medical,
  ) {
    final hasGpa = student.gpa > 0;
    final hasAttendance = student.attendanceRate > 0;
    final bloodGroup = medical.bloodGroup.trim().isEmpty
        ? 'Qeyd yoxdur'
        : medical.bloodGroup;

    return SliverAppBar(
      expandedHeight: 306,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: palette.brandNavy,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          tooltip: 'Geri',
          onPressed: () => Navigator.maybePop(context),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: LayoutBuilder(
          builder: (context, constraints) {
            final showContent = constraints.maxHeight >= 230;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07152B),
                    Color(0xFF0E3166),
                    Color(0xFF1D4ED8),
                  ],
                ),
              ),
              child: !showContent
                  ? const SizedBox.expand()
                  : Stack(
                      children: [
                        Positioned(
                          right: -48,
                          top: 34,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -34,
                          bottom: -54,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.brandAzure.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 72, 20, 18),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white
                                            .withValues(alpha: 0.16),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: ModernAvatar(
                                        imageUrl: student.photoUrl,
                                        name: student.fullName,
                                        size: 78,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              _headerPill(
                                                icon: Icons.school_rounded,
                                                label: student.className,
                                              ),
                                              Text(
                                                student.studentNumber,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.72),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _headerStat(
                                        label: 'GPA',
                                        value: hasGpa
                                            ? student.gpa.toStringAsFixed(2)
                                            : 'Yeni',
                                        icon: Icons.auto_graph_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _headerStat(
                                        label: 'Davamiyyət',
                                        value: hasAttendance
                                            ? '${student.attendanceRate}%'
                                            : 'Yeni',
                                        icon: Icons.fact_check_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _headerStat(
                                        label: 'Qan qrupu',
                                        value: bloodGroup,
                                        icon: Icons.bloodtype_rounded,
                                      ),
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

  Widget _headerPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.86)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.76)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(
    BuildContext context,
    AppState appState,
    AppPalette palette,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      key: const PageStorageKey('teacher-student-profile'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const SectionHeader(
          title: 'Şəxsi məlumatlar',
          padding: EdgeInsets.only(top: 12, bottom: 8),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              _infoRow('Ad, Soyad', student.fullName, colorScheme),
              _infoDivider(palette),
              _infoRow('Ata adı', student.fatherName ?? '—', colorScheme),
              _infoDivider(palette),
              _infoRow('Cins', student.gender ?? '—', colorScheme),
              _infoDivider(palette),
              _infoRow('Doğum tarixi', _formatDate(student.birthDate), colorScheme),
              _infoDivider(palette),
              _infoRow('FIN kod', student.finCode ?? '—', colorScheme),
              _infoDivider(palette),
              _infoRow('Şagird kodu', student.studentNumber, colorScheme),
              _infoDivider(palette),
              _infoRow('Təhsil ili', student.academicYear, colorScheme),
              _infoDivider(palette),
              _infoRow('E-poçt', student.email ?? '—', colorScheme),
              _infoDivider(palette),
              _infoRow('Ünvan', student.address ?? '—', colorScheme),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Valideyn / Qəyyum',
          padding: EdgeInsets.only(top: 20, bottom: 8),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.brandGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: palette.brandGold,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.parentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title1(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rəsmi qəyyum',
                          style: AppTypography.caption1(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _infoRow('Telefon', student.parentPhone, colorScheme, dense: true),
              if (student.parentEmail != null &&
                  student.parentEmail!.trim().isNotEmpty) ...[
                _infoDivider(palette),
                _infoRow(
                  'E-poçt',
                  student.parentEmail!,
                  colorScheme,
                  dense: true,
                ),
              ],
              if (student.parentAddress != null &&
                  student.parentAddress!.trim().isNotEmpty) ...[
                _infoDivider(palette),
                _infoRow(
                  'Ünvan',
                  student.parentAddress!,
                  colorScheme,
                  dense: true,
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          SendNotificationDialog(directStudent: student),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 17),
                  label: const Text('Valideynə bildiriş göndər'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicTab(
    BuildContext context,
    AppState appState,
    AppPalette palette,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final teacherSubject =
        appState.currentUser?.subject?.trim().toLowerCase() ?? '';
    final allGrades = appState.grades
        .where((g) => g.studentId == student.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final subjectGrades = teacherSubject.isEmpty
        ? allGrades
        : allGrades
            .where((g) => g.subject.toLowerCase().contains(teacherSubject))
            .toList();

    double averageOf(List<GradeRecord> grades) {
      if (grades.isEmpty) return 0;
      return grades.map((g) => g.percentage).reduce((a, b) => a + b) /
          grades.length;
    }

    final subjectAverage = averageOf(subjectGrades);

    return ListView(
      key: const PageStorageKey('teacher-student-academic'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const SectionHeader(
          title: 'Akademik göstəricilər',
          padding: EdgeInsets.only(top: 12, bottom: 8),
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: _metricTile(
                  context,
                  icon: Icons.workspace_premium_rounded,
                  label: 'Ümumi GPA',
                  value: student.gpa > 0
                      ? student.gpa.toStringAsFixed(2)
                      : 'Yeni',
                  color: palette.brandRoyal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile(
                  context,
                  icon: Icons.fact_check_rounded,
                  label: 'Davamiyyət',
                  value: student.attendanceRate > 0
                      ? '${student.attendanceRate}%'
                      : 'Yeni',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile(
                  context,
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Qiymət sayı',
                  value: '${allGrades.length}',
                  color: palette.brandGold,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          title: teacherSubject.isEmpty
              ? 'Bütün qiymətlər'
              : 'Sizin fənniniz',
          subtitle: teacherSubject.isEmpty
              ? null
              : '${appState.currentUser?.subject ?? ''} • ${subjectGrades.length} qiymət',
          trailing: subjectGrades.isEmpty
              ? null
              : StatusBadge(
                  label: '${subjectAverage.toStringAsFixed(1)} bal',
                  color: palette.brandRoyal,
                  fontSize: 10.5,
                ),
          padding: const EdgeInsets.only(top: 20, bottom: 8),
        ),
        if (allGrades.isEmpty)
          _emptyCard(
            context,
            palette,
            icon: Icons.assessment_outlined,
            title: 'Hələ qiymət yoxdur',
            message:
                'Bu şagird üzrə qiymət qeydi yaradılanda burada görünəcək.',
          )
        else if (subjectGrades.isEmpty)
          _emptyCard(
            context,
            palette,
            icon: Icons.filter_alt_off_rounded,
            title: 'Bu fənn üzrə qiymət yoxdur',
            message:
                'Şagirdin digər fənlər üzrə ${allGrades.length} qiyməti mövcuddur.',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < subjectGrades.length && i < 12; i++) ...[
                  if (i > 0) _infoDivider(palette),
                  _gradeRow(
                    context,
                    palette,
                    colorScheme,
                    subjectGrades[i],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _gradeRow(
    BuildContext context,
    AppPalette palette,
    ColorScheme colorScheme,
    GradeRecord grade,
  ) {
    final score = grade.displayScore;
    final maxScore = grade.maxScore;
    final percent = grade.percentage;
    final scoreColor = percent >= 81
        ? AppColors.success
        : percent >= 61
            ? palette.brandRoyal
            : percent >= 31
                ? palette.brandGold
                : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                grade.gradeLetter,
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${grade.subject} • ${grade.type.displayName} • ${_formatDate(grade.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
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
              color: scoreColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${score.toStringAsFixed(0)} / ${maxScore.toStringAsFixed(0)}',
              style: TextStyle(
                color: scoreColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab(
    BuildContext context,
    AppState appState,
    AppPalette palette,
    StudentMedicalCard medical,
    bool canEditMedical,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bloodGroup = medical.bloodGroup.trim().isEmpty
        ? 'Qeyd yoxdur'
        : medical.bloodGroup;

    return ListView(
      key: const PageStorageKey('teacher-student-health'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        SectionHeader(
          title: 'Fiziki inkişaf & BMI',
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          trailing: canEditMedical
              ? TextButton.icon(
                  onPressed: () => _showPhysicalStatsDialog(context, appState, medical),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Redaktə'),
                )
              : null,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _healthMetric(
                      context,
                      label: 'Boy',
                      value: medical.heightCm > 0
                          ? '${medical.heightCm.toInt()} sm'
                          : '—',
                      color: palette.brandRoyal,
                    ),
                  ),
                  _verticalDivider(palette),
                  Expanded(
                    child: _healthMetric(
                      context,
                      label: 'Çəki',
                      value: medical.weightKg > 0
                          ? '${medical.weightKg.toInt()} kq'
                          : '—',
                      color: palette.brandAzure,
                    ),
                  ),
                  _verticalDivider(palette),
                  Expanded(
                    child: _healthMetric(
                      context,
                      label: 'Qan qrupu',
                      value: bloodGroup,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: medical.bmiColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: medical.bmiColor.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 18,
                      color: medical.bmiColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BMI: ${medical.bmiDisplay} • ${medical.bmiCategory}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: medical.bmiColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (medical.bmiWarning != null) ...[
                const SizedBox(height: 8),
                Text(
                  medical.bmiWarning!,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (medical.chronicConditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: medical.chronicConditions
                      .map(
                        (condition) => StatusBadge(
                          label: condition,
                          color: palette.brandGold,
                          fontSize: 9.5,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        SectionHeader(
          title: 'Allergiyalar',
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          trailing: canEditMedical
              ? TextButton.icon(
                  onPressed: () => _showAddAllergyDialog(context, appState),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Əlavə et'),
                )
              : null,
        ),
        if (medical.allergies.isEmpty)
          _emptyCard(
            context,
            palette,
            icon: Icons.verified_user_outlined,
            title: 'Allergiya qeydi yoxdur',
            message: 'Şagird üzrə allergiya və ya tibbi qeyd daxil edilməyib.',
          )
        else
          ...medical.allergies.map(
            (allergy) => AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              color: AppColors.danger.withValues(alpha: 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                allergy.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            StatusBadge(
                              label: allergy.severity,
                              color: AppColors.danger,
                              fontSize: 9,
                            ),
                          ],
                        ),
                        if (allergy.reaction.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Reaksiya: ${allergy.reaction}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (allergy.firstAid.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'İlk yardım: ${allergy.firstAid}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        SectionHeader(
          title: 'Peyvənd tarixçəsi',
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          trailing: canEditMedical
              ? TextButton.icon(
                  onPressed: () => _showAddVaccineDialog(context, appState),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Əlavə et'),
                )
              : null,
        ),
        if (medical.vaccineHistory.isEmpty)
          _emptyCard(
            context,
            palette,
            icon: Icons.vaccines_outlined,
            title: 'Peyvənd qeydi yoxdur',
            message: 'Peyvənd məlumatı daxil edilməyib.',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < medical.vaccineHistory.length; i++) ...[
                  if (i > 0) _infoDivider(palette),
                  _vaccineRow(
                    context,
                    palette,
                    colorScheme,
                    medical.vaccineHistory[i],
                  ),
                ],
              ],
            ),
          ),
        if (medical.parentNotes.isNotEmpty) ...[
          const SectionHeader(
            title: 'Valideyn qeydləri',
            padding: EdgeInsets.only(top: 20, bottom: 8),
          ),
          ...medical.parentNotes.map(
            (note) => AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              color: palette.brandGold.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.parentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: palette.brandGold,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(note.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.note,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _vaccineRow(
    BuildContext context,
    AppPalette palette,
    ColorScheme colorScheme,
    VaccineRecord vaccine,
  ) {
    final isDone = vaccine.status == 'Tamamlandı';
    final color = isDone ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.vaccines_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${vaccine.doctor} • ${_formatDate(vaccine.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          StatusBadge(label: vaccine.status, color: color, fontSize: 9),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool dense = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 7 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider(AppPalette palette) {
    return Divider(height: 1, thickness: 1, color: palette.borderHairline);
  }

  Widget _verticalDivider(AppPalette palette) {
    return Container(
      width: 1,
      height: 34,
      color: palette.borderHairline,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(
    BuildContext context,
    AppPalette palette, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.brandRoyal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: palette.brandRoyal),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionBar(
    BuildContext context,
    AppPalette palette,
  ) {
    if (widget.onEdit == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        border: Border(top: BorderSide(color: palette.borderHairline)),
        boxShadow: AppShadows.adaptiveModal(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandRoyal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => widget.onEdit!(student),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Şagirdi redaktə et'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.brandRoyal,
                    side: BorderSide(
                      color: palette.brandRoyal.withValues(alpha: 0.34),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          SendNotificationDialog(directStudent: student),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: const Text('Bildiriş'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, AppPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        border: Border(top: BorderSide(color: palette.borderHairline)),
        boxShadow: AppShadows.adaptiveModal(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandRoyal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QuickGradingScreen(preSelectedStudent: student),
                      ),
                    );
                  },
                  icon: const Icon(Icons.grade_rounded, size: 18),
                  label: const Text('Qiymətləndir'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.brandRoyal,
                    side: BorderSide(color: palette.brandRoyal.withValues(alpha: 0.34)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateAssignmentScreen(preSelectedStudent: student),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Tapşırıq'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhysicalStatsDialog(
    BuildContext context,
    AppState appState,
    StudentMedicalCard card,
  ) async {
    final heightCtrl = TextEditingController(
      text: card.heightCm > 0 ? '${card.heightCm.toInt()}' : '',
    );
    final weightCtrl = TextEditingController(
      text: card.weightKg > 0 ? '${card.weightKg.toInt()}' : '',
    );
    var selectedBlood =
        card.bloodGroup.isNotEmpty && card.bloodGroup != 'Məlumat yoxdur'
            ? card.bloodGroup
            : 'A(II) Rh+';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Fiziki və tibbi göstəricilər',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Boy (sm)',
                        hintText: 'Məs: 160',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Çəki (kq)',
                        hintText: 'Məs: 52',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBlood,
                      decoration: const InputDecoration(labelText: 'Qan qrupu'),
                      items: const [
                        'A(II) Rh+',
                        'A(II) Rh-',
                        'B(III) Rh+',
                        'B(III) Rh-',
                        'AB(IV) Rh+',
                        'AB(IV) Rh-',
                        'O(I) Rh+',
                        'O(I) Rh-',
                      ]
                          .map(
                            (bg) => DropdownMenuItem(value: bg, child: Text(bg)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedBlood = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Ləğv et'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final height =
                        double.tryParse(heightCtrl.text.trim()) ?? 0.0;
                    final weight =
                        double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                    appState.updateStudentPhysicalStats(
                      studentId: student.id,
                      heightCm: height,
                      weightKg: weight,
                      bloodGroup: selectedBlood,
                    );
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Yadda saxla'),
                ),
              ],
            );
          },
        );
      },
    );

    heightCtrl.dispose();
    weightCtrl.dispose();

    if (result == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Boy, çəki və qan qrupu yeniləndi.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showAddAllergyDialog(
    BuildContext context,
    AppState appState,
  ) async {
    final nameCtrl = TextEditingController();
    final reactionCtrl = TextEditingController();
    final firstAidCtrl = TextEditingController();
    var severity = 'Yüksək dərəcə';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Allergiya / tibbi qeyd',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Allergiya / qeyd',
                        hintText: 'Məs: Fındıq',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: severity,
                      decoration: const InputDecoration(
                        labelText: 'Təhlükə dərəcəsi',
                      ),
                      items: const ['Orta dərəcə', 'Yüksək dərəcə', 'Kritik']
                          .map(
                            (item) =>
                                DropdownMenuItem(value: item, child: Text(item)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => severity = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reactionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reaksiya',
                        hintText: 'Məs: Dəri səpgisi',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: firstAidCtrl,
                      decoration: const InputDecoration(
                        labelText: 'İlk yardım qeydi',
                        hintText: 'Məs: Antihistamin verilməlidir',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Ləğv et'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    appState.addAllergyToStudent(
                      student.id,
                      AllergyItem(
                        name: nameCtrl.text.trim(),
                        severity: severity,
                        reaction: reactionCtrl.text.trim().isEmpty
                            ? 'Allergik reaksiya'
                            : reactionCtrl.text.trim(),
                        firstAid: firstAidCtrl.text.trim().isEmpty
                            ? 'Tibb otağına məlumat verilsin'
                            : firstAidCtrl.text.trim(),
                      ),
                    );
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Əlavə et'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    reactionCtrl.dispose();
    firstAidCtrl.dispose();

    if (result == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Tibbi qeyd əlavə edildi.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showAddVaccineDialog(
    BuildContext context,
    AppState appState,
  ) async {
    final nameCtrl = TextEditingController(
      text: 'QPM (Qızılca, Parotit, Məxmərək)',
    );
    final doctorCtrl = TextEditingController(
      text: 'Dr. Əliyeva N. (Məktəb Tibb Otağı)',
    );
    var status = 'Tamamlandı';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'Peyvənd / vaksina qeydi',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Peyvəndin adı',
                        hintText: 'Məs: Hepatit B, QPM',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Vuruluş statusu',
                      ),
                      items: const [
                        'Tamamlandı',
                        'Növbəti doza gözlənilir',
                        'Müddəti çatıb',
                      ]
                          .map(
                            (item) =>
                                DropdownMenuItem(value: item, child: Text(item)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: doctorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Həkim / tibb müəssisəsi',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Ləğv et'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    appState.addVaccineRecordToStudent(
                      student.id,
                      VaccineRecord(
                        name: nameCtrl.text.trim(),
                        date: DateTime.now(),
                        status: status,
                        doctor: doctorCtrl.text.trim().isEmpty
                            ? 'Məktəb Tibb Otağı'
                            : doctorCtrl.text.trim(),
                      ),
                    );
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Yadda saxla'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    doctorCtrl.dispose();

    if (result == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Peyvənd qeydi əlavə edildi.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color background;
  final Color borderColor;

  _TabHeaderDelegate({
    required this.tabBar,
    required this.background,
    required this.borderColor,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      alignment: Alignment.center,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar ||
        oldDelegate.background != background ||
        oldDelegate.borderColor != borderColor;
  }
}
