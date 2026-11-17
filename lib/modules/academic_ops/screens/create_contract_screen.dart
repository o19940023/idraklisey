import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/status_badge.dart';

class CreateContractScreen extends StatefulWidget {
  final String studentId;
  const CreateContractScreen({super.key, required this.studentId});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _ServiceDraft {
  String? id;
  String type;
  String? clubId;
  bool discountPercent = false;
  bool isCalculating = false;
  String? calculationNote;

  final total = TextEditingController(text: '0');
  final startDate = TextEditingController();
  final endDate = TextEditingController();
  final discount = TextEditingController(text: '0');
  final initial = TextEditingController(text: '0');
  final installments = TextEditingController(text: '4');
  final pickup = TextEditingController();
  final dropoff = TextEditingController();
  final uniformItems = TextEditingController();
  final gradeSuffix = TextEditingController();

  _ServiceDraft({required this.type});

  void dispose() {
    total.dispose();
    startDate.dispose();
    endDate.dispose();
    discount.dispose();
    initial.dispose();
    installments.dispose();
    pickup.dispose();
    dropoff.dispose();
    uniformItems.dispose();
    gradeSuffix.dispose();
  }
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _data = {};
  Map<String, dynamic> _student = {};
  Map<String, dynamic> _studentAddressInfo = {};
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _years = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _statuses = [];
  List<Map<String, dynamic>> _existingContracts = [];

  String? _parentId;
  String? _yearId;
  String? _classId;
  String _status = 'draft';
  final _notes = TextEditingController();
  final List<_ServiceDraft> _services = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final s in _services) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final results = await Future.wait([
      SchoolApiService.instance.getContractFormData(widget.studentId),
      SchoolApiService.instance.fetchStudentAddress(widget.studentId),
    ]);

    if (!mounted) return;

    final data = results[0];
    _studentAddressInfo = results[1] ?? {};

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    _data = data;
    _student = (data['student'] as Map?)?.cast<String, dynamic>() ?? {};
    _parents = List<Map<String, dynamic>>.from(data['parents'] ?? []);
    _years = List<Map<String, dynamic>>.from(data['academicYears'] ?? []);
    _classes = List<Map<String, dynamic>>.from(data['classes'] ?? []);
    _clubs = List<Map<String, dynamic>>.from(data['clubs'] ?? []);
    _types = List<Map<String, dynamic>>.from(data['contractTypes'] ?? []);
    _statuses = List<Map<String, dynamic>>.from(data['statuses'] ?? []);
    _existingContracts = List<Map<String, dynamic>>.from(data['existingContracts'] ?? []);

    final defaults = (data['defaults'] as Map?)?.cast<String, dynamic>() ?? {};
    _parentId = _parents.isNotEmpty ? _parents.first['id']?.toString() : null;
    _yearId = defaults['academicYearId']?.toString();
    _status = 'draft';

    final initialService = _ServiceDraft(type: 'education')
      ..startDate.text = defaults['startDate']?.toString() ?? ''
      ..endDate.text = defaults['endDate']?.toString() ?? ''
      ..gradeSuffix.text = _student['gradeSuffix']?.toString() ?? _studentAddressInfo['target_grade_suffix']?.toString() ?? '';

    _attachListeners(initialService);
    _services.add(initialService);

    setState(() => _loading = false);

    if (_yearId != null) {
      _fetchTuitionFeeForService(initialService);
    }
  }

  void _attachListeners(_ServiceDraft s) {
    for (final c in [s.total, s.startDate, s.endDate, s.discount, s.initial, s.installments]) {
      c.addListener(_recalc);
    }
  }

  void _recalc() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchTuitionFeeForService(_ServiceDraft s) async {
    if (_yearId == null) return;
    setState(() => s.isCalculating = true);

    final fee = await SchoolApiService.instance.fetchTuitionFee(
      userId: widget.studentId,
      academicYearId: _yearId!,
      contractType: s.type,
    );

    if (!mounted) return;
    setState(() {
      s.isCalculating = false;
      if (fee != null && fee['amount'] != null) {
        final amount = double.tryParse(fee['amount'].toString()) ?? 0;
        if (amount > 0) {
          s.total.text = amount.toStringAsFixed(0);
          final lvl = fee['grade_level'] ?? fee['matched_grade_level'] ?? '';
          s.calculationNote = 'Tarif tapıldı: ${amount.toStringAsFixed(2)} AZN ($lvl-ci sinif)';
        }
      } else {
        s.calculationNote = 'Bu sinif üçün xüsusi tarif tapılmadı, məbləği daxil edin.';
      }
    });
  }

  Future<void> _calculateTransportForService(_ServiceDraft s) async {
    if (_yearId == null) return;
    final start = s.startDate.text.trim();
    if (start.isEmpty) {
      _snack('Zəhmət olmasa başlama tarixini seçin', ok: false);
      return;
    }
    final pickup = s.pickup.text.trim();
    final dropoff = s.dropoff.text.trim();
    if (pickup.isEmpty && dropoff.isEmpty) {
      _snack('Gediş və ya Qayıdış ünvanını daxil edin', ok: false);
      return;
    }

    setState(() => s.isCalculating = true);
    final res = await SchoolApiService.instance.calculateTransportPrice(
      studentId: widget.studentId,
      academicYearId: _yearId!,
      startDate: start,
      pickupAddress: pickup,
      dropoffAddress: dropoff,
    );

    if (!mounted) return;
    setState(() {
      s.isCalculating = false;
      if (res != null && res['calculated_amount'] != null) {
        final calc = double.tryParse(res['calculated_amount'].toString()) ?? 0;
        final base = double.tryParse(res['base_price']?.toString() ?? '0') ?? calc;
        s.total.text = base.toStringAsFixed(0);
        s.calculationNote = 'Məsafə: ${res['distance_km'] ?? '—'} km • Aylıq: ${res['monthly_price'] ?? '—'} AZN';
      } else {
        s.calculationNote = 'Servis qiyməti hesablana bilmədi, məbləği daxil edin.';
      }
    });
  }

  Map<String, dynamic> get _year {
    final list = _years.where((y) => y['id']?.toString() == _yearId).toList();
    return list.isNotEmpty ? list.first : <String, dynamic>{};
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  Map<String, double> _calc(_ServiceDraft s) {
    final total = _num(s.total);
    final yearStart = DateTime.tryParse(_year['startDate']?.toString() ?? '');
    final yearEnd = DateTime.tryParse(_year['endDate']?.toString() ?? '');
    final conStart = DateTime.tryParse(s.startDate.text.trim());
    final conEnd = DateTime.tryParse(s.endDate.text.trim());
    var calculated = total;
    var isProrated = false;
    var totalDays = 0;
    var contractDays = 0;
    var effectiveDiscount = _num(s.discount);

    if (s.discountPercent) {
      effectiveDiscount = total * (effectiveDiscount / 100.0);
    }

    if (['education', 'transportation'].contains(s.type) && yearStart != null && yearEnd != null && conStart != null && conEnd != null) {
      totalDays = yearEnd.difference(yearStart).inDays + 1;
      final clampedStart = conStart.isAfter(yearStart) ? conStart : yearStart;
      final clampedEnd = conEnd.isBefore(yearEnd) ? conEnd : yearEnd;
      contractDays = clampedEnd.difference(clampedStart).inDays + 1;
      if (totalDays > 0 && contractDays > 0 && contractDays < totalDays) {
        isProrated = true;
        calculated = (total / totalDays * contractDays).roundToDouble();
        effectiveDiscount = (effectiveDiscount / totalDays * contractDays).roundToDouble();
      }
    }
    calculated = calculated > total ? total : calculated;
    var finalAmount = calculated - effectiveDiscount;
    if (finalAmount < 0) finalAmount = 0;
    final initialPayment = _num(s.initial);
    final installments = int.tryParse(s.installments.text.trim()) ?? 0;
    final remaining = finalAmount - initialPayment;
    final monthly = installments > 0 ? (remaining < 0 ? 0.0 : remaining / installments) : remaining;
    return {
      'total': total,
      'calculated': calculated,
      'discount': effectiveDiscount,
      'final': finalAmount,
      'initial': initialPayment,
      'installments': installments.toDouble(),
      'monthly': monthly,
      'prorated': isProrated ? 1 : 0,
    };
  }

  double get _totalPayable => _services.fold(0, (sum, s) => sum + _calc(s)['final']!);

  String _money(double v) => '${v.toStringAsFixed(2)} AZN';

  void _snack(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController c, {DateTime? initial}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text.trim()) ?? initial ?? now,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => c.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _addService() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = AppPalette.of(ctx);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: palette.textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Xidmət növü seçin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                for (final t in _types)
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: palette.brandRoyal.withOpacity(0.12),
                      child: Icon(_typeIcon(t['value'].toString()), color: palette.brandRoyal, size: 18),
                    ),
                    title: Text(t['label']?.toString() ?? '', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.pop(ctx, t['value']?.toString()),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (type == null) return;

    final defaults = (_data['defaults'] as Map?)?.cast<String, dynamic>() ?? {};
    final s = _ServiceDraft(type: type)
      ..startDate.text = defaults['startDate']?.toString() ?? ''
      ..endDate.text = defaults['endDate']?.toString() ?? '';

    if (type == 'transportation') {
      final defaultAddr = _studentAddressInfo['default_address']?.toString() ?? '';
      s.pickup.text = defaultAddr;
      s.dropoff.text = defaultAddr;
    } else if (type == 'club' && _clubs.isNotEmpty) {
      s.clubId = _clubs.first['id']?.toString();
      s.total.text = (_clubs.first['price'] ?? 0).toString();
    }

    _attachListeners(s);
    setState(() => _services.add(s));

    if (type == 'education') {
      _fetchTuitionFeeForService(s);
    }
  }

  IconData _typeIcon(String type) => switch (type) {
        'education' => Icons.school_rounded,
        'transportation' => Icons.directions_bus_rounded,
        'club' => Icons.palette_rounded,
        'support' => Icons.co_present_rounded,
        'book' => Icons.menu_book_rounded,
        'uniform' => Icons.checkroom_rounded,
        _ => Icons.description_rounded,
      };

  String _typeLabel(String type) {
    for (final t in _types) {
      if (t['value']?.toString() == type) return t['label']?.toString() ?? type;
    }
    return switch (type) {
      'education' => 'Təhsil haqqı',
      'transportation' => 'Nəqliyyat / Servis',
      'club' => 'Dərnək',
      'support' => 'Dəstək',
      'book' => 'Kitab',
      'uniform' => 'Uniforma',
      _ => type,
    };
  }

  Future<void> _showPreview() async {
    final palette = AppPalette.of(context);
    final parent = _parents.where((p) => p['id']?.toString() == _parentId).toList();
    final parentName = parent.isNotEmpty ? parent.first['name']?.toString() ?? '' : '—';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Müqavilə Önizləməsi', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Şagird: ${_student['name'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('Valideyn: $parentName', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
              const SizedBox(height: 3),
              Text('Status: ${_statuses.where((s) => s['value']?.toString() == _status).map((s) => s['label']).firstOrNull ?? _status}',
                  style: TextStyle(fontSize: 12, color: palette.textSecondary)),
              const Divider(height: 18),
              for (final s in _services) ...[
                Row(
                  children: [
                    Icon(_typeIcon(s.type), size: 16, color: palette.brandRoyal),
                    const SizedBox(width: 6),
                    Text(_typeLabel(s.type), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${s.startDate.text} — ${s.endDate.text}', style: const TextStyle(fontSize: 11.5)),
                Text('İllik tarif: ${_money(_num(s.total))} • Son məbləğ: ${_money(_calc(s)['final']!)}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                Text('İlkin: ${_money(_num(s.initial))} • Aylıq: ${_money(_calc(s)['monthly']!)} (${s.installments.text} ay)',
                    style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                const SizedBox(height: 10),
              ],
              const Divider(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ümumi ödəniləcək:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(_money(_totalPayable), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
                  ],
                ),
              ),
              if (_notes.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Qeyd: ${_notes.text.trim()}', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.brandNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bağla', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _save({bool force = false}) async {
    if (_parentId == null) {
      _snack('Valideyn seçilməlidir', ok: false);
      return;
    }
    for (final s in _services) {
      final c = _calc(s);
      if (c['total']! <= 0) {
        _snack('${_typeLabel(s.type)} üçün illik məbləğ daxil edin', ok: false);
        return;
      }
    }
    setState(() => _saving = true);

    final session = context.read<SessionController>();
    final canApprove = session.profile?.isSuper == true ||
        session.can('gopanel.finance.student_contracts.director_approve');

    final payload = <String, dynamic>{
      'userId': widget.studentId,
      'parentId': _parentId,
      'academicYearId': _yearId,
      'status': _status,
      'notes': _notes.text.trim(),
      'selectedClassId': _classId,
      'forceUpdate': force,
      'approve': canApprove,
      'services': [
        for (final s in _services)
          {
            'id': s.id,
            'contractType': s.type,
            'clubId': s.clubId,
            'startDate': s.startDate.text.trim(),
            'endDate': s.endDate.text.trim(),
            'totalAmount': _num(s.total),
            'calculatedTotalAmount': _calc(s)['calculated'],
            'discountAmount': s.discountPercent ? 0 : _num(s.discount),
            'discountPercentage': s.discountPercent ? _num(s.discount) : 0,
            'finalAmount': _calc(s)['final'],
            'initialPayment': _num(s.initial),
            'numberOfInstallments': int.tryParse(s.installments.text.trim()) ?? 0,
            'pickupAddress': s.pickup.text.trim(),
            'dropoffAddress': s.dropoff.text.trim(),
            'uniformItems': s.uniformItems.text.trim(),
            'gradeSuffix': s.gradeSuffix.text.trim(),
          },
      ],
    };

    final res = await SchoolApiService.instance.saveContract(payload);
    if (!mounted) return;
    setState(() => _saving = false);

    if (res != null && res['conflict'] == true && !force) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Mövcud müqavilə'),
          content: Text(res['message']?.toString() ?? 'Bu növ müqavilə artıq mövcuddur. Yenilənsin?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yenilə'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _save(force: true);
      }
      return;
    }

    if (res != null && res['success'] == true) {
      _snack('Müqavilə uğurla yadda saxlanıldı');
      Navigator.pop(context, true);
    } else {
      _snack(res?['message']?.toString() ?? 'Müqavilə yadda saxlanıla bilmədi', ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Müqavilə yarat', style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yenidən yüklə',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(child: Text('Məlumat yüklənə bilmədi', style: TextStyle(color: palette.textSecondary)))
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  children: [
                    _buildStudentBanner(palette),
                    if (_existingContracts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildExistingContracts(palette),
                    ],
                    const SizedBox(height: 10),
                    _buildGeneralSection(palette),
                    const SizedBox(height: 10),
                    for (int i = 0; i < _services.length; i++) ...[
                      _buildServiceCard(palette, i),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: _addService,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                      label: const Text('Xidmət əlavə et', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.brandRoyal,
                        side: BorderSide(color: palette.brandRoyal.withOpacity(0.5), width: 1.5),
                        backgroundColor: palette.brandRoyal.withOpacity(0.04),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildNotesSection(palette),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _showPreview,
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Müqavilə Önizləməsi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.brandNavy,
                        side: BorderSide(color: palette.borderHairline),
                        backgroundColor: palette.surface1,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: palette.surface1,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(top: BorderSide(color: palette.borderHairline)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ümumi ödəniləcək', style: TextStyle(fontSize: 11, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(_money(_totalPayable), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.brandNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Yadda saxla', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentBanner(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: palette.brandRoyal.withOpacity(0.12),
            child: Text(
              (_student['name']?.toString() ?? 'Ş').isNotEmpty ? _student['name'].toString()[0].toUpperCase() : 'Ş',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: palette.brandRoyal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _student['name']?.toString() ?? 'Şagird',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _student['className'] ?? 'Sinif təyin edilməyib',
                      style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w700),
                    ),
                    if ((_student['code'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: palette.textTertiary)),
                      const SizedBox(width: 6),
                      Text(
                        _student['code'] ?? '',
                        style: TextStyle(fontSize: 11, color: palette.textTertiary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(label: 'Müqavilə', color: palette.brandRoyal, fontSize: 10),
        ],
      ),
    );
  }

  Widget _buildExistingContracts(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: 6),
              const Text('Mövcud Müqavilələr', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.info)),
              const Spacer(),
              StatusBadge(label: '${_existingContracts.length} ədəd', color: AppColors.info, fontSize: 9.5),
            ],
          ),
          const SizedBox(height: 6),
          for (final c in _existingContracts)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(_typeIcon(c['type']?.toString() ?? ''), size: 13, color: palette.textSecondary),
                  const SizedBox(width: 5),
                  Text(_typeLabel(c['type']?.toString() ?? ''), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${c['finalAmount'] ?? c['totalAmount'] ?? '0'} AZN', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  StatusBadge(
                    label: c['status']?.toString() ?? 'draft',
                    color: c['status'] == 'active' ? AppColors.emerald : AppColors.warning,
                    fontSize: 8.5,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 17, color: AppColors.info),
              const SizedBox(width: 6),
              Text('Ümumi Məlumat', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown(
            'Valideyn *',
            _parentId,
            _parents.map((p) => (p['id']?.toString(), '${p['name']} (${p['phone'] ?? 'Əlaqə yoxdur'})')).toList(),
            (v) => setState(() => _parentId = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  'Akademik il',
                  _yearId,
                  _years.map((y) => (y['id']?.toString(), y['label']?.toString() ?? '')).toList(),
                  (v) {
                    setState(() => _yearId = v);
                    final y = _years.where((e) => e['id']?.toString() == v).toList();
                    if (y.isNotEmpty) {
                      for (final s in _services) {
                        s.startDate.text = y.first['startDate']?.toString() ?? s.startDate.text;
                        s.endDate.text = y.first['endDate']?.toString() ?? s.endDate.text;
                        if (s.type == 'education') {
                          _fetchTuitionFeeForService(s);
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'Status',
                  _status,
                  _statuses.map((s) => (s['value']?.toString(), s['label']?.toString() ?? '')).toList(),
                  (v) => setState(() => _status = v ?? 'draft'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _dropdown(
            'Sinif təyinatı (istəyə bağlı)',
            _classId,
            _classes.map((c) => (c['id']?.toString(), c['name']?.toString() ?? '')).toList(),
            (v) => setState(() => _classId = v),
            allowNull: true,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(AppPalette palette, int index) {
    final s = _services[index];
    final c = _calc(s);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.brandRoyal.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: palette.brandRoyal.withOpacity(0.12),
                child: Icon(_typeIcon(s.type), color: palette.brandRoyal, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _typeLabel(s.type),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              if (s.isCalculating) ...[
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 6),
              ],
              if (_services.length > 1 || s.type != 'education')
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    final removed = _services.removeAt(index);
                    removed.dispose();
                  }),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 19),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Service Type Dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: s.type,
            decoration: _deco('Müqavilə tipi'),
            items: _types.map((t) => DropdownMenuItem(value: t['value']?.toString(), child: Text(t['label']?.toString() ?? '', style: const TextStyle(fontSize: 12.5)))).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => s.type = v);
              if (v == 'education') {
                _fetchTuitionFeeForService(s);
              } else if (v == 'transportation') {
                final defaultAddr = _studentAddressInfo['default_address']?.toString() ?? '';
                if (s.pickup.text.isEmpty) s.pickup.text = defaultAddr;
                if (s.dropoff.text.isEmpty) s.dropoff.text = defaultAddr;
                _calculateTransportForService(s);
              }
            },
          ),

          if (s.type == 'club') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: s.clubId,
              decoration: _deco('Dərnək seçin'),
              items: _clubs.map((cl) => DropdownMenuItem(
                value: cl['id']?.toString(),
                child: Text('${cl['name']} — ${cl['price']} AZN', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  s.clubId = v;
                  final cl = _clubs.where((e) => e['id']?.toString() == v).toList();
                  if (cl.isNotEmpty) s.total.text = (cl.first['price'] ?? 0).toString();
                });
              },
            ),
          ],

          const SizedBox(height: 10),

          // Start & End Dates Row
          Row(
            children: [
              Expanded(child: _datePickerTile(palette, 'Başlama tarixi', s.startDate)),
              const SizedBox(width: 8),
              Expanded(child: _datePickerTile(palette, 'Bitmə tarixi', s.endDate)),
            ],
          ),

          if (s.type == 'education') ...[
            const SizedBox(height: 10),
            TextField(controller: s.gradeSuffix, decoration: _deco('Sinif hərfi (məsələn: A)')),
          ],

          if (s.calculationNote != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.brandAzure.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 14, color: palette.brandAzure),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.calculationNote!,
                      style: TextStyle(fontSize: 11, color: palette.brandAzure, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Total Amount & Calculated Row
          Row(
            children: [
              Expanded(child: _amountField('İllik məbləğ (AZN)', s.total)),
              const SizedBox(width: 8),
              Expanded(child: _readOnlyBox(palette, 'Hesablanmış məbləğ', _money(c['calculated']!))),
            ],
          ),

          if (c['prorated'] == 1) ...[
            const SizedBox(height: 4),
            Text('ℹ️ Günə-gün pro-rata tətbiq edildi', style: TextStyle(fontSize: 10.5, color: palette.brandAzure, fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 10),

          // Discount Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Endirim', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        _discountToggle(s),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: s.discount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _deco(s.discountPercent ? 'Endirim faizi (%)' : 'Endirim məbləği (AZN)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Yekun məbləğ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.brandRoyal.withOpacity(0.3)),
                      ),
                      child: Text(
                        _money(c['final']!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (s.type == 'transportation') ...[
            const SizedBox(height: 10),
            TextField(controller: s.pickup, decoration: _deco('Götürülmə yeri (Ünvan)')),
            const SizedBox(height: 8),
            TextField(controller: s.dropoff, decoration: _deco('Düşürülmə yeri (Ünvan)')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: s.isCalculating ? null : () => _calculateTransportForService(s),
              icon: const Icon(Icons.calculate_rounded, size: 16),
              label: const Text('Servis qiymətini hesabla', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.brandRoyal,
                side: BorderSide(color: palette.brandRoyal),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],

          if (s.type == 'uniform') ...[
            const SizedBox(height: 10),
            TextField(controller: s.uniformItems, maxLines: 2, decoration: _deco('Forma çeşidləri')),
          ],

          const SizedBox(height: 12),

          // Installments Row
          Row(
            children: [
              Expanded(child: _amountField('İlkin ödəniş (AZN)', s.initial)),
              const SizedBox(width: 8),
              Expanded(child: _amountField('Bölünəcək ay', s.installments, integer: true)),
            ],
          ),

          const SizedBox(height: 8),
          _readOnlyBox(palette, 'Təxmini aylıq ödəniş', _money(c['monthly']!)),
        ],
      ),
    );
  }

  Widget _discountToggle(_ServiceDraft s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _modeChip('AZN', !s.discountPercent, () => setState(() => s.discountPercent = false)),
        const SizedBox(width: 3),
        _modeChip('%', s.discountPercent, () => setState(() => s.discountPercent = true)),
      ],
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
        ),
        child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  Widget _buildNotesSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Qeydlər', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
          const SizedBox(height: 8),
          TextField(controller: _notes, maxLines: 2, decoration: _deco('Bütün müqavilələrə aid ümumi qeyd')),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<(String?, String)> items, ValueChanged<String?> onChanged, {bool allowNull = false}) {
    final exists = items.any((i) => i.$1 == value);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: exists ? value : null,
      decoration: _deco(label),
      items: [
        if (allowNull) const DropdownMenuItem<String>(value: null, child: Text('Təyin edilməyib', style: TextStyle(fontSize: 12))),
        ...items.map((i) => DropdownMenuItem(value: i.$1, child: Text(i.$2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _datePickerTile(AppPalette palette, String label, TextEditingController controller) {
    return InkWell(
      onTap: () => _pickDate(controller),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    controller.text.isEmpty ? 'Tarix seçin' : controller.text,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.calendar_month_rounded, size: 16, color: palette.brandRoyal),
          ],
        ),
      ),
    );
  }

  Widget _amountField(String label, TextEditingController controller, {bool integer = false}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      decoration: _deco(label),
    );
  }

  Widget _readOnlyBox(AppPalette palette, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11.5),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      );
}
