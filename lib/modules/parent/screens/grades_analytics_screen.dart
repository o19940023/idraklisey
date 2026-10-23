import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/grade_model.dart';
import '../../../providers/app_state.dart';

class GradesAnalyticsScreen extends StatefulWidget {
  const GradesAnalyticsScreen({super.key});

  @override
  State<GradesAnalyticsScreen> createState() => _GradesAnalyticsScreenState();
}

class _GradesAnalyticsScreenState extends State<GradesAnalyticsScreen> {
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);

  AssessmentType? _selectedFilter;
  int _selectedChartType = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;
    final isStaff = appState.currentRole == UserRole.admin ||
        appState.currentRole == UserRole.teacher;

    final studentGrades = (appState.currentRole == UserRole.student ||
            appState.currentRole == UserRole.parent)
        ? appState.grades
            .where((g) => g.studentId == currentStudent.id)
            .toList()
        : appState.grades;

    final filteredGrades = _selectedFilter == null
        ? studentGrades
        : studentGrades.where((g) => g.type == _selectedFilter).toList();

    double avgScore = 0;
    if (studentGrades.isNotEmpty) {
      final percentages = studentGrades.map((g) => g.percentage).toList();
      avgScore = (percentages.reduce((a, b) => a + b) / percentages.length)
          .clamp(0.0, 100.0);
    }

    final calculatedGpa = ((avgScore / 100.0) * 5.0).clamp(0.0, 5.0);
    final gpaValue = currentStudent.gpa > 0 && currentStudent.gpa <= 5.0
        ? currentStudent.gpa
        : calculatedGpa;

    final ksqGrades =
        studentGrades.where((g) => g.type == AssessmentType.ksq).toList();
    final bsqGrades =
        studentGrades.where((g) => g.type == AssessmentType.bsq).toList();
    final ksqAvg = ksqGrades.isNotEmpty
        ? ksqGrades.map((g) => g.percentage).reduce((a, b) => a + b) /
            ksqGrades.length
        : 0.0;
    final bsqAvg = bsqGrades.isNotEmpty
        ? bsqGrades.map((g) => g.percentage).reduce((a, b) => a + b) /
            bsqGrades.length
        : 0.0;

    final Map<String, List<double>> subjectScores = {};
    for (final grade in studentGrades) {
      final subject = grade.subject.trim();
      if (subject.isNotEmpty) {
        subjectScores.putIfAbsent(subject, () => []).add(grade.percentage);
      }
    }

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => handleBackNavigation(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStaff ? 'Akademik göstəricilər' : 'Qiymətlər & GPA',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${currentStudent.fullName} • ${currentStudent.className} sinfi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(
              palette: palette,
              avgScore: avgScore,
              gpaValue: gpaValue,
              ksqAvg: ksqAvg,
              bsqAvg: bsqAvg,
              gradeCount: studentGrades.length,
            ),
            if (studentGrades.isEmpty)
              const AppEmptyState(
                icon: Icons.insights_rounded,
                title: 'Hələlik qiymət daxil edilməyib',
                message:
                    'Müəllimlər tərəfindən KSQ, BSQ və cari qiymətlər daxil edildikcə burada qrafiklər və hesabatlar görünəcək.',
              )
            else ...[
              const SizedBox(height: 16),
              _buildChartCard(palette, studentGrades),
              if (subjectScores.isNotEmpty) ...[
                SectionHeader(
                  title: 'Fənlər üzrə müvəffəqiyyət',
                  subtitle: 'Ən yüksək nəticə göstərən fənlər',
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                ),
                _buildSubjectBreakdown(palette, subjectScores),
              ],
              SectionHeader(
                title: 'Rəsmi qiymətləndirmə jurnalı',
                subtitle: '${filteredGrades.length} qeyd göstərilir',
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              ),
              _buildFilterChips(palette),
              const SizedBox(height: 12),
              ...filteredGrades.map(
                (grade) => _buildGradeCard(
                  context,
                  appState,
                  grade,
                  currentStudent.id,
                  isStaff,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero({
    required AppPalette palette,
    required double avgScore,
    required double gpaValue,
    required double ksqAvg,
    required double bsqAvg,
    required int gradeCount,
  }) {
    final statusColor = gpaValue >= 4.0 ? _success : _warning;
    final statusLabel = gpaValue >= 4.5
        ? 'Əlaçı şagird'
        : gpaValue >= 3.5
            ? 'Yaxşı tərəqqi'
            : 'İnkişaf mərhələsində';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1428), Color(0xFF101B33), Color(0xFF172554)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.brandRoyal.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: (avgScore.clamp(0, 100)) / 100,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          avgScore > 0 ? avgScore.toStringAsFixed(1) : '0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          'BAL / 100',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ÜMUMİ AKADEMİK GPA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          gpaValue.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ 5.00',
                          style: TextStyle(
                            color: Color(0xFF7DD3FC),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          Row(
            children: [
              _heroStat(
                'KSQ ortalaması',
                ksqAvg > 0 ? ksqAvg.toStringAsFixed(1) : '–',
                palette,
              ),
              _heroDivider(),
              _heroStat(
                'BSQ ortalaması',
                bsqAvg > 0 ? bsqAvg.toStringAsFixed(1) : '–',
                palette,
              ),
              _heroDivider(),
              _heroStat('Qeydlər', '$gradeCount', palette),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, AppPalette palette) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.46),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildChartCard(AppPalette palette, List<GradeRecord> grades) {
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.03,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tədris dinamikası',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(palette, 0, Icons.show_chart_rounded, 'Xətti'),
                    _buildToggleBtn(palette, 1, Icons.bar_chart_rounded, 'Sütun'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _selectedChartType == 0
                ? _buildLineChart(grades, palette)
                : _buildBarChart(grades, palette),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
    AppPalette palette,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedChartType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? palette.brandRoyal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : palette.textMuted,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdown(
    AppPalette palette,
    Map<String, List<double>> subjectScores,
  ) {
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        children: subjectScores.entries.take(5).map((entry) {
          final subjectAvg =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
          final color = subjectAvg >= 80
              ? _success
              : subjectAvg >= 60
                  ? palette.brandRoyal
                  : _warning;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      subjectAvg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (subjectAvg / 100.0).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: palette.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChips(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(palette, 'Bütün qiymətlər', null),
          _buildFilterChip(palette, 'KSQ', AssessmentType.ksq),
          _buildFilterChip(palette, 'BSQ', AssessmentType.bsq),
          _buildFilterChip(palette, 'Diaqnostik', AssessmentType.diagnostic),
          _buildFilterChip(palette, 'Monitorinq', AssessmentType.monitoring),
          _buildFilterChip(palette, 'Beynəlxalq', AssessmentType.international),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    AppPalette palette,
    String label,
    AssessmentType? type,
  ) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? palette.brandRoyal : palette.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? palette.brandRoyal : palette.borderHairline,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<GradeRecord> grades, AppPalette palette) {
    final chronological = grades.reversed.toList();
    final spots = chronological.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.percentage);
    }).toList();

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: palette.borderHairline,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: palette.brandRoyal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: palette.brandRoyal,
                  strokeWidth: 2,
                  strokeColor: palette.surface1,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: palette.brandRoyal.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<GradeRecord> grades, AppPalette palette) {
    final chronological = grades.reversed.toList().take(8).toList();
    final barGroups = chronological.asMap().entries.map((entry) {
      final value = entry.value.percentage;
      final color = value >= 80
          ? _success
          : value >= 60
              ? palette.brandRoyal
              : _warning;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 13,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: palette.borderHairline,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildGradeCard(
    BuildContext context,
    AppState appState,
    GradeRecord grade,
    String currentStudentId,
    bool isStaff,
  ) {
    final palette = AppPalette.of(context);
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final isHigh = grade.percentage >= 80;
    final isMid = grade.percentage >= 60;
    final badgeColor =
        isHigh ? _success : (isMid ? palette.brandRoyal : _warning);
    final displayScore =
        grade.score == grade.score.toInt() ? '${grade.score.toInt()}' : '${grade.score}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Text(
                  grade.type.displayName,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: palette.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                DateFormat('dd.MM.yyyy').format(grade.date),
                style: TextStyle(
                  fontSize: 10,
                  color: palette.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isStaff)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 17,
                    color: palette.textMuted,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteGradeDialog(
                        context,
                        appState,
                        grade,
                        currentStudentId,
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: _danger,
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Qiyməti sil',
                            style: TextStyle(color: _danger, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: palette.brandRoyal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      grade.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      displayScore,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      grade.gradeLetter,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (grade.teacherFeedback.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 13,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      grade.teacherFeedback,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteGradeDialog(
    BuildContext context,
    AppState appState,
    GradeRecord grade,
    String currentStudentId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Qiymət qeydini sil'),
        content: Text(
          '"${grade.title}" (${grade.score} bal) qeydini silmək və GPA-nı yenidən hesablamaq istəyirsiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ləğv et'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _danger),
            onPressed: () {
              appState.deleteGrade(grade.id, currentStudentId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Qiymət silindi və GPA yeniləndi.'),
                  backgroundColor: _success,
                ),
              );
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
