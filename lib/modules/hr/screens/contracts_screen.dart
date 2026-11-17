import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/employee_model.dart';
import '../../../providers/app_state.dart';
import 'salary_calculator_screen.dart';

void showEmployeeContractDetailSheet(
  BuildContext context,
  EmployeeContract contract, {
  VoidCallback? onTerminated,
  VoidCallback? onEdit,
}) {
  final palette = AppPalette.of(context);
  String formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  Widget rowItem(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isHighlight ? palette.brandAzure : palette.textPrimary,
                fontSize: isBold ? 14 : 13,
                fontWeight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: palette.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.employeeName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contract.positionTitle,
                        style: TextStyle(
                          color: palette.brandAzure,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: contract.status == 'terminated'
                      ? 'Xitam verilib'
                      : (contract.isActive ? 'Aktiv Müqavilə' : 'Müddəti bitib'),
                  color: contract.status == 'terminated'
                      ? AppColors.danger
                      : (contract.isActive ? AppColors.emerald : AppColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    rowItem('Müqavilə Nömrəsi', contract.contractNumber, isBold: true),
                    rowItem(
                      'Müqavilə Növü',
                      contract.isIndefinite ? 'Müddətsiz (Daimi)' : 'Müddətli',
                    ),
                    if (contract.employeeFin.isNotEmpty)
                      rowItem('FİN Kod', contract.employeeFin),
                    if (contract.employeeCode.isNotEmpty)
                      rowItem('Əməkdaş Kodu', contract.employeeCode),
                    if (contract.company.isNotEmpty)
                      rowItem('Şirkət', contract.company),
                    if (contract.filial.isNotEmpty)
                      rowItem('Filial', contract.filial),
                    if (contract.department.isNotEmpty)
                      rowItem('Struktur / Şöbə', contract.department),
                    if (contract.costCenter.isNotEmpty)
                      rowItem('Xərc Mərkəzi', contract.costCenter),
                    if (contract.teqvim.isNotEmpty)
                      rowItem('İstehsalat Təqvimi', contract.teqvim),
                    rowItem('Başlama Tarixi', formatDate(contract.startDate)),
                    rowItem(
                      'Bitmə Tarixi',
                      contract.endDate != null ? formatDate(contract.endDate!) : 'Müddətsiz',
                    ),
                    rowItem('Həftəlik İş Saatı', '${contract.workHours.toStringAsFixed(0)} saat'),
                    if (contract.workSchedule.isNotEmpty)
                      rowItem('İş Qrafiki', contract.workSchedule),
                    rowItem('Status / Müddət', contract.remainingText, isHighlight: true),
                    if (contract.baseVacationDays != null && contract.baseVacationDays! > 0)
                      rowItem('Əsas Məzuniyyət', '${contract.baseVacationDays} gün'),
                    if (contract.trialPeriodValue != null && contract.trialPeriodValue! > 0) ...[
                      rowItem(
                        'Sınaq Müddəti',
                        '${contract.trialPeriodValue} ${contract.trialPeriodUnit == 'day' ? 'gün' : 'ay'}',
                      ),
                      if (contract.probationEndDate != null)
                        rowItem('Sınaq Bitmə Tarixi', formatDate(contract.probationEndDate!)),
                    ],
                    if (contract.notes.trim().isNotEmpty)
                      rowItem('Əlavə Qeyd', contract.notes),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Financial details
                    rowItem(
                      'Gross Əməkhaqqı',
                      '${contract.grossSalary.toStringAsFixed(2)} AZN',
                      isBold: true,
                    ),
                    rowItem(
                      'Xalis (Net) Maaş',
                      '${contract.netSalary.toStringAsFixed(2)} AZN',
                      isBold: true,
                      isHighlight: true,
                    ),
                    if (contract.salarySupplement > 0)
                      rowItem(
                        'Maaşa Əlavə',
                        '${contract.salarySupplement.toStringAsFixed(2)} AZN',
                      ),
                    if (contract.foodAllowance > 0)
                      rowItem(
                        'Yemək Pulu',
                        '${contract.foodAllowance.toStringAsFixed(2)} AZN',
                      ),
                    if (contract.workConditionSupplement > 0)
                      rowItem(
                        'Əmək Şəraiti Əlavəsi',
                        '${contract.workConditionSupplement.toStringAsFixed(2)} AZN',
                      ),

                    // Work Regime details (if provided)
                    if (contract.workRegime.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'İş vaxtı rejimi haqqında məlumat:',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: Text(
                          contract.workRegime,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    // Job Description (if provided)
                    if (contract.jobDescription.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Əmək funksiyası:',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: Text(
                          contract.jobDescription,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onEdit != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: palette.brandRoyal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 19),
                      label: const Text('Düzəliş Et', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandRoyal,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SalaryCalculatorScreen(
                            initialGrossSalary: contract.grossSalary,
                            employeeName: contract.employeeName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: const Text('Vergi Hesabla', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                if (contract.status != 'terminated' && onTerminated != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                      foregroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    tooltip: 'Müqaviləyə Xitam Ver',
                    onPressed: () {
                      Navigator.pop(ctx);
                      onTerminated();
                    },
                    icon: const Icon(Icons.cancel_presentation_rounded, size: 20),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ContractsScreen extends StatefulWidget {
  final String? employeeId;
  final String? employeeCode;
  final String? employeeName;
  final bool autoOpenFirstContract;

  const ContractsScreen({
    super.key,
    this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.autoOpenFirstContract = false,
  });

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Hamısı';
  bool _isLoading = true;
  bool _didAutoOpen = false;

  List<EmployeeContract> _contracts = [];
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _documentTypes = [];
  Map<String, dynamic> _formOptions = {};

  final List<String> _statuses = [
    'Hamısı',
    'Aktiv',
    'Müddətsiz',
    'Müddətli',
    'Bitməkdə olan',
    'Xitam verilmiş',
  ];

  bool get _isSingleEmployeeMode =>
      (widget.employeeId != null && widget.employeeId!.trim().isNotEmpty) ||
      (widget.employeeCode != null && widget.employeeCode!.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final res = await SchoolApiService.instance.fetchContractsDetailedData(
        employeeId: widget.employeeId,
        employeeCode: widget.employeeCode,
        search: _searchController.text.trim(),
      );

      if (res != null && res['success'] == true) {
        _summary = (res['summary'] as Map?)?.cast<String, dynamic>() ?? {};
        _documentTypes = (res['documentTypes'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        _formOptions = (res['options'] as Map?)?.cast<String, dynamic>() ?? {};

        final rawList = (res['data'] as List?) ?? [];
        final parsed = rawList.map((m) {
          final start = DateTime.tryParse(m['startDate']?.toString() ?? '') ?? DateTime(2024, 9, 1);
          final endStr = m['endDate']?.toString();
          final end = (endStr != null && endStr.isNotEmpty) ? DateTime.tryParse(endStr) : null;
          final gross = (m['grossSalary'] as num?)?.toDouble() ?? 0.0;
          final net = (m['netSalary'] as num?)?.toDouble() ?? (gross * 0.875);
          final dept = m['department']?.toString() ?? '';
          final filial = m['filial']?.toString() ?? '';
          final company = m['company']?.toString() ?? '';
          final food = (m['foodAllowance'] as num?)?.toDouble() ?? 0.0;
          final supp = (m['salarySupplement'] as num?)?.toDouble() ?? 0.0;
          final condSupp = (m['workConditionSupplement'] as num?)?.toDouble() ?? 0.0;
          final hrs = (m['workHours'] as num?)?.toDouble() ?? 40.0;
          final costCenter = m['costCenter']?.toString() ?? '';
          final teqvim = m['teqvim']?.toString() ?? '';
          final workSchedule = m['workSchedule']?.toString() ?? '';
          final workRegime = m['workRegime']?.toString() ?? '';
          final jobDesc = m['jobDescription']?.toString() ?? '';
          final probEndStr = m['probationEndDate']?.toString();
          final probEnd = (probEndStr != null && probEndStr.isNotEmpty) ? DateTime.tryParse(probEndStr) : null;
          final trialVal = m['trialPeriodValue'] != null ? int.tryParse(m['trialPeriodValue'].toString()) : null;
          final trialUnit = m['trialPeriodUnit']?.toString();
          final vacDays = m['baseVacationDays'] != null ? int.tryParse(m['baseVacationDays'].toString()) : 21;
          final posId = m['positionId'] != null ? int.tryParse(m['positionId'].toString()) : null;
          final structId = m['structureId'] != null ? int.tryParse(m['structureId'].toString()) : null;
          final filId = m['filialId'] != null ? int.tryParse(m['filialId'].toString()) : null;
          final compId = m['companyId'] != null ? int.tryParse(m['companyId'].toString()) : null;
          final teqId = m['teqvimId'] != null ? int.tryParse(m['teqvimId'].toString()) : null;

          return EmployeeContract(
            id: m['id']?.toString() ?? '',
            employeeId: m['employeeId']?.toString() ?? '',
            employeeName: m['employeeName']?.toString() ?? widget.employeeName ?? 'Əməkdaş',
            employeeCode: m['employeeCode']?.toString() ?? '',
            employeeFin: m['employeeFin']?.toString() ?? '',
            contractNumber: m['contractNumber']?.toString() ?? 'MÜQ',
            contractType: m['contractType']?.toString() ?? (end == null ? 'indefinite' : 'fixed'),
            startDate: start,
            endDate: end,
            grossSalary: gross,
            netSalary: net,
            foodAllowance: food,
            salarySupplement: supp,
            workConditionSupplement: condSupp,
            workHours: hrs,
            status: m['status']?.toString() ?? 'active',
            isActive: m['isActive'] == true || m['status'] == 'active',
            positionTitle: m['position']?.toString() ?? 'Vəzifə',
            department: dept,
            filial: filial,
            company: company,
            notes: [if (dept.isNotEmpty) dept, if (filial.isNotEmpty) filial].join(' • '),
            costCenter: costCenter,
            teqvim: teqvim,
            workSchedule: workSchedule,
            workRegime: workRegime,
            jobDescription: jobDesc,
            trialPeriodValue: trialVal,
            trialPeriodUnit: trialUnit,
            probationEndDate: probEnd,
            baseVacationDays: vacDays,
            positionId: posId,
            structureId: structId,
            filialId: filId,
            companyId: compId,
            teqvimId: teqId,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _contracts = parsed;
            _isLoading = false;
          });
          if (widget.autoOpenFirstContract && !_didAutoOpen && _contracts.isNotEmpty) {
            _didAutoOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                showEmployeeContractDetailSheet(
                  context,
                  _contracts.first,
                  onTerminated: () => _confirmTerminate(_contracts.first),
                  onEdit: () => _openContractFormSheet(existingContract: _contracts.first),
                );
              }
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<EmployeeContract> get _filteredContracts {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final in30 = now.add(const Duration(days: 30));

    return _contracts.where((cnt) {
      final matchesStatus = switch (_selectedStatus) {
        'Aktiv' => cnt.isActive && cnt.status != 'terminated',
        'Müddətsiz' => cnt.isIndefinite,
        'Müddətli' => !cnt.isIndefinite,
        'Bitməkdə olan' => cnt.endDate != null &&
            cnt.endDate!.isAfter(now.subtract(const Duration(days: 1))) &&
            cnt.endDate!.isBefore(in30),
        'Xitam verilmiş' => cnt.status == 'terminated',
        _ => true,
      };
      final matchesSearch = query.isEmpty ||
          cnt.employeeName.toLowerCase().contains(query) ||
          cnt.contractNumber.toLowerCase().contains(query) ||
          cnt.employeeFin.toLowerCase().contains(query) ||
          cnt.employeeCode.toLowerCase().contains(query) ||
          cnt.positionTitle.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _confirmTerminate(EmployeeContract cnt) async {
    final palette = AppPalette.of(context);
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface1,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Müqaviləyə Xitam Ver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cnt.employeeName} üçün ${cnt.contractNumber} nömrəli müqaviləyə xitam vermək istəyirsiniz?',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Xitam Tarixi (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ləğv et'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xitam Ver'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await SchoolApiService.instance.terminateHrContract(
        cnt.id,
        endDate: dateCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Müqaviləyə xitam verildi' : 'Xəta baş verdi'),
            backgroundColor: success ? AppColors.emerald : AppColors.danger,
          ),
        );
        if (success) _loadContracts();
      }
    }
  }

  Future<void> _openContractFormSheet({EmployeeContract? existingContract}) async {
    final palette = AppPalette.of(context);
    final isEditing = existingContract != null;

    final contractNumberCtrl = TextEditingController(
      text: existingContract?.contractNumber ?? 'MÜQ-${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
    final startDateCtrl = TextEditingController(
      text: existingContract != null
          ? existingContract.startDate.toIso8601String().split('T').first
          : DateTime.now().toIso8601String().split('T').first,
    );
    final endDateCtrl = TextEditingController(
      text: existingContract?.endDate?.toIso8601String().split('T').first ?? '',
    );
    final grossSalaryCtrl = TextEditingController(
      text: existingContract != null && existingContract.grossSalary > 0
          ? existingContract.grossSalary.toStringAsFixed(2)
          : '',
    );
    final netSalaryCtrl = TextEditingController(
      text: existingContract != null && existingContract.netSalary > 0
          ? existingContract.netSalary.toStringAsFixed(2)
          : '',
    );
    final foodAllowanceCtrl = TextEditingController(
      text: existingContract != null && existingContract.foodAllowance > 0
          ? existingContract.foodAllowance.toStringAsFixed(2)
          : '0.00',
    );
    final salarySupplementCtrl = TextEditingController(
      text: existingContract != null && existingContract.salarySupplement > 0
          ? existingContract.salarySupplement.toStringAsFixed(2)
          : '0.00',
    );
    final workHoursCtrl = TextEditingController(
      text: existingContract != null ? existingContract.workHours.toStringAsFixed(0) : '40',
    );
    final workScheduleCtrl = TextEditingController(
      text: existingContract?.workSchedule ?? '5 günlük iş həftəsi (09:00 - 18:00)',
    );
    final workRegimeCtrl = TextEditingController(
      text: existingContract?.workRegime ?? '',
    );
    final jobDescCtrl = TextEditingController(
      text: existingContract?.jobDescription ?? '',
    );
    final vacationDaysCtrl = TextEditingController(
      text: existingContract != null ? existingContract.baseVacationDays?.toString() ?? '21' : '21',
    );

    String contractType = existingContract?.isIndefinite == false ? 'fixed-term' : 'indefinite';
    int? selectedPositionId = existingContract?.positionId;
    int? selectedStructureId = existingContract?.structureId;
    int? selectedFilialId = existingContract?.filialId;
    int? selectedCompanyId = existingContract?.companyId ?? 1;
    int? selectedTeqvimId = existingContract?.teqvimId;

    final positions = (_formOptions['positions'] as List?)?.cast<Map>() ?? [];
    final structures = (_formOptions['structures'] as List?)?.cast<Map>() ?? [];
    final filials = (_formOptions['filials'] as List?)?.cast<Map>() ?? [];
    final companies = (_formOptions['companies'] as List?)?.cast<Map>() ?? [];
    final teqvims = (_formOptions['teqvims'] as List?)?.cast<Map>() ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void updateNetSalary(String val) {
            final gross = double.tryParse(val) ?? 0.0;
            final net = gross > 0 ? (gross * 0.875) : 0.0;
            netSalaryCtrl.text = net.toStringAsFixed(2);
            setModalState(() {});
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 14,
            ),
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
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: palette.textTertiary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEditing ? Icons.edit_document : Icons.add_circle_outline_rounded,
                            color: palette.brandRoyal,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Müqaviləyə Düzəliş Et' : 'Yeni Əmək Müqaviləsi',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  if (existingContract != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Əməkdaş: ${existingContract.employeeName}',
                        style: TextStyle(color: palette.brandAzure, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Contract Number & Type
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: contractNumberCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Müqavilə Nömrəsi *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: contractType,
                                  decoration: const InputDecoration(
                                    labelText: 'Müqavilə Tipi *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'indefinite', child: Text('Müddətsiz')),
                                    DropdownMenuItem(value: 'fixed-term', child: Text('Müddətli')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => contractType = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Dates: Start Date & End Date
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: startDateCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Başlama Tarixi *',
                                    hintText: 'YYYY-MM-DD',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                                  ),
                                  onTap: () async {
                                    final current = DateTime.tryParse(startDateCtrl.text) ?? DateTime.now();
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: current,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2040),
                                    );
                                    if (picked != null) {
                                      startDateCtrl.text = picked.toIso8601String().split('T').first;
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: endDateCtrl,
                                  enabled: contractType == 'fixed-term',
                                  decoration: InputDecoration(
                                    labelText: contractType == 'fixed-term' ? 'Bitmə Tarixi *' : 'Bitmə Tarixi',
                                    hintText: contractType == 'fixed-term' ? 'YYYY-MM-DD' : 'Müddətsiz',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                                  ),
                                  onTap: () async {
                                    if (contractType != 'fixed-term') return;
                                    final current = DateTime.tryParse(endDateCtrl.text) ?? DateTime.now().add(const Duration(days: 365));
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: current,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2040),
                                    );
                                    if (picked != null) {
                                      endDateCtrl.text = picked.toIso8601String().split('T').first;
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Position & Structure
                          if (positions.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: selectedPositionId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Vəzifə *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: positions.map((p) {
                                return DropdownMenuItem<int>(
                                  value: int.tryParse(p['id'].toString()),
                                  child: Text(
                                    p['title']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(() => selectedPositionId = val),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (structures.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: selectedStructureId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Struktur / Şöbə *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: structures.map((s) {
                                return DropdownMenuItem<int>(
                                  value: int.tryParse(s['id'].toString()),
                                  child: Text(
                                    s['title']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(() => selectedStructureId = val),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Filial & Company
                          Row(
                            children: [
                              if (filials.isNotEmpty)
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: selectedFilialId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Filial *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: filials.map((f) {
                                      return DropdownMenuItem<int>(
                                        value: int.tryParse(f['id'].toString()),
                                        child: Text(f['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(() => selectedFilialId = val),
                                  ),
                                ),
                              if (filials.isNotEmpty && companies.isNotEmpty)
                                const SizedBox(width: 10),
                              if (companies.isNotEmpty)
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: selectedCompanyId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Şirkət *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: companies.map((c) {
                                      return DropdownMenuItem<int>(
                                        value: int.tryParse(c['id'].toString()),
                                        child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(() => selectedCompanyId = val),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Salary Information
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: grossSalaryCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: updateNetSalary,
                                  decoration: const InputDecoration(
                                    labelText: 'Gross Əməkhaqqı (AZN) *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: netSalaryCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Net (Xalis) Maaş',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    filled: true,
                                    fillColor: palette.surface2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Supplements (Salary supplement + Food allowance)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: salarySupplementCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Maaşa Əlavə (AZN)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: foodAllowanceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Yemək Pulu (AZN)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Work Schedule & Hours & Vacation
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: workScheduleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'İş Qrafiki',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: workHoursCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Saat/Həftə',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: vacationDaysCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Məzuniyyət',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (teqvims.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: selectedTeqvimId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'İstehsalat Təqvimi',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: teqvims.map((t) {
                                return DropdownMenuItem<int>(
                                  value: int.tryParse(t['id'].toString()),
                                  child: Text(t['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(() => selectedTeqvimId = val),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Work Regime details
                          TextField(
                            controller: workRegimeCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'İş vaxtı rejimi haqqında məlumat',
                              hintText: 'Məs: 5 günlük iş həftəsi, 09:00 - 18:00 arası...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Job Description
                          TextField(
                            controller: jobDescCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Əmək funksiyası',
                              hintText: 'Vəzifə və əmək öhdəliklərinin təsviri...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandRoyal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (contractNumberCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Zəhmət olmasa müqavilə nömrəsini qeyd edin!')),
                        );
                        return;
                      }

                      final gross = double.tryParse(grossSalaryCtrl.text.trim()) ?? 0.0;
                      final net = double.tryParse(netSalaryCtrl.text.trim()) ?? (gross * 0.875);
                      final payload = <String, dynamic>{
                        'contract_number': contractNumberCtrl.text.trim(),
                        'type': contractType,
                        'start_date': startDateCtrl.text.trim(),
                        if (contractType == 'fixed-term' && endDateCtrl.text.trim().isNotEmpty)
                          'end_date': endDateCtrl.text.trim(),
                        if (selectedPositionId != null) 'position_id': selectedPositionId!,
                        if (selectedStructureId != null) 'structure_id': selectedStructureId!,
                        if (selectedFilialId != null) 'filial_id': selectedFilialId!,
                        if (selectedCompanyId != null) 'company_id': selectedCompanyId!,
                        if (selectedTeqvimId != null) 'teqvim_id': selectedTeqvimId!,
                        'gross_salary': gross,
                        'net_salary': net,
                        'salary_supplement': double.tryParse(salarySupplementCtrl.text.trim()) ?? 0.0,
                        'food_allowance': double.tryParse(foodAllowanceCtrl.text.trim()) ?? 0.0,
                        'work_hours': double.tryParse(workHoursCtrl.text.trim()) ?? 40.0,
                        'work_schedule': workScheduleCtrl.text.trim(),
                        'work_regime': workRegimeCtrl.text.trim(),
                        'job_description': jobDescCtrl.text.trim(),
                        'base_vacation_days': int.tryParse(vacationDaysCtrl.text.trim()) ?? 21,
                        if (existingContract != null) 'employee_id': existingContract.employeeId,
                        if (existingContract == null && widget.employeeId != null)
                          'employee_id': widget.employeeId,
                      };

                      final res = await SchoolApiService.instance.saveHrContract(
                        payload,
                        contractId: existingContract?.id,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        final ok = res != null && (res['success'] == true || res['status'] == 'success');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? (isEditing ? 'Müqavilə uğurla yeniləndi!' : 'Yeni müqavilə yaradıldı!')
                                  : (res?['message']?.toString() ?? 'Xəta baş verdi'),
                            ),
                            backgroundColor: ok ? AppColors.emerald : AppColors.danger,
                          ),
                        );
                        if (ok) _loadContracts();
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      isEditing ? 'Dəyişiklikləri Yadda Saxla' : 'Müqaviləni Yarat',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showIssueDocumentSheet(EmployeeContract cnt, Map<String, dynamic> docType) async {
    final palette = AppPalette.of(context);
    final startCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Sənəd: ${docType['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Əməkdaş: ${cnt.employeeName} (${cnt.positionTitle})',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sənədin Tarixi *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Əlavə Qeyd / Əsaslandırma',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandRoyal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final empId = int.tryParse(cnt.employeeId) ?? 0;
                    final dtId = int.tryParse(docType['id']?.toString() ?? '') ?? 0;
                    if (empId <= 0 || dtId <= 0) return;

                    final res = await SchoolApiService.instance.createEmployeeDocument(
                      employeeId: empId,
                      documentTypeId: dtId,
                      startDate: startCtrl.text.trim(),
                      notes: noteCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      final ok = res != null && res['success'] == true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Sənəd uğurla yaradıldı!' : 'Xəta baş verdi'),
                          backgroundColor: ok ? AppColors.emerald : AppColors.danger,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Sənədi Bazada Yarat', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String title, dynamic value, Color col, AppPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value?.toString() ?? '0',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 15.5),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = Provider.of<AppState>(context, listen: false);
    final canCreate = appState.hasPermission('gopanel.hr.contracts.create') ||
        appState.hasPermission('gopanel.contracts.create') ||
        appState.isPrimaryAdmin;
    final canEdit = appState.hasPermission('gopanel.hr.contracts.update') ||
        appState.hasPermission('gopanel.contracts.update') ||
        appState.isPrimaryAdmin;

    final contracts = _filteredContracts;
    final titleText = _isSingleEmployeeMode
        ? '${widget.employeeName ?? 'Əməkdaş'} — Müqavilələr'
        : 'Əmək Müqavilələri';

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenilə',
            onPressed: _loadContracts,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
        elevation: 0,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _openContractFormSheet(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Müqavilə', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: ResponsiveCenter(
        child: Column(
          children: [
            if (!_isSingleEmployeeMode) ...[
              // Summary Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.surface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  children: [
                    Expanded(child: _miniStat('Cəmi', _summary['totalContracts'] ?? _contracts.length, palette.textPrimary, palette)),
                    Container(width: 1, height: 26, color: palette.borderHairline),
                    Expanded(child: _miniStat('Aktiv', _summary['activeContracts'] ?? 0, AppColors.emerald, palette)),
                    Container(width: 1, height: 26, color: palette.borderHairline),
                    Expanded(child: _miniStat('Müddətsiz', _summary['indefiniteContracts'] ?? 0, palette.brandRoyal, palette)),
                    Container(width: 1, height: 26, color: palette.borderHairline),
                    Expanded(child: _miniStat('Bitməkdə', _summary['expiringContracts'] ?? 0, AppColors.gold, palette)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Müqavilə nömrəsi, FİN, vəzifə və ya əməkdaş axtar...',
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statuses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = status == _selectedStatus;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedStatus = status);
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
                        side: BorderSide(
                          color: isSelected ? palette.brandRoyal : palette.borderHairline,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            SectionHeader(
              title: _isSingleEmployeeMode ? 'Əməkdaşın Rəsmi Müqavilələri' : 'Müqavilə Qeydiyyatı',
              subtitle: _isLoading
                  ? 'Baza ilə sinxronlaşdırılır...'
                  : '${contracts.length} müqavilə tapıldı',
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : contracts.isEmpty
                      ? Center(
                          child: Text(
                            'Uyğun müqavilə tapılmadı',
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: contracts.length,
                          itemBuilder: (context, index) {
                            final cnt = contracts[index];
                            final isTerminated = cnt.status == 'terminated';

                            return ModernCard(
                              onTap: () => showEmployeeContractDetailSheet(
                                context,
                                cnt,
                                onTerminated: () => _confirmTerminate(cnt),
                                onEdit: canEdit ? () => _openContractFormSheet(existingContract: cnt) : null,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Contract number pill + Badges
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.brandRoyal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.description_outlined, size: 13, color: palette.brandRoyal),
                                            const SizedBox(width: 4),
                                            Text(
                                              cnt.contractNumber,
                                              style: TextStyle(
                                                color: palette.brandRoyal,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (cnt.isIndefinite ? AppColors.emerald : palette.brandAzure)
                                                  .withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              cnt.isIndefinite ? 'Müddətsiz' : 'Müddətli',
                                              style: TextStyle(
                                                color: cnt.isIndefinite ? AppColors.emerald : palette.brandAzure,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          StatusBadge(
                                            label: isTerminated
                                                ? 'Xitam'
                                                : (cnt.isActive ? 'Aktiv' : 'Bitib'),
                                            color: isTerminated
                                                ? AppColors.danger
                                                : (cnt.isActive ? AppColors.emerald : AppColors.gold),
                                            fontSize: 10.5,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Employee Info
                                  Text(
                                    cnt.employeeName,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cnt.positionTitle,
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  // Structure & Filial details
                                  if (cnt.filial.isNotEmpty || cnt.department.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (cnt.filial.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: palette.surface2,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              cnt.filial,
                                              style: TextStyle(color: palette.textSecondary, fontSize: 11),
                                            ),
                                          ),
                                        if (cnt.department.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: palette.surface2,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              cnt.department,
                                              style: TextStyle(color: palette.textSecondary, fontSize: 11),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  // Financial block
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Gross Maaş',
                                              style: TextStyle(
                                                color: palette.textTertiary,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                            Text(
                                              '${cnt.grossSalary.toStringAsFixed(2)} AZN',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Net (Xalis) Maaş',
                                              style: TextStyle(
                                                color: palette.textTertiary,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                            Text(
                                              '${cnt.netSalary.toStringAsFixed(2)} AZN',
                                              style: const TextStyle(
                                                color: AppColors.emerald,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Action Buttons: Sənədlər dropdown, Düzəliş, Vergi, Xitam (Responsive Wrap)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 5,
                                      runSpacing: 5,
                                      children: [
                                        // Sənədlər Dropdown (Web GoPanel getDocumentDropdown 1:1)
                                        if (_documentTypes.isNotEmpty)
                                          PopupMenuButton<Map<String, dynamic>>(
                                            tooltip: 'Əməkdaş üçün Sənəd Yarat',
                                            onSelected: (dt) => _showIssueDocumentSheet(cnt, dt),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            itemBuilder: (_) => _documentTypes.map((dt) {
                                              return PopupMenuItem<Map<String, dynamic>>(
                                                value: dt,
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.note_add_outlined, size: 16, color: Color(0xFF2563EB)),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        dt['name']?.toString() ?? 'Sənəd',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 12.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                                              decoration: BoxDecoration(
                                                color: palette.brandRoyal.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: palette.brandRoyal.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.file_present_rounded, size: 13, color: palette.brandRoyal),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'Sənədlər',
                                                    style: TextStyle(
                                                      color: palette.brandRoyal,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 1),
                                                  Icon(Icons.arrow_drop_down, size: 14, color: palette.brandRoyal),
                                                ],
                                              ),
                                            ),
                                          ),

                                        if (canEdit)
                                          InkWell(
                                            onTap: () => _openContractFormSheet(existingContract: cnt),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                                              decoration: BoxDecoration(
                                                color: palette.brandAzure.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 13, color: palette.brandAzure),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'Düzəliş',
                                                    style: TextStyle(
                                                      color: palette.brandAzure,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                        // Kalkulyator (Vergini hesabla)
                                        InkWell(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SalaryCalculatorScreen(
                                                initialGrossSalary: cnt.grossSalary,
                                                employeeName: cnt.employeeName,
                                              ),
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                                            decoration: BoxDecoration(
                                              color: palette.surface2,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.calculate_outlined, size: 13),
                                                SizedBox(width: 3),
                                                Text('Vergi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),

                                        if (!isTerminated)
                                          InkWell(
                                            onTap: () => _confirmTerminate(cnt),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.cancel_outlined, size: 13, color: AppColors.danger),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Xitam',
                                                    style: TextStyle(
                                                      color: AppColors.danger,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
}
