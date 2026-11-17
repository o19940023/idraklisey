import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'manage_schedule_dialog.dart';
import '../../../data/models/finance_model.dart';

/// 100% Web Parity Modal for Student 360 Financial View (_payments_modal.blade.php)
class StudentFinanceModal extends StatefulWidget {
  final int contractId;
  final String? studentNameFallback;
  final String? codeFallback;

  const StudentFinanceModal({
    super.key,
    required this.contractId,
    this.studentNameFallback,
    this.codeFallback,
  });

  static Future<void> show(
    BuildContext context, {
    required int contractId,
    String? studentNameFallback,
    String? codeFallback,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudentFinanceModal(
        contractId: contractId,
        studentNameFallback: studentNameFallback,
        codeFallback: codeFallback,
      ),
    );
  }

  @override
  State<StudentFinanceModal> createState() => _StudentFinanceModalState();
}

class _StudentFinanceModalState extends State<StudentFinanceModal> {
  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  // Selected Tab: 'overall' or contract_type string (e.g. 'education', 'transportation')
  String _selectedTab = 'overall';

  // Filters for Payment History
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedMethod;
  final TextEditingController _noteSearchController = TextEditingController();

  final List<Map<String, String>> _monthOptions = const [
    {'code': '', 'label': 'Hamısı'},
    {'code': '01', 'label': 'Yanvar'},
    {'code': '02', 'label': 'Fevral'},
    {'code': '03', 'label': 'Mart'},
    {'code': '04', 'label': 'Aprel'},
    {'code': '05', 'label': 'May'},
    {'code': '06', 'label': 'İyun'},
    {'code': '07', 'label': 'İyul'},
    {'code': '08', 'label': 'Avqust'},
    {'code': '09', 'label': 'Sentyabr'},
    {'code': '10', 'label': 'Oktyabr'},
    {'code': '11', 'label': 'Noyabr'},
    {'code': '12', 'label': 'Dekabr'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _noteSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _noteSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await SchoolApiService.instance.fetchStudentFinanceModal(widget.contractId);
      if (res != null) {
        setState(() {
          _data = res;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Məlumatlar yüklənərkən xəta baş verdi.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Şəbəkə və ya sistem xətası: $e';
        _loading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Student Name + Code + Close Button
            _buildHeader(palette),

            const Divider(height: 1, thickness: 1),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorView(palette)
                      : _buildContent(palette),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    final student = _data?['student'] as Map<String, dynamic>?;
    final fullName = student?['full_name']?.toString() ?? widget.studentNameFallback ?? 'Şagird Maliyyə Profili';
    final studentNumber = student?['student_number']?.toString() ?? widget.codeFallback ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: fullName,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                children: [
                  if (studentNumber.isNotEmpty)
                    TextSpan(
                      text: ' (#$studentNumber)',
                      style: TextStyle(
                        color: palette.brandAzure,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.textSecondary, size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.rose),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Xəta baş verdi',
              style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Yenidən yoxla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.brandRoyal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppPalette palette) {
    final student = _data?['student'] as Map<String, dynamic>? ?? {};
    final overall = _data?['overall'] as Map<String, dynamic>? ?? {};
    final contracts = (_data?['contracts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final allPayments = (_data?['payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Current active financial metrics depending on selected tab
    Map<String, dynamic> activeMetrics;
    if (_selectedTab == 'overall') {
      activeMetrics = overall;
    } else {
      activeMetrics = contracts.firstWhere(
        (c) => (c['contract_type']?.toString() == _selectedTab),
        orElse: () => overall,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Student & Family Profile Summary Card
          _buildStudentInfoCard(palette, student),

          const SizedBox(height: 14),

          // 2. Tabs for Contract Types (Ümumi, Təhsil haqqı, Servis, Dərnək...)
          _buildContractTabs(palette, contracts),

          const SizedBox(height: 14),

          // 3. 5 Financial KPI Boxes
          _buildFinancialKpiBoxes(palette, activeMetrics),

          const SizedBox(height: 18),

          // 4. Monthly Payment Schedule Section (Aylıq Ödəniş Qrafiki)
          _buildMonthlyScheduleSection(palette, contracts),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 5. Payment History Section (Ödəniş Tarixçəsi)
          _buildPaymentHistorySection(palette, allPayments),

          const SizedBox(height: 16),

          // 6. Bottom helper note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ödəniş qəbul etmək üçün yuxarıdan müvafiq müqavilə növünü seçin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textTertiary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 1. Student Info Card =====
  Widget _buildStudentInfoCard(AppPalette palette, Map<String, dynamic> student) {
    final className = student['class_name']?.toString() ?? '-';
    final classSector = student['class_sector']?.toString() ?? '-';
    final classTeacherName = student['class_teacher_name']?.toString() ?? '-';
    final parents = (student['parents'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderHairline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class, Sector, Homeroom teacher row
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  palette: palette,
                  icon: Icons.school_outlined,
                  iconColor: palette.brandRoyal,
                  label: 'SİNİF',
                  value: className,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  palette: palette,
                  icon: Icons.language_rounded,
                  iconColor: palette.brandAzure,
                  label: 'SEKTOR / BÖLMƏ',
                  value: classSector,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  palette: palette,
                  icon: Icons.person_pin_outlined,
                  iconColor: AppColors.emerald,
                  label: 'SİNİF RƏHBƏRİ',
                  value: classTeacherName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 10),

          // Parents and related contacts
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 14, color: palette.textTertiary),
              const SizedBox(width: 4),
              Text(
                'VALİDEYNLƏR VƏ ƏLAQƏLİ ŞƏXSLƏR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: palette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (parents.isEmpty)
            Text(
              'Valideyn və ya qohum məlumatı daxil edilməyib.',
              style: TextStyle(color: palette.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: parents.map((p) => _buildParentChip(palette, p)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required AppPalette palette,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textTertiary,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildParentChip(AppPalette palette, Map<String, dynamic> parent) {
    final relationship = parent['relationship']?.toString() ?? 'Qohum';
    final name = parent['full_name']?.toString() ?? '-';
    final phone = parent['phone']?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: palette.brandAzure.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, size: 11, color: palette.brandAzure),
                const SizedBox(width: 2),
                Text(
                  relationship,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.brandAzure,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _makePhoneCall(phone),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded, size: 11, color: palette.brandRoyal),
                    const SizedBox(width: 2),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.brandRoyal,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 2. Contract Type Tabs =====
  Widget _buildContractTabs(AppPalette palette, List<Map<String, dynamic>> contracts) {
    final tabs = <Map<String, String>>[
      {'id': 'overall', 'label': 'Ümumi'},
    ];

    for (final c in contracts) {
      final type = c['contract_type']?.toString() ?? '';
      final label = c['contract_type_label']?.toString() ?? type;
      if (type.isNotEmpty && !tabs.any((t) => t['id'] == type)) {
        tabs.add({'id': type, 'label': label});
      }
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderHairline),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, idx) {
          final tab = tabs[idx];
          final isSelected = _selectedTab == tab['id'];

          return InkWell(
            onTap: () => setState(() => _selectedTab = tab['id']!),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? palette.brandRoyal : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.brandRoyal.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                tab['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : palette.textSecondary,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== 3. 5 KPI Boxes =====
  Widget _buildFinancialKpiBoxes(AppPalette palette, Map<String, dynamic> metrics) {
    final totalAmount = (metrics['total_amount'] as num?)?.toDouble() ?? 0.0;
    final discountAmount = (metrics['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final finalAmount = (metrics['final_amount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (metrics['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final remainingDebt = (metrics['remaining_debt'] as num?)?.toDouble() ??
        (metrics['total_debt'] as num?)?.toDouble() ??
        (finalAmount - paidAmount);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildKpiCard(
            palette: palette,
            label: 'Müqavilə məbləği',
            amount: totalAmount,
            amountColor: palette.textPrimary,
            bgColor: palette.surface2,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            palette: palette,
            label: 'Güzəşt',
            amount: discountAmount,
            amountColor: const Color(0xFFD97706), // Amber
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFEF3C7),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            palette: palette,
            label: 'Ödəniləcək məbləğ',
            amount: finalAmount,
            amountColor: palette.brandAzure,
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFDBEAFE),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            palette: palette,
            label: 'Ödənilən',
            amount: paidAmount,
            amountColor: AppColors.emerald,
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFD1FAE5),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            palette: palette,
            label: 'Qalıq borc',
            amount: remainingDebt,
            amountColor: remainingDebt > 0.01 ? AppColors.rose : AppColors.emerald,
            bgColor: remainingDebt > 0.01 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
            borderColor: remainingDebt > 0.01 ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required AppPalette palette,
    required String label,
    required double amount,
    required Color amountColor,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            '${amount.toStringAsFixed(2)} AZN',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===== 4. Monthly Payment Schedule Section =====
  Widget _buildMonthlyScheduleSection(AppPalette palette, List<Map<String, dynamic>> contracts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Title + Excel export button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: palette.brandRoyal),
                const SizedBox(width: 6),
                Text(
                  'Aylıq Ödəniş Qrafiki',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final url = '${SchoolApiService.baseUrl.replaceAll('/api/mobile', '')}/gopanel/academic/finance/student-payments/export-student-schedule/${widget.contractId}';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.table_chart_rounded, size: 14, color: AppColors.emerald),
              label: const Text(
                'Excel Çıxarış',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.emerald, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_selectedTab == 'overall') ...[
          // Consolidated Cards per contract type (Photo 3 view)
          if (contracts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.borderHairline),
              ),
              child: Text(
                'Aktiv müqavilə və qrafik tapılmadı.',
                style: TextStyle(color: palette.textTertiary, fontSize: 13),
              ),
            )
          else
            ...contracts.map((c) => _buildContractScheduleCard(palette, c)),
        ] else ...[
          // Specific selected contract table view
          _buildContractScheduleTableView(palette, contracts),
        ],
      ],
    );
  }

  Widget _buildContractScheduleCard(AppPalette palette, Map<String, dynamic> contract) {
    final label = contract['contract_type_label']?.toString() ?? 'Müqavilə';
    final contractId = contract['contract_id'] as int? ?? widget.contractId;
    final code = contract['code']?.toString() ?? '';
    final paidCount = contract['paid_months_count'] as int? ?? 0;
    final totalCount = contract['total_months_count'] as int? ?? 0;
    final items = (contract['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      final fAmt = (contract['final_amount'] as num?)?.toDouble() ?? 0.0;
                      final inv = StudentInvoice(
                        id: contractId.toString(),
                        contractId: contractId,
                        code: code,
                        invoiceNumber: code,
                        contractType: contract['contract_type']?.toString() ?? 'education',
                        contractTypeLabel: label,
                        studentId: _data?['student']?['id']?.toString() ?? '',
                        studentName: _data?['student']?['full_name']?.toString() ?? '',
                        parentName: '',
                        className: _data?['student']?['class_name']?.toString() ?? '',
                        dueDate: DateTime.now(),
                        amount: fAmt,
                        totalAmount: (contract['total_amount'] as num?)?.toDouble() ?? 0.0,
                        discountAmount: (contract['discount_amount'] as num?)?.toDouble() ?? 0.0,
                        finalAmount: fAmt,
                        paidAmount: (contract['paid_amount'] as num?)?.toDouble() ?? 0.0,
                        remainingDebt: (contract['remaining_debt'] as num?)?.toDouble() ?? 0.0,
                        status: 'active',
                        statusLabel: 'Aktiv',
                      );
                      ManageScheduleDialog.show(context, inv, onSaved: _loadData);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: palette.brandAzure.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.edit_calendar_rounded, size: 14, color: palette.brandAzure),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$paidCount / $totalCount ödənilib',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.brandRoyal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            Text('Qrafik maddələri yoxdur.', style: TextStyle(color: palette.textTertiary, fontSize: 11))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((it) => _buildMonthBadge(palette, it)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthBadge(AppPalette palette, Map<String, dynamic> item) {
    final monthName = item['month_name']?.toString() ?? '';
    final isPaid = item['is_paid'] == true;
    final isPartial = item['is_partial'] == true;
    final paidAmount = (item['paid_amount'] as num?)?.toDouble() ?? 0.0;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (isPaid) {
      bgColor = const Color(0xFFDCFCE7); // Soft Green
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF15803D);
      icon = Icons.check_circle_rounded;
    } else if (isPartial) {
      bgColor = const Color(0xFFFEF9C3); // Soft Yellow
      borderColor = const Color(0xFFFDE047);
      textColor = const Color(0xFF854D0E);
      icon = Icons.adjust_rounded;
    } else {
      bgColor = palette.surface1; // Slate / Unpaid
      borderColor = palette.borderHairline;
      textColor = palette.textSecondary;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Tooltip(
      message: isPaid
          ? '$monthName: Tam ödənilib'
          : isPartial
              ? '$monthName: Qismən (${paidAmount.toStringAsFixed(2)} AZN)'
              : '$monthName: Ödənilməyib',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              monthName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractScheduleTableView(AppPalette palette, List<Map<String, dynamic>> contracts) {
    final c = contracts.firstWhere(
      (ct) => ct['contract_type']?.toString() == _selectedTab,
      orElse: () => contracts.isNotEmpty ? contracts.first : {},
    );
    final items = (c['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Bu müqavilə üzrə qrafik məlumatı tapılmadı.',
          style: TextStyle(color: palette.textTertiary, fontSize: 12),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Dövr / Ay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Məbləğ', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Ödənilib', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final it = items[idx];
              final index = it['index'] ?? (idx + 1);
              final month = it['month_name']?.toString() ?? '';
              final amount = (it['amount'] as num?)?.toDouble() ?? 0.0;
              final paid = (it['paid_amount'] as num?)?.toDouble() ?? 0.0;
              final isPaid = it['is_paid'] == true;
              final isPartial = it['is_partial'] == true;
              final isInitial = it['type'] == 'initial';

              return Container(
                color: isPaid ? const Color(0xFFDCFCE7).withValues(alpha: 0.25) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('$index', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textTertiary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              month,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isInitial) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: palette.brandAzure.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'İlkin',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: palette.brandAzure),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${amount.toStringAsFixed(2)} ₼',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: palette.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${paid.toStringAsFixed(2)} ₼',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: paid > 0 ? AppColors.emerald : palette.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? const Color(0xFFDCFCE7)
                                : isPartial
                                    ? const Color(0xFFFEF9C3)
                                    : palette.surface2,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isPaid
                                  ? const Color(0xFF86EFAC)
                                  : isPartial
                                      ? const Color(0xFFFDE047)
                                      : palette.borderHairline,
                            ),
                          ),
                          child: Text(
                            isPaid ? 'Ödənilib' : (isPartial ? 'Qismən' : 'Ödənilməyib'),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isPaid
                                  ? const Color(0xFF15803D)
                                  : (isPartial ? const Color(0xFF854D0E) : palette.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== 5. Payment History Section =====
  Widget _buildPaymentHistorySection(AppPalette palette, List<Map<String, dynamic>> allPayments) {
    // Filter payments based on search and dropdown selections
    final filtered = allPayments.filterPayments(
      year: _selectedYear,
      month: _selectedMonth,
      method: _selectedMethod,
      search: _noteSearchController.text,
    );

    final totalFilteredAmount = filtered.fold<double>(0.0, (acc, p) => acc + ((p['amount'] as num?)?.toDouble() ?? 0.0));

    // Collect unique payment methods and years from payments
    final years = (_data?['payment_years'] as List?)?.cast<String>() ?? [];
    final methods = allPayments
        .map((p) => p['payment_method']?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 16, color: palette.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Ödəniş Tarixçəsi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Filter Controls Row (Akademik İl, Ay, Ödəniş Metodu, Qeyd Search)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Year filter
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Akademik İl', style: TextStyle(fontSize: 10, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedYear,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 11, color: palette.textPrimary),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Hamısı')),
                      ...years.map((y) => DropdownMenuItem(value: y, child: Text(y))),
                    ],
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                ],
              ),
            ),

            // Month filter
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ay', style: TextStyle(fontSize: 10, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMonth,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 11, color: palette.textPrimary),
                    items: _monthOptions.map((m) {
                      return DropdownMenuItem(
                        value: m['code']!.isEmpty ? null : m['code'],
                        child: Text(m['label']!),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMonth = val),
                  ),
                ],
              ),
            ),

            // Method filter
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ödəniş Metodu', style: TextStyle(fontSize: 10, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMethod,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 11, color: palette.textPrimary),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Hamısı')),
                      ...methods.map((m) => DropdownMenuItem(value: m, child: Text(m == 'cash' ? 'Nağd' : (m == 'bank_transfer' ? 'Bank köçürməsi' : m)))),
                    ],
                    onChanged: (val) => setState(() => _selectedMethod = val),
                  ),
                ],
              ),
            ),

            // Search filter
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Qeyd', style: TextStyle(fontSize: 10, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _noteSearchController,
                    style: TextStyle(fontSize: 11, color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Axtar...',
                      hintStyle: TextStyle(fontSize: 11, color: palette.textTertiary),
                      prefixIcon: Icon(Icons.search, size: 14, color: palette.textTertiary),
                      prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Table (exact match with web: TARİX | MÜQAVİLƏ | MƏBLƏĞ | METOD | BANK HESABI)
        Container(
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Column(
            children: [
              // Horizontal Scrollable Data Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Container(
                        color: palette.surface2,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            _buildTh(palette, 'TARİX', width: 90),
                            _buildTh(palette, 'MÜQAVİLƏ', width: 140),
                            _buildTh(palette, 'MƏBLƏĞ', width: 100, align: TextAlign.right),
                            _buildTh(palette, 'METOD', width: 90, align: TextAlign.center),
                            _buildTh(palette, 'BANK HESABI', width: 120),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Rows
                      if (filtered.isEmpty)
                        Container(
                          width: 540,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 36, color: palette.textTertiary.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text(
                                'Bu müqavilə üzrə heç bir ödəniş qeydə alınmayıb.',
                                style: TextStyle(color: palette.textTertiary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map((p) => _buildPaymentRow(palette, p)),

                      const Divider(height: 1, thickness: 1.5),

                      // Footer Row: Cəm
                      Container(
                        color: palette.surface2.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                'Cəm',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 140),
                            SizedBox(
                              width: 100,
                              child: Text(
                                '${totalFilteredAmount.toStringAsFixed(2)} AZN',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 90),
                            const SizedBox(width: 120),
                          ],
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
    );
  }

  Widget _buildTh(AppPalette palette, String title, {required double width, TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: align,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: palette.textTertiary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildPaymentRow(AppPalette palette, Map<String, dynamic> payment) {
    final date = payment['payment_date']?.toString() ?? '-';
    final contractCode = payment['contract_code']?.toString() ?? '-';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final method = payment['payment_method_label']?.toString() ?? payment['payment_method']?.toString() ?? 'Nağd';
    final isCash = (payment['payment_method']?.toString() == 'cash');
    final bank = payment['bank_account']?.toString() ?? (isCash ? 'Nağd kassa' : '-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.borderHairline, width: 0.6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              date,
              style: TextStyle(fontSize: 11.5, color: palette.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              contractCode,
              style: TextStyle(fontSize: 11.5, color: palette.brandRoyal, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '${amount.toStringAsFixed(2)} AZN',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  method == 'bank_transfer' ? 'Bank köçürməsi' : method,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              bank,
              style: TextStyle(fontSize: 11, color: palette.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

extension _PaymentsFilterExt on List<Map<String, dynamic>> {
  List<Map<String, dynamic>> filterPayments({
    String? year,
    String? month,
    String? method,
    String? search,
  }) {
    return where((p) {
      if (year != null && year.isNotEmpty) {
        final pDate = p['payment_date']?.toString() ?? '';
        if (!pDate.contains(year)) return false;
      }
      if (month != null && month.isNotEmpty) {
        final pDate = p['payment_date']?.toString() ?? '';
        final parts = pDate.split('.');
        if (parts.length >= 2 && parts[1] != month) return false;
      }
      if (method != null && method.isNotEmpty) {
        final pMethod = p['payment_method']?.toString() ?? '';
        if (pMethod != method) return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final notes = (p['notes']?.toString() ?? '').toLowerCase();
        final code = (p['code']?.toString() ?? '').toLowerCase();
        final contractCode = (p['contract_code']?.toString() ?? '').toLowerCase();
        if (!notes.contains(q) && !code.contains(q) && !contractCode.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
