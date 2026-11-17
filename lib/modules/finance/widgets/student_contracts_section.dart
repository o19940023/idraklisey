import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../data/models/finance_model.dart';
import 'contract_quick_actions.dart';
import 'manage_schedule_dialog.dart';
import 'edit_contract_sheet.dart';
import 'student_finance_modal.dart';

class StudentContractsSection extends StatefulWidget {
  final int? studentId;
  final String studentNumber;
  final String studentName;

  const StudentContractsSection({
    super.key,
    required this.studentId,
    required this.studentNumber,
    required this.studentName,
  });

  @override
  State<StudentContractsSection> createState() => _StudentContractsSectionState();
}

class _StudentContractsSectionState extends State<StudentContractsSection> {
  bool _isLoading = true;
  String? _errorMessage;
  List<StudentInvoice> _contracts = [];

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SchoolApiService.instance.fetchContractsDetailed(
        search: widget.studentNumber.isNotEmpty ? widget.studentNumber : null,
        studentId: widget.studentId,
      );

      if (!mounted) return;

      if (res != null && res['success'] == true) {
        final rawList = (res['data'] as List?) ?? [];
        final parsed = rawList.map((e) => StudentInvoice.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _contracts = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res?['message']?.toString() ?? 'Müqavilələr yüklənmədi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Xəta: $e';
        _isLoading = false;
      });
    }
  }

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
      _loadContracts();
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
      _loadContracts();
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
      _loadContracts();
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
                      '${inv.code} • ${inv.studentName}',
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
                      onPressed: () {
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
      _loadContracts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canCreateContract = isSuper || session.can('gopanel.finance.student_contracts.create');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Müqavilələr (${_contracts.length})',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_contracts.isNotEmpty) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        final first = _contracts.first;
                        final cId = first.contractId ?? int.tryParse(first.id);
                        if (cId != null) {
                          StudentFinanceModal.show(
                            context,
                            contractId: cId,
                            studentNameFallback: widget.studentName,
                            codeFallback: widget.studentNumber,
                          );
                        }
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 15),
                      label: const Text('360° Maliyyə', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (canCreateContract)
                    TextButton.icon(
                      onPressed: () => EditContractSheet.show(
                        context,
                        studentId: widget.studentId,
                        onSaved: _loadContracts,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: const Text('Yeni Müqavilə'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Body
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(_errorMessage!, style: TextStyle(color: palette.textSecondary, fontSize: 13))),
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadContracts),
              ],
            ),
          )
        else if (_contracts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 40, color: palette.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('Bu şagird üzrə aktiv müqavilə yoxdur', style: TextStyle(color: palette.textSecondary, fontSize: 13)),
                if (canCreateContract) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => EditContractSheet.show(
                      context,
                      studentId: widget.studentId,
                      onSaved: _loadContracts,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Müqavilə Bağla'),
                  ),
                ],
              ],
            ),
          )
        else
          ..._contracts.map((inv) => _buildContractCard(inv, palette, session)),
      ],
    );
  }

  Widget _buildContractCard(StudentInvoice inv, AppPalette palette, SessionController session) {
    Color dirColor = AppColors.warning;
    IconData dirIcon = Icons.hourglass_top_rounded;
    if (inv.directorApprovalStatus == 'approved') {
      dirColor = AppColors.emerald;
      dirIcon = Icons.verified_rounded;
    } else if (inv.directorApprovalStatus == 'rejected') {
      dirColor = AppColors.rose;
      dirIcon = Icons.cancel_rounded;
    }

    final isSuper = session.profile?.isSuper == true;
    final canEditContract = isSuper || session.can('gopanel.finance.student_contracts.update');
    final canManageInstallments = isSuper || session.can('gopanel.finance.student_contracts.manage_installments');
    final canCreatePayment = isSuper || session.can('gopanel.finance.payments.create') || session.can('gopanel.finance.invoices.manage_payments');
    final canApplyDiscount = isSuper || session.can('gopanel.finance.student_invoices.apply_discount');
    final canEditAmount = isSuper || session.can('gopanel.finance.student_contracts.edit_amount');
    final canPrintContract = isSuper || session.can('gopanel.finance.student_contracts.print') || session.can('gopanel.finance.student_contracts.view');
    final canDirectorApprove = isSuper || session.can('gopanel.finance.student_contracts.director_approve');
    final canTerminate = isSuper || session.can('gopanel.finance.student_contracts.delete') || session.can('gopanel.finance.student_contracts.update');

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code, Contract Type, Director Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  final cId = inv.contractId ?? int.tryParse(inv.id);
                  if (cId != null) {
                    StudentFinanceModal.show(
                      context,
                      contractId: cId,
                      studentNameFallback: widget.studentName,
                      codeFallback: widget.studentNumber,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.brandAzure.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            inv.code.isNotEmpty ? inv.code : inv.invoiceNumber,
                            style: TextStyle(color: palette.brandAzure, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded, size: 12, color: palette.brandAzure),
                        ],
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
              ),
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

          // Financial breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yekun Məbləğ', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                  Text(
                    '${inv.finalAmount.toStringAsFixed(2)} ₼',
                    style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Ödənilib', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                  Text(
                    '${inv.paidAmount.toStringAsFixed(2)} ₼',
                    style: const TextStyle(color: AppColors.emerald, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Qalıq Borc', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
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
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Redaktə
              if (canEditContract)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => EditContractSheet.show(context, contractId: inv.contractId, onSaved: _loadContracts),
                  icon: const Icon(Icons.edit_note_rounded, size: 15),
                  label: const Text('Redaktə', style: TextStyle(fontSize: 11)),
                ),

              // Qrafik
              if (canManageInstallments)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => ManageScheduleDialog.show(context, inv, onSaved: _loadContracts),
                  icon: const Icon(Icons.calendar_month_rounded, size: 15),
                  label: const Text('Qrafik', style: TextStyle(fontSize: 11)),
                ),

              // Ödəniş
              if (canCreatePayment && inv.balance > 0)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _handleRecordPayment(inv),
                  icon: const Icon(Icons.payments_rounded, size: 15),
                  label: const Text('Ödəniş', style: TextStyle(fontSize: 11)),
                ),

              // Güzəşt
              if (canApplyDiscount)
                IconButton.outlined(
                  tooltip: 'Güzəşt tətbiq et',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.showDiscountDialog(context, inv, onSuccess: _loadContracts),
                  icon: const Icon(Icons.discount_rounded, size: 15),
                ),

              // Məbləğ
              if (canEditAmount)
                IconButton.outlined(
                  tooltip: 'Məbləği dəyiş',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.showUpdateAmountDialog(context, inv, onSuccess: _loadContracts),
                  icon: const Icon(Icons.price_change_rounded, size: 15),
                ),

              // Çap
              if (canPrintContract && inv.contractId != null)
                IconButton.outlined(
                  tooltip: 'Çap et (PDF)',
                  style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => ContractQuickActions.openContractPrint(context, inv.contractId!),
                  icon: const Icon(Icons.print_rounded, size: 15),
                ),

              // Tarixçə (Full 360 Payment History Modal)
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
                icon: const Icon(Icons.receipt_long_rounded, size: 15),
              ),

              // Direktor təsdiq/imtina
              if (canDirectorApprove && inv.directorApprovalStatus == 'pending') ...[
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                    foregroundColor: AppColors.emerald,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'Təsdiqlə',
                  onPressed: () => _handleDirectorApprove(inv),
                  icon: const Icon(Icons.check_rounded, size: 15),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.rose.withValues(alpha: 0.15),
                    foregroundColor: AppColors.rose,
                    visualDensity: VisualDensity.compact,
                  ),
                  tooltip: 'İmtina et',
                  onPressed: () => _handleDirectorReject(inv),
                  icon: const Icon(Icons.close_rounded, size: 15),
                ),
              ],

              // Xitam
              if (canTerminate && inv.status != 'cancelled')
                IconButton(
                  tooltip: 'Xitam ver',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.rose,
                  ),
                  onPressed: () => _handleTerminateContract(inv),
                  icon: const Icon(Icons.block_rounded, size: 15),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
