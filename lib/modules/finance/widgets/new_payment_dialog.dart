import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class NewPaymentDialog extends StatefulWidget {
  final int? initialStudentId;
  final String? initialStudentName;
  final int? initialParentId;
  final String? initialParentName;
  final VoidCallback onPaymentRecorded;

  const NewPaymentDialog({
    super.key,
    this.initialStudentId,
    this.initialStudentName,
    this.initialParentId,
    this.initialParentName,
    required this.onPaymentRecorded,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialStudentId,
    String? initialStudentName,
    int? initialParentId,
    String? initialParentName,
    required VoidCallback onPaymentRecorded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewPaymentDialog(
        initialStudentId: initialStudentId,
        initialStudentName: initialStudentName,
        initialParentId: initialParentId,
        initialParentName: initialParentName,
        onPaymentRecorded: onPaymentRecorded,
      ),
    );
  }

  @override
  State<NewPaymentDialog> createState() => _NewPaymentDialogState();
}

class _NewPaymentDialogState extends State<NewPaymentDialog> {
  String _mode = 'student'; // 'student' or 'parent'

  int? _selectedStudentId;
  String? _selectedStudentName;
  int? _selectedParentId;
  String? _selectedParentName;

  String? _selectedContractType;
  DateTime _paymentDate = DateTime.now();
  String _selectedMethod = 'bank_transfer';
  int? _selectedAccountId;
  bool _isFutureYear = false;

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loadingMeta = true;
  bool _loadingInvoices = false;
  bool _submitting = false;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _contractTypes = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _noteTemplates = [];

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  // Pending Invoices from API
  bool _hasHistoricalDebt = false;
  String _historicalDebtAmount = '0.00';
  List<Map<String, dynamic>> _pendingInvoices = [];
  String? _parentInfo;

  @override
  void initState() {
    super.initState();
    if (widget.initialParentId != null) {
      _mode = 'parent';
      _selectedParentId = widget.initialParentId;
      _selectedParentName = widget.initialParentName;
    } else if (widget.initialStudentId != null) {
      _mode = 'student';
      _selectedStudentId = widget.initialStudentId;
      _selectedStudentName = widget.initialStudentName;
    }

    _loadInitialMeta();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMeta() async {
    setState(() => _loadingMeta = true);
    final res = await SchoolApiService.instance.fetchStudentPaymentsPage();
    if (res != null) {
      final meta = res['meta'] as Map<String, dynamic>? ?? {};
      _students = (res['students'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _parents = (res['parents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _contractTypes = (meta['contract_types'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _paymentMethods = (meta['payment_methods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _bankAccounts = (meta['bank_accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _noteTemplates = (meta['note_templates'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (_bankAccounts.isNotEmpty && _selectedAccountId == null) {
        final firstId = _asInt(_bankAccounts.first['id'], fallback: -1);
        if (firstId != -1) _selectedAccountId = firstId;
      }
    }

    setState(() => _loadingMeta = false);

    if (_selectedStudentId != null || _selectedParentId != null) {
      _fetchPendingInvoices();
    }
  }

  Future<void> _fetchPendingInvoices() async {
    setState(() => _loadingInvoices = true);

    try {
      final res = await SchoolApiService.instance.fetchPaymentPendingInvoices(
        studentId: _mode == 'student' ? _selectedStudentId : null,
        parentId: _mode == 'parent' ? _selectedParentId : null,
        contractType: _selectedContractType,
      );

      if (res != null) {
        setState(() {
          _hasHistoricalDebt = res['has_historical_debt'] == true;
          _historicalDebtAmount = res['historical_debt_amount']?.toString() ?? '0.00';
          _pendingInvoices = (res['invoices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _parentInfo = res['parent_info']?.toString();

          // Calculate total remaining debt from invoices
          double totalRemaining = 0.0;
          for (final inv in _pendingInvoices) {
            totalRemaining += double.tryParse(inv['total_due']?.toString() ?? inv['remaining_debt']?.toString() ?? '0') ?? 0.0;
          }

          if (totalRemaining > 0 && _amountCtrl.text.isEmpty) {
            _amountCtrl.text = totalRemaining.toStringAsFixed(2);
          }
        });
      }
    } catch (_) {}

    setState(() => _loadingInvoices = false);
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa düzgün məbləğ daxil edin.'), backgroundColor: AppColors.rose),
      );
      return;
    }

    if (_mode == 'student' && _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şagird seçilməlidir.'), backgroundColor: AppColors.rose),
      );
      return;
    }

    if (_mode == 'parent' && _selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valideyn seçilməlidir.'), backgroundColor: AppColors.rose),
      );
      return;
    }

    setState(() => _submitting = true);

    final payload = <String, dynamic>{
      'amount': amount,
      'payment_date': '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
      'payment_method': _selectedMethod,
      'notes': _notesCtrl.text.trim(),
      'is_future_year': _isFutureYear ? 1 : 0,
      if (_mode == 'student') 'student_id': _selectedStudentId,
      if (_mode == 'parent') 'parent_id': _selectedParentId,
      if (_selectedAccountId != null && _selectedMethod != 'cash') 'bank_account_id': _selectedAccountId,
      if (_selectedContractType != null && _selectedContractType!.isNotEmpty) 'contract_type': _selectedContractType,
    };

    final res = await SchoolApiService.instance.storeStudentPayment(payload);
    setState(() => _submitting = false);

    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Ödəniş uğurla qeydə alındı!'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
      widget.onPaymentRecorded();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message']?.toString() ?? 'Ödəniş qeydə alınarkən xəta baş verdi.'),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: palette.borderHairline),
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

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_card_rounded, color: AppColors.emerald, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Ödəniş Qəbulu',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (_mode == 'student' && _selectedStudentName != null && _selectedStudentName!.isNotEmpty)
                            Text(
                              _selectedStudentName!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.brandAzure,
                              ),
                            )
                          else if (_mode == 'parent' && _selectedParentName != null && _selectedParentName!.isNotEmpty)
                            Text(
                              _selectedParentName!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.brandAzure,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.textSecondary, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Body
            Expanded(
              child: _loadingMeta
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mode switch: Şagird vs Valideyn
                          _buildModeSwitch(palette),

                          const SizedBox(height: 14),

                          // Target Selector (Student / Parent)
                          if (_mode == 'student')
                            _buildStudentSelector(palette)
                          else
                            _buildParentSelector(palette),

                          // Parent contact info chip if student selected
                          if (_parentInfo != null && _parentInfo!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: palette.borderHairline),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.family_restroom_rounded, size: 14, color: palette.brandAzure),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Valideyn: $_parentInfo',
                                      style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Contract Type Dropdown
                          _buildContractTypeSelector(palette),

                          const SizedBox(height: 14),

                          // Pending Invoices / Outstanding Area
                          _buildPendingObligationsArea(palette),

                          const SizedBox(height: 16),

                          // Amount & Payment Date
                          Row(
                            children: [
                              // Amount Field
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Məbləğ (AZN) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _amountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.textPrimary),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                                        suffixText: '₼',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Date Field
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ödəniş Tarixi *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _paymentDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          setState(() => _paymentDate = picked);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: palette.borderHairline),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${_paymentDate.day.toString().padLeft(2, '0')}.${_paymentDate.month.toString().padLeft(2, '0')}.${_paymentDate.year}',
                                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                                            ),
                                            Icon(Icons.calendar_today_rounded, size: 14, color: palette.brandRoyal),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Payment Method & Bank Account
                          Row(
                            children: [
                              // Method
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ödəniş Metodu *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedMethod,
                                      isDense: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w600),
                                      items: _paymentMethods.isNotEmpty
                                          ? _paymentMethods.map((m) {
                                              return DropdownMenuItem<String>(
                                                value: m['value']?.toString() ?? '',
                                                child: Text(m['label']?.toString() ?? ''),
                                              );
                                            }).toList()
                                          : const [
                                              DropdownMenuItem(value: 'bank_transfer', child: Text('Bank köçürməsi')),
                                              DropdownMenuItem(value: 'cash', child: Text('Nağd (Kassa)')),
                                              DropdownMenuItem(value: 'card', child: Text('Bank kartı')),
                                              DropdownMenuItem(value: 'pos', child: Text('POS Terminal')),
                                            ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedMethod = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              if (_selectedMethod != 'cash') ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Bank Hesabı *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                                      const SizedBox(height: 4),
                                      DropdownButtonFormField<int>(
                                        initialValue: _selectedAccountId,
                                        isDense: true,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w600),
                                        items: _bankAccounts.map((b) {
                                          return DropdownMenuItem<int>(
                                            value: _asInt(b['id']),
                                            child: Text(
                                              b['account_name']?.toString() ?? 'Hesab',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(() => _selectedAccountId = val),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Note Templates Chips
                          if (_noteTemplates.isNotEmpty) ...[
                            Text('Qeyd şablonları:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: palette.textTertiary)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _noteTemplates.map((nt) {
                                final title = nt['title']?.toString() ?? '';
                                final text = nt['text']?.toString() ?? title;
                                return ActionChip(
                                  label: Text(title, style: const TextStyle(fontSize: 10.5)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final current = _notesCtrl.text.trim();
                                    _notesCtrl.text = current.isEmpty ? text : '$current, $text';
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Notes text field
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            style: TextStyle(fontSize: 12, color: palette.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Qeydlər daxil edin...',
                              hintStyle: TextStyle(fontSize: 12, color: palette.textTertiary),
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Future Year Checkbox
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              'Bu qeydi gələcək illərdə də göstər',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary),
                            ),
                            value: _isFutureYear,
                            onChanged: (v) => setState(() => _isFutureYear = v ?? false),
                          ),
                        ],
                      ),
                    ),
            ),

            const Divider(height: 1),

            // Submit Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Bağla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submitting ? null : _submitPayment,
                      icon: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        _submitting ? 'Tamamlanır...' : 'Ödənişi Tamamla',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitch(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _mode = 'student';
                  _fetchPendingInvoices();
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _mode == 'student' ? palette.brandRoyal : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: _mode == 'student' ? Colors.white : palette.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Şagirdə görə',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == 'student' ? Colors.white : palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _mode = 'parent';
                  _fetchPendingInvoices();
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _mode == 'parent' ? palette.brandRoyal : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.family_restroom_rounded, size: 14, color: _mode == 'parent' ? Colors.white : palette.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Valideynə görə',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == 'parent' ? Colors.white : palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Şagird Seçin *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: _selectedStudentId,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Şagird axtarın...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: TextStyle(fontSize: 12.5, color: palette.textPrimary, fontWeight: FontWeight.w600),
          items: _students.map((s) {
            final id = _asInt(s['id']);
            final name = s['full_name']?.toString() ?? 'Şagird';
            final className = s['class_name']?.toString() ?? '';
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                '$name ${className.isNotEmpty ? "($className)" : ""}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id != null) {
              final student = _students.firstWhere((s) => s['id'] == id, orElse: () => {});
              setState(() {
                _selectedStudentId = id;
                _selectedStudentName = student['full_name']?.toString();
              });
              _fetchPendingInvoices();
            }
          },
        ),
      ],
    );
  }

  Widget _buildParentSelector(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Valideyn Seçin *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: _selectedParentId,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Valideyn axtarın...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: TextStyle(fontSize: 12.5, color: palette.textPrimary, fontWeight: FontWeight.w600),
          items: _parents.map((p) {
            final id = _asInt(p['id']);
            final name = p['full_name']?.toString() ?? 'Valideyn';
            final count = p['children_count'] ?? 0;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                '$name ($count uşaq)',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id != null) {
              final parent = _parents.firstWhere((p) => p['id'] == id, orElse: () => {});
              setState(() {
                _selectedParentId = id;
                _selectedParentName = parent['full_name']?.toString();
              });
              _fetchPendingInvoices();
            }
          },
        ),
      ],
    );
  }

  Widget _buildContractTypeSelector(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Müqavilə Növü', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _selectedContractType,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w600),
          items: [
            const DropdownMenuItem(value: null, child: Text('Hamısı (Təhsil / Servis / Dərnək)')),
            ..._contractTypes.map((ct) {
              return DropdownMenuItem<String>(
                value: ct['value']?.toString(),
                child: Text(ct['label']?.toString() ?? ''),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _selectedContractType = val);
            _fetchPendingInvoices();
          },
        ),
      ],
    );
  }

  Widget _buildPendingObligationsArea(AppPalette palette) {
    if (_loadingInvoices) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_pendingInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.borderHairline),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: palette.textTertiary),
            const SizedBox(width: 8),
            Text(
              _selectedStudentId != null || _selectedParentId != null
                  ? 'Bütün müqavilələr üzrə borclar ödənilib!'
                  : 'Şagird və ya valideyn seçin...',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historical debt alert
          if (_hasHistoricalDebt) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.rose),
                  const SizedBox(width: 6),
                  Text(
                    'Gecikmiş tarixi borc: $_historicalDebtAmount AZN',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.rose),
                  ),
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ödənilməli Aylıq Qrafik (${_pendingInvoices.length})',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.textPrimary),
              ),
              Text(
                'FIFO Avtomatik',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: palette.brandAzure),
              ),
            ],
          ),
          const SizedBox(height: 6),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _pendingInvoices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final inv = _pendingInvoices[idx];
                final month = inv['month_title']?.toString() ?? '';
                final typeLabel = inv['contract_type_label']?.toString() ?? '';
                final due = inv['total_due']?.toString() ?? inv['remaining_debt']?.toString() ?? '0.00';
                final overdueDays = _asInt(inv['overdue_days']);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(month, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: palette.brandAzure.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(typeLabel, style: TextStyle(fontSize: 9.5, color: palette.brandAzure, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          if (overdueDays > 0)
                            Text('$overdueDays gün gecikmə', style: const TextStyle(fontSize: 9.5, color: AppColors.rose, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '$due ₼',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.rose),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
