import '../../../core/services/school_api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/exam_model.dart';

class ExamResultsScreen extends StatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealExamResults();
  }

  Future<void> _loadRealExamResults() async {
    final rows = await SchoolApiService.instance.fetchExamResults();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _results
          ..clear()
          ..addAll(rows.map((r) => ExamResult(
            id: r['id']?.toString() ?? 'res-1',
            examId: r['examId']?.toString() ?? 'ex-1',
            examTitle: r['examTitle']?.toString() ?? 'İmtahan',
            studentId: r['studentId']?.toString() ?? '',
            studentName: r['studentName']?.toString() ?? 'Şagird',
            className: r['className']?.toString() ?? 'Sinif',
            subject: r['subject']?.toString() ?? 'Fənn',
            score: (r['score'] as num?)?.toDouble() ?? 0.0,
            maxScore: (r['maxScore'] as num?)?.toDouble() ?? 100.0,
            examDate: DateTime.tryParse(r['examDate']?.toString() ?? '') ?? DateTime.now(),
            notes: r['notes']?.toString() ?? '',
          )));
      });
    }
  }

  final List<ExamResult> _results = [
    ExamResult(
      id: 'res-1',
      examId: 'ex-1',
      examTitle: 'KSQ-1: Riyaziyyat',
      studentId: 'std-1',
      studentName: 'Murad Əliyev',
      className: '10-A',
      subject: 'Riyaziyyat',
      score: 95.0,
      maxScore: 100.0,
      examDate: DateTime(2026, 10, 20),
      notes: 'Həndəsə və funksiya bölməsində xüsusi fəallıq',
    ),
    ExamResult(
      id: 'res-2',
      examId: 'ex-1',
      examTitle: 'KSQ-1: Riyaziyyat',
      studentId: 'std-2',
      studentName: 'Aytən Məmmədova',
      className: '10-A',
      subject: 'Riyaziyyat',
      score: 88.0,
      maxScore: 100.0,
      examDate: DateTime(2026, 10, 20),
      notes: 'Bütün test tapşırıqları düzgün',
    ),
    ExamResult(
      id: 'res-3',
      examId: 'ex-2',
      examTitle: 'KSQ-1: Azərbaycan Dili',
      studentId: 'std-3',
      studentName: 'Kənan Rəhimov',
      className: '9-B',
      subject: 'Azərbaycan Dili',
      score: 74.0,
      maxScore: 100.0,
      examDate: DateTime(2026, 10, 22),
      notes: 'İnşa yazısında cüzi orfoqrafik xətalar',
    ),
    ExamResult(
      id: 'res-4',
      examId: 'ex-4',
      examTitle: 'IB MYP Physics Criterion Assessment',
      studentId: 'std-4',
      studentName: 'Dəniz Quliyeva',
      className: '10-IB',
      subject: 'Fizika',
      score: 98.0,
      maxScore: 100.0,
      examDate: DateTime(2026, 10, 24),
      notes: 'Criterion A üzrə ən yüksək nəticə',
    ),
    ExamResult(
      id: 'res-5',
      examId: 'ex-3',
      examTitle: 'BSQ-1: İngilis Dili',
      studentId: 'std-5',
      studentName: 'Leyla Həsənli',
      className: '9-A',
      subject: 'İngilis Dili',
      score: 62.0,
      maxScore: 100.0,
      examDate: DateTime(2026, 10, 18),
      notes: 'Reading hissəsi yaxşıdır, Listening təkrar edilməlidir',
    ),
  ];

  final List<String> _classes = ['Hamısı', '10-A', '9-B', '10-IB', '9-A'];

  List<ExamResult> get _filteredResults {
    final query = _searchController.text.trim().toLowerCase();
    return _results.where((r) {
      final matchesClass = _selectedClass == 'Hamısı' || r.className == _selectedClass;
      final matchesSearch = query.isEmpty ||
          r.studentName.toLowerCase().contains(query) ||
          r.examTitle.toLowerCase().contains(query) ||
          r.subject.toLowerCase().contains(query);
      return matchesClass && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return AppColors.emerald;
    if (percentage >= 80) return const Color(0xFF0EA5E9);
    if (percentage >= 70) return AppColors.gold;
    if (percentage >= 60) return Colors.orange;
    return AppColors.rose;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final results = _filteredResults;

    final avgScore = _results.isNotEmpty
        ? _results.fold<double>(0.0, (acc, r) => acc + r.score) / _results.length
        : 0.0;
    final topScore = _results.isNotEmpty
        ? _results.fold<double>(0.0, (acc, r) => r.score > acc ? r.score : acc)
        : 0.0;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('İmtahan Qiymətləndirmə Nəticələri', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Analytics Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: _statPill('Orta Bal', '${avgScore.toStringAsFixed(1)} / 100', palette.brandRoyal, palette),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statPill('Ən Yüksək Nəticə', '${topScore.toInt()} bal', AppColors.emerald, palette),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'Şagird adı və ya fənn axtar...',
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),

            // Class Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _classes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = _classes[index];
                  final isSelected = c == _selectedClass;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedClass = c);
                    },
                    selectedColor: palette.brandRoyal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : palette.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: palette.surface1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      side: BorderSide(color: isSelected ? palette.brandRoyal : palette.borderHairline),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            SectionHeader(
              title: 'Qiymətləndirmə Jurnalı',
              subtitle: '${results.length} şagird nəticəsi qeydə alınıb',
            ),

            // Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'Axtarışa uyğun nəticə tapılmadı',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final r = results[index];
                        final gradeColor = _getGradeColor(r.percentage);

                        return ModernCard(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.studentName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                        ),
                                        Text(
                                          '${r.className}  •  ${r.examTitle}',
                                          style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${r.score.toInt()} / ${r.maxScore.toInt()}',
                                        style: TextStyle(color: gradeColor, fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                      StatusBadge(
                                        label: r.gradeLetter,
                                        color: gradeColor,
                                        fontSize: 10,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: r.percentage / 100,
                                  minHeight: 6,
                                  backgroundColor: palette.surface2,
                                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                                ),
                              ),
                              if (r.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  r.notes,
                                  style: TextStyle(
                                    color: palette.textTertiary,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String title, String value, Color color, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
