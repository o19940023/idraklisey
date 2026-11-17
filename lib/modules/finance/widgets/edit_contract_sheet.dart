import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'manage_schedule_dialog.dart';

class EditContractSheet extends StatefulWidget {
  final int? contractId;
  final int? studentId;
  final VoidCallback onSaved;

  const EditContractSheet({
    super.key,
    this.contractId,
    this.studentId,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    int? contractId,
    int? studentId,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditContractSheet(
        contractId: contractId,
        studentId: studentId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditContractSheet> createState() => _EditContractSheetState();
}

class _EditContractSheetState extends State<EditContractSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Metadata from backend
  List<Map<String, dynamic>> _contractTypes = [];
  List<Map<String, dynamic>> _statuses = [];
  List<Map<String, dynamic>> _gradeSuffixes = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _studentsList = [];

  // Form Fields
  int? _userId;
  int? _parentId;
  int? _academicYearId;
  String _studentName = '';
  String _parentName = '';
  String _academicYearTitle = '';

  String _contractType = 'education';
  int? _selectedClassId;
  String _gradeSuffix = '';
  int? _selectedClubId;
  String _pickupAddress = '';
  String _dropoffAddress = '';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 300));

  final TextEditingController _totalAmountCtrl = TextEditingController(text: '0.00');
  final TextEditingController _calculatedAmountCtrl = TextEditingController(text: '0.00');

  String _discountMode = 'amount'; // 'amount' or 'percent'
  final TextEditingController _discountValCtrl = TextEditingController(text: '0.00');
  final TextEditingController _initialPaymentCtrl = TextEditingController(text: '0.00');
  final TextEditingController _installmentsCtrl = TextEditingController(text: '9');
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _pickupCtrl = TextEditingController();
  final TextEditingController _dropoffCtrl = TextEditingController();

  String _status = 'active';

  // Custom Schedule Table
  bool _showCustomSchedule = false;
  List<ScheduleItemRow> _customSchedule = [];

  final List<String> _monthNames = [
    'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun'
  ];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _totalAmountCtrl.dispose();
    _calculatedAmountCtrl.dispose();
    _discountValCtrl.dispose();
    _initialPaymentCtrl.dispose();
    _installmentsCtrl.dispose();
    _notesCtrl.dispose();
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    super.dispose();
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  double _asDouble(dynamic v, [double defaultValue = 0.0]) {
    if (v == null) return defaultValue;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? defaultValue;
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SchoolApiService.instance.fetchContractEditForm(
        contractId: widget.contractId,
        studentId: widget.studentId,
      );

      if (!mounted) return;

      if (res != null && res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};

        _contractTypes = (data['contract_types'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _statuses = (data['statuses'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _gradeSuffixes = (data['grade_suffixes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _classes = (data['available_classes'] ?? data['classes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _clubs = (data['clubs'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _parents = (data['parents'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _studentsList = (data['students'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

        final contract = data['contract'] is Map ? Map<String, dynamic>.from(data['contract'] as Map) : null;
        final student = data['student'] is Map ? Map<String, dynamic>.from(data['student'] as Map) : null;
        final academicYears = (data['academic_years'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

        if (contract != null) {
          // Editing existing contract
          _userId = _asInt(contract['user_id']);
          _parentId = _asInt(contract['parent_id']);
          _academicYearId = _asInt(contract['academic_year_id']);
          _contractType = contract['contract_type']?.toString() ?? 'education';
          _selectedClassId = _asInt(contract['class_id']);
          _gradeSuffix = contract['grade_suffix']?.toString() ?? '';
          _selectedClubId = _asInt(contract['club_id']);
          _pickupAddress = contract['pickup_address']?.toString() ?? '';
          _dropoffAddress = contract['dropoff_address']?.toString() ?? '';
          _pickupCtrl.text = _pickupAddress;
          _dropoffCtrl.text = _dropoffAddress;

          if (contract['start_date'] != null) {
            _startDate = DateTime.tryParse(contract['start_date'].toString()) ?? _startDate;
          }
          if (contract['end_date'] != null) {
            _endDate = DateTime.tryParse(contract['end_date'].toString()) ?? _endDate;
          }

          final total = _asDouble(contract['total_amount']);
          final calcTotal = _asDouble(contract['calculated_total_amount'], total);
          _totalAmountCtrl.text = total.toStringAsFixed(2);
          _calculatedAmountCtrl.text = calcTotal.toStringAsFixed(2);

          _discountMode = contract['discount_mode']?.toString() ?? 'amount';
          final discountAmt = _asDouble(contract['discount_amount']);
          final discountPct = _asDouble(contract['discount_percentage']);
          _discountValCtrl.text = _discountMode == 'percent'
              ? (discountPct > 0 ? discountPct.toStringAsFixed(0) : '0')
              : (discountAmt > 0 ? discountAmt.toStringAsFixed(2) : '0.00');

          _initialPaymentCtrl.text = _asDouble(contract['initial_payment']).toStringAsFixed(2);
          _installmentsCtrl.text = (_asInt(contract['number_of_installments']) ?? 9).toString();
          _status = contract['status']?.toString() ?? 'active';
          _notesCtrl.text = contract['notes']?.toString() ?? '';

          // Parse schedule
          final rawSched = contract['payment_schedule'];
          List<dynamic> schedList = [];
          if (rawSched is List) {
            schedList = rawSched;
          } else if (rawSched is String && rawSched.isNotEmpty) {
            try {
              final dec = jsonDecode(rawSched);
              if (dec is List) schedList = dec;
            } catch (_) {}
          }

          if (schedList.isNotEmpty) {
            _customSchedule = schedList.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return ScheduleItemRow(
                month: m['month']?.toString() ?? '',
                date: m['date']?.toString() ?? '',
                amount: _asDouble(m['amount']),
                isManual: m['is_manual'] == 1 || m['is_manual'] == true,
              );
            }).toList();
            _showCustomSchedule = true;
          }
        } else if (student != null) {
          // Creating new contract
          _userId = _asInt(student['id']);
          if (_parents.isNotEmpty) {
            _parentId = _asInt(_parents.first['id']);
          }
          if (academicYears.isNotEmpty) {
            _academicYearId = _asInt(academicYears.first['id']);
          }
        } else if (_studentsList.isNotEmpty && _userId == null) {
          if (academicYears.isNotEmpty) {
            _academicYearId = _asInt(academicYears.first['id']);
          }
        }

        // Display labels
        if (student != null) {
          _studentName = '${student['name'] ?? ''} ${student['surname'] ?? ''}'.trim();
        }
        if (_parents.isNotEmpty) {
          final p = _parents.firstWhere((element) => _asInt(element['id']) == _parentId, orElse: () => _parents.first);
          _parentName = p['full_name']?.toString() ?? p['name']?.toString() ?? '';
        }
        if (academicYears.isNotEmpty) {
          final y = academicYears.firstWhere((element) => _asInt(element['id']) == _academicYearId, orElse: () => academicYears.first);
          _academicYearTitle = y['title']?.toString() ?? '';
        }

        if (_customSchedule.isEmpty) {
          _regenerateSchedule();
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res?['message']?.toString() ?? 'Məlumatlar yüklənərkən xəta baş verdi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Xəta: $e';
      });
    }
  }

  double get _totalAmount => double.tryParse(_totalAmountCtrl.text.trim()) ?? 0.0;
  double get _calculatedTotalAmount => double.tryParse(_calculatedAmountCtrl.text.trim()) ?? _totalAmount;

  double get _discountAmount {
    final val = double.tryParse(_discountValCtrl.text.trim()) ?? 0.0;
    if (_discountMode == 'percent') {
      return (_calculatedTotalAmount * (val / 100)).clamp(0.0, _calculatedTotalAmount);
    }
    return val.clamp(0.0, _calculatedTotalAmount);
  }

  double get _discountPercentage {
    if (_calculatedTotalAmount <= 0) return 0.0;
    if (_discountMode == 'percent') {
      return double.tryParse(_discountValCtrl.text.trim()) ?? 0.0;
    }
    return ((_discountAmount / _calculatedTotalAmount) * 100).clamp(0.0, 100.0);
  }

  double get _finalAmount => (_calculatedTotalAmount - _discountAmount).clamp(0.0, double.infinity);

  double get _initialPayment => double.tryParse(_initialPaymentCtrl.text.trim()) ?? 0.0;

  int get _installmentsCount => int.tryParse(_installmentsCtrl.text.trim()) ?? 9;

  double get _approxMonthlyPayment {
    final remaining = (_finalAmount - _initialPayment).clamp(0.0, double.infinity);
    return _installmentsCount > 0 ? (remaining / _installmentsCount) : 0.0;
  }

  void _regenerateSchedule() {
    final count = _installmentsCount.clamp(1, 12);
    _customSchedule.clear();
    final remaining = (_finalAmount - _initialPayment).clamp(0.0, double.infinity);
    final perMonth = count > 0 ? (remaining / count) : 0.0;

    final startYear = _startDate.year;
    for (int i = 0; i < count; i++) {
      final monthIndex = (_startDate.month - 1 + i) % 12;
      final yearOffset = (_startDate.month - 1 + i) ~/ 12;
      final year = startYear + yearOffset;
      final monthNum = monthIndex + 1;
      final dateStr = '$year-${monthNum.toString().padLeft(2, '0')}-15';
      final name = i < _monthNames.length ? _monthNames[i] : 'Ay ${i + 1}';

      _customSchedule.add(ScheduleItemRow(
        month: name,
        date: dateStr,
        amount: double.parse(perMonth.toStringAsFixed(2)),
        isManual: false,
      ));
    }
  }

  void _distributeEvenly() {
    final remaining = (_finalAmount - _initialPayment).clamp(0.0, double.infinity);
    if (_customSchedule.isEmpty) return;

    final perMonth = double.parse((remaining / _customSchedule.length).toStringAsFixed(2));
    double running = 0.0;
    for (int i = 0; i < _customSchedule.length; i++) {
      if (i == _customSchedule.length - 1) {
        _customSchedule[i].amount = double.parse((remaining - running).clamp(0.0, double.infinity).toStringAsFixed(2));
      } else {
        _customSchedule[i].amount = perMonth;
        running += perMonth;
      }
      _customSchedule[i].isManual = false;
    }
    setState(() {});
  }

  double get _scheduleSum => _customSchedule.fold(0.0, (acc, item) => acc + item.amount);
  double get _scheduleTarget => (_finalAmount - _initialPayment).clamp(0.0, double.infinity);
  bool get _isScheduleBalanced => (_scheduleTarget - _scheduleSum).abs() < 0.1;

  Future<void> _selectDateRange(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 270));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveContract() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şagird seçilməyib.'), backgroundColor: AppColors.rose),
      );
      return;
    }

    if (_parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valideyn seçilməyib.'), backgroundColor: AppColors.rose),
      );
      return;
    }

    setState(() => _isSaving = true);

    final startStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

    final scheduleData = _customSchedule.map((s) => s.toJson()).toList();

    final serviceItem = <String, dynamic>{
      if (widget.contractId != null) 'id': widget.contractId,
      'contract_type': _contractType,
      'start_date': startStr,
      'end_date': endStr,
      'total_amount': _totalAmount,
      'calculated_total_amount': _calculatedTotalAmount,
      'discount_amount': _discountAmount,
      'discount_percentage': _discountPercentage,
      'final_amount': _finalAmount,
      'grade_suffix': _gradeSuffix.isNotEmpty ? _gradeSuffix : null,
      'initial_payment': _initialPayment,
      'number_of_installments': _installmentsCount,
      'payment_schedule': jsonEncode(scheduleData),
    };

    if (_contractType == 'transportation') {
      serviceItem['pickup_address'] = _pickupCtrl.text.trim();
      serviceItem['dropoff_address'] = _dropoffCtrl.text.trim();
      serviceItem['address'] = '${_pickupCtrl.text.trim()} -> ${_dropoffCtrl.text.trim()}';
    }

    if (_contractType == 'club') {
      serviceItem['club_id'] = _selectedClubId;
    }

    final payload = <String, dynamic>{
      'user_id': _userId,
      'parent_id': _parentId,
      'academic_year_id': _academicYearId ?? 4,
      'status': _status,
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      'selected_class_id': _selectedClassId,
      'services': [serviceItem],
    };

    final res = await SchoolApiService.instance.saveContractFull(payload, contractId: widget.contractId);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res != null && res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Müqavilə uğurla yadda saxlanıldı.'),
          backgroundColor: AppColors.emerald,
        ),
      );
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.94),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: palette.borderHairline),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: palette.textSecondary)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _loadFormData, child: const Text('Yenidən yoxla')),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Handle
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.contractId != null ? 'Müqaviləni Redaktə Et' : 'Yeni Müqavilə Bağla',
                                  style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  _studentName.isNotEmpty ? _studentName : 'Şagird müqaviləsi',
                                  style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 16),

                      // Scrollable Form Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. General Info Card (Student, Parent, Academic Year)
                              _buildGeneralInfoSection(palette),
                              const SizedBox(height: 16),

                              // 2. Contract Type & Service Specifics
                              _buildServiceSection(palette),
                              const SizedBox(height: 16),

                              // 3. Dates Section
                              _buildDatesSection(palette),
                              const SizedBox(height: 16),

                              // 4. Financials (Total, Discount, Final Amount)
                              _buildFinancialSection(palette),
                              const SizedBox(height: 16),

                              // 5. Payment Plan & Custom Schedule
                              _buildPaymentPlanSection(palette),
                              const SizedBox(height: 16),

                              // 6. Status & Notes
                              _buildStatusNotesSection(palette),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Save Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Ləğv et'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: palette.brandRoyal,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.check_rounded),
                                label: Text(
                                  _isSaving ? 'Yadda saxlanılır...' : 'Müqaviləni Saxla',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                onPressed: _isSaving ? null : _saveContract,
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

  Future<void> _loadStudentDetails(int studentId) async {
    final res = await SchoolApiService.instance.fetchContractEditForm(studentId: studentId);
    if (!mounted || res == null || res['success'] != true) return;
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final parents = (data['parents'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final student = data['student'] is Map ? Map<String, dynamic>.from(data['student'] as Map) : null;
    setState(() {
      _parents = parents;
      if (student != null) {
        _studentName = '${student['name'] ?? ''} ${student['surname'] ?? ''}'.trim();
      }
      if (_parents.isNotEmpty) {
        _parentId = _asInt(_parents.first['id']);
        _parentName = _parents.first['name']?.toString() ?? '';
      }
    });
  }

  Widget _buildGeneralInfoSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: palette.brandAzure, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ümumi Məlumatlar (Əsas)',
                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.contractId == null && _studentsList.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _userId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Şagird Seçimi',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: _studentsList.map((s) {
                final id = _asInt(s['id']);
                final name = s['name']?.toString() ?? 'Şagird $id';
                final code = s['code']?.toString() ?? '';
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text('$name ${code.isNotEmpty ? '($code)' : ''}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _userId = val;
                    final match = _studentsList.firstWhere((s) => _asInt(s['id']) == val, orElse: () => {});
                    _studentName = match['name']?.toString() ?? '';
                  });
                  _loadStudentDetails(val);
                }
              },
            ),
            const SizedBox(height: 10),
          ] else ...[
            _readOnlyRow('Şagird', _studentName.isNotEmpty ? _studentName : 'Seçilməyib', palette),
            const SizedBox(height: 6),
          ],
          _readOnlyRow('Valideyn', _parentName.isNotEmpty ? _parentName : 'Seçilməyib', palette),
          const SizedBox(height: 6),
          _readOnlyRow('Tədris İli', _academicYearTitle.isNotEmpty ? _academicYearTitle : 'Cari İl', palette),
        ],
      ),
    );
  }

  Widget _readOnlyRow(String label, String value, AppPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  Widget _buildServiceSection(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Müqavilə Tipi və Təyinatı', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),

        // Contract Type Dropdown
        DropdownButtonFormField<String>(
          value: _contractType,
          decoration: const InputDecoration(
            labelText: 'Müqavilə növü',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _contractTypes.map((t) {
            return DropdownMenuItem<String>(
              value: t['value']?.toString(),
              child: Text(t['label']?.toString() ?? ''),
            );
          }).toList(),
          onChanged: widget.contractId != null
              ? null // Locked on edit matching web
              : (val) {
                  if (val != null) setState(() => _contractType = val);
                },
        ),

        // If Education -> Class and Grade Suffix
        if (_contractType == 'education') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Sinif',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: _classes.map((cls) {
                    final id = _asInt(cls['id']);
                    final name = cls['class_name']?.toString() ?? cls['name']?.toString() ?? 'Sinif $id';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedClassId = val;
                      final match = _classes.firstWhere((c) => _asInt(c['id']) == val, orElse: () => {});
                      if (match['grade_suffix'] != null && match['grade_suffix'].toString().isNotEmpty) {
                        _gradeSuffix = match['grade_suffix'].toString();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gradeSuffix.isNotEmpty ? _gradeSuffix : null,
                  decoration: const InputDecoration(
                    labelText: 'Sinif sonluğu',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: _gradeSuffixes.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['value']?.toString(),
                      child: Text(s['label']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _gradeSuffix = val);
                  },
                ),
              ),
            ],
          ),
        ],

        // If Club -> Club dropdown
        if (_contractType == 'club') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedClubId,
            decoration: const InputDecoration(
              labelText: 'Dərnək seçimi',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _clubs.map((c) {
              final id = _asInt(c['id']);
              final name = c['name']?.toString() ?? 'Dərnək $id';
              final price = _asDouble(c['price']);
              return DropdownMenuItem<int>(
                value: id,
                child: Text('$name (${price.toStringAsFixed(0)} AZN)', style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedClubId = val;
                final match = _clubs.firstWhere((c) => _asInt(c['id']) == val, orElse: () => {});
                if (match['price'] != null) {
                  final p = _asDouble(match['price']);
                  _totalAmountCtrl.text = p.toStringAsFixed(2);
                  _calculatedAmountCtrl.text = p.toStringAsFixed(2);
                }
              });
            },
          ),
        ],

        // If Transportation -> Addresses
        if (_contractType == 'transportation') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _pickupCtrl,
            decoration: const InputDecoration(
              labelText: 'Gediş ünvanı (Pickup)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.emerald),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dropoffCtrl,
            decoration: InputDecoration(
              labelText: 'Qayıdış ünvanı (Dropoff)',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_rounded, color: palette.brandAzure),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatesSection(AppPalette palette) {
    final startStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Müqavilə Müddəti', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDateRange(true),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Başlama tarixi',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Text(startStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectDateRange(false),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bitmə tarixi',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Text(endStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSection(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Maliyyə Məbləğləri və Güzəşt', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _totalAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'İllik məbləğ (AZN)',
                  border: OutlineInputBorder(),
                  suffixText: '₼',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) {
                  _calculatedAmountCtrl.text = val;
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _calculatedAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Hesablanmış məbləğ',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: palette.surface2,
                  suffixText: '₼',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Discount Toggle and Input
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _discountValCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _discountMode == 'percent' ? 'Güzəşt (%)' : 'Güzəşt (AZN)',
                  border: const OutlineInputBorder(),
                  suffixText: _discountMode == 'percent' ? '%' : '₼',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('AZN', style: TextStyle(fontSize: 11)),
                      selected: _discountMode == 'amount',
                      onSelected: (val) {
                        if (val) setState(() => _discountMode = 'amount');
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('%', style: TextStyle(fontSize: 11)),
                      selected: _discountMode == 'percent',
                      onSelected: (val) {
                        if (val) setState(() => _discountMode = 'percent');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Final Amount Preview Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.brandAzure.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Güzəşt məbləği:', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                  Text('-${_discountAmount.toStringAsFixed(2)} ₼', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('YEKUN MƏBLƏĞ', style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                  Text(
                    '${_finalAmount.toStringAsFixed(2)} ₼',
                    style: TextStyle(color: palette.brandAzure, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentPlanSection(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ödəniş Planı', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCustomSchedule = !_showCustomSchedule;
                  if (_showCustomSchedule && _customSchedule.isEmpty) {
                    _regenerateSchedule();
                  }
                });
              },
              icon: Icon(_showCustomSchedule ? Icons.expand_less_rounded : Icons.tune_rounded, size: 16),
              label: Text(_showCustomSchedule ? 'Qrafiki bağla' : 'Fərdi qrafik (Manual)'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _initialPaymentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'İlkin ödəniş',
                  border: OutlineInputBorder(),
                  suffixText: '₼',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _installmentsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hissə sayı (Ay)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                onChanged: (val) {
                  _regenerateSchedule();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Təxmini aylıq',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: palette.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                child: Text(
                  '${_approxMonthlyPayment.toStringAsFixed(0)} ₼',
                  style: TextStyle(fontWeight: FontWeight.w800, color: palette.textPrimary, fontSize: 13),
                ),
              ),
            ),
          ],
        ),

        // Custom Schedule Expandable Box
        if (_showCustomSchedule) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aylıq Ödəniş Qrafiki',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: palette.textPrimary),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 14),
                      label: const Text('Bərabər böl', style: TextStyle(fontSize: 11)),
                      onPressed: _distributeEvenly,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Balance status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Borc: ${_scheduleTarget.toStringAsFixed(2)} ₼ | Qrafik: ${_scheduleSum.toStringAsFixed(2)} ₼',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isScheduleBalanced ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.rose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isScheduleBalanced ? 'Balans tamdır' : 'Fərq: ${(_scheduleTarget - _scheduleSum).abs().toStringAsFixed(2)} ₼',
                        style: TextStyle(
                          color: _isScheduleBalanced ? AppColors.emerald : AppColors.rose,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // List of months
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customSchedule.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final row = _customSchedule[idx];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: palette.brandAzure.withValues(alpha: 0.15),
                          child: Text('${idx + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: palette.brandAzure)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(row.month, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: palette.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final current = DateTime.tryParse(row.date) ?? DateTime.now();
                              final p = await showDatePicker(
                                context: context,
                                initialDate: current,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (p != null) {
                                setState(() {
                                  row.date = '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: Text(
                              row.date,
                              style: TextStyle(color: palette.brandAzure, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: row.amount > 0 ? row.amount.toStringAsFixed(2) : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              suffixText: '₼',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              row.amount = double.tryParse(val.trim()) ?? 0.0;
                              row.isManual = true;
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusNotesSection(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status və Qeydlər', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(
            labelText: 'Müqavilə statusu',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _statuses.map((s) {
            return DropdownMenuItem<String>(
              value: s['value']?.toString(),
              child: Text(s['label']?.toString() ?? ''),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _status = val);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Qeydlər',
            hintText: 'Müqavilə ilə bağlı əlavə qeydlər...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
