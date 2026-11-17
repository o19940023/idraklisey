import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Ultra-Modern Parent Create & Edit Screen
/// 1:1 Parity with GoPanel Web Parent form.
class ParentEditScreen extends StatefulWidget {
  final Map<String, dynamic>? parentToEdit;

  const ParentEditScreen({super.key, this.parentToEdit});

  @override
  State<ParentEditScreen> createState() => _ParentEditScreenState();
}

class _ParentEditScreenState extends State<ParentEditScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _surnameCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _finCtrl;
  late final TextEditingController _serialNumberCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _registrationAddressCtrl;
  late final TextEditingController _workplaceCtrl;
  late final TextEditingController _positionCtrl;

  String _gender = 'female';
  String _serialType = 'AA';
  DateTime? _birthDate;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _allStudents = [];

  static const _serialTypes = ['AA', 'AZE', 'AR', 'AB', 'AC'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final p = widget.parentToEdit ?? {};
    final pr = (p['profile'] as Map?) ?? {};

    _nameCtrl = TextEditingController(text: p['name']?.toString() ?? p['firstName']?.toString() ?? '');
    _surnameCtrl = TextEditingController(text: p['surname']?.toString() ?? p['lastName']?.toString() ?? '');
    _fatherNameCtrl = TextEditingController(text: p['fatherName']?.toString() ?? p['father_name']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p['phone']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: p['email']?.toString() ?? '');
    _passwordCtrl = TextEditingController();

    _finCtrl = TextEditingController(text: pr['finCode']?.toString() ?? p['finCode']?.toString() ?? p['fin_code']?.toString() ?? '');
    _serialNumberCtrl = TextEditingController(text: pr['serialNumber']?.toString() ?? p['serialNumber']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: pr['address']?.toString() ?? p['address']?.toString() ?? '');
    _registrationAddressCtrl = TextEditingController(text: pr['registrationAddress']?.toString() ?? p['registration_address']?.toString() ?? '');
    _workplaceCtrl = TextEditingController(text: pr['companyName']?.toString() ?? p['workplace']?.toString() ?? '');
    _positionCtrl = TextEditingController(text: pr['companyPosition']?.toString() ?? p['position']?.toString() ?? '');

    final rawGender = (pr['gender']?.toString() ?? p['gender']?.toString() ?? 'female').toLowerCase();
    _gender = rawGender.contains('qad') || rawGender == 'female' ? 'female' : 'male';

    final rawSerialType = pr['serialType']?.toString() ?? p['serialType']?.toString() ?? 'AA';
    _serialType = _serialTypes.contains(rawSerialType) ? rawSerialType : 'AA';

    final rawBirth = pr['birthDate']?.toString() ?? p['birthDate']?.toString();
    if (rawBirth != null && rawBirth.isNotEmpty) {
      _birthDate = DateTime.tryParse(rawBirth);
    }

    _isActive = p['isActive'] != false && p['is_active'] != 0;

    final rawChildren = (p['children'] as List? ?? []);
    for (final c in rawChildren) {
      _children.add(Map<String, dynamic>.from(c as Map));
    }

    _loadFullFormData();
  }

  Future<void> _loadFullFormData() async {
    final id = widget.parentToEdit?['id']?.toString();
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        id != null ? SchoolApiService.instance.fetchParentForm(id) : Future.value(null),
        SchoolApiService.instance.fetchStudents(),
      ]);

      final form = results[0] as Map<String, dynamic>?;
      final students = results[1] as List<Map<String, dynamic>>? ?? [];

      if (mounted) {
        setState(() {
          _allStudents = students;
          if (form != null) {
            final pr = (form['profile'] as Map?) ?? {};
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = form['name']?.toString() ?? '';
            if (_surnameCtrl.text.isEmpty) _surnameCtrl.text = form['surname']?.toString() ?? '';
            if (_fatherNameCtrl.text.isEmpty) _fatherNameCtrl.text = form['fatherName']?.toString() ?? form['father_name']?.toString() ?? '';
            if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = form['phone']?.toString() ?? '';
            if (_emailCtrl.text.isEmpty) _emailCtrl.text = form['email']?.toString() ?? '';

            if (_finCtrl.text.isEmpty) _finCtrl.text = pr['finCode']?.toString() ?? '';
            if (_serialNumberCtrl.text.isEmpty) _serialNumberCtrl.text = pr['serialNumber']?.toString() ?? '';
            if (_addressCtrl.text.isEmpty) _addressCtrl.text = pr['address']?.toString() ?? '';
            if (_workplaceCtrl.text.isEmpty) _workplaceCtrl.text = pr['companyName']?.toString() ?? '';
            if (_positionCtrl.text.isEmpty) _positionCtrl.text = pr['companyPosition']?.toString() ?? '';

            if (form['children'] is List && _children.isEmpty) {
              for (final c in (form['children'] as List)) {
                _children.add(Map<String, dynamic>.from(c as Map));
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _finCtrl.dispose();
    _serialNumberCtrl.dispose();
    _addressCtrl.dispose();
    _registrationAddressCtrl.dispose();
    _workplaceCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1985),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zəhmət olmasa tələb olunan sahələri doldurun.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final isEdit = widget.parentToEdit != null;
    final parentId = widget.parentToEdit?['id']?.toString();

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'surname': _surnameCtrl.text.trim(),
      'fatherName': _fatherNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'isActive': _isActive,
      'gender': _gender,
      'finCode': _finCtrl.text.trim().toUpperCase(),
      'serialType': _serialType,
      'serialNumber': _serialNumberCtrl.text.trim(),
      'birthDate': _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
      'address': _addressCtrl.text.trim(),
      'companyName': _workplaceCtrl.text.trim(),
      'companyPosition': _positionCtrl.text.trim(),
      if (_passwordCtrl.text.trim().isNotEmpty) 'password': _passwordCtrl.text.trim(),
      'children': _children.map((c) => {
        'studentId': c['id']?.toString() ?? c['studentId']?.toString(),
        'parentType': c['parentType']?.toString() ?? c['parent_type']?.toString() ?? 'other',
      }).toList(),
    };

    try {
      final res = await SchoolApiService.instance.saveParent(payload, id: isEdit ? parentId : null);
      if (mounted) {
        setState(() => _isSaving = false);
        if (res != null && res['success'] != false) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Valideyn məlumatları uğurla yeniləndi.' : 'Yeni valideyn qeydiyyata alındı.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res?['message']?.toString() ?? 'Xəta baş verdi.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddChildDialog() {
    String? selectedStudentId;
    String selectedRelation = _gender == 'female' ? 'mom' : 'father';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Övlad Əlavə Et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Şagird Seçin', border: OutlineInputBorder()),
                items: _allStudents.map((s) {
                  final sName = s['full_name'] ?? '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}';
                  final sCode = s['code'] ?? s['student_code'] ?? '';
                  return DropdownMenuItem(
                    value: s['id']?.toString(),
                    child: Text('$sName ($sCode)', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setDlg(() => selectedStudentId = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRelation,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Qohumluq Əlaqəsi', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'father', child: Text('Ata')),
                  DropdownMenuItem(value: 'mom', child: Text('Ana')),
                  DropdownMenuItem(value: 'guardian', child: Text('Qəyyum / Vəsi')),
                  DropdownMenuItem(value: 'other', child: Text('Digər')),
                ],
                onChanged: (val) => setDlg(() => selectedRelation = val ?? 'mom'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İmtina')),
            FilledButton(
              onPressed: selectedStudentId == null
                  ? null
                  : () {
                      final found = _allStudents.firstWhere((s) => s['id']?.toString() == selectedStudentId);
                      final sName = found['full_name'] ?? '${found['first_name'] ?? ''} ${found['last_name'] ?? ''}';
                      final sClass = found['class_name'] ?? found['grade'] ?? '';
                      final sCode = found['code'] ?? found['student_code'] ?? '';

                      setState(() {
                        _children.add({
                          'id': selectedStudentId,
                          'name': sName,
                          'className': sClass,
                          'code': sCode,
                          'parentType': selectedRelation,
                        });
                      });
                      Navigator.pop(ctx);
                    },
              child: const Text('Əlavə Et'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isEdit = widget.parentToEdit != null;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Valideyni Redaktə Et' : 'Yeni Valideyn Əlavə Et',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F1E36),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: palette.surface1,
            child: TabBar(
              controller: _tabController,
              indicatorColor: palette.brandRoyal,
              labelColor: palette.brandRoyal,
              unselectedLabelColor: palette.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.person_outline, size: 16), text: '1. Şəxsi'),
                Tab(icon: Icon(Icons.contact_mail_outlined, size: 16), text: '2. Əlaqə & İş'),
                Tab(icon: Icon(Icons.escalator_warning_outlined, size: 16), text: '3. Övladlar'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTab1(palette),
                  _buildTab2(palette),
                  _buildTab3(palette),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surface1,
            border: Border(top: BorderSide(color: palette.borderHairline)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('İmtina'),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.brandRoyal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Saxlanılır...' : (isEdit ? 'Yadda Saxla' : 'Bazada Qeydiyyata Al'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: Şəxsi
  Widget _buildTab1(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Adı *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ad mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _surnameCtrl,
                decoration: const InputDecoration(labelText: 'Soyadı *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Soyad mütləqdir' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fatherNameCtrl,
                decoration: const InputDecoration(labelText: 'Ata adı', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cinsiyyəti *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Qadın (Ana)')),
                  DropdownMenuItem(value: 'male', child: Text('Kişi (Ata)')),
                ],
                onChanged: (val) => setState(() => _gender = val ?? 'female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _finCtrl,
                maxLength: 7,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'FİN Kod',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Doğum Tarixi', border: OutlineInputBorder()),
                  child: Text(
                    _birthDate != null ? DateFormat('dd.MM.yyyy').format(_birthDate!) : 'Tarix seçin',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                initialValue: _serialType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Seriya', border: OutlineInputBorder()),
                items: _serialTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _serialType = val ?? 'AA'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: TextFormField(
                controller: _serialNumberCtrl,
                decoration: const InputDecoration(labelText: 'Ş.V. Nömrəsi', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Status: Aktiv Valideyn', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Deaktiv edildikdə şəxsi kabinetə giriş bağlanır'),
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
        ),
      ],
    );
  }

  // TAB 2: Əlaqə & İş
  Widget _buildTab2(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Əlaqə Telefonu *',
            hintText: '+994...',
            border: OutlineInputBorder(),
          ),
          validator: (val) => val == null || val.trim().isEmpty ? 'Telefon mütləqdir' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Elektron Poçt',
            hintText: 'valideyn@idrak.edu.az',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Şifrə',
            hintText: 'Dəyişmək istəmirsinizsə boş saxlayın',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _workplaceCtrl,
                decoration: const InputDecoration(labelText: 'İş Yeri', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _positionCtrl,
                decoration: const InputDecoration(labelText: 'Vəzifəsi', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'Faktiki Yaşadığı Ünvan', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _registrationAddressCtrl,
          decoration: const InputDecoration(labelText: 'Qeydiyyat Ünvanı', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  // TAB 3: Övladlar
  Widget _buildTab3(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bağlı Şagirdlər (${_children.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Övlad Əlavə Et'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_children.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderHairline),
            ),
            child: const Center(
              child: Text('Bu valideynə bağlı heç bir şagird yoxdur.'),
            ),
          )
        else
          ...List.generate(_children.length, (idx) {
            final c = _children[idx];
            final name = c['name'] ?? '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}';
            final className = c['className'] ?? c['grade'] ?? '';
            final code = c['code'] ?? '';
            final rel = c['parentType'] == 'father'
                ? 'Ata'
                : (c['parentType'] == 'mom' ? 'Ana' : 'Qəyyum');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.borderHairline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: palette.brandRoyal.withValues(alpha: 0.12),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'Ş', style: TextStyle(color: palette.brandRoyal, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text('$className • Kod: $code • $rel', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    onPressed: () => setState(() => _children.removeAt(idx)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
