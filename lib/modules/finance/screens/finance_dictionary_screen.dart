import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/finance_model.dart';

class FinanceDictionaryScreen extends StatelessWidget {
  const FinanceDictionaryScreen({super.key});

  final List<FinanceCategory> _categories = const [
    FinanceCategory(
      id: 'cat-1',
      name: 'Təhsil Haqqı',
      type: 'income',
      code: 'INC-EDU',
      description: 'Şagirdlərin illik və yarımillik təhsil haqqı daxilolmaları',
    ),
    FinanceCategory(
      id: 'cat-2',
      name: 'Yeməkxana və Kafe',
      type: 'income',
      code: 'INC-FOOD',
      description: 'Məktəb yeməkxanası və kafeteriya abunəlik gəlirləri',
    ),
    FinanceCategory(
      id: 'cat-3',
      name: 'Məktəb Nəqliyyatı',
      type: 'income',
      code: 'INC-TRANS',
      description: 'Şagird servis daşınma xidməti ödənişləri',
    ),
    FinanceCategory(
      id: 'cat-4',
      name: 'Dərnək və Kurslar',
      type: 'income',
      code: 'INC-CLUB',
      description: 'Dərsdənkənar STEAM, idman və dil dərnəkləri',
    ),
    FinanceCategory(
      id: 'cat-5',
      name: 'Əməkhaqqı Fondu',
      type: 'expense',
      code: 'EXP-SALARY',
      description: 'Pedaqoji, inzibati və texniki heyətin aylıq əməkhaqqı xərcləri',
    ),
    FinanceCategory(
      id: 'cat-6',
      name: 'Kommunal və Ərazi Xidmətləri',
      type: 'expense',
      code: 'EXP-UTIL',
      description: 'Elektrik, qaz, su, istilik və təmizlik təminatı xərcləri',
    ),
    FinanceCategory(
      id: 'cat-7',
      name: 'İT və Rəqəmsal İnfrastruktur',
      type: 'expense',
      code: 'EXP-IT',
      description: 'Server hostinq, internet provayder və təhsil lisenziyaları',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Maliyyə Soraqçası (Kateqoriyalar)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const SectionHeader(
              title: 'Gəlir və Xərc Maddələri',
              subtitle: 'Sistemdə qeydiyyatdan keçən rəsmi maliyyə kateqoriyaları',
            ),
            ..._categories.map((cat) {
              final isIncome = cat.type == 'income';
              final color = isIncome ? AppColors.emerald : AppColors.rose;

              return ModernCard(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cat.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: palette.surface2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat.code,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: palette.brandRoyal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cat.description,
                            style: TextStyle(color: palette.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: isIncome ? 'Mədaxil' : 'Məxaric',
                      color: color,
                      fontSize: 10,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
