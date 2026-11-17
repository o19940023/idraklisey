import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/finance_model.dart';
import '../widgets/contract_quick_actions.dart';
import '../widgets/manage_schedule_dialog.dart';
import '../widgets/edit_contract_sheet.dart';
import '../widgets/student_finance_modal.dart';

class StudentInvoicesScreen extends StatefulWidget {
  const StudentInvoicesScreen({super.key});

  @override
  State<StudentInvoicesScreen> createState() => _StudentInvoicesScreenState();
}

class _StudentInvoicesScreenState extends State<StudentInvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  List<StudentInvoice> _invoices = [];
  StudentContractSummary _summary = const StudentContractSummary();

  // Filters
  String _selectedContractType = 'all';
  String _selectedStatus = 'all';
  String _selectedDirectorStatus = 'all';

  final List<Map<String, String>> _contractTypes = [
    {'id': 'all', 'label': 'Bütün tiplər'},
    {'id': 'education', 'label': 'Təhsil haqqı'},
    {'id': 'club', 'label': 'Dərnək'},
    {'id': 'transportation', 'label': 'Nəqliyyat / Servis'},
    {'id': 'support', 'label': 'Dəstək dərsləri'},
    {'id': 'book', 'label': 'Dərslik'},
    {'id': 'uniform', 'label': 'Məktəbli forması'},
    {'id': 'other', 'label': 'Digər'},
  ];

  final List<Map<String, String>> _statuses = [
    {'id': 'all', 'label': 'Hamısı'},
    {'id': 'active', 'label': 'Aktiv'},
    {'id': 'signed', 'label': 'İmzalanıb'},
    {'id': 'draft', 'label': 'Qaralama'},
    {'id': 'cancelled', 'label': 'Xitam verilib'},
  ];

  final List<Map<String, String>> _directorStatuses = [
    {'id': 'all', 'label': 'Direktor: Hamısı'},
    {'id': 'approved', 'label': 'Təsdiqlənib'},
    {'id': 'pending', 'label': 'Təsdiq gözləyir'},
    {'id': 'rejected', 'label': 'İmtina edilib'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SchoolApiService.instance.fetchContractsDetailed(
        search: _searchController.text.trim(),
        contractType: _selectedContractType,
        status: _selectedStatus,
        directorApprovalStatus: _selectedDirectorStatus,
      );

      if (!mounted) return;

      if (res != null && res['success'] == true) {
        final rawList = (res['data'] as List?) ?? [];
        final parsed = rawList.map((e) => StudentInvoice.fromJson(e as Map<String, dynamic>)).toList();
        final summaryData = res['summary'] is Map<String, dynamic>
            ? StudentContractSummary.fromJson(res['summary'] as Map<String, dynamic>)
            : const StudentContractSummary();

        setState(() {
          _invoices = parsed;
          _summary = summaryData;
          _isLoading = false;
        });
      } else {
        final msg = res?['message']?.toString() ?? 'Müqavilələr yüklənərkən xəta baş verdi.';
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Şəbəkə xətası: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _loadData();
  }

  // --- ACTIONS ---

  Future<void> _handleDirectorApprove(StudentInvoice inv) async {
    final contractId = inv.contractId;
    if (contractId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müqaviləni təsdiqlə'),
        content: Text('${inv.code} nömrəli müqaviləni direktor olaraq təsdiqləmək istəyirsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ləğv et')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Təsdiqlə'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await SchoolApiService.instance.directorApproveContract(contractId);
    if (!mounted) return;

    if (res != null && res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Müqavilə təsdiqləndi.'), backgroundColor: AppColors.emerald),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  Future<void> _handleDirectorReject(StudentInvoice inv) async {
    final contractId = inv.contractId;
    if (contractId == null) return;

    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müqaviləyə imtina et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inv.code} nömrəli müqavilə üçün imtina səbəbini daxil edin:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'İmtina səbəbi...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bağla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İmtina et'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await SchoolApiService.instance.directorRejectContract(contractId, reasonCtrl.text.trim());
    if (!mounted) return;

    if (res != null && res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'İmtina qeydə alındı.'), backgroundColor: AppColors.warning),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  Future<void> _handleTerminateContract(StudentInvoice inv) async {
    final contractId = inv.contractId;
    if (contractId == null) return;

    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müqaviləyə xitam ver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inv.code} nömrəli müqaviləyə xitam vermək istəyirsiniz?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Xitam səbəbi...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bağla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xitam ver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await SchoolApiService.instance.terminateStudentContract(contractId, reason: reasonCtrl.text.trim());
    if (!mounted) return;

    if (res != null && res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Müqaviləyə xitam verildi.'), backgroundColor: AppColors.emerald),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  Future<void> _handleRecordPayment(StudentInvoice inv) async {
    final contractId = inv.contractId;
    if (contractId == null) return;

    final amountCtrl = TextEditingController(text: inv.balance > 0 ? inv.balance.toStringAsFixed(2) : '');
    final notesCtrl = TextEditingController();
    String selectedMethod = 'cash';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final palette = AppPalette.of(ctx);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
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
                        decoration: BoxDecoration(
                          color: palette.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ödəniş qəbul et',
                      style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${inv.code} • ${inv.studentName} (${inv.className})',
                      style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Ödənilən məbləğ (AZN)',
                        border: const OutlineInputBorder(),
                        suffixText: '₼',
                        helperText: 'Qalıq borc: ${inv.balance.toStringAsFixed(2)} ₼',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Ödəniş növü',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Nağd')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank köçürməsi')),
                        DropdownMenuItem(value: 'card', child: Text('Onlayn / Terminal kart')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Qeyd (İxtiyari)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Ödənişi təsdiqlə', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () async {
                        final val = double.tryParse(amountCtrl.text.trim());
                        if (val == null || val <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Düzgün məbləğ daxil edin.')),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result != true) return;

    final payAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    final res = await SchoolApiService.instance.recordContractPayment(
      contractId,
      amount: payAmount,
      paymentMethod: selectedMethod,
      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (res != null && res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Ödəniş qeydə alındı.'), backgroundColor: AppColors.emerald),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canCreateContract = isSuper || session.can('gopanel.finance.student_contracts.create');

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Şagird Müqavilələri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (canCreateContract)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => EditContractSheet.show(context, onSaved: _loadData),
              tooltip: 'Yeni Müqavilə',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Yenilə',
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // KPI Header Cards (Scrollable)
              _buildKpiSection(palette),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Şagird, valideyn, kod və ya sinif...',
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _loadData();
                  },
                ),
              ),

              // Contract Types Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _contractTypes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final t = _contractTypes[index];
                    final isSelected = t['id'] == _selectedContractType;
                    return ChoiceChip(
                      label: Text(t['label']!),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedContractType = t['id']!);
                          _loadData();
                        }
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

              const SizedBox(height: 6),

              // Secondary filter row (Contract Status & Director Status)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Contract Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: palette.surface1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            items: _statuses.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['label']!))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                                _loadData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Director Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: palette.surface1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDirectorStatus,
                            isExpanded: true,
                            style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            items: _directorStatuses.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['label']!))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDirectorStatus = val);
                                _loadData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Content List or Loader
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: palette.textSecondary, fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _loadData,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Yenidən yoxla'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _invoices.isEmpty
                            ? Center(
                                child: Text(
                                  'Axtarışa uyğun müqavilə tapılmadı.',
                                  style: TextStyle(color: palette.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.only(top: 4, bottom: 140),
                                itemCount: _invoices.length,
                                itemBuilder: (context, index) {
                                  final inv = _invoices[index];
                                  return _buildContractCard(inv, palette, session);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreateContract
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Müqavilə', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => EditContractSheet.show(context, onSaved: _loadData),
            )
          : null,
    );
  }

  Widget _buildKpiSection(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          _summaryCard('Müqavilələr', '${_summary.totalContracts}', palette.brandRoyal, palette),
          const SizedBox(width: 8),
          _summaryCard('Cəmi Məbləğ', '${_formatMoney(_summary.totalAmount)} ₼', palette.textPrimary, palette),
          const SizedBox(width: 8),
          _summaryCard('Ödənilmiş', '${_formatMoney(_summary.totalPaid)} ₼', AppColors.emerald, palette),
          const SizedBox(width: 8),
          _summaryCard('Qalıq Borc', '${_formatMoney(_summary.totalRemaining)} ₼', AppColors.rose, palette),
          const SizedBox(width: 8),
          _summaryCard('Təsdiq Gözləyən', '${_summary.pendingApprovalCount}', AppColors.warning, palette),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _summaryCard(String title, String value, Color color, AppPalette palette) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(StudentInvoice inv, AppPalette palette, SessionController session) {
    final hasDiscount = inv.discountAmount > 0;
    final isSuper = session.profile?.isSuper == true;

    final canEditContract = isSuper || session.can('gopanel.finance.student_contracts.update');
    final canManageInstallments = isSuper || session.can('gopanel.finance.student_contracts.manage_installments');
    final canCreatePayment = isSuper || session.can('gopanel.finance.payments.create') || session.can('gopanel.finance.invoices.manage_payments');
    final canApplyDiscount = isSuper || session.can('gopanel.finance.student_invoices.apply_discount');
    final canEditAmount = isSuper || session.can('gopanel.finance.student_contracts.edit_amount');
    final canPrintContract = isSuper || session.can('gopanel.finance.student_contracts.print') || session.can('gopanel.finance.student_contracts.view');
    final canDirectorApprove = isSuper || session.can('gopanel.finance.student_contracts.director_approve');
    final canTerminate = isSuper || session.can('gopanel.finance.student_contracts.delete') || session.can('gopanel.finance.student_contracts.update');

    Color dirColor = AppColors.warning;
    IconData dirIcon = Icons.hourglass_top_rounded;
    if (inv.directorApprovalStatus == 'approved') {
      dirColor = AppColors.emerald;
      dirIcon = Icons.verified_rounded;
    } else if (inv.directorApprovalStatus == 'rejected') {
      dirColor = AppColors.rose;
      dirIcon = Icons.cancel_rounded;
    }

    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Code, Contract Type, and Director Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.brandAzure.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.code.isNotEmpty ? inv.code : inv.invoiceNumber,
                      style: TextStyle(color: palette.brandAzure, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.contractTypeLabel,
                      style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              // Director Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dirColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dirColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(dirIcon, size: 12, color: dirColor),
                    const SizedBox(width: 4),
                    Text(
                      inv.directorApprovalLabel,
                      style: TextStyle(color: dirColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Student & Parent details (Clickable to open Student 360 Financial Modal)
          InkWell(
            onTap: () {
              final cId = inv.contractId ?? int.tryParse(inv.id);
              if (cId != null) {
                StudentFinanceModal.show(
                  context,
                  contractId: cId,
                  studentNameFallback: inv.studentName,
                  codeFallback: inv.code,
                );
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: palette.brandRoyal.withValues(alpha: 0.12),
                    child: Text(
                      inv.studentName.isNotEmpty ? inv.studentName.substring(0, 1).toUpperCase() : 'Ş',
                      style: TextStyle(color: palette.brandRoyal, fontWeight: FontWeight.w800, fontSize: 16),
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
                                inv.studentName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.brandRoyal,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded, size: 14, color: palette.brandAzure),
                            const SizedBox(width: 6),
                            if (inv.className.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: palette.brandRoyal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  inv.className,
                                  style: TextStyle(color: palette.brandRoyal, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Valideyn: ${inv.parentName}${inv.parentPhone != null && inv.parentPhone!.isNotEmpty ? " • ${inv.parentPhone}" : ""}',
                          style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        if (inv.academicYearTitle != null && inv.academicYearTitle!.isNotEmpty)
                          Text(
                            inv.academicYearTitle!,
                            style: TextStyle(color: palette.textTertiary, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Financial Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yekun Məbləğ',
                    style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        '${inv.finalAmount.toStringAsFixed(2)} ₼',
                        style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${inv.discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ödənilib',
                    style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${inv.paidAmount.toStringAsFixed(2)} ₼',
                    style: const TextStyle(color: AppColors.emerald, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Qalıq Borc',
                    style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${inv.balance.toStringAsFixed(2)} ₼',
                    style: TextStyle(
                      color: inv.balance > 0 ? AppColors.rose : AppColors.emerald,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons (100% Web Parity - Rol və icazələrə uyğun dinamik görünüş)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Redaktə (Yalnız müqavilə yeniləmə icazəsi olanlar)
              if (canEditContract)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => EditContractSheet.show(context, contractId: inv.contractId, onSaved: _loadData),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Redaktə', style: TextStyle(fontSize: 12)),
                ),

              // 2. Qrafik (Yalnız aylıqları tənzimləmə icazəsi olanlar)
              if (canManageInstallments)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => ManageScheduleDialog.show(context, inv, onSaved: _loadData),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Qrafik', style: TextStyle(fontSize: 12)),
                ),

              // 3. Ödəniş qəbul et (Yalnız ödəniş yaratma icazəsi olanlar)
              if (canCreatePayment && inv.balance > 0)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _handleRecordPayment(inv),
                  icon: const Icon(Icons.payments_rounded, size: 16),
                  label: const Text('Ödəniş', style: TextStyle(fontSize: 12)),
                ),

              // 4. Güzəşt tətbiq et (Yalnız güzəşt icazəsi olanlar)
              if (canApplyDiscount)
                IconButton.outlined(
                  tooltip: 'Güzəşt tətbiq et',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.showDiscountDialog(context, inv, onSuccess: _loadData),
                  icon: const Icon(Icons.discount_rounded, size: 16),
                ),

              // 5. Məbləği dəyiş (Yalnız məbləğ dəyişmə icazəsi olanlar)
              if (canEditAmount)
                IconButton.outlined(
                  tooltip: 'Məbləği dəyiş',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.showUpdateAmountDialog(context, inv, onSuccess: _loadData),
                  icon: const Icon(Icons.price_change_rounded, size: 16),
                ),

              // 6. Çap et (PDF)
              if (canPrintContract && inv.contractId != null)
                IconButton.outlined(
                  tooltip: 'Çap et (PDF)',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.openContractPrint(context, inv.contractId!),
                  icon: const Icon(Icons.print_rounded, size: 16),
                ),

              // 7. Tarixçə (Full 360 Payment History Modal - Müqavilə görənlər üçün həmişə aktiv)
              IconButton.outlined(
                tooltip: 'Ödəniş tarixçəsi',
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () {
                  final cId = inv.contractId ?? int.tryParse(inv.id);
                  if (cId != null) {
                    StudentFinanceModal.show(
                      context,
                      contractId: cId,
                      studentNameFallback: inv.studentName,
                      codeFallback: inv.code,
                    );
                  }
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
              ),

              // 8. Direktor təsdiq/imtina (Yalnız direktor təsdiq icazəsi olanlar)
              if (canDirectorApprove && inv.directorApprovalStatus == 'pending') ...[
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                    foregroundColor: AppColors.emerald,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'Təsdiqlə',
                  onPressed: () => _handleDirectorApprove(inv),
                  icon: const Icon(Icons.check_rounded, size: 16),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.rose.withValues(alpha: 0.15),
                    foregroundColor: AppColors.rose,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'İmtina et',
                  onPressed: () => _handleDirectorReject(inv),
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              ],

              // 9. Xitam ver (Yalnız xitam/delete icazəsi olanlar)
              if (canTerminate && inv.status != 'cancelled')
                IconButton(
                  tooltip: 'Xitam ver',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.rose,
                  ),
                  onPressed: () => _handleTerminateContract(inv),
                  icon: const Icon(Icons.block_rounded, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
