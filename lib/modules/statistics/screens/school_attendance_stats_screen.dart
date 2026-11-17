import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';

class SchoolAttendanceStatsScreen extends StatefulWidget {
  const SchoolAttendanceStatsScreen({super.key});

  @override
  State<SchoolAttendanceStatsScreen> createState() => _SchoolAttendanceStatsScreenState();
}

class _SchoolAttendanceStatsScreenState extends State<SchoolAttendanceStatsScreen> {
  final List<Map<String, dynamic>> _classStats = [
    {
      'className': '10-A (Riyaziyyat Təmayüllü)',
      'totalStudents': 24,
      'presentCount': 24,
      'absentCount': 0,
      'rate': 100.0,
      'curator': 'Fatma Zalova',
    },
    {
      'className': '9-B (Humanitar Təmayüllü)',
      'totalStudents': 22,
      'presentCount': 21,
      'absentCount': 1,
      'rate': 95.5,
      'curator': 'Sevinc Məmmədova',
    },
    {
      'className': '11-A (Buraxılış & IB)',
      'totalStudents': 20,
      'presentCount': 19,
      'absentCount': 1,
      'rate': 95.0,
      'curator': 'Tural Əliyev',
    },
    {
      'className': '8-C (Ümumi Orta)',
      'totalStudents': 25,
      'presentCount': 23,
      'absentCount': 2,
      'rate': 92.0,
      'curator': 'Aynur Hüseynova',
    },
    {
      'className': '7-A (İbtidai Sonrası)',
      'totalStudents': 26,
      'presentCount': 23,
      'absentCount': 3,
      'rate': 88.5,
      'curator': 'Rəşad Quliyev',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const overallRate = 95.2;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Ümumtəhsil Davamiyyəti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          child: const Icon(Icons.co_present_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bugünkü Məktəb İştirakı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year} • Real-vaxt analizi',
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
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('$overallRate%', 'Məktəb Üzrə Orta'),
                        Container(width: 1, height: 28, color: Colors.white30),
                        _buildMetricCol('110 / 117', 'İştirak Edənlər'),
                        Container(width: 1, height: 28, color: Colors.white30),
                        _buildMetricCol('7 nəfər', 'Qayıblar (4 üzrlü)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Siniflər Üzrə Reytinq Cədvəli',
              trailing: '${_classStats.length} sinif',
            ),
            const SizedBox(height: 8),
            ..._classStats.map((item) {
              final double rate = item['rate'] as double;
              final isHigh = rate >= 95.0;

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
                                color: (isHigh ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Icon(
                                isHigh ? Icons.check_circle_outline : Icons.error_outline,
                                color: isHigh ? AppColors.success : AppColors.warning,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['className'].toString(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Kurator: ${item['curator']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: '$rate%',
                              color: isHigh ? AppColors.success : AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: rate / 100.0,
                            backgroundColor: AppColors.getBorder(context),
                            color: isHigh ? AppColors.success : AppColors.warning,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cəmi: ${item['totalStudents']} şagird',
                              style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context)),
                            ),
                            Text(
                              'İştirak: ${item['presentCount']} nəfər • Qayıb: ${item['absentCount']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextPrimary(context),
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

  Widget _buildMetricCol(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
