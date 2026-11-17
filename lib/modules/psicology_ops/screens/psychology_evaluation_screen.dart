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

class PsychologyEvaluationItem {
  final String id;
  final String studentName;
  final String className;
  final String evaluationType; // 'Qəbul Müsahibəsi', 'Dövrü Qiymətləndirmə', 'Fərdi İnkişaf Planı', 'Adaptasiya'
  final String psychologistName;
  final DateTime date;
  final double score; // 1 to 5
  final String summary;
  final String recommendations;
  final String status; // 'Normal', 'Dəstək Tələb Olunur', 'Yüksək Potensial'

  const PsychologyEvaluationItem({
    required this.id,
    required this.studentName,
    required this.className,
    required this.evaluationType,
    required this.psychologistName,
    required this.date,
    required this.score,
    required this.summary,
    required this.recommendations,
    this.status = 'Normal',
  });
}

class PsychologyEvaluationScreen extends StatefulWidget {
  const PsychologyEvaluationScreen({super.key});

  @override
  State<PsychologyEvaluationScreen> createState() => _PsychologyEvaluationScreenState();
}

class _PsychologyEvaluationScreenState extends State<PsychologyEvaluationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealPsychology();
  }

  Future<void> _loadRealPsychology() async {
    final rows = await SchoolApiService.instance.fetchPsychologyRecords();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _evaluations
          ..clear()
          ..addAll(rows.map((r) => PsychologyEvaluationItem(
            id: r['id']?.toString() ?? 'psy-1',
            studentName: r['studentName']?.toString() ?? 'Şagird',
            className: r['className']?.toString() ?? 'Məktəb üzrə',
            evaluationType: r['evaluationType']?.toString() ?? 'Psixoloji Qiymətləndirmə',
            psychologistName: r['psychologistName']?.toString() ?? 'Psixoloq',
            date: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
            score: (r['score'] as num?)?.toDouble() ?? 4.5,
            summary: r['summary']?.toString() ?? '',
            recommendations: r['recommendations']?.toString() ?? '',
            status: r['status']?.toString() ?? 'Normal',
          )));
      });
    }
  }

  final List<PsychologyEvaluationItem> _evaluations = [
    PsychologyEvaluationItem(
      id: 'psy-1',
      studentName: 'Murad Əliyev',
      className: '10-A',
      evaluationType: 'Fərdi İnkişaf Planı',
      psychologistName: 'Aytəkin Hüseynova (Məktəb Psixoloqu)',
      date: DateTime(2026, 10, 22),
      score: 4.8,
      summary: 'Liderlik qabiliyyəti və analitik təfəkkür yüksəkdir. İmtahan öncəsi stress idarəetməsi stabildir.',
      recommendations: 'Debat klubunda və beynəlxalq layihələrdə moderator kimi cəlb edilməsi tövsiyə olunur.',
      status: 'Yüksək Potensial',
    ),
    PsychologyEvaluationItem(
      id: 'psy-2',
      studentName: 'Nərgiz Qasımova',
      className: '9-B',
      evaluationType: 'Dövrü Qiymətləndirmə',
      psychologistName: 'Aytəkin Hüseynova',
      date: DateTime(2026, 10, 18),
      score: 4.2,
      summary: 'Sosial münasibətlər aktivdir, komanda işində əməkdaşlıq meyli güclüdür.',
      recommendations: 'Dərslərdə diqqət konsentrasiyasını artırmaq üçün fərdi tapşırıqlar verilsin.',
      status: 'Normal',
    ),
    PsychologyEvaluationItem(
      id: 'psy-3',
      studentName: 'Rauf Əhmədov',
      className: '1-A',
      evaluationType: 'Qəbul Müsahibəsi',
      psychologistName: 'Gülşən Məmmədova',
      date: DateTime(2026, 10, 10),
      score: 3.5,
      summary: 'Məktəb mühitinə ilkin adaptasiya dövrü keçir. Ayrılıq həyəcanı müşahidə olunur.',
      recommendations: 'Valideynlə birgə gündəlik adaptasiya dəstək saatları təşkil olunsun.',
      status: 'Dəstək Tələb Olunur',
    ),
  ];

  final List<String> _types = [
    'Hamısı',
    'Qəbul Müsahibəsi',
    'Dövrü Qiymətləndirmə',
    'Fərdi İnkişaf Planı',
  ];

  List<PsychologyEvaluationItem> get _filteredEvaluations {
    final query = _searchController.text.trim().toLowerCase();
    return _evaluations.where((item) {
      final matchesType = _selectedType == 'Hamısı' || item.evaluationType == _selectedType;
      final matchesSearch = query.isEmpty ||
          item.studentName.toLowerCase().contains(query) ||
          item.className.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportNeededCount = _evaluations.where((e) => e.status == 'Dəstək Tələb Olunur').length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Psixoloji Xidmət və Rəylər', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            ModernCard(
              gradient: LinearGradient(
                colors: [
                  AppPalette.primary.withValues(alpha: 0.85),
                  AppPalette.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Şagird Psixoloji Portfeli',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_evaluations.length} rəy qeydiyyatdadır • $supportNeededCount fərdi diqqət mərkəzində',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppSearchBar(
              hintText: 'Şagird adı, sinif və ya rəy qeydi...',
              onChanged: (_) => setState(() {}),
              controller: _searchController,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                      selectedColor: AppPalette.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppPalette.primary : AppColors.getTextSecondary(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Psixoloji Qiymətləndirmə Siyahısı',
              trailing: '${_filteredEvaluations.length} qeyd',
            ),
            const SizedBox(height: 8),
            if (_filteredEvaluations.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.psychology_outlined, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun psixoloji rəy tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredEvaluations.map((item) {
                final statusColor = switch (item.status) {
                  'Yüksək Potensial' => AppPalette.primary,
                  'Dəstək Tələb Olunur' => AppColors.warning,
                  _ => AppColors.success,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Icon(Icons.sentiment_satisfied_alt_rounded, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.studentName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.className} • ${item.evaluationType}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: item.status,
                                color: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.summary,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.getTextPrimary(context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 16, color: AppColors.getTextSecondary(context)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tövsiyə: ${item.recommendations}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.psychologistName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                              Text(
                                '${item.date.day.toString().padLeft(2, '0')}.${item.date.month.toString().padLeft(2, '0')}.${item.date.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
