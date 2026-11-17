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
import 'exam_results_screen.dart';
import 'exam_categories_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealExams();
  }

  Future<void> _loadRealExams() async {
    final rows = await SchoolApiService.instance.fetchExams();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _allExams
          ..clear()
          ..addAll(rows.map((r) => ExamItem(
            id: 'ex-${r['id']}',
            title: r['title']?.toString() ?? 'İmtahan',
            examType: r['type']?.toString() ?? 'KSQ',
            subject: r['subject']?.toString() ?? 'Ümumi Fənn',
            className: 'Bütün siniflər',
            examDate: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
            startTime: '09:30',
            durationMinutes: 60,
            room: 'İmtahan Zalı',
            maxScore: (r['maxScore'] as num?)?.toDouble() ?? 100.0,
            status: 'completed',
            instructions: 'Rəsmi GoPanel imtahan qeydiyyatı.',
          )));
      });
    }
  }

  final List<ExamItem> _allExams = [
    ExamItem(
      id: 'ex-1',
      title: 'KSQ-1: Riyaziyyat (Cəbr və Funksiyalar)',
      examType: 'KSQ',
      subject: 'Riyaziyyat',
      className: '10-A',
      examDate: DateTime(2026, 11, 10),
      startTime: '09:25',
      durationMinutes: 45,
      room: 'Otaq 302',
      maxScore: 100.0,
      status: 'upcoming',
      instructions: 'Kalkulyator istifadəsinə icazə verilmir. 20 test və 5 açıq sual.',
    ),
    ExamItem(
      id: 'ex-2',
      title: 'KSQ-1: Azərbaycan Dili və Ədəbiyyat',
      examType: 'KSQ',
      subject: 'Azərbaycan Dili',
      className: '10-A',
      examDate: DateTime(2026, 11, 12),
      startTime: '10:20',
      durationMinutes: 45,
      room: 'Otaq 204',
      maxScore: 100.0,
      status: 'upcoming',
      instructions: 'Qrammatika qaydaları və mətn üzrə oxuyub-anlama tapşırıqları.',
    ),
    ExamItem(
      id: 'ex-3',
      title: 'BSQ-1: İngilis Dili (I Yarımil Yekun)',
      examType: 'BSQ',
      subject: 'İngilis Dili',
      className: '9-B',
      examDate: DateTime(2026, 12, 22),
      startTime: '09:00',
      durationMinutes: 90,
      room: 'Akt Zalı',
      maxScore: 100.0,
      status: 'upcoming',
      instructions: 'Listening, Reading və Writing bölmələri üzrə standart BSQ testi.',
    ),
    ExamItem(
      id: 'ex-4',
      title: 'IB MYP Criterion Assessment: Physics',
      examType: 'Beynəlxalq',
      subject: 'Fizika',
      className: '10-IB',
      examDate: DateTime(2026, 10, 24),
      startTime: '11:15',
      durationMinutes: 60,
      room: 'Laboratoriya 1',
      maxScore: 100.0,
      status: 'completed',
      instructions: 'Criterion A (Knowing and understanding) və Criterion B qiymətləndirməsi.',
    ),
    ExamItem(
      id: 'ex-5',
      title: 'Məktəbdaxili Sınaq İmtahanı №2',
      examType: 'Sınaq',
      subject: 'Blok Fənləri (I Qrup)',
      className: '11-ci siniflər',
      examDate: DateTime(2026, 11, 28),
      startTime: '10:00',
      durationMinutes: 180,
      room: 'Böyük İdman Kompleksi',
      maxScore: 400.0,
      status: 'upcoming',
      instructions: 'DİM formatında 125 sual. Cavab kartları optik oxuyucu ilə yoxlanılacaq.',
    ),
  ];

  final List<String> _types = ['Hamısı', 'KSQ', 'BSQ', 'Sınaq', 'Beynəlxalq'];

  List<ExamItem> get _filteredExams {
    final query = _searchController.text.trim().toLowerCase();
    return _allExams.where((e) {
      final matchesType = _selectedType == 'Hamısı' || e.examType == _selectedType;
      final matchesSearch = query.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.subject.toLowerCase().contains(query) ||
          e.className.toLowerCase().contains(query) ||
          e.room.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showExamSheet(ExamItem exam) {
    final palette = AppPalette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.borderHairline),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.assignment_rounded, color: palette.brandRoyal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${exam.className}  •  ${exam.subject}',
                          style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              _row('İmtahan Tipi', exam.examType, palette),
              _row('Tarix və Saat', '${_formatDate(exam.examDate)} saat ${exam.startTime}', palette),
              _row('Müddət', '${exam.durationMinutes} dəqiqə', palette),
              _row('İmtahan Otağı', exam.room, palette),
              _row('Maksimal Bal', '${exam.maxScore.toInt()} bal', palette, isBold: true),
              if (exam.instructions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Təlimat: ${exam.instructions}',
                  style: TextStyle(color: palette.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExamResultsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Bu İmtahanın Nəticələrinə Keç'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, AppPalette palette, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final exams = _filteredExams;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('İmtahanlar Cədvəli', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Nəticələr',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExamResultsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Qaydalar və Şkala',
            icon: const Icon(Icons.rule_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExamCategoriesScreen()),
            ),
          ),
        ],),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'Fənn, sinif və ya otaq ilə axtar...',
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),

            // Exam Type Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final t = _types[index];
                  final isSelected = t == _selectedType;
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = t);
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
              title: 'Təqvimdəki İmtahanlar',
              subtitle: '${exams.length} imtahan sessiyası qeydə alınıb',
            ),

            // List
            Expanded(
              child: exams.isEmpty
                  ? Center(
                      child: Text(
                        'Axtarışa uyğun imtahan tapılmadı',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: exams.length,
                      itemBuilder: (context, index) {
                        final ex = exams[index];
                        final isUpcoming = ex.isUpcoming;

                        return ModernCard(
                          onTap: () => _showExamSheet(ex),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StatusBadge(
                                    label: ex.examType,
                                    color: palette.brandRoyal,
                                    fontSize: 11,
                                  ),
                                  Text(
                                    '${_formatDate(ex.examDate)}  •  ${ex.startTime}',
                                    style: TextStyle(
                                      color: palette.brandAzure,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ex.title,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sinif: ${ex.className}  •  Otaq: ${ex.room}  •  ${ex.durationMinutes} dəq',
                                style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Maksimal: ${ex.maxScore.toInt()} bal',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  StatusBadge(
                                    label: isUpcoming ? 'Planlaşdırılıb' : 'Keçirilib',
                                    color: isUpcoming ? AppColors.gold : AppColors.emerald,
                                    fontSize: 10,
                                  ),
                                ],
                              ),
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
}
