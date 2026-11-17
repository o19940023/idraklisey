import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/responsive.dart';

class SalaryCalculatorScreen extends StatefulWidget {
  final double? initialGrossSalary;
  final String? employeeName;

  const SalaryCalculatorScreen({
    super.key,
    this.initialGrossSalary,
    this.employeeName,
  });

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  late final TextEditingController _grossCtrl;
  late double _grossSalary;
  bool _isPrivateSector = true; // Qeyri-neft özəl sektor (vergi güzəşti ilə)

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialGrossSalary != null && widget.initialGrossSalary! > 0)
        ? widget.initialGrossSalary!
        : 1500.0;
    _grossSalary = initial;
    _grossCtrl = TextEditingController(
      text: initial == initial.roundToDouble()
          ? initial.toStringAsFixed(0)
          : initial.toStringAsFixed(2),
    );
    _grossCtrl.addListener(() {
      final parsed = double.tryParse(_grossCtrl.text.replaceAll(',', '.')) ?? 0.0;
      setState(() => _grossSalary = parsed);
    });
  }

  @override
  void dispose() {
    _grossCtrl.dispose();
    super.dispose();
  }

  // Azərbaycan Respublikası Vergi Məcəlləsinə uyğun rəsmi hesablamalar
  double get _tax {
    if (_grossSalary <= 0) return 0.0;
    if (_isPrivateSector) {
      // Qeyri-neft özəl sektorda 8000 AZN-ə qədər gəlir vergisi 0%-dir
      if (_grossSalary <= 8000) return 0.0;
      return (_grossSalary - 8000) * 0.14;
    } else {
      // Dövlət / Neft sektoru: 2500-ə qədər 14% (çıxılsın 200 AZN güzəşt)
      final taxable = (_grossSalary - 200).clamp(0.0, double.infinity);
      if (_grossSalary <= 2500) {
        return taxable * 0.14;
      }
      return (2300 * 0.14) + ((_grossSalary - 2500) * 0.25);
    }
  }

  double get _dsmf {
    if (_grossSalary <= 0) return 0.0;
    // DSMF: 200 AZN-dək 3%, 200-dən yuxarı hissə üçün 10%
    if (_grossSalary <= 200) {
      return _grossSalary * 0.03;
    }
    return (200 * 0.03) + ((_grossSalary - 200) * 0.10);
  }

  double get _unemploymentInsurance {
    // İşsizlikdən sığorta haqqı 0.5%
    return _grossSalary * 0.005;
  }

  double get _healthInsurance {
    if (_grossSalary <= 0) return 0.0;
    // İcbari Tibbi Sığorta: 8000 AZN-dək 2%
    if (_grossSalary <= 8000) {
      return _grossSalary * 0.02;
    }
    return (8000 * 0.02) + ((_grossSalary - 8000) * 0.005);
  }

  double get _totalDeductions =>
      _tax + _dsmf + _unemploymentInsurance + _healthInsurance;

  double get _netSalary =>
      (_grossSalary - _totalDeductions).clamp(0.0, double.infinity);

  void _setQuickAmount(double amount) {
    _grossCtrl.text = amount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final empTitle = widget.employeeName?.trim() ?? '';

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maaş və Vergi Kalkulyatoru',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (empTitle.isNotEmpty)
              Text(
                empTitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        elevation: 0,
      ),
      body: ResponsiveCenter(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sector selector
              Container(
                decoration: BoxDecoration(
                  color: palette.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.borderHairline),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _sectorButton(
                        'Qeyri-Neft / Özəl (Güzəştli)',
                        _isPrivateSector,
                        () => setState(() => _isPrivateSector = true),
                        palette,
                      ),
                    ),
                    Expanded(
                      child: _sectorButton(
                        'Dövlət / Neft Sektoru',
                        !_isPrivateSector,
                        () => setState(() => _isPrivateSector = false),
                        palette,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Gross Salary Input
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gross Əməkhaqqı (AZN)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _grossCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'AZN',
                        suffixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: palette.brandRoyal,
                        ),
                        filled: true,
                        fillColor: palette.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick amount buttons
                    Wrap(
                      spacing: 8,
                      children: [500.0, 1000.0, 1500.0, 2000.0, 2500.0].map((amt) {
                        final isSelected = _grossSalary == amt;
                        return ChoiceChip(
                          label: Text('${amt.toInt()} AZN'),
                          selected: isSelected,
                          onSelected: (_) => _setQuickAmount(amt),
                          selectedColor: palette.brandRoyal,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : palette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          backgroundColor: palette.surface2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Net Salary Result Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.brandRoyal, palette.brandAzure],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: palette.brandRoyal.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ƏLƏ ÇATACAQ XALİS (NET) MAAŞ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_netSalary.toStringAsFixed(2)} AZN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Ümumi tutulmalar: ${_totalDeductions.toStringAsFixed(2)} AZN (${_grossSalary > 0 ? ((_totalDeductions / _grossSalary) * 100).toStringAsFixed(1) : 0}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Breakdown Header
              const SectionHeader(
                title: 'Rəsmi Tutulmaların Bölgüsü',
                subtitle: 'AR Qanunvericiliyinə uyğun icbari ödənişlər',
              ),

              // Deductions Breakdown
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _deductionRow(
                      'Gəlir Vergisi (14%)',
                      _isPrivateSector ? '0 AZN (8000-dək güzəştli)' : '${_tax.toStringAsFixed(2)} AZN',
                      _tax,
                      AppColors.gold,
                      palette,
                    ),
                    const Divider(height: 20),
                    _deductionRow(
                      'DSMF (Sosial Sığorta - 3% / 10%)',
                      '${_dsmf.toStringAsFixed(2)} AZN',
                      _dsmf,
                      AppColors.sky,
                      palette,
                    ),
                    const Divider(height: 20),
                    _deductionRow(
                      'İşsizlikdən Sığorta (0.5%)',
                      '${_unemploymentInsurance.toStringAsFixed(2)} AZN',
                      _unemploymentInsurance,
                      AppColors.rose,
                      palette,
                    ),
                    const Divider(height: 20),
                    _deductionRow(
                      'İcbari Tibbi Sığorta (2%)',
                      '${_healthInsurance.toStringAsFixed(2)} AZN',
                      _healthInsurance,
                      AppColors.emerald,
                      palette,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectorButton(String title, bool isSelected, VoidCallback onTap, AppPalette palette) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.brandRoyal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : palette.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _deductionRow(String title, String displayValue, double amount, Color dotColor, AppPalette palette) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
