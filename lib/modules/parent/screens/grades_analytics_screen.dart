import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_state.dart';
import '../../../data/models/grade_model.dart';
import '../../../core/utils/navigation_utils.dart';

class GradesAnalyticsScreen extends StatefulWidget {
  const GradesAnalyticsScreen({super.key});

  @override
  State<GradesAnalyticsScreen> createState() => _GradesAnalyticsScreenState();
}

class _GradesAnalyticsScreenState extends State<GradesAnalyticsScreen> {
  AssessmentType? _selectedFilter;
  int _selectedChartType = 0; // 0: Line Chart, 1: Bar Chart

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;

    final studentGrades = (appState.currentRole == UserRole.student || appState.currentRole == UserRole.parent)
        ? appState.grades.where((g) => g.studentId == currentStudent.id).toList()
        : appState.grades;

    final filteredGrades = _selectedFilter == null
        ? studentGrades
        : studentGrades.where((g) => g.type == _selectedFilter).toList();

    double avgScore = 0;
    if (studentGrades.isNotEmpty) {
      final pcts = studentGrades.map((g) => g.percentage).toList();
      avgScore = (pcts.reduce((a, b) => a + b) / pcts.length).clamp(0.0, 100.0);
    }

    final calculatedGpa = ((avgScore / 100.0) * 5.0).clamp(0.0, 5.0);
    final gpaValue = currentStudent.gpa > 0 && currentStudent.gpa <= 5.0
        ? currentStudent.gpa
        : calculatedGpa;

    // Calculate KSQ vs BSQ averages
    final ksqGrades = studentGrades.where((g) => g.type == AssessmentType.ksq).toList();
    final bsqGrades = studentGrades.where((g) => g.type == AssessmentType.bsq).toList();
    final ksqAvg = ksqGrades.isNotEmpty
        ? (ksqGrades.map((g) => g.percentage).reduce((a, b) => a + b) / ksqGrades.length)
        : 0.0;
    final bsqAvg = bsqGrades.isNotEmpty
        ? (bsqGrades.map((g) => g.percentage).reduce((a, b) => a + b) / bsqGrades.length)
        : 0.0;

    // Subject breakdown
    final Map<String, List<double>> subjectScores = {};
    for (final g in studentGrades) {
      final subj = g.subject.trim();
      if (subj.isNotEmpty) {
        subjectScores.putIfAbsent(subj, () => []).add(g.percentage);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.currentRole == UserRole.admin
                  ? 'Ümumi Məktəb Qiymətləri'
                  : 'Akademik Göstəricilər & GPA',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white, letterSpacing: -0.3),
            ),
            Text(
              '${currentStudent.fullName} • ${currentStudent.className} Sinfi',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5, color: Colors.white.withAlpha(200)),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Executive Academic Hero Card ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF1E3A8A),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Radial Score Ring
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 3),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                avgScore > 0 ? avgScore.toStringAsFixed(1) : '0',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Text(
                                'BAL / 100',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ümumi Akademik GPA',
                              style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  gpaValue.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '/ 5.00',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (gpaValue >= 4.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                gpaValue >= 4.5 ? '🏆 Əlaçı Şagird (A+)' : (gpaValue >= 3.5 ? '⭐ Yaxşı Tərəqqi' : '📈 İnkişaf Mərhələsində'),
                                style: TextStyle(
                                  color: gpaValue >= 4.0 ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Container(height: 1, color: Colors.white.withAlpha(25)),
                  const SizedBox(height: 14),

                  // 3 Breakdown Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeroStatMini('KSQ Ortalaması', ksqAvg > 0 ? '${ksqAvg.toStringAsFixed(1)} Bal' : '-'),
                      Container(width: 1, height: 26, color: Colors.white.withAlpha(20)),
                      _buildHeroStatMini('BSQ Ortalaması', bsqAvg > 0 ? '${bsqAvg.toStringAsFixed(1)} Bal' : '-'),
                      Container(width: 1, height: 26, color: Colors.white.withAlpha(20)),
                      _buildHeroStatMini('Qeydlər', '${studentGrades.length} Ədəd'),
                    ],
                  ),
                ],
              ),
            ),

            if (studentGrades.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.insights_rounded, size: 48, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hələlik qiymət daxil edilməyib',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Müəllimlər tərəfindən KSQ, BSQ və cari qiymətlər daxil edildikcə burada qrafiklər və hesabatlar görünəcək.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

            if (studentGrades.isNotEmpty) ...[
              // ── Dynamic Chart Card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tədris Dinamikası',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildToggleBtn(0, Icons.show_chart_rounded, 'Xətti'),
                              _buildToggleBtn(1, Icons.bar_chart_rounded, 'Sütunlu'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _selectedChartType == 0
                          ? _buildLineChart(studentGrades)
                          : _buildBarChart(studentGrades),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Subject Breakdown Bars ──
              if (subjectScores.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: const Text(
                    'Fənlər üzrə Müvəffəqiyyət',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: subjectScores.entries.take(5).map((entry) {
                      final subjAvg = entry.value.reduce((a, b) => a + b) / entry.value.length;
                      final isHigh = subjAvg >= 80;
                      final color = isHigh ? const Color(0xFF10B981) : (subjAvg >= 60 ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  '${subjAvg.toStringAsFixed(1)} Bal',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: (subjAvg / 100.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Bütün Qiymətlər', null),
                    _buildFilterChip('KSQ', AssessmentType.ksq),
                    _buildFilterChip('BSQ', AssessmentType.bsq),
                    _buildFilterChip('Diaqnostik', AssessmentType.diagnostic),
                    _buildFilterChip('Monitorinq', AssessmentType.monitoring),
                    _buildFilterChip('Beynəlxalq', AssessmentType.international),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Rəsmi Qiymətləndirmə Jurnalı',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Grades Records List
              ...filteredGrades.map((grade) => _buildGradeCard(context, appState, grade, currentStudent.id)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatMini(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(int index, IconData icon, String label) {
    final isSelected = _selectedChartType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AssessmentType? type) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<GradeRecord> grades) {
    final chronological = grades.reversed.toList();
    final spots = chronological.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.percentage);
    }).toList();

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (val, meta) {
                return Text(
                  '${val.toInt()}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold),
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
            color: const Color(0xFF2563EB),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF2563EB),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2563EB).withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<GradeRecord> grades) {
    final chronological = grades.reversed.toList().take(8).toList();
    final barGroups = chronological.asMap().entries.map((e) {
      final isHigh = e.value.percentage >= 80;
      final isMid = e.value.percentage >= 60;
      final barColor = isHigh ? const Color(0xFF10B981) : (isMid ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));

      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.percentage,
            color: barColor,
            width: 14,
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
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (val, meta) {
                return Text(
                  '${val.toInt()}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold),
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

  Widget _buildGradeCard(BuildContext context, AppState appState, GradeRecord grade, String currentStudentId) {
    final isHigh = grade.percentage >= 80;
    final isMid = grade.percentage >= 60;
    final badgeColor = isHigh ? const Color(0xFF10B981) : (isMid ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));
    final displayScoreStr = grade.score == grade.score.toInt() ? '${grade.score.toInt()}' : '${grade.score}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withAlpha(10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      grade.type.displayName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd.MM.yyyy').format(grade.date),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (appState.currentRole == UserRole.admin || appState.currentRole == UserRole.teacher)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'delete') {
                      _showDeleteGradeDialog(context, appState, grade, currentStudentId);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 15),
                          SizedBox(width: 8),
                          Text('Qiyməti Sil', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.subject,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      grade.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Text(
                      displayScoreStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      grade.gradeLetter,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (grade.teacherFeedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Müəllim Rəyi: "${grade.teacherFeedback}"',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF475569),
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

  void _showDeleteGradeDialog(BuildContext context, AppState appState, GradeRecord grade, String currentStudentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Qiymət Qeydini Sil'),
        content: Text('"${grade.title}" (${grade.score} bal) qeydini silmək və GPA-nı yenidən hesablamaq istəyirsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ləğv et')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              appState.deleteGrade(grade.id, currentStudentId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Qiymət silindi və GPA yeniləndi!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
