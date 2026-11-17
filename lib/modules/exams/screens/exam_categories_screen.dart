import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';

class ExamCategoriesScreen extends StatelessWidget {
  const ExamCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('İmtahan Kateqoriyaları və Şkala', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            const SectionHeader(
              title: 'Rəsmi Qiymətləndirmə Modelləri',
              subtitle: 'AR Təhsil Nazirliyi və Beynəlxalq IB Standartları',
            ),

            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Milli Kurikulum (KSQ və BSQ)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      StatusBadge(label: 'Standart', color: palette.brandRoyal),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kiçik Summativ Qiymətləndirmə (KSQ) hər bölmə sonunda keçirilir və yarımillik balın 40%-ni təşkil edir. Böyük Summativ Qiymətləndirmə (BSQ) isə yarımil sonunda 60% çəki ilə hesablanır.',
                    style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _ruleRow('KSQ Çəkisi', '40%', palette),
                  _ruleRow('BSQ Çəkisi', '60%', palette),
                  _ruleRow('Keçid Balı', '60 bal (Kafi)', palette),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Beynəlxalq IB MYP / DP Şkalası',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      StatusBadge(label: 'Beynəlxalq', color: AppColors.emerald),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'International Baccalaureate proqramı üzrə 4 əsas meyar (Criterion A, B, C, D) üzrə hər biri 1-8 bal şkalasında qiymətləndirilir və 1-7 yekun dərəcəsinə çevrilir.',
                    style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _ruleRow('Maksimal IB Dərəcəsi', '7 Bal (Əla)', palette),
                  _ruleRow('Keçid Həddi', '4 Bal', palette),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const SectionHeader(
              title: 'Bal və Hərf Şkalası',
              subtitle: '100 ballıq sistemin hərf ekvivalentləri',
            ),

            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _scaleItem('90 - 100 bal', 'A', 'Əla (5+)', AppColors.emerald, palette),
                  const Divider(height: 16),
                  _scaleItem('80 - 89 bal', 'B', 'Çox yaxşı (5)', const Color(0xFF0EA5E9), palette),
                  const Divider(height: 16),
                  _scaleItem('70 - 79 bal', 'C', 'Yaxşı (4)', AppColors.gold, palette),
                  const Divider(height: 16),
                  _scaleItem('60 - 69 bal', 'D', 'Kafi (3)', Colors.orange, palette),
                  const Divider(height: 16),
                  _scaleItem('0 - 59 bal', 'E', 'Qeyri-kafi (2)', AppColors.rose, palette),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _ruleRow(String title, String value, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _scaleItem(String range, String letter, String desc, Color color, AppPalette palette) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          range,
          style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
