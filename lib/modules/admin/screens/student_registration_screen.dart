import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/email_generator.dart';
import '../../../core/utils/fin_code_formatter.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/password_hasher.dart';
import '../../../core/widgets/profile_photo_picker.dart';
import '../../../providers/app_state.dart';

/// Şagird qeydiyyatı / redaktəsi — Web GoPanel ilə 1:1, 3 addımlı sehrbaz:
/// 1) Şagird Kimliyi  2) Sinif, Səhiyyə & Yoxlanış  3) Ailə üzvləri & Giriş
class StudentRegistrationScreen extends StatefulWidget {
  final String? studentId;
  const StudentRegistrationScreen({super.key, this.studentId});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _FamilyMember {
  String? id;
  bool isExisting = false;
  String relationType;
  String? existingParentId;
  bool expanded;
  final name = TextEditingController();
  final surname = TextEditingController();
  final fatherName = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  final email = TextEditingController();
  final finCode = TextEditingController();
  final serialNumber = TextEditingController();
  final birthDate = TextEditingController();
  final idCardDate = TextEditingController();
  final companyName = TextEditingController();
  final positionName = TextEditingController();
  final registrationAddress = TextEditingController();
  final actualAddress = TextEditingController();
  String serialType = 'AA';

  _FamilyMember({
    this.id,
    this.relationType = 'father',
    this.expanded = true,
  });

  void dispose() {
    name.dispose();
    surname.dispose();
    fatherName.dispose();
    phone.dispose();
    whatsapp.dispose();
    email.dispose();
    finCode.dispose();
    serialNumber.dispose();
    birthDate.dispose();
    idCardDate.dispose();
    companyName.dispose();
    positionName.dispose();
    registrationAddress.dispose();
    actualAddress.dispose();
  }
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _serialNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _regAddressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _eyeColorCtrl = TextEditingController();
  final _contractNumberCtrl = TextEditingController();
  final _contractAmountCtrl = TextEditingController(text: '6500');
  final _allergiesCtrl = TextEditingController();
  final _studentPassCtrl = TextEditingController(text: '123456');
  final _parentPassCtrl = TextEditingController(text: '123456');
  final _oldSchoolNameCtrl = TextEditingController();
  final _oldSchoolGradeCtrl = TextEditingController();
  final _oldSchoolEndCtrl = TextEditingController();
  final _probationCtrl = TextEditingController();

  static const _stepTitles = ['Şagird Kimliyi', 'Sinif & Yoxlanış', 'Ailə & Giriş'];
  static const _bloodGroups = [
    'A(I) Rh+', 'A(II) Rh+', 'B(III) Rh+', 'AB(IV) Rh+',
    'A(II) Rh-', 'B(III) Rh-', 'AB(IV) Rh-',
    'O(I) Rh+', 'O(I) Rh-',
  ];
  static const _commonAllergies = ['Qoz/Fıstıq', 'Laktoza', 'Qlüten', 'Sitrus', 'Toz'];

  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  bool get _isEdit => widget.studentId != null;

  String _gender = 'male';
  String _serialType = 'AA';
  String _exclusiveType = '';
  String _examStatus = 'pending';
  String _medicalStatus = 'pending';
  String _psychologyStatus = 'pending';
  String? _filialId;
  String? _academicYearId;
  String? _targetGradeLevel;
  String _targetGradeLanguage = 'azerbaijan';
  String? _selectedClass;
  String _bloodGroup = 'A(II) Rh+';
  String? _photoUrl;
  DateTime? _birthDate;
  DateTime? _idCardDate;

  Map<String, dynamic> _meta = {};
  List<Map<String, dynamic>> _parentsCatalog = [];
  final List<_FamilyMember> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _fatherNameCtrl, _finCtrl, _serialNumberCtrl,
      _addressCtrl, _regAddressCtrl, _noteCtrl, _eyeColorCtrl, _contractNumberCtrl,
      _contractAmountCtrl, _allergiesCtrl, _studentPassCtrl, _parentPassCtrl,
      _oldSchoolNameCtrl, _oldSchoolGradeCtrl, _oldSchoolEndCtrl, _probationCtrl,
    ]) {
      c.dispose();
    }
    for (final f in _familyMembers) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final meta = await SchoolApiService.instance.fetchStudentFormMeta();
    final parents = await SchoolApiService.instance.fetchParents();
    Map<String, dynamic>? form;
    if (_isEdit) {
      form = await SchoolApiService.instance.fetchStudentForm(widget.studentId!);
    }
    if (!mounted) return;

    _meta = meta ?? {};
    _parentsCatalog = parents;

    if (form != null) {
      _populateFromForm(form);
    } else {
      final years = (_meta['academicYears'] as List?) ?? [];
      final filials = (_meta['filials'] as List?) ?? [];
      if (years.isNotEmpty) {
        final current = years.firstWhere((y) => y['isCurrent'] == true, orElse: () => years.first);
        _academicYearId = current['id']?.toString();
      }
      if (filials.isNotEmpty) _filialId = filials.first['id']?.toString();
      if (_familyMembers.isEmpty) _addFamilyMember();
    }

    setState(() => _loading = false);
  }

  void _populateFromForm(Map<String, dynamic> form) {
    _firstNameCtrl.text = form['name']?.toString() ?? '';
    _lastNameCtrl.text = form['surname']?.toString() ?? '';
    _fatherNameCtrl.text = form['fatherName']?.toString() ?? '';
    final p = (form['profile'] as Map?) ?? {};
    _finCtrl.text = p['finCode']?.toString() ?? '';
    _serialNumberCtrl.text = p['serialNumber']?.toString() ?? '';
    _serialType = (p['serialType']?.toString().isNotEmpty == true) ? p['serialType'].toString() : 'AA';
    _exclusiveType = (p['exclusiveType']?.toString().isNotEmpty == true) ? p['exclusiveType'].toString() : '';
    _gender = p['gender']?.toString() == 'female' ? 'female' : 'male';
    _eyeColorCtrl.text = p['eyeColor']?.toString() ?? '';
    if (_bloodGroups.contains(p['bloodGroup']?.toString())) _bloodGroup = p['bloodGroup'].toString();
    _addressCtrl.text = (p['actualAddress']?.toString().isNotEmpty == true) ? p['actualAddress'].toString() : (p['address']?.toString() ?? '');
    _regAddressCtrl.text = p['registrationAddress']?.toString() ?? '';
    _noteCtrl.text = p['note']?.toString() ?? '';
    _targetGradeLevel = p['targetGradeLevel']?.toString();
    _targetGradeLanguage = (p['targetGradeLanguage']?.toString().isNotEmpty == true) ? p['targetGradeLanguage'].toString() : 'azerbaijan';
    _academicYearId = (p['targetAcademicYearId']?.toString().isNotEmpty == true) ? p['targetAcademicYearId'].toString() : _academicYearId;
    _birthDate = DateTime.tryParse(p['birthDate']?.toString() ?? '');
    _idCardDate = DateTime.tryParse(p['dateOfIssueOfIdCard']?.toString() ?? '');
    _probationCtrl.text = p['probationEndDate']?.toString() ?? '';
    final old = (form['oldSchool'] as Map?) ?? {};
    _oldSchoolNameCtrl.text = old['schoolName']?.toString() ?? '';
    _oldSchoolGradeCtrl.text = old['gradeLevel']?.toString() ?? '';
    _oldSchoolEndCtrl.text = old['endTime']?.toString() ?? '';
    _selectedClass = form['className']?.toString();
    _examStatus = form['examStatus']?.toString() ?? 'pending';
    _medicalStatus = form['medicalStatus']?.toString() ?? 'pending';
    _psychologyStatus = form['psychologyStatus']?.toString() ?? 'pending';

    for (final f in _familyMembers) {
      f.dispose();
    }
    _familyMembers.clear();
    final members = (form['familyMembers'] as List?) ?? [];
    for (final m in members) {
      final map = m as Map;
      final fm = _FamilyMember(
        id: map['familyMemberId']?.toString(),
        relationType: map['relationType']?.toString() ?? 'other',
      );
      fm.name.text = map['name']?.toString() ?? '';
      fm.surname.text = map['surname']?.toString() ?? '';
      fm.fatherName.text = map['fatherName']?.toString() ?? '';
      fm.phone.text = map['phone']?.toString() ?? '';
      fm.whatsapp.text = map['whatsapp']?.toString() ?? '';
      fm.email.text = map['email']?.toString() ?? '';
      fm.finCode.text = map['finCode']?.toString() ?? '';
      fm.serialNumber.text = map['serialNumber']?.toString() ?? '';
      fm.serialType = map['serialType']?.toString().isNotEmpty == true ? map['serialType'].toString() : 'AA';
      fm.birthDate.text = map['birthDate']?.toString() ?? '';
      fm.idCardDate.text = map['idCardIssueDate']?.toString() ?? '';
      fm.companyName.text = map['companyName']?.toString() ?? '';
      fm.positionName.text = map['positionName']?.toString() ?? '';
      fm.registrationAddress.text = map['registrationAddress']?.toString() ?? '';
      fm.actualAddress.text = map['actualAddress']?.toString() ?? '';
      _familyMembers.add(fm);
    }
    if (_familyMembers.isEmpty) _addFamilyMember();
  }

  void _addFamilyMember() {
    setState(() {
      _familyMembers.add(_FamilyMember(
        relationType: _familyMembers.isEmpty ? 'father' : 'other',
        expanded: true,
      ));
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      final removed = _familyMembers.removeAt(index);
      removed.dispose();
    });
  }

  List<Map<String, dynamic>> get _gradeLanguages => List<Map<String, dynamic>>.from(_meta['gradeLanguages'] ?? []);
  List<Map<String, dynamic>> get _serialTypes => List<Map<String, dynamic>>.from(_meta['serialTypes'] ?? []);
  List<Map<String, dynamic>> get _exclusiveTypes => List<Map<String, dynamic>>.from(_meta['exclusiveTypes'] ?? []);
  List<Map<String, dynamic>> get _relationTypes => List<Map<String, dynamic>>.from(_meta['relationTypes'] ?? []);
  List<Map<String, dynamic>> get _years => List<Map<String, dynamic>>.from(_meta['academicYears'] ?? []);
  List<Map<String, dynamic>> get _filials => List<Map<String, dynamic>>.from(_meta['filials'] ?? []);
  List<Map<String, dynamic>> get _classes => List<Map<String, dynamic>>.from(_meta['classes'] ?? []);

  String _fmt(DateTime? d) => d == null ? '' : DateFormat('dd.MM.yyyy').format(d);
  String _iso(DateTime? d) => d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  Future<void> _pickDate({required DateTime? initial, required DateTime first, required DateTime last, required ValueChanged<DateTime> onPicked, Color color = const Color(0xFF2563EB)}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? first,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: color, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  MapEntry<String, String> _previewEmails() {
    final existing = _parentsCatalog.map((e) => (e['email'] ?? '').toString().toLowerCase()).where((e) => e.isNotEmpty).toList();
    final name = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final studentEmail = _firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty
        ? ''
        : EmailGenerator.generateStudentEmail(name, EmailGenerator.getYearFromFIN(_finCtrl.text.trim()), existingEmails: existing);
    final newMembers = _familyMembers.where((f) => !f.isExisting).toList();
    final parentEmail = newMembers.isEmpty || newMembers.first.name.text.trim().isEmpty
        ? ''
        : EmailGenerator.generateParentEmail('${newMembers.first.name.text.trim()} ${newMembers.first.surname.text.trim()}'.trim(), existingEmails: existing);
    return MapEntry(studentEmail, parentEmail);
  }

  Future<void> _nextOrSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_step < _stepTitles.length - 1) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    setState(() => _saving = true);

    final emails = _previewEmails();
    final studentEmail = _firstNameCtrl.text.trim().isEmpty ? '' : (emails.key);

    final familyPayload = <Map<String, dynamic>>[];
    for (final f in _familyMembers) {
      if (f.isExisting) {
        if (f.existingParentId == null || f.existingParentId!.isEmpty) continue;
        familyPayload.add({
          'is_existing_student': '1',
          'existing_student_id': 'parent:${f.existingParentId}',
          'relation_type': f.relationType,
          'filial_id': _filialId,
        });
      } else {
        if (f.name.text.trim().isEmpty || f.surname.text.trim().isEmpty) continue;
        var pEmail = f.email.text.trim();
        if (pEmail.isEmpty) {
          pEmail = EmailGenerator.generateParentEmail(
            '${f.name.text.trim()} ${f.surname.text.trim()}'.trim(),
            existingEmails: [..._parentsCatalog.map((e) => (e['email'] ?? '').toString()), if (studentEmail.isNotEmpty) studentEmail],
          );
        }
        familyPayload.add({
          'family_member_id': f.id,
          'is_existing_student': '0',
          'relation_type': f.relationType,
          'name': f.name.text.trim(),
          'surname': f.surname.text.trim(),
          'father_name': f.fatherName.text.trim(),
          'phone': f.phone.text.trim(),
          'whatsapp': f.whatsapp.text.trim(),
          'email': pEmail,
          'fin_code': f.finCode.text.trim().toUpperCase(),
          'serial_type': f.serialType,
          'serial_number': f.serialNumber.text.trim(),
          'birth_date': f.birthDate.text.trim(),
          'date_of_issue_of_the_id_card': f.idCardDate.text.trim(),
          'company_name': f.companyName.text.trim(),
          'position_name': f.positionName.text.trim(),
          'registration_address': f.registrationAddress.text.trim(),
          'actual_address': f.actualAddress.text.trim(),
          'filial_id': _filialId,
        });
      }
    }

    final payload = <String, dynamic>{
      'name': _firstNameCtrl.text.trim(),
      'surname': _lastNameCtrl.text.trim(),
      'fatherName': _fatherNameCtrl.text.trim(),
      'phone': _familyMembers.isNotEmpty ? _familyMembers.first.phone.text.trim() : '',
      'email': studentEmail,
      'password': _studentPassCtrl.text.trim(),
      'parentPassword': _parentPassCtrl.text.trim(),
      'filialId': _filialId,
      'className': _selectedClass,
      'profile': {
        'fin_code': _finCtrl.text.trim().toUpperCase(),
        'birth_date': _iso(_birthDate),
        'gender': _gender,
        'serial_type': _serialType,
        'serial_number': _serialNumberCtrl.text.trim(),
        'date_of_issue_of_the_id_card': _iso(_idCardDate),
        'eye_color': _eyeColorCtrl.text.trim(),
        'blood_group': _bloodGroup,
        'registration_address': _regAddressCtrl.text.trim(),
        'actual_address': _addressCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'probation_end_date': _probationCtrl.text.trim(),
        'target_grade_level': _targetGradeLevel,
        'target_grade_language': _targetGradeLanguage,
        'target_academic_year_id': _academicYearId,
        'exclusive_type': _exclusiveType.isEmpty ? null : _exclusiveType,
      },
      'old_school_name': _oldSchoolNameCtrl.text.trim(),
      'grade_level': _oldSchoolGradeCtrl.text.trim(),
      'end_time': _oldSchoolEndCtrl.text.trim(),
      'exam_status': _examStatus,
      'medical_status': _medicalStatus,
      'psychology_status': _psychologyStatus,
      'family_members': familyPayload,
    };

    Map<String, dynamic>? result;
    try {
      result = await SchoolApiService.instance.saveStudentFull(payload, id: widget.studentId);
      await appState.syncStudentsFromApi();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _saving = false);

    if (result == null || result['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?['message']?.toString() ?? 'Yadda saxlamaq alınmadı'), backgroundColor: AppColors.danger),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_isEdit ? 'Şagird yeniləndi' : 'Şagird və ailə üzvləri yaradıldı', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _credRow('Ad Soyad', '${result!['name']} ${result['surname']}'),
            _credRow('İdrak kodu', result['code']?.toString() ?? ''),
            _credRow('E-poçt (Login)', result['email']?.toString() ?? ''),
            _credRow('FİN', result['finCode']?.toString() ?? ''),
            if ((result['parentName']?.toString() ?? '').isNotEmpty) ...[
              const Divider(),
              _credRow('Valideyn', result['parentName'].toString()),
              _credRow('Valideyn e-poçt', result['parentEmail']?.toString() ?? ''),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bağla')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required IconData icon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6)),
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
    );
  }

  Widget _modernInput({
    required TextEditingController controller,
    required String label,
    String hint = '',
    required IconData icon,
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      decoration: _inputDeco(icon: icon).copyWith(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _formCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: const Color(0xFF0F172A).withAlpha(10), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _dateField({required String label, required DateTime? date, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDeco(icon: icon).copyWith(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 18),
        ),
        child: Text(
          date != null ? _fmt(date) : 'Tarixi seçin',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: date != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _genderChoice(String title, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.w900 : FontWeight.w600, color: selected ? const Color(0xFF1E40AF) : const Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _emailBox(String email, String placeholder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
      child: Row(children: [
        const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(child: Text(email.isNotEmpty ? email : placeholder, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: email.isNotEmpty ? const Color(0xFF1E40AF) : const Color(0xFF94A3B8)))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previews = _previewEmails();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Şagird Məlumatlarını Düzəliş Et' : 'Şagird Qeydiyyatı', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.3)),
            Text('Addım ${_step + 1} / 3: ${_stepTitles[_step]}', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
          ),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              handleBackNavigation(context);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))),
              child: Row(
                children: List.generate(_stepTitles.length, (index) {
                  final isDone = index < _step;
                  final isCurrent = index == _step;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (index < _step) setState(() => _step = index);
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: index < _stepTitles.length - 1 ? 8 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isDone ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFF38BDF8) : Colors.white.withAlpha(20)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isDone
                                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                                      : Text('${index + 1}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: isCurrent ? const Color(0xFF0F172A) : Colors.white70)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(_stepTitles[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: isCurrent ? Colors.white : Colors.white60))),
                            ]),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: isDone || isCurrent ? 1.0 : 0.0,
                                minHeight: 4,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor: AlwaysStoppedAnimation<Color>(isDone ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  if (_step == 0) ..._stepIdentity(previews),
                  if (_step == 1) ..._stepAcademic(),
                  if (_step == 2) ..._stepFamily(previews),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(children: [
            if (_step > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _step--),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Geri', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _nextOrSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_step == _stepTitles.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    _saving ? 'Yadda saxlanılır...' : (_step == _stepTitles.length - 1 ? (_isEdit ? 'Yenilə' : 'Şagirdi Qeydiyyata Al') : 'Növbəti Addım'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _stepIdentity(MapEntry<String, String> previews) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          ProfilePhotoPicker(
            initialPhotoUrl: _photoUrl,
            onPhotoUploaded: (url) => setState(() => _photoUrl = url),
            folder: 'idrak/profiles/students',
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Şagirdin Profil Şəkli', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                SizedBox(height: 3),
                Text('Rəqəmsal ID kart və elektron jurnalda əks olunacaq fotoşəkil.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3)),
              ],
            ),
          ),
        ]),
      ),
      _formCard(
        title: 'Şəxsi Məlumatlar',
        icon: Icons.badge_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modernInput(
              controller: _finCtrl,
              label: 'FİN Kod *',
              hint: 'Məs: 7K9Y12A',
              icon: Icons.fingerprint_rounded,
              inputFormatters: finCodeInputFormatters(),
              validator: (v) => validateFinCode((v ?? '').trim().toUpperCase()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _filialId,
                  decoration: _inputDeco(icon: Icons.business_rounded).copyWith(labelText: 'Filial'),
                  items: _filials.map((f) => DropdownMenuItem(value: f['id']?.toString(), child: Text(f['name']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setState(() => _filialId = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _academicYearId,
                  decoration: _inputDeco(icon: Icons.event_rounded).copyWith(labelText: 'Akademik il'),
                  items: _years.map((y) => DropdownMenuItem(value: y['id']?.toString(), child: Text(y['label']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setState(() => _academicYearId = v),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _targetGradeLevel,
                  decoration: _inputDeco(icon: Icons.school_rounded).copyWith(labelText: 'Sinif nömrəsi *'),
                  items: List.generate(12, (i) => i).map((i) => DropdownMenuItem(value: '$i', child: Text('$i', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setState(() => _targetGradeLevel = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _targetGradeLanguage,
                  decoration: _inputDeco(icon: Icons.language_rounded).copyWith(labelText: 'Tədris dili *'),
                  items: _gradeLanguages.map((l) => DropdownMenuItem(value: l['value']?.toString(), child: Text(l['label']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setState(() => _targetGradeLanguage = v ?? 'azerbaijan'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _modernInput(
                  controller: _firstNameCtrl,
                  label: 'Ad *',
                  hint: 'Elmir',
                  icon: Icons.person_rounded,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Ad tələb olunur' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modernInput(
                  controller: _lastNameCtrl,
                  label: 'Soyad *',
                  hint: 'Quliyev',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Soyad tələb olunur' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _modernInput(controller: _fatherNameCtrl, label: 'Ata adı *', hint: 'İlham', icon: Icons.person_pin_rounded, validator: (v) => (v ?? '').trim().isEmpty ? 'Ata adı tələb olunur' : null),
            const SizedBox(height: 14),
            const Text('Cinsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _genderChoice('Kişi (Oğlan)', Icons.face_rounded, _gender == 'male', () => setState(() => _gender = 'male'))),
              const SizedBox(width: 10),
              Expanded(child: _genderChoice('Qadın (Qız)', Icons.face_3_rounded, _gender == 'female', () => setState(() => _gender = 'female'))),
            ]),
            const SizedBox(height: 14),
            _dateField(label: 'Doğum Tarixi *', date: _birthDate, icon: Icons.cake_rounded, onTap: () => _pickDate(
              initial: _birthDate,
              first: DateTime(DateTime.now().year - 30),
              last: DateTime.now(),
              onPicked: (d) => _birthDate = d,
            )),
            const SizedBox(height: 12),
            _dateField(label: 'Vəsiqənin verilmə tarixi', date: _idCardDate, icon: Icons.credit_card_rounded, onTap: () => _pickDate(
              initial: _idCardDate,
              first: DateTime(2000),
              last: DateTime(DateTime.now().year + 5),
              onPicked: (d) => _idCardDate = d,
            )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _serialType,
                  decoration: _inputDeco(icon: Icons.article_rounded).copyWith(labelText: 'Seriya növü *'),
                  items: _serialTypes.map((s) => DropdownMenuItem(value: s['value']?.toString(), child: Text(s['label']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setState(() => _serialType = v ?? 'AA'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modernInput(
                  controller: _serialNumberCtrl,
                  label: 'Seriya nömrəsi *',
                  hint: '1234567',
                  icon: Icons.numbers_rounded,
                  keyboard: TextInputType.number,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Seriya nömrəsi tələb olunur' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _exclusiveType.isEmpty ? null : _exclusiveType,
              decoration: _inputDeco(icon: Icons.workspace_premium_rounded).copyWith(labelText: 'Güzəşt növü'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Heç biri', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                ..._exclusiveTypes.map((e) => DropdownMenuItem(value: e['value']?.toString(), child: Text(e['label']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))),
              ],
              onChanged: (v) => setState(() => _exclusiveType = v ?? ''),
            ),
          ],
        ),
      ),
      _formCard(
        title: 'Ünvanlar & Qeyd',
        icon: Icons.home_rounded,
        child: Column(
          children: [
            _modernInput(controller: _addressCtrl, label: 'Faktiki ünvan', hint: 'Bakı şəh., Nəsimi ray., ...', icon: Icons.location_on_rounded, maxLines: 2),
            const SizedBox(height: 12),
            _modernInput(controller: _regAddressCtrl, label: 'Qeydiyyat ünvanı', hint: 'Şəxsiyyət vəsiqəsindəki ünvan', icon: Icons.assignment_ind_rounded, maxLines: 2),
            const SizedBox(height: 12),
            _modernInput(controller: _noteCtrl, label: 'Qeyd', hint: 'Əlavə qeyd...', icon: Icons.sticky_note_2_outlined, maxLines: 2),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Sistemdə yaradılacaq rəsmi e-poçt:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
            const SizedBox(height: 6),
            _emailBox(previews.key, 'ad.soyad@student.idrak.edu.az (Avtomatik formalaşacaq)'),
          ],
        ),
      ),
    ];
  }

  List<Widget> _stepAcademic() {
    return [
      _formCard(
        title: 'Sinif Təyinatı',
        icon: Icons.school_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Şagirdin təhsil alacağı sinfi seçin (istəyə bağlı):', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _classes.map((c) {
                final name = c['name']?.toString() ?? '';
                final isSelected = _selectedClass == name;
                return GestureDetector(
                  onTap: () => setState(() => _selectedClass = isSelected ? null : name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: isSelected ? 1.5 : 1),
                    ),
                    child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF334155))),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      _formCard(
        title: 'Səhiyyə & Tibbi Göstəricilər',
        icon: Icons.local_hospital_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Qan Qrupu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _bloodGroups.contains(_bloodGroup) ? _bloodGroup : _bloodGroups.first,
              decoration: _inputDeco(icon: Icons.bloodtype_rounded),
              items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
              onChanged: (v) => setState(() => _bloodGroup = v!),
            ),
            const SizedBox(height: 14),
            const Text('Alergiyalar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonAllergies.map((allergy) {
                return GestureDetector(
                  onTap: () {
                    final current = _allergiesCtrl.text.trim();
                    if (current.isEmpty) {
                      _allergiesCtrl.text = allergy;
                    } else if (!current.contains(allergy)) {
                      _allergiesCtrl.text = '$current, $allergy';
                    }
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                    child: Text('+ $allergy', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            _modernInput(controller: _allergiesCtrl, label: 'Alergiyalar siyahısı', hint: 'Məs: Fıstıq, Sitrus', icon: Icons.healing_rounded, maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _modernInput(controller: _eyeColorCtrl, label: 'Göz Rəngi', hint: 'Qəhvəyi', icon: Icons.remove_red_eye_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _modernInput(controller: _contractAmountCtrl, label: 'Təhsil Haqqı (AZN)', hint: '6500', icon: Icons.payments_rounded, keyboard: TextInputType.number)),
            ]),
          ],
        ),
      ),
      _formCard(
        title: 'Köhnə Məktəb Məlumatları',
        icon: Icons.history_edu_rounded,
        child: Column(
          children: [
            _modernInput(controller: _oldSchoolNameCtrl, label: 'Köhnə məktəbin adı', hint: 'Məs: 132 nömrəli məktəb', icon: Icons.apartment_rounded),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _modernInput(controller: _oldSchoolGradeCtrl, label: 'Sinif', hint: '4', icon: Icons.numbers_rounded, keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _modernInput(controller: _oldSchoolEndCtrl, label: 'Bitirmə tarixi', hint: '2025-06-01', icon: Icons.event_busy_rounded)),
            ]),
          ],
        ),
      ),
      _formCard(
        title: 'Sınaq Müddəti & Başlanğıc Yoxlanış',
        icon: Icons.fact_check_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modernInput(controller: _probationCtrl, label: 'Sınaq müddətinin bitmə tarixi', hint: '2026-12-31', icon: Icons.timer_rounded),
            const SizedBox(height: 14),
            _statusDropdown('İmtahan mərhələsi', _examStatus, (v) => setState(() => _examStatus = v)),
            const SizedBox(height: 12),
            _statusDropdown('Tibbi yoxlanış', _medicalStatus, (v) => setState(() => _medicalStatus = v)),
            const SizedBox(height: 12),
            _statusDropdown('Psixoloq rəyi', _psychologyStatus, (v) => setState(() => _psychologyStatus = v)),
          ],
        ),
      ),
    ];
  }

  Widget _statusDropdown(String label, String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: _inputDeco(icon: Icons.task_alt_rounded).copyWith(labelText: label),
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Gözlənilir', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
        DropdownMenuItem(value: 'passed', child: Text('Keçib / Təsdiqlənib', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
        DropdownMenuItem(value: 'exempt', child: Text('Azad / Güzəşt', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
      ],
      onChanged: (v) => onChanged(v ?? 'pending'),
    );
  }

  List<Widget> _stepFamily(MapEntry<String, String> previews) {
    return [
      _formCard(
        title: 'Ailə Üzvləri',
        icon: Icons.family_restroom_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Valideyn, qohum və ya digər ailə üzvlərini əlavə edin. Hər üzvün bütün məlumatları web GoPanel ilə eyni saxlanılır.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
            const SizedBox(height: 10),
            for (int i = 0; i < _familyMembers.length; i++) _familyMemberCard(i),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _addFamilyMember,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni ailə üzvü əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: const BorderSide(color: Color(0xFF059669)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      _formCard(
        title: 'İlkin Giriş Şifrələri',
        icon: Icons.password_rounded,
        child: Row(children: [
          Expanded(
            child: _modernInput(
              controller: _studentPassCtrl,
              label: _isEdit ? 'Şagird şifrəsi (dəyişmək üçün)' : 'Şagird Şifrəsi *',
              hint: '123456',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              validator: (v) => _isEdit && (v ?? '').isEmpty ? null : PasswordHasher.validate(v, minLength: 6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _modernInput(
              controller: _parentPassCtrl,
              label: 'Valideyn Şifrəsi *',
              hint: '123456',
              icon: Icons.lock_reset_rounded,
              obscure: true,
              validator: (v) => PasswordHasher.validate(v, minLength: 6),
            ),
          ),
        ]),
      ),
      _formCard(
        title: 'Xülasə',
        icon: Icons.fact_check_rounded,
        child: Column(
          children: [
            _summaryRow('Şagird', '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'),
            _summaryRow('FİN', _finCtrl.text.trim()),
            _summaryRow('Sinif / dil', '${_targetGradeLevel ?? '-'} • ${_targetGradeLanguage}'),
            _summaryRow('Ailə üzvləri', '${_familyMembers.length} nəfər'),
            _summaryRow('E-poçt', previews.key.isNotEmpty ? previews.key : '-'),
          ],
        ),
      ),
    ];
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Flexible(child: Text(value.isEmpty ? '-' : value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  Widget _familyMemberCard(int index) {
    final f = _familyMembers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => f.expanded = !f.expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF2563EB).withAlpha(20),
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.isExisting ? 'Mövcud şəxs' : (f.name.text.trim().isEmpty ? 'Yeni ailə üzvü' : '${f.name.text} ${f.surname.text}'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeFamilyMember(index),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                ),
                Icon(f.expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF64748B)),
              ]),
            ),
          ),
          if (f.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => f.isExisting = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: !f.isExisting ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Center(child: Text('Yeni şəxs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: !f.isExisting ? Colors.white : const Color(0xFF64748B)))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => f.isExisting = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: f.isExisting ? const Color(0xFFD4AF37) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Center(child: Text('Mövcud şəxs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: f.isExisting ? Colors.black87 : const Color(0xFF64748B)))),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: f.relationType,
                    decoration: _inputDeco(icon: Icons.link_rounded).copyWith(labelText: 'Əlaqə növü *'),
                    items: _relationTypes.map((r) => DropdownMenuItem(value: r['value']?.toString(), child: Text(r['label']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                    onChanged: (v) => setState(() => f.relationType = v ?? 'other'),
                  ),
                  if (f.isExisting) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: f.existingParentId,
                      decoration: _inputDeco(icon: Icons.person_search_rounded).copyWith(labelText: 'Mövcud valideyn seçin *'),
                      items: _parentsCatalog.map((p) => DropdownMenuItem(value: p['id']?.toString(), child: Text('${p['name']} (${p['phone'] ?? ''})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) => setState(() => f.existingParentId = v),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _fmInput(f.name, 'Ad *', Icons.person_rounded, validator: (v) => (v ?? '').trim().isEmpty ? 'Ad tələb olunur' : null)),
                      const SizedBox(width: 8),
                      Expanded(child: _fmInput(f.surname, 'Soyad *', Icons.person_outline_rounded, validator: (v) => (v ?? '').trim().isEmpty ? 'Soyad tələb olunur' : null)),
                    ]),
                    const SizedBox(height: 8),
                    _fmInput(f.fatherName, 'Ata adı *', Icons.person_pin_rounded, validator: (v) => (v ?? '').trim().isEmpty ? 'Ata adı tələb olunur' : null),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _fmInput(f.phone, 'Telefon', Icons.phone_rounded, keyboard: TextInputType.phone)),
                      const SizedBox(width: 8),
                      Expanded(child: _fmInput(f.whatsapp, 'WhatsApp', Icons.chat_rounded, keyboard: TextInputType.phone)),
                    ]),
                    const SizedBox(height: 8),
                    _fmInput(f.email, 'E-poçt (boş buraxılsa avtomatik yaradılır)', Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 8),
                    _fmInput(f.finCode, 'FİN kod', Icons.fingerprint_rounded, inputFormatters: finCodeInputFormatters()),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                  isExpanded: true,
                          initialValue: f.serialType,
                          decoration: _inputDeco(icon: Icons.article_rounded).copyWith(labelText: 'Seriya növü'),
                          items: _serialTypes.map((s) => DropdownMenuItem(value: s['value']?.toString(), child: Text(s['label']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))).toList(),
                          onChanged: (v) => setState(() => f.serialType = v ?? 'AA'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _fmInput(f.serialNumber, 'Seriya nömrəsi', Icons.numbers_rounded, keyboard: TextInputType.number)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _fmInput(f.birthDate, 'Doğum tarixi (YYYY-MM-DD)', Icons.cake_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _fmInput(f.idCardDate, 'Vəsiqə tarixi (YYYY-MM-DD)', Icons.credit_card_rounded)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _fmInput(f.companyName, 'İş yeri', Icons.business_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _fmInput(f.positionName, 'Vəzifə', Icons.work_outline_rounded)),
                    ]),
                    const SizedBox(height: 8),
                    _fmInput(f.registrationAddress, 'Qeydiyyat ünvanı', Icons.home_rounded, maxLines: 2),
                    const SizedBox(height: 8),
                    _fmInput(f.actualAddress, 'Faktiki ünvan', Icons.location_on_rounded, maxLines: 2),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fmInput(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text, int maxLines = 1, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      decoration: _inputDeco(icon: icon).copyWith(labelText: label, isDense: true),
    );
  }
}
