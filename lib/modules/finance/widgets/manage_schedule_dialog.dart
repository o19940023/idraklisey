import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/finance_model.dart';

class ScheduleItemRow {
  String month;
  String date;
  double amount;
  bool isManual;

  ScheduleItemRow({
    required this.month,
    required this.date,
    required this.amount,
    this.isManual = false,
  });

  Map<String, dynamic> toJson() => {
    'month': month,
    'date': date,
    'amount': amount,
    'is_manual': isManual ? 1 : 0,
  };
}

class ManageScheduleDialog extends StatefulWidget {
  final StudentInvoice invoice;
  final VoidCallback onSaved;

  const ManageScheduleDialog({
    super.key,
    required this.invoice,
    required this.onSaved,
  });

  static Future<void> show(BuildContext context, StudentInvoice invoice, {required VoidCallback onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManageScheduleDialog(invoice: invoice, onSaved: onSaved),
    );
  }

  @override
  State<ManageScheduleDialog> createState() => _ManageScheduleDialogState();
}

class _ManageScheduleDialogState extends State<ManageScheduleDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  int _installmentsCount = 9;
  final TextEditingController _initialPaymentCtrl = TextEditingController(text: '0.00');
  final TextEditingController _reasonCtrl = TextEditingController();

  List<ScheduleItemRow> _schedule = [];

  final List<String> _monthNames = [
    'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  @override
  void dispose() {
    _initialPaymentCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSchedule() async {
    final contractId = widget.invoice.contractId;
    if (contractId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Müqavilə identifikatoru tapılmadı.';
      });
      return;
    }

    try {
      final res = await SchoolApiService.instance.fetchContractInstallments(contractId);
      final rawList = (res?['installments'] as List?) ?? [];

      final List<ScheduleItemRow> loaded = [];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          loaded.add(ScheduleItemRow(
            month: item['month']?.toString() ?? '',
            date: item['date']?.toString() ?? '',
            amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
            isManual: item['is_manual'] == 1 || item['is_manual'] == true,
          ));
        }
      }

      if (loaded.isEmpty) {
        _generateDefaultSchedule(widget.invoice.numberOfInstallments > 0 ? widget.invoice.numberOfInstallments : 9);
      } else {
        _schedule = loaded;
        _installmentsCount = loaded.length;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Qrafik yüklənərkən xəta: $e';
      });
    }
  }

  void _generateDefaultSchedule(int count) {
    _schedule.clear();
    _installmentsCount = count.clamp(1, 12);
    final initPay = double.tryParse(_initialPaymentCtrl.text.trim()) ?? 0.0;
    final remainingDebt = (widget.invoice.finalAmount - initPay).clamp(0.0, double.infinity);
    final perMonth = count > 0 ? (remainingDebt / count) : 0.0;

    final now = DateTime.now();
    final startYear = (now.month >= 8) ? now.year : now.year - 1;

    for (int i = 0; i < _installmentsCount; i++) {
      final monthIndex = (8 + i) % 12; // 8 = September (0-indexed)
      final yearOffset = (8 + i) ~/ 12;
      final year = startYear + yearOffset;
      final monthNum = monthIndex + 1;
      final dateStr = '$year-${monthNum.toString().padLeft(2, '0')}-15';
      final name = i < _monthNames.length ? _monthNames[i] : 'Ay ${i + 1}';

      _schedule.add(ScheduleItemRow(
        month: name,
        date: dateStr,
        amount: double.parse(perMonth.toStringAsFixed(2)),
        isManual: false,
      ));
    }
  }

  void _distributeEvenly() {
    final initPay = double.tryParse(_initialPaymentCtrl.text.trim()) ?? 0.0;
    final remainingDebt = (widget.invoice.finalAmount - initPay).clamp(0.0, double.infinity);
    if (_schedule.isEmpty) return;

    final perMonth = double.parse((remainingDebt / _schedule.length).toStringAsFixed(2));
    double runningSum = 0.0;

    for (int i = 0; i < _schedule.length; i++) {
      if (i == _schedule.length - 1) {
        // Last installment gets the rounding difference
        _schedule[i].amount = double.parse((remainingDebt - runningSum).clamp(0.0, double.infinity).toStringAsFixed(2));
      } else {
        _schedule[i].amount = perMonth;
        runningSum += perMonth;
      }
      _schedule[i].isManual = false;
    }

    setState(() {});
  }

  double get _targetDebt {
    final initPay = double.tryParse(_initialPaymentCtrl.text.trim()) ?? 0.0;
    return (widget.invoice.finalAmount - initPay).clamp(0.0, double.infinity);
  }

  double get _scheduleSum {
    return _schedule.fold(0.0, (acc, item) => acc + item.amount);
  }

  bool get _isBalanced {
    return (_targetDebt - _scheduleSum).abs() < 0.1;
  }

  Future<void> _selectDate(ScheduleItemRow item) async {
    DateTime initial = DateTime.tryParse(item.date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        item.date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    final contractId = widget.invoice.contractId;
    if (contractId == null) return;

    if (!_isBalanced) {
      final diff = (_targetDebt - _scheduleSum).abs().toStringAsFixed(2);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Balans uyğunsuzluğu'),
          content: Text('Qrafik cəmi ilə qalıq borc arasında $diff AZN fərq var. Yadda saxlamaq istəyirsiniz?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xeyr')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bəli, davam et')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSaving = true);

    final res = await SchoolApiService.instance.saveContractInstallments(
      contractId,
      numberOfInstallments: _schedule.length,
      initialPayment: double.tryParse(_initialPaymentCtrl.text.trim()) ?? 0.0,
      reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
      schedule: _schedule.map((s) => s.toJson()).toList(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res != null && res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Ödəniş qrafiki yeniləndi.'), backgroundColor: AppColors.emerald),
      );
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'), backgroundColor: AppColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: palette.borderHairline),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.rose)))
                : Column(
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
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.invoice.code} • Aylıqları tənzimlə',
                                  style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  widget.invoice.studentName,
                                  style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Config row: Initial Payment & Installments Count
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _initialPaymentCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'İlkin ödəniş (AZN)',
                                isDense: true,
                                border: OutlineInputBorder(),
                                suffixText: '₼',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Bərabər böl', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _distributeEvenly,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Balance Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: palette.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isBalanced ? AppColors.emerald.withValues(alpha: 0.3) : AppColors.rose.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qalıq: ${_targetDebt.toStringAsFixed(2)} ₼  |  Qrafik: ${_scheduleSum.toStringAsFixed(2)} ₼',
                              style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isBalanced ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.rose.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isBalanced ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                    size: 13,
                                    color: _isBalanced ? AppColors.emerald : AppColors.rose,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isBalanced ? 'Balans tamdır' : 'Fərq: ${(_targetDebt - _scheduleSum).abs().toStringAsFixed(2)} ₼',
                                    style: TextStyle(
                                      color: _isBalanced ? AppColors.emerald : AppColors.rose,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Installments List
                      Expanded(
                        child: ListView.separated(
                          itemCount: _schedule.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final item = _schedule[idx];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: palette.surface2.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: palette.borderHairline),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: palette.brandAzure.withValues(alpha: 0.15),
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: palette.brandAzure),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: InkWell(
                                      onTap: () => _selectDate(item),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.month,
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: palette.textPrimary),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded, size: 11, color: palette.brandAzure),
                                              const SizedBox(width: 3),
                                              Text(
                                                item.date,
                                                style: TextStyle(fontSize: 11, color: palette.brandAzure, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: item.amount > 0 ? item.amount.toStringAsFixed(2) : '',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      textAlign: TextAlign.end,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        suffixText: '₼',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) {
                                        item.amount = double.tryParse(val.trim()) ?? 0.0;
                                        item.isManual = true;
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Reason input
                      TextField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Qeyd / Dəyişiklik səbəbi (İxtiyari)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Button
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(_isSaving ? 'Saxlanılır...' : 'Qrafiki Yadda Saxla', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: _isSaving ? null : _save,
                      ),
                    ],
                  ),
      ),
    );
  }
}
