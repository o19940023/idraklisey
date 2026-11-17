import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/statistics_model.dart';
import 'school_attendance_stats_screen.dart';

class WorkloadReportScreen extends StatefulWidget {
  const WorkloadReportScreen({super.key});

  @override
  State<WorkloadReportScreen> createState() => _WorkloadReportScreenState();
}

class _WorkloadReportScreenState extends State<WorkloadReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDept = 'Hamısı';

  final List<TeacherWorkload> _workloads = [
    TeacherWorkload(
      id: 'wl-1',
      teacherName: 'Sevinc Məmmədova',
      department: 'Azərbaycan Dili və Ədəbiyyat',
      weeklyHours: 26,
      classCount: 6,
      subjectCount: 2,
      overloadHours: 2,
      maxLoadHours: 24,
    ),
    TeacherWorkload(
      id: 'wl-2',
      teacherName: 'Fatma Zalova',
      department: 'Dəqiq Elmlər (Riyaziyyat)',
      weeklyHours: 28,
      classCount: 7,
      subjectCount: 2,
      overloadHours: 4,
      maxLoadHours: 24,
    ),
    TeacherWorkload(
      id: 'wl-3',
      teacherName: 'Rəşad Quliyev',
      department: 'Təbiət Elmləri (Fizika)',
      weeklyHours: 20,
      classCount: 5,
      subjectCount: 1,
      overloadHours: 0,
      maxLoadHours: 24,
    ),
    TeacherWorkload(
      id: 'wl-4',
      teacherName: 'Aynur Hüseynova',
      department: 'Xarici Dillər (İngilis dili)',
      weeklyHours: 22,
      classCount: 6,
      subjectCount: 2,
      overloadHours: 0,
      maxLoadHours: 24,
    ),
    TeacherWorkload(
      id: 'wl-5',
      teacherName: 'Tural Əliyev',
      department: 'İnformatika və Robototexnika',
      weeklyHours: 18,
      classCount: 4,
      subjectCount: 2,
      overloadHours: 0,
      maxLoadHours: 24,
    ),
  ];

  final List<String> _departments = [
    'Hamısı',
    'Azərbaycan Dili və Ədəbiyyat',
    'Dəqiq Elmlər (Riyaziyyat)',
    'Təbiət Elmləri (Fizika)',
    'Xarici Dillər (İngilis dili)',
    'İnformatika və Robototexnika',
  ];

  List<TeacherWorkload> get _filteredWorkloads {
    final query = _searchController.text.trim().toLowerCase();
    return _workloads.where((wl) {
      final matchesDept = _selectedDept == 'Hamısı' || wl.department == _selectedDept;
      final matchesSearch = query.isEmpty ||
          wl.teacherName.toLowerCase().contains(query) ||
          wl.department.toLowerCase().contains(query);
      return matchesDept && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWeeklyHours = _workloads.fold<int>(0, (acc, wl) => acc + wl.weeklyHours);
    final overloadedCount = _workloads.where((wl) => wl.isOverloaded).length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Dərs Yükü və Ştat Cədvəli', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Məktəb Davamiyyət Statistikası',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolAttendanceStatsScreen()),
              );
            },
          ),
        ],),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pedaqoji Yük Balansı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_workloads.length} pedaqoqun həftəlik dərs bölgüsü',
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$totalWeeklyHours saat',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Ümumi Dərs Saatı', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white30),
                          Column(
                            children: [
                              Text(
                                '$overloadedCount müəllim',
                                style: TextStyle(
                                  color: overloadedCount > 0 ? Colors.orangeAccent : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Artıq Yük (>24s)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
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
              hintText: 'Müəllim və ya kafedra axtarışı...',
              onChanged: (_) => setState(() {}),
              controller: _searchController,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _departments.map((dept) {
                  final isSelected = _selectedDept == dept;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(dept),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDept = dept);
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
              title: 'Müəllim Dərs Yükləri',
              trailing: '${_filteredWorkloads.length} pedaqoq',
            ),
            const SizedBox(height: 8),
            if (_filteredWorkloads.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun dərs yükü tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredWorkloads.map((wl) {
                final ratio = (wl.weeklyHours / wl.maxLoadHours).clamp(0.0, 1.5);

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
                                  color: AppPalette.primary.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: const Icon(Icons.person_pin_rounded, color: AppPalette.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wl.teacherName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      wl.department,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: wl.isOverloaded ? '+${wl.overloadHours}s Artıq' : 'Normal',
                                color: wl.isOverloaded ? AppColors.warning : AppColors.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Həftəlik Yük: ${wl.weeklyHours} saat / ${wl.maxLoadHours} maks',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${wl.loadPercentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: wl.isOverloaded ? AppColors.warning : AppPalette.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (ratio > 1.0 ? 1.0 : ratio),
                              backgroundColor: AppColors.getBorder(context),
                              color: wl.isOverloaded ? Colors.orange : AppPalette.primary,
                              minHeight: 6,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.class_outlined, size: 16, color: AppColors.getTextSecondary(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${wl.classCount} sinif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.menu_book, size: 16, color: AppColors.getTextSecondary(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${wl.subjectCount} fənn',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextSecondary(context),
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
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
