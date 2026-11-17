import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import '../services/academic_meta.dart';

class ApiStudentWizardScreen extends StatefulWidget {
  const ApiStudentWizardScreen({super.key});

  @override
  State<ApiStudentWizardScreen> createState() => _ApiStudentWizardScreenState();
}

class _ApiStudentWizardScreenState extends State<ApiStudentWizardScreen> {
  final _client = ApiClient.instance;
  final _pageController = PageController();

  int _step = 0;
  bool _submitting = false;
  String? _error;

  // Step 1 — personal
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _fatherName = TextEditingController();
  final _fin = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _gender = 'male';
  DateTime? _birthDate;

  // Step 2 — parents
  final _fatherFullName = TextEditingController();
  final _fatherPhone = TextEditingController();
  final _fatherFin = TextEditingController();
  final _motherFullName = TextEditingController();
  final _motherPhone = TextEditingController();
  final _motherFin = TextEditingController();

  // Step 3 — placement
  int? _academicYearId;
  int _gradeLevel = 1;
  String _gradeLanguage = 'azerbaijan';
  String _gradeSuffix = 'A';
  int? _filialId;

  // Step 4 — medical / notes
  String? _bloodGroup;
  String? _eyeColor;
  String? _exclusiveType;
  final _note = TextEditingController();

  static const _steps = [
    'Şəxsi məlumat',
    'Valideynlər',
    'Yerləşdirmə',
    'Tibbi / Qeyd',
    'Yoxlama',
  ];

  @override
  void initState() {
    super.initState();
    _initMeta();
  }

  Future<void> _initMeta() async {
    try {
      await AcademicMeta.instance.load();
      if (!mounted) return;
      setState(() {
        _academicYearId = (AcademicMeta.instance.currentYear?['id'] as num?)?.toInt();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _surname, _fatherName, _fin, _email, _phone,
      _fatherFullName, _fatherPhone, _fatherFin,
      _motherFullName, _motherPhone, _motherFin, _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateStep(int step) {
    if (step == 0) {
      if (_name.text.trim().isEmpty) return 'Ad daxil edilməlidir.';
      if (_surname.text.trim().isEmpty) return 'Soyad daxil edilməlidir.';
      if (_fatherName.text.trim().isEmpty) return 'Ata adı daxil edilməlidir.';
      if (_fin.text.trim().length != 7) return 'FİN kod 7 simvol olmalıdır.';
      if (_birthDate == null) return 'Doğum tarixi seçilməlidir.';
      if (_email.text.trim().isNotEmpty && !_email.text.contains('@')) return 'E-poçt düzgün deyil.';
    }
    if (step == 1) {
      if (_fatherFullName.text.trim().isEmpty && _motherFullName.text.trim().isEmpty) {
        return 'Ən azı bir valideyn (ata və ya ana) daxil edilməlidir.';
      }
    }
    if (step == 2) {
      if (_academicYearId == null) return 'Tədris ili seçilməlidir.';
    }
    return null;
  }

  void _next() {
    final error = _validateStep(_step);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _error = null);
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _step--;
      _error = null;
    });
    _pageController.animateToPage(_step, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  Map<String, dynamic> _splitName(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return {'name': '', 'surname': '', 'father_name': ''};
    if (parts.length == 1) return {'name': parts[0], 'surname': '', 'father_name': ''};
    if (parts.length == 2) return {'name': parts[0], 'surname': parts[1], 'father_name': ''};
    return {'name': parts[0], 'surname': parts[1], 'father_name': parts.sublist(2).join(' ')};
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final familyMembers = <Map<String, dynamic>>[];

    if (_fatherFullName.text.trim().isNotEmpty) {
      final parts = _splitName(_fatherFullName.text);
      familyMembers.add({
        'is_existing_student': '0',
        'relation_type': 'father',
        'name': parts['name'],
        'surname': parts['surname'],
        'father_name': parts['father_name'],
        'phone': _fatherPhone.text.trim(),
        'fin_code': _fatherFin.text.trim(),
      });
    }

    if (_motherFullName.text.trim().isNotEmpty) {
      final parts = _splitName(_motherFullName.text);
      familyMembers.add({
        'is_existing_student': '0',
        'relation_type': 'mother',
        'name': parts['name'],
        'surname': parts['surname'],
        'father_name': parts['father_name'],
        'phone': _motherPhone.text.trim(),
        'fin_code': _motherFin.text.trim(),
      });
    }

    final payload = {
      'name': _name.text.trim(),
      'surname': _surname.text.trim(),
      'father_name': _fatherName.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'filial_id': _filialId,
      'profile': {
        'fin_code': _fin.text.trim().toUpperCase(),
        'birth_date': _birthDate?.toIso8601String().substring(0, 10),
        'gender': _gender,
        'blood_group': _bloodGroup,
        'eye_color': _eyeColor,
        'exclusive_type': _exclusiveType,
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'target_grade_level': _gradeLevel,
        'target_grade_language': _gradeLanguage,
        'target_grade_suffix': _gradeSuffix,
        'target_academic_year_id': _academicYearId,
      },
      'family_members': familyMembers,
      'exam_status': 'pending',
      'medical_status': 'pending',
      'psychology_status': 'pending',
    };

    try {
      await _client.post('academic/students', data: payload);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
          title: const Text('Qeydiyyat tamamlandı'),
          content: Text(
            '${_name.text.trim()} ${_surname.text.trim()} qəbul prosesinə əlavə edildi.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bağla'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Qeydiyyat zamanı xəta baş verdi.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni şagird — ${_step + 1}/${_steps.length}'),
      ),
      body: Column(
        children: [
          _progress(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepPersonal(),
                _stepParents(),
                _stepPlacement(),
                _stepMedical(),
                _stepReview(),
              ],
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.danger.withAlpha(20),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _back,
                      child: Text(_step == 0 ? 'Ləğv et' : 'Geri'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting ? null : _next,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAccent),
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_step == _steps.length - 1 ? 'Qeydiyyatı tamamla' : 'Davam et'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              final active = index <= _step;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryAccent : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(_steps[_step], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  Widget _stepPersonal() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: _dec('Ad *')),
        const SizedBox(height: 12),
        TextField(controller: _surname, textCapitalization: TextCapitalization.words, decoration: _dec('Soyad *')),
        const SizedBox(height: 12),
        TextField(controller: _fatherName, textCapitalization: TextCapitalization.words, decoration: _dec('Ata adı *')),
        const SizedBox(height: 12),
        TextField(
          controller: _fin,
          textCapitalization: TextCapitalization.characters,
          maxLength: 7,
          decoration: _dec('FİN kod *', hint: '7 simvol'),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: _dec('Cins *'),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Kişi')),
            DropdownMenuItem(value: 'female', child: Text('Qadın')),
          ],
          onChanged: (value) => setState(() => _gender = value ?? 'male'),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _birthDate ?? DateTime(2012, 1, 1),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _birthDate = picked);
          },
          child: InputDecorator(
            decoration: _dec('Doğum tarixi *'),
            child: Text(
              _birthDate == null
                  ? 'Seçin'
                  : '${_birthDate!.day.toString().padLeft(2, '0')}.'
                      '${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}',
              style: TextStyle(color: _birthDate == null ? AppColors.textMuted : null),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _dec('E-poçt')),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _dec('Telefon', hint: '+994 50 000 00 00')),
      ],
    );
  }

  Widget _stepParents() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Ata', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(controller: _fatherFullName, decoration: _dec('Ad Soyad Ata adı')),
        const SizedBox(height: 10),
        TextField(controller: _fatherPhone, keyboardType: TextInputType.phone, decoration: _dec('Telefon')),
        const SizedBox(height: 10),
        TextField(controller: _fatherFin, maxLength: 7, decoration: _dec('FİN kod')),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        const Text('Ana', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(controller: _motherFullName, decoration: _dec('Ad Soyad Ata adı')),
        const SizedBox(height: 10),
        TextField(controller: _motherPhone, keyboardType: TextInputType.phone, decoration: _dec('Telefon')),
        const SizedBox(height: 10),
        TextField(controller: _motherFin, maxLength: 7, decoration: _dec('FİN kod')),
        const SizedBox(height: 8),
        Text(
          'Ən azı bir valideyn daxil edilməlidir. Valideynlər sonradan profil bölməsindən də əlavə oluna bilər.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _stepPlacement() {
    final meta = AcademicMeta.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<int>(
          initialValue: _academicYearId,
          decoration: _dec('Tədris ili *'),
          items: meta.academicYears
              .map((year) => DropdownMenuItem<int>(
                    value: (year['id'] as num?)?.toInt(),
                    child: Text(year['name']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _academicYearId = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _gradeLevel,
          decoration: _dec('Sinif səviyyəsi *'),
          items: meta.gradeLevels
              .map((level) => DropdownMenuItem<int>(
                    value: (level['value'] as num?)?.toInt(),
                    child: Text(level['label']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _gradeLevel = value ?? 1),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _gradeLanguage,
          decoration: _dec('Təhsil dili *'),
          items: meta.sectors
              .map((sector) => DropdownMenuItem<String>(
                    value: sector['value']?.toString(),
                    child: Text(sector['label']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _gradeLanguage = value ?? 'azerbaijan'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _gradeSuffix,
          decoration: _dec('Hərf (şöbə)'),
          items: meta.gradeSuffixes
              .map((suffix) => DropdownMenuItem<String>(
                    value: suffix['value']?.toString(),
                    child: Text(suffix['label']?.toString() ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _gradeSuffix = value ?? 'A'),
        ),
        if (meta.filials.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _filialId,
            decoration: _dec('Filial'),
            items: meta.filials
                .map((filial) => DropdownMenuItem<int>(
                      value: (filial['id'] as num?)?.toInt(),
                      child: Text(filial['name']?.toString() ?? ''),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _filialId = value),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Sinifə təyinat qəbul təsdiqləndikdən sonra "Siniflər" bölməsindən edilir.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _stepMedical() {
    const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    const eyeColors = {
      'brown': 'Qəhvəyi',
      'blue': 'Mavi',
      'green': 'Yaşıl',
      'hazel': 'Fındıq',
      'amber': 'Kəhrəba',
      'gray': 'Boz',
      'black': 'Qara',
    };
    final meta = AcademicMeta.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _bloodGroup,
          decoration: _dec('Qan qrupu'),
          items: bloodGroups
              .map((group) => DropdownMenuItem(value: group, child: Text(group)))
              .toList(),
          onChanged: (value) => setState(() => _bloodGroup = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _eyeColor,
          decoration: _dec('Göz rəngi'),
          items: eyeColors.entries
              .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
              .toList(),
          onChanged: (value) => setState(() => _eyeColor = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _exclusiveType,
          decoration: _dec('Güzəşt kateqoriyası'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Yoxdur')),
            ...meta.exclusiveTypes.map((type) => DropdownMenuItem<String>(
                  value: type['value']?.toString(),
                  child: Text(type['label']?.toString() ?? ''),
                )),
          ],
          onChanged: (value) => setState(() => _exclusiveType = value),
        ),
        const SizedBox(height: 12),
        TextField(controller: _note, maxLines: 3, decoration: _dec('Qeyd')),
        const SizedBox(height: 10),
        Text(
          'Tibbi sənədlər və foto yükləmə mobil tətbiqdə növbəti mərhələdə əlavə olunacaq; '
          'hazırda qeydiyyat əsas məlumatlarla tamamlanır.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _stepReview() {
    Widget row(String label, dynamic value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 130, child: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5))),
              Expanded(
                child: Text(
                  (value == null || value.toString().isEmpty) ? '—' : value.toString(),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    final meta = AcademicMeta.instance;
    final yearName = meta.academicYears
        .firstWhere(
          (year) => (year['id'] as num?)?.toInt() == _academicYearId,
          orElse: () => const {},
        )['name'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Şəxsi məlumat', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              row('Ad', _name.text),
              row('Soyad', _surname.text),
              row('Ata adı', _fatherName.text),
              row('FİN', _fin.text.toUpperCase()),
              row('Cins', _gender == 'male' ? 'Kişi' : 'Qadın'),
              row('Doğum tarixi', _birthDate == null
                  ? '—'
                  : '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}'),
              row('E-poçt', _email.text),
              row('Telefon', _phone.text),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yerləşdirmə', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              row('Tədris ili', yearName ?? '—'),
              row('Sinif', '$_gradeLevel$_gradeSuffix'),
              row('Təhsil dili', _gradeLanguage),
              row('Valideynlər', [
                if (_fatherFullName.text.trim().isNotEmpty) 'Ata',
                if (_motherFullName.text.trim().isNotEmpty) 'Ana',
              ].join(', ')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Qeydiyyat tamamlandıqda şagird "Gözləyir" statusu ilə qəbul siyahısına düşəcək. '
            'İmtahan, tibbi və psixoloji mərhələlər Qəbul bölməsindən idarə olunur.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
