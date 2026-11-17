import '../../../core/services/school_api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/finance_model.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  String _selectedMonth = 'Oktyabr 2026';

  @override
  void initState() {
    super.initState();
    _loadRealPayroll();
  }

  Future<void> _loadRealPayroll() async {
    final rows = await SchoolApiService.instance.fetchContracts();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _payrollItems
          ..clear()
          ..addAll(rows.take(100).map((r) {
            final gross = (r['grossSalary'] as num?)?.toDouble() ?? 1200.0;
            final net = (r['netSalary'] as num?)?.toDouble() ?? (gross * 0.875);
            return PayrollItem(
              id: 'pay-${r['id']}',
              employeeId: r['employeeId']?.toString() ?? '',
              employeeName: r['employeeName']?.toString() ?? 'Əməkdaş',
              position: r['position']?.toString() ?? 'Vəzifə',
              month: _selectedMonth,
              grossSalary: gross,
              netSalary: net,
              taxAmount: 0.0,
              dsmfAmount: double.parse((gross * 0.10).toStringAsFixed(2)),
              insuranceAmount: double.parse((gross * 0.025).toStringAsFixed(2)),
              bonusAmount: 0.0,
              status: r['status'] == 'active' ? 'paid' : 'pending',
              paidDate: DateTime.now(),
            );
          }));
      });
    }
  }

  final List<String> _months = [
    'Oktyabr 2026',
    'Sentyabr 2026',
    'Avqust 2026',
    'İyul 2026',
  ];

  final List<PayrollItem> _payrollItems = [
    PayrollItem(
      id: 'pay-1',
      employeeId: 'emp-1',
      employeeName: 'Fatma Zalova',
      position: 'İngilis dili kafedra müdiri',
      month: 'Oktyabr 2026',
      grossSalary: 2100.0,
      netSalary: 1845.0,
      taxAmount: 0.0,
      dsmfAmount: 196.0,
      insuranceAmount: 42.0,
      bonusAmount: 150.0,
      status: 'paid',
      paidDate: DateTime(2026, 10, 31),
    ),
    PayrollItem(
      id: 'pay-2',
      employeeId: 'emp-32',
      employeeName: 'Gülnarə Səlimova',
      position: 'İT Rəhbəri',
      month: 'Oktyabr 2026',
      grossSalary: 1850.0,
      netSalary: 1625.0,
      taxAmount: 0.0,
      dsmfAmount: 171.0,
      insuranceAmount: 37.0,
      bonusAmount: 200.0,
      status: 'paid',
      paidDate: DateTime(2026, 10, 31),
    ),
    PayrollItem(
      id: 'pay-3',
      employeeId: 'emp-97',
      employeeName: 'Gülnarə İbrahimova',
      position: 'Alman dili müəllimi',
      month: 'Oktyabr 2026',
      grossSalary: 1420.0,
      netSalary: 1250.0,
      taxAmount: 0.0,
      dsmfAmount: 128.0,
      insuranceAmount: 28.4,
      bonusAmount: 0.0,
      status: 'paid',
      paidDate: DateTime(2026, 10, 31),
    ),
    PayrollItem(
      id: 'pay-4',
      employeeId: 'emp-180',
      employeeName: 'Gülnarə Fətiyeva',
      position: 'Aparıcı Mühasib',
      month: 'Oktyabr 2026',
      grossSalary: 1600.0,
      netSalary: 1405.0,
      taxAmount: 0.0,
      dsmfAmount: 146.0,
      insuranceAmount: 32.0,
      bonusAmount: 100.0,
      status: 'paid',
      paidDate: DateTime(2026, 10, 31),
    ),
    PayrollItem(
      id: 'pay-5',
      employeeId: 'emp-365',
      employeeName: 'Ramiz Mehdiyev',
      position: 'Baş İT Mütəxəssis',
      month: 'Oktyabr 2026',
      grossSalary: 1950.0,
      netSalary: 1715.0,
      taxAmount: 0.0,
      dsmfAmount: 181.0,
      insuranceAmount: 39.0,
      bonusAmount: 250.0,
      status: 'pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final totalGross = _payrollItems.fold<double>(0.0, (acc, p) => acc + p.grossSalary);
    final totalNet = _payrollItems.fold<double>(0.0, (acc, p) => acc + p.netSalary);
    final totalTaxes = _payrollItems.fold<double>(
        0.0, (acc, p) => acc + (p.taxAmount + p.dsmfAmount + p.insuranceAmount));

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Əməkhaqqı Fondu və Cədvəli', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Month Selector
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.borderHairline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hesabat Dövrü:',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      style: TextStyle(
                        color: palette.brandRoyal,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                      items: _months
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Payroll Totals Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard('Ümumi Fond (Gross)', '${totalGross.toInt()} AZN', palette.brandRoyal, palette),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard('Xalis Ödəniş (Net)', '${totalNet.toInt()} AZN', AppColors.emerald, palette),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard('İcbari Tutulma', '${totalTaxes.toInt()} AZN', AppColors.gold, palette),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SectionHeader(
              title: 'İşçi Maaş Cədvəli',
              subtitle: '${_payrollItems.length} əməkdaş üzrə ödəniş hesabatı',
            ),

            // Payroll list
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _payrollItems.length,
                itemBuilder: (context, index) {
                  final p = _payrollItems[index];
                  return ModernCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p.employeeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            StatusBadge(
                              label: p.isPaid ? 'Ödənilib' : 'Gözləmədə',
                              color: p.isPaid ? AppColors.emerald : AppColors.gold,
                              fontSize: 11,
                            ),
                          ],
                        ),
                        Text(
                          p.position,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gross Maaş',
                                    style: TextStyle(color: palette.textTertiary, fontSize: 11),
                                  ),
                                  Text(
                                    '${p.grossSalary.toStringAsFixed(2)} AZN',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (p.bonusAmount > 0)
                                Column(
                                  children: [
                                    Text(
                                      'Mükafat',
                                      style: TextStyle(color: palette.textTertiary, fontSize: 11),
                                    ),
                                    Text(
                                      '+${p.bonusAmount.toStringAsFixed(2)} AZN',
                                      style: TextStyle(color: palette.brandAzure, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Xalis (Net)',
                                    style: TextStyle(color: palette.textTertiary, fontSize: 11),
                                  ),
                                  Text(
                                    '${p.netSalary.toStringAsFixed(2)} AZN',
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Widget _statCard(String label, String value, Color color, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
