import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/grade_model.dart';
import '../../../l10n/app_localizations.dart';

/// Sürətli qiymətləndirmə — sinif seç → şagird seç → tez bal ver.
///
/// Dizayn: tək axın, böyük bal sahəsi və hazır bal çiplleri ilə
/// müəllim 10 saniyədə not yazır. Mantıq əvvəlki ilə eynidir.
class QuickGradingScreen extends StatefulWidget {
  final StudentProfile? preSelectedStudent;

  const QuickGradingScreen({super.key, this.preSelectedStudent});

  @override
  State<QuickGradingScreen> createState() => _QuickGradingScreenState();
}

class _QuickGradingScreenState extends State<QuickGradingScreen> {
  int _selectedAssessmentSystem = 0; // 0: AZ/RU (100 Bal / 5-lik), 1: IB MYP (1-7 Band & STR)
  StudentProfile? _selectedStudent;
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  AssessmentType _assessmentType = AssessmentType.ksq;
  String _selectedClassFilter = 'Hamısı'; // 'Hamısı' means all

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.preSelectedStudent;

    // Default class filter to teacher's first assigned class
    final appState = Provider.of<AppState>(context, listen: false);
    final teacherClasses = appState.currentTeacherClasses;
    if (teacherClasses.isNotEmpty) {
      _selectedClassFilter = teacherClasses.first;
    }
    if (widget.preSelectedStudent != null) {
      _selectedClassFilter = widget.preSelectedStudent!.className;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String _initialsOf(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Ş';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Fotoşəkili avatar; yoxdursa/yüklənmədisə baş hərflərlə gradyan.
  Widget _studentAvatar(StudentProfile student, double radius) {
    final hasPhoto = student.photoUrl.trim().isNotEmpty;
    final initials = _initialsOf(student.fullName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF564BC7),
      foregroundColor: Colors.white,
      backgroundImage: hasPhoto ? NetworkImage(student.photoUrl) : null,
      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
      child: hasPhoto
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
    );
  }

  void _applyQuickScore(double score, bool isIbSystem) {
    HapticHelper.light();
    _scoreController.text = isIbSystem
        ? score.toInt().toString()
        : score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final isIbSystem = _selectedAssessmentSystem == 1;

    // Demo məlumat axını QADAĞDIR: siyahı boşdursa saxta şagirdə not
    // yazılmasın — boş vəziyyət göstərilir.
    final allStudents = appState.students;

    // Class filtering
    final distinctClasses =
        allStudents.map((s) => s.className).toSet().toList()..sort();
    final availableStudents = _selectedClassFilter == 'Hamısı'
        ? allStudents
        : allStudents.where((s) => s.className == _selectedClassFilter).toList();

    // If selected student is not in the filtered list, reset
    if (_selectedStudent != null &&
        !availableStudents.any((s) => s.id == _selectedStudent!.id)) {
      _selectedStudent = availableStudents.isNotEmpty
          ? availableStudents.first
          : null;
    }
    final activeStudent = _selectedStudent ??
        (availableStudents.isNotEmpty ? availableStudents.first : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 122,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              onPressed: () => handleBackNavigation(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1B2E), Color(0xFF4F46E5), Color(0xFF6C5CE7)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -10,
                      child: Icon(
                        Icons.grade_rounded,
                        size: 130,
                        color: Colors.white.withAlpha(8),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 44, 20, 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.quickGrading,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      availableStudents.isEmpty
                                          ? loc.grades
                                          : '${allStudents.length} ${loc.students.toLowerCase()} • ${distinctClasses.length} sinif',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(178),
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
              ),
            ),
          ),

          if (activeStudent == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.school_rounded,
                title: loc.noResultsFound,
                message:
                    'Qiymət vermək üçün əvvəlcə şagird siyahısı yüklənməlidir.',
              ),
            )
          else ...[
            // ── Sistem seçimi: AZ/RU və IB ──
            SliverToBoxAdapter(
              child: FadeIn(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSystemToggleBtn(
                          0,
                          'AZ / RU',
                          '100 ${loc.score}',
                        ),
                      ),
                      Expanded(
                        child: _buildSystemToggleBtn(1, 'IB MYP', 'Band 1-7'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sinif çiplperi ──
            SliverToBoxAdapter(
              child: FadeIn(
                duration: const Duration(milliseconds: 380),
                delay: const Duration(milliseconds: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        '${loc.classLabel}:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildClassFilterChip('Hamısı', allStudents.length, loc.all),
                          ...distinctClasses.map((cls) {
                            final count = allStudents
                                .where((s) => s.className == cls)
                                .length;
                            return _buildClassFilterChip(cls, count, cls);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Şagird seçimi (foto + ad + işarə) ──
            SliverToBoxAdapter(
              child: FadeIn(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            '${loc.student}:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withAlpha(12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${availableStudents.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 104,
                      child: availableStudents.isEmpty
                          ? Center(
                              child: Text(
                                loc.noResultsFound,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: availableStudents.length,
                              itemBuilder: (context, index) {
                                final student = availableStudents[index];
                                final isSelected = student.id == activeStudent.id;

                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedStudent = student,
                                  ),
                                  child: PressableScale(
                                    pressedScale: 0.94,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 84,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryAccent.withAlpha(14)
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryAccent
                                              : AppColors.cardBorder,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primaryAccent
                                                      .withAlpha(30),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.primaryAccent
                                                        : Colors.transparent,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: _studentAvatar(student, 19),
                                              ),
                                              if (isSelected)
                                                Positioned(
                                                  right: -4,
                                                  bottom: -4,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(
                                                      2.5,
                                                    ),
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.primaryAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_rounded,
                                                      size: 10,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              student.fullName.split(' ').first,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.primaryAccent
                                                    : AppColors.textPrimary,
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
                ),
              ),
            ),

            // ── Aktiv şagird xülasəsi ──
            SliverToBoxAdapter(
              child: FadeIn(
                duration: const Duration(milliseconds: 380),
                delay: const Duration(milliseconds: 160),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Row(
                    children: [
                      _studentAvatar(activeStudent, 23),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeStudent.fullName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeStudent.className} • ${activeStudent.studentNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: activeStudent.gpa > 0
                            ? 'GPA ${activeStudent.gpa.toStringAsFixed(1)}'
                            : 'GPA —',
                        color: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Qiymət kartı ──
            SliverToBoxAdapter(
              child: FadeIn(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 200),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryAccent.withAlpha(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withAlpha(10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Böyük bal sahəsi
                      Center(
                        child: Column(
                          children: [
                            Text(
                              isIbSystem
                                  ? 'IB MYP BAND (1 — 7)'
                                  : '${loc.score.toUpperCase()} (0 — 100)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 170,
                              child: TextField(
                                controller: _scoreController,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                                decoration: InputDecoration(
                                  hintText: isIbSystem ? '6' : '88',
                                  hintStyle: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textMuted.withAlpha(90),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Hazır bal çiplperi — bir toxunuşla
                      Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: (isIbSystem
                              ? const [7.0, 6.0, 5.0, 4.0, 3.0]
                              : const [95.0, 85.0, 75.0, 60.0, 45.0])
                              .map((score) {
                              final active =
                                  _scoreController.text.trim() ==
                                      (isIbSystem
                                          ? score.toInt().toString()
                                          : score
                                                .toStringAsFixed(
                                                  score.truncateToDouble() ==
                                                          score
                                                      ? 0
                                                      : 1,
                                                ));
                              return GestureDetector(
                                onTap: () => _applyQuickScore(score, isIbSystem),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primaryAccent
                                        : AppColors.primaryAccent.withAlpha(10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: active
                                          ? AppColors.primaryAccent
                                          : AppColors.primaryAccent.withAlpha(30),
                                    ),
                                  ),
                                  child: Text(
                                    isIbSystem
                                        ? 'Band ${score.toInt()}'
                                        : score.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: active
                                          ? Colors.white
                                          : AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                        ),
                      ),

                      const SizedBox(height: 18),
                      Divider(color: AppColors.cardBorder, height: 1),
                      const SizedBox(height: 16),

                      // Qiymət tipi
                      Text(
                        loc.grades,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AssessmentType>(
                        initialValue: _assessmentType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: AssessmentType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _assessmentType = val);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Rəy
                      Text(
                        loc.feedback,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: loc.feedback,
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Yadda saxla
                      SizedBox(
                        width: double.infinity,
                        child: PressableScale(
                          pressedScale: 0.98,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _saveGrade(
                              context,
                              loc,
                              appState,
                              activeStudent,
                              isIbSystem,
                            ),
                            icon: const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              loc.save,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveGrade(
    BuildContext context,
    AppLocalizations loc,
    AppState appState,
    StudentProfile activeStudent,
    bool isIbSystem,
  ) async {
    final rawScoreText = _scoreController.text.trim().replaceAll(',', '.');
    if (rawScoreText.isEmpty) {
      HapticHelper.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.score} - ${loc.required}'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final parsedScore = double.tryParse(rawScoreText);
    if (parsedScore == null || parsedScore < 0) {
      HapticHelper.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (isIbSystem) {
      if (parsedScore < 1 || parsedScore > 7) {
        HapticHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IB MYP Band: 1 - 7'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    } else {
      if (parsedScore > 100) {
        HapticHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.score}: 0 - 100'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final score = parsedScore;
    final teacherSubject = appState.currentUser?.subject ?? loc.subject;

    final newGrade = GradeRecord(
      id: 'gr-${DateTime.now().millisecondsSinceEpoch}',
      studentId: activeStudent.id,
      studentName: activeStudent.fullName,
      subject: '$teacherSubject (${activeStudent.className})',
      type: _assessmentType,
      title: '${_assessmentType.displayName} Qiymətləndirməsi',
      score: score,
      maxScore: isIbSystem ? 7.0 : 100.0,
      gradeLetter: isIbSystem
          ? 'Band ${score.toInt()}'
          : (score >= 90
                ? '5 (Əla)'
                : (score >= 70
                      ? '4 (Yaxşı)'
                      : (score >= 50 ? '3 (Kafi)' : '2 (Qeyri-kafi)'))),
      date: DateTime.now(),
      teacherFeedback: _feedbackController.text.trim(),
    );

    final saved = await appState.addGrade(newGrade, activeStudent.id);
    _scoreController.clear();
    _feedbackController.clear();
    setState(() {});

    if (!context.mounted) return;
    if (saved) {
      HapticHelper.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${activeStudent.fullName} - ${loc.successfullySaved}'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      HapticHelper.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Məlumat yerli yadda saxlandı, buluda yazıla bilmədi.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Widget _buildSystemToggleBtn(int index, String title, String subtitle) {
    final isSelected = _selectedAssessmentSystem == index;
    return GestureDetector(
      onTap: () {
        HapticHelper.light();
        setState(() => _selectedAssessmentSystem = index);
        _scoreController.clear();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withAlpha(200)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassFilterChip(String cls, int count, [String? label]) {
    final isSelected = _selectedClassFilter == cls;
    final displayLabel = label ?? cls;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticHelper.light();
          setState(() {
            _selectedClassFilter = cls;
            _selectedStudent = null; // Reset student selection on class change
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryAccent : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withAlpha(180)
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
