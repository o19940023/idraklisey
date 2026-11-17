import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../data/models/finance_model.dart';
import '../widgets/new_payment_dialog.dart';
import '../widgets/student_finance_modal.dart';
import '../widgets/manage_schedule_dialog.dart';
import '../widgets/contract_quick_actions.dart';

class StudentPaymentsScreen extends StatefulWidget {
  const StudentPaymentsScreen({super.key});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _errorMessage;

  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _allParents = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _recentPayments = [];

  // Filters
  int? _selectedYearId;
  int? _selectedClassId;
  String? _selectedContractType;
  String? _selectedLanguage;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _contractTypes = [];

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchCtrl.addListener(() => setState(() {}));
    _loadPageData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- Rol və İcazə Yoxlamaları (GoPanel Web Parity) ---
  bool _canCreatePayment(SessionController session) =>
      session.profile?.isSuper == true ||
      session.can('gopanel.finance.payments.create') ||
      session.can('gopanel.finance.invoices.manage_payments');

  bool _canEditAmount(SessionController session) =>
      session.profile?.isSuper == true || session.can('gopanel.finance.student_contracts.edit_amount');

  bool _canManageInstallments(SessionController session) =>
      session.profile?.isSuper == true || session.can('gopanel.finance.student_contracts.manage_installments');

  bool _canApplyDiscount(SessionController session) =>
      session.profile?.isSuper == true || session.can('gopanel.finance.student_invoices.apply_discount');

  bool _canPrintReceipt(SessionController session) =>
      session.profile?.isSuper == true ||
      session.can('gopanel.finance.payments.receipt') ||
      session.can('gopanel.finance.payments.view') ||
      session.can('gopanel.finance.payments.create');

  bool _canPrintContract(SessionController session) =>
      session.profile?.isSuper == true ||
      session.can('gopanel.finance.student_contracts.print') ||
      session.can('gopanel.finance.student_contracts.view');

  bool _canCancelPayment(SessionController session) =>
      session.profile?.isSuper == true ||
      session.can('gopanel.finance.payments.delete') ||
      session.can('gopanel.finance.student_payments.delete');

  bool _canApprovePending(SessionController session) =>
      session.profile?.isSuper == true ||
      session.can('gopanel.finance.student_contracts.director_approve') ||
      session.can('gopanel.finance.payments.create');

  Future<void> _loadPageData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await SchoolApiService.instance.fetchStudentPaymentsPage(
        academicYearId: _selectedYearId,
        classId: _selectedClassId,
        contractType: _selectedContractType,
        gradeLanguage: _selectedLanguage,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

      if (res != null) {
        setState(() {
          _data = res;
          _allStudents = (res['students'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _allParents = (res['parents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _pendingPayments = (res['pending_payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _recentPayments = (res['recent_payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          final meta = res['meta'] as Map<String, dynamic>? ?? {};
          _classes = (meta['classes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _academicYears = (meta['academic_years'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _contractTypes = (meta['contract_types'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _selectedYearId ??= int.tryParse(meta['selected_year_id']?.toString() ?? '');

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
        _errorMessage = 'Şəbəkə xətası: $e';
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

  Future<void> _openReceipt(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qəbz linki açıla bilmədi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  Future<void> _handleApprovePending(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    final studentName = item['student_name']?.toString() ?? '';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödənişi Təsdiqlə'),
        content: Text('$studentName üzrə ${amount.toStringAsFixed(2)} ₼ məbləğində ilkin ödənişi təsdiqləmək istəyirsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Təsdiqlə'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await SchoolApiService.instance.approvePendingPayment(
        id,
        amount: amount,
        paymentMethod: 'bank_transfer',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message']?.toString() ?? 'Ödəniş təsdiqləndi!'),
            backgroundColor: AppColors.emerald,
          ),
        );
        _loadPageData();
      }
    }
  }

  Future<void> _handleRejectPending(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödənişdən İmtina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gözləyən ödənişdən imtina etmək üçün səbəb daxil edin:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(hintText: 'Səbəb...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bağla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İmtina Et'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await SchoolApiService.instance.rejectPendingPayment(id, reason: reasonCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message']?.toString() ?? 'Ödəniş ləğv edildi.'),
            backgroundColor: AppColors.rose,
          ),
        );
        _loadPageData();
      }
    }
  }

  Future<void> _handleCancelPayment(Map<String, dynamic> payment) async {
    final id = _asInt(payment['id']);
    final code = payment['code']?.toString() ?? '#$id';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ödənişi Ləğv Et ($code)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${amount.toStringAsFixed(2)} ₼ məbləğində bu ödənişi ləğv etmək istədiyinizdən əminsiniz? Müqavilə və qrafik balansı avtomatik bərpa olunacaq.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Ləğv səbəbi (məcburi deyil)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Geri')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bəli, Ləğv Et'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await SchoolApiService.instance.cancelStudentPayment(id, reason: reasonCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message']?.toString() ?? 'Ödəniş uğurla ləğv edildi.'),
            backgroundColor: AppColors.emerald,
          ),
        );
        _loadPageData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final summary = _data?['summary'] as Map<String, dynamic>? ?? {};

    final canCreate = _canCreatePayment(session);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Text(
          'Ödənişlər',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        actions: [
          // + Yeni Ödəniş Yarat Button (Yalnız icazəsi olanlar görə bilər)
          if (canCreate)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => NewPaymentDialog.show(context, onPaymentRecorded: _loadPageData),
              icon: const Icon(Icons.add_card_rounded, size: 16),
              label: const Text('Yeni Ödəniş', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPageData,
            tooltip: 'Yenilə',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: palette.surface1,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: palette.brandRoyal,
              unselectedLabelColor: palette.textSecondary,
              indicatorColor: palette.brandRoyal,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.school_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Şagirdlər (${_allStudents.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.family_restroom_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Valideynlər (${_allParents.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Gözləyən (${_pendingPayments.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Jurnal (${_recentPayments.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(palette)
              : Column(
                  children: [
                    // Top KPI Summary Cards (Müqavilələr, Güzəşt, Ödənilən, Qalıq Borc)
                    _buildSummaryKpiHeader(palette, summary),

                    // Filter & Search Row
                    _buildFilterAndSearchBar(palette),

                    // Tab View Body
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStudentsTab(palette, session),
                          _buildParentsTab(palette, session),
                          _buildPendingTab(palette, session),
                          _buildJournalTab(palette, session),
                        ],
                      ),
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
              onPressed: _loadPageData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenidən yoxla'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== TOP KPI SUMMARY HEADER =====
  Widget _buildSummaryKpiHeader(AppPalette palette, Map<String, dynamic> summary) {
    final totalContracts = (summary['total_contracts_amount'] as num?)?.toDouble() ?? 0.0;
    final totalDiscount = (summary['total_discount_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (summary['total_paid_amount'] as num?)?.toDouble() ?? 0.0;
    final totalDebt = (summary['total_debt_amount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      color: palette.surface1,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildKpiCard(
              palette: palette,
              label: 'Müqavilələr Cəmi',
              amount: totalContracts,
              amountColor: palette.textPrimary,
              bgColor: palette.surface2,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              palette: palette,
              label: 'Ümumi Güzəşt',
              amount: totalDiscount,
              amountColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFEF3C7),
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              palette: palette,
              label: 'Ödənilmiş Cəm',
              amount: totalPaid,
              amountColor: AppColors.emerald,
              bgColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFD1FAE5),
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              palette: palette,
              label: 'Qalıq Borc',
              amount: totalDebt,
              amountColor: AppColors.rose,
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFEE2E2),
            ),
          ],
        ),
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
    String formattedAmount;
    if (amount >= 1000000) {
      formattedAmount = '${(amount / 1000000).toStringAsFixed(2)}M ₼';
    } else if (amount >= 1000) {
      formattedAmount = '${(amount / 1000).toStringAsFixed(1)}K ₼';
    } else {
      formattedAmount = '${amount.toStringAsFixed(2)} ₼';
    }

    return Container(
      width: 125,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            formattedAmount,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }

  // ===== SEARCH & FILTERS BAR =====
  Widget _buildFilterAndSearchBar(AppPalette palette) {
    return Container(
      color: palette.surface1,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          // Search box
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _loadPageData(),
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Şagird, valideyn və ya kod üzrə axtar...',
                      hintStyle: TextStyle(fontSize: 12, color: palette.textTertiary),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: palette.textTertiary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadPageData();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Filtrlər',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: _showFilterModal,
                icon: Icon(Icons.tune_rounded, size: 18, color: palette.brandRoyal),
              ),
            ],
          ),

          // Active filter badges row
          if (_selectedClassId != null || _selectedContractType != null || _selectedLanguage != null) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedClassId != null) ...[
                    _buildActiveFilterChip(
                      label: 'Sinif: ${_classes.firstWhere((c) => c['id'] == _selectedClassId, orElse: () => {})['class_name'] ?? ''}',
                      onRemove: () {
                        setState(() => _selectedClassId = null);
                        _loadPageData();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedContractType != null) ...[
                    _buildActiveFilterChip(
                      label: 'Növ: ${_contractTypes.firstWhere((ct) => ct['value'] == _selectedContractType, orElse: () => {})['label'] ?? _selectedContractType}',
                      onRemove: () {
                        setState(() => _selectedContractType = null);
                        _loadPageData();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedLanguage != null) ...[
                    _buildActiveFilterChip(
                      label: 'Bölmə: ${_selectedLanguage == 'azerbaijan' ? 'Azərbaycan' : (_selectedLanguage == 'russian' ? 'Rus' : 'İngilis')}',
                      onRemove: () {
                        setState(() => _selectedLanguage = null);
                        _loadPageData();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
      deleteIcon: const Icon(Icons.close, size: 12),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final palette = AppPalette.of(ctx);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ətraflı Filtrlər', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Academic Year
                Text('Akademik İl', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: _selectedYearId,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _academicYears.map((y) {
                    final id = int.tryParse(y['id']?.toString() ?? '') ?? 0;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(y['title']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => _selectedYearId = val),
                ),
                const SizedBox(height: 12),

                // Class
                Text('Sinif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: _selectedClassId,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Bütün Siniflər')),
                    ..._classes.map((c) {
                      final id = int.tryParse(c['id']?.toString() ?? '') ?? 0;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(c['class_name']?.toString() ?? ''),
                      );
                    }),
                  ],
                  onChanged: (val) => setModalState(() => _selectedClassId = val),
                ),
                const SizedBox(height: 12),

                // Contract Type
                Text('Müqavilə Növü', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedContractType,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Bütün Müqavilələr')),
                    ..._contractTypes.map((ct) {
                      return DropdownMenuItem<String>(
                        value: ct['value']?.toString(),
                        child: Text(ct['label']?.toString() ?? ''),
                      );
                    }),
                  ],
                  onChanged: (val) => setModalState(() => _selectedContractType = val),
                ),
                const SizedBox(height: 12),

                // Language
                Text('Bölmə', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Bütün Bölmələr')),
                    DropdownMenuItem(value: 'azerbaijan', child: Text('Azərbaycan')),
                    DropdownMenuItem(value: 'russian', child: Text('Rus')),
                    DropdownMenuItem(value: 'english', child: Text('İngilis')),
                  ],
                  onChanged: (val) => setModalState(() => _selectedLanguage = val),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedClassId = null;
                            _selectedContractType = null;
                            _selectedLanguage = null;
                          });
                          Navigator.pop(ctx);
                          _loadPageData();
                        },
                        child: const Text('Təmizlə'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: palette.brandRoyal),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                          _loadPageData();
                        },
                        child: const Text('Tətbiq Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== TAB 1: ŞAGİRDƏ GÖRƏ ÖDƏNİŞLƏR =====
  Widget _buildStudentsTab(AppPalette palette, SessionController session) {
    if (_allStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 48, color: palette.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text('Şagird tapılmadı', style: TextStyle(color: palette.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: _allStudents.length,
      itemBuilder: (context, idx) {
        final s = _allStudents[idx];
        return _buildStudentCard(palette, s, session);
      },
    );
  }

  Widget _buildStudentCard(AppPalette palette, Map<String, dynamic> s, SessionController session) {
    final studentId = _asInt(s['id']);
    final fullName = s['full_name']?.toString() ?? 'Şagird';
    final studentNumber = s['student_number']?.toString() ?? '';
    final className = s['class_name']?.toString() ?? '';
    final classSector = s['class_sector']?.toString() ?? '';
    final parentName = s['parent_name']?.toString() ?? '';
    final parentPhone = s['parent_phone']?.toString();

    final cAmount = (s['contract_amount'] as num?)?.toDouble() ?? 0.0;
    final dAmount = (s['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final pAmount = (s['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final debt = (s['total_debt'] as num?)?.toDouble() ?? 0.0;

    final primaryContractId = s['primary_contract_id'] != null ? _asInt(s['primary_contract_id']) : null;
    final badges = (s['contract_badges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final contractsList = (s['contracts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final canCreate = _canCreatePayment(session);
    final canEditAmt = _canEditAmount(session);
    final canManageInst = _canManageInstallments(session);
    final canDiscount = _canApplyDiscount(session);
    final canPrintCont = _canPrintContract(session);
    final canPrintRec = _canPrintReceipt(session);

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Student name (tappable to open 360 modal) + Class pill
          InkWell(
            onTap: () {
              if (primaryContractId != null) {
                StudentFinanceModal.show(
                  context,
                  contractId: primaryContractId,
                  studentNameFallback: fullName,
                  codeFallback: studentNumber,
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: palette.brandRoyal.withValues(alpha: 0.12),
                  child: Text(
                    fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'Ş',
                    style: TextStyle(color: palette.brandRoyal, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: palette.brandRoyal,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.open_in_new_rounded, size: 14, color: palette.brandAzure),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (className.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$className • $classSector',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textSecondary),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(studentNumber, style: TextStyle(fontSize: 10.5, color: palette.textTertiary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contract Type Badges
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: badges.map((b) {
                final label = b['label']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.brandAzure.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.brandAzure),
                  ),
                );
              }).toList(),
            ),
          ],

          // Parent row
          if (parentName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.family_restroom_rounded, size: 12, color: palette.textTertiary),
                const SizedBox(width: 4),
                Text(
                  parentName,
                  style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
                ),
                if (parentPhone != null && parentPhone.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _makePhoneCall(parentPhone),
                    child: Text(
                      parentPhone,
                      style: TextStyle(fontSize: 11, color: palette.brandRoyal, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Financial numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Müqavilə', '${cAmount.toStringAsFixed(0)} ₼', palette.textPrimary),
              _buildMiniStat('Güzəşt', '${dAmount.toStringAsFixed(0)} ₼', const Color(0xFFD97706)),
              _buildMiniStat('Ödənilib', '${pAmount.toStringAsFixed(0)} ₼', AppColors.emerald),
              _buildMiniStat('Qalıq Borc', '${debt.toStringAsFixed(0)} ₼', debt > 0.01 ? AppColors.rose : AppColors.emerald),
            ],
          ),

          const SizedBox(height: 10),

          // Action buttons bar (Rollara və icazələrə uyğun filtrlənir)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // + Ödəniş (Yalnız ödəniş yaratma icazəsi olanlar)
              if (canCreate)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 30),
                  ),
                  onPressed: () => NewPaymentDialog.show(
                    context,
                    initialStudentId: studentId,
                    initialStudentName: fullName,
                    onPaymentRecorded: _loadPageData,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Ödəniş', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),

              // 360° Modalı (Müqaviləyə baxış icazəsi olan hər kəs görə bilər)
              if (primaryContractId != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 30),
                  ),
                  onPressed: () => StudentFinanceModal.show(
                    context,
                    contractId: primaryContractId,
                    studentNameFallback: fullName,
                    codeFallback: studentNumber,
                  ),
                  icon: const Icon(Icons.history_rounded, size: 14),
                  label: const Text('360° Tarixçə', style: TextStyle(fontSize: 11)),
                ),

              // Qrafik tənzimləmə (Yalnız qrafik idarəetmə icazəsi olanlar)
              if (canManageInst && contractsList.isNotEmpty)
                IconButton.outlined(
                  tooltip: 'Aylıq qrafiki tənzimlə',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    final first = contractsList.first;
                    final inv = StudentInvoice(
                      id: first['id'].toString(),
                      contractId: _asInt(first['id']),
                      code: first['code']?.toString() ?? '',
                      invoiceNumber: first['code']?.toString() ?? '',
                      contractType: first['type']?.toString() ?? 'education',
                      contractTypeLabel: first['type_label']?.toString() ?? 'Müqavilə',
                      studentId: studentId.toString(),
                      studentName: fullName,
                      parentName: parentName,
                      className: className,
                      dueDate: DateTime.now(),
                      amount: (first['final_amount'] as num?)?.toDouble() ?? 0.0,
                      totalAmount: (first['total_amount'] as num?)?.toDouble() ?? 0.0,
                      discountAmount: (first['discount_amount'] as num?)?.toDouble() ?? 0.0,
                      finalAmount: (first['final_amount'] as num?)?.toDouble() ?? 0.0,
                      paidAmount: (first['paid_amount'] as num?)?.toDouble() ?? 0.0,
                      remainingDebt: (first['remaining_debt'] as num?)?.toDouble() ?? 0.0,
                      status: 'active',
                      statusLabel: 'Aktiv',
                    );
                    ManageScheduleDialog.show(context, inv, onSaved: _loadPageData);
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 15),
                ),

              // Güzəşt tətbiq et (Yalnız güzəşt tətbiq etmə icazəsi olanlar)
              if (canDiscount && contractsList.isNotEmpty)
                IconButton.outlined(
                  tooltip: 'Güzəşt tətbiq et',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    final first = contractsList.first;
                    final inv = StudentInvoice(
                      id: first['id'].toString(),
                      contractId: _asInt(first['id']),
                      code: first['code']?.toString() ?? '',
                      invoiceNumber: first['code']?.toString() ?? '',
                      contractType: first['type']?.toString() ?? 'education',
                      contractTypeLabel: first['type_label']?.toString() ?? 'Müqavilə',
                      studentId: studentId.toString(),
                      studentName: fullName,
                      parentName: parentName,
                      className: className,
                      dueDate: DateTime.now(),
                      amount: (first['final_amount'] as num?)?.toDouble() ?? 0.0,
                      totalAmount: (first['total_amount'] as num?)?.toDouble() ?? 0.0,
                      discountAmount: (first['discount_amount'] as num?)?.toDouble() ?? 0.0,
                      finalAmount: (first['final_amount'] as num?)?.toDouble() ?? 0.0,
                      paidAmount: (first['paid_amount'] as num?)?.toDouble() ?? 0.0,
                      remainingDebt: (first['remaining_debt'] as num?)?.toDouble() ?? 0.0,
                    );
                    ContractQuickActions.showDiscountDialog(context, inv, onSuccess: _loadPageData);
                  },
                  icon: const Icon(Icons.discount_rounded, size: 15),
                ),

              // Müqavilə məbləğinə düzəliş et (Yalnız məbləğ dəyişmə icazəsi olanlar)
              if (canEditAmt && contractsList.isNotEmpty)
                IconButton.outlined(
                  tooltip: 'Müqavilə məbləğinə düzəliş et',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    final first = contractsList.first;
                    final inv = StudentInvoice(
                      id: first['id'].toString(),
                      contractId: _asInt(first['id']),
                      code: first['code']?.toString() ?? '',
                      invoiceNumber: first['code']?.toString() ?? '',
                      contractType: first['type']?.toString() ?? 'education',
                      contractTypeLabel: first['type_label']?.toString() ?? 'Müqavilə',
                      studentId: studentId.toString(),
                      studentName: fullName,
                      parentName: parentName,
                      className: className,
                      dueDate: DateTime.now(),
                      amount: (first['final_amount'] as num?)?.toDouble() ?? 0.0,
                      totalAmount: (first['total_amount'] as num?)?.toDouble() ?? 0.0,
                      discountAmount: (first['discount_amount'] as num?)?.toDouble() ?? 0.0,
                      finalAmount: (first['final_amount'] as num?)?.toDouble() ?? 0.0,
                      paidAmount: (first['paid_amount'] as num?)?.toDouble() ?? 0.0,
                      remainingDebt: (first['remaining_debt'] as num?)?.toDouble() ?? 0.0,
                    );
                    ContractQuickActions.showUpdateAmountDialog(context, inv, onSuccess: _loadPageData);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                ),

              // Çap et (PDF)
              if (canPrintCont && primaryContractId != null)
                IconButton.outlined(
                  tooltip: 'Müqaviləni çap et',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.openContractPrint(context, primaryContractId),
                  icon: const Icon(Icons.print_rounded, size: 15),
                ),

              // Bütün qəbzlər (Yalnız qəbz görmə/çap icazəsi olanlar)
              if (canPrintRec && s['all_receipts_url'] != null)
                IconButton.outlined(
                  tooltip: 'Bütün qəbzlər',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _openReceipt(s['all_receipts_url']?.toString()),
                  icon: const Icon(Icons.receipt_long_rounded, size: 15),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  // ===== TAB 2: VALİDEYNƏ GÖRƏ ÖDƏNİŞLƏR =====
  Widget _buildParentsTab(AppPalette palette, SessionController session) {
    if (_allParents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom_rounded, size: 48, color: palette.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text('Valideyn tapılmadı', style: TextStyle(color: palette.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final canCreate = _canCreatePayment(session);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: _allParents.length,
      itemBuilder: (context, idx) {
        final p = _allParents[idx];
        final parentId = _asInt(p['id']);
        final name = p['full_name']?.toString() ?? 'Valideyn';
        final phone = p['phone']?.toString();
        final count = p['children_count'] ?? 0;
        final children = (p['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        final cAmount = (p['contract_amount'] as num?)?.toDouble() ?? 0.0;
        final dAmount = (p['discount_amount'] as num?)?.toDouble() ?? 0.0;
        final pAmount = (p['paid_amount'] as num?)?.toDouble() ?? 0.0;
        final debt = (p['total_debt'] as num?)?.toDouble() ?? 0.0;

        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () => _makePhoneCall(phone),
                            child: Text(
                              phone,
                              style: TextStyle(fontSize: 11.5, color: palette.brandRoyal, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count uşaq',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.brandRoyal),
                    ),
                  ),
                ],
              ),

              // Children chips
              if (children.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: children.map((ch) {
                    final chName = ch['name']?.toString() ?? '';
                    final chClass = ch['class_name']?.toString() ?? '';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Text(
                        '$chName ($chClass)',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Financial stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Müqavilə', '${cAmount.toStringAsFixed(0)} ₼', palette.textPrimary),
                  _buildMiniStat('Güzəşt', '${dAmount.toStringAsFixed(0)} ₼', const Color(0xFFD97706)),
                  _buildMiniStat('Ödənilib', '${pAmount.toStringAsFixed(0)} ₼', AppColors.emerald),
                  _buildMiniStat('Qalıq Borc', '${debt.toStringAsFixed(0)} ₼', debt > 0.01 ? AppColors.rose : AppColors.emerald),
                ],
              ),

              if (canCreate) ...[
                const SizedBox(height: 10),

                // Actions (Yalnız ödəniş yaratma icazəsi olanlar görə bilər)
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 30),
                      ),
                      onPressed: () => NewPaymentDialog.show(
                        context,
                        initialParentId: parentId,
                        initialParentName: name,
                        onPaymentRecorded: _loadPageData,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Ödəniş Qəbul Et', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ===== TAB 3: GÖZLƏYƏN ÖDƏNİŞLƏR =====
  Widget _buildPendingTab(AppPalette palette, SessionController session) {
    if (_pendingPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.emerald.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text('Hazırda təsdiq gözləyən ödəniş yoxdur', style: TextStyle(color: palette.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final canApprove = _canApprovePending(session);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: _pendingPayments.length,
      itemBuilder: (context, idx) {
        final item = _pendingPayments[idx];
        final student = item['student_name']?.toString() ?? '—';
        final parent = item['parent_name']?.toString() ?? '—';
        final code = item['contract_code']?.toString() ?? '—';
        final typeLabel = item['contract_type_label']?.toString() ?? 'Müqavilə';
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final date = item['payment_date']?.toString() ?? '';
        final notes = item['notes']?.toString();

        return ModernCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                        Text('Valideyn: $parent', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(2)} ₼',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.emerald),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.brandAzure.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$typeLabel ($code)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: palette.brandAzure)),
                  ),
                  const SizedBox(width: 8),
                  Text('Tarix: $date', style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                ],
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Qeyd: $notes', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: palette.textSecondary)),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),

              // Action buttons (Təsdiqlə / İmtina et) - Yalnız səlahiyyəti olanlara
              if (canApprove)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rose,
                        side: const BorderSide(color: AppColors.rose),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                      onPressed: () => _handleRejectPending(item),
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('İmtina et', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                      onPressed: () => _handleApprovePending(item),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: const Text('Təsdiqlə', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 13, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('Təsdiq gözləyir', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ===== TAB 4: ÖDƏNİŞ JURNALI =====
  Widget _buildJournalTab(AppPalette palette, SessionController session) {
    if (_recentPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: palette.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text('Ödəniş qeydi tapılmadı', style: TextStyle(color: palette.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final canPrintRec = _canPrintReceipt(session);
    final canCancel = _canCancelPayment(session);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: _recentPayments.length,
      itemBuilder: (context, idx) {
        final p = _recentPayments[idx];
        final code = p['code']?.toString() ?? 'Ödəniş';
        final student = p['student_name']?.toString() ?? '—';
        final contractCode = p['contract_code']?.toString() ?? '—';
        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        final date = p['payment_date']?.toString() ?? '';
        final method = p['payment_method_label']?.toString() ?? p['payment_method']?.toString() ?? 'Nağd';
        final bank = p['bank_account']?.toString() ?? '';
        final notes = p['notes']?.toString();

        return ModernCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                child: const Icon(Icons.arrow_downward_rounded, color: AppColors.emerald, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(code, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.brandRoyal)),
                        Text('+${amount.toStringAsFixed(2)} ₼', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.emerald)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$student • $contractCode', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '$date · $method${bank.isNotEmpty ? " · $bank" : ""}',
                      style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                    ),
                    if (notes != null && notes.isNotEmpty)
                      Text('Qeyd: $notes', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: palette.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (canPrintRec && p['receipt_url'] != null)
                IconButton(
                  tooltip: 'Qəbzi çap et / bax',
                  icon: const Icon(Icons.print_outlined, size: 18),
                  onPressed: () => _openReceipt(p['receipt_url']?.toString()),
                ),
              if (canCancel)
                IconButton(
                  tooltip: 'Ödənişi ləğv et',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
                  onPressed: () => _handleCancelPayment(p),
                ),
            ],
          ),
        );
      },
    );
  }
}
