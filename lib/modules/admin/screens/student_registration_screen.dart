import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/email_generator.dart';
import '../../../core/utils/fin_code_formatter.dart';
import '../../../core/utils/password_hasher.dart';
import '../../../core/widgets/profile_photo_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../widgets/credentials_result_dialog.dart';

/// Şagird qeydiyyatı — Müasir, yormayan 3 addımlı Sehrbaz (Multi-step Wizard):
/// 1) Şagird Kimliyi & Şəkil
/// 2) Sinif & Səhiyyə (Vizual sinif və qan qrupu seçimi)
/// 3) Valideyn & Giriş Məlumatları
class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _studentPassCtrl = TextEditingController(text: '123456');
  final _parentNameCtrl = TextEditingController();
  final _parentFinCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _parentAddressCtrl = TextEditingController();
  final _parentPassCtrl = TextEditingController(text: '123456');

  static const _stepTitles = ['Şagird Kimliyi', 'Sinif & Səhiyyə', 'Valideyn & Giriş'];

  static const _bloodGroups = [
    'A(I) Rh+', 'A(II) Rh+', 'B(III) Rh+', 'AB(IV) Rh+',
    'A(II) Rh-', 'B(III) Rh-', 'AB(IV) Rh-',
    'O(I) Rh+', 'O(I) Rh-',
  ];

  static const _commonAllergies = [
    'Qoz/Fıstıq',
    'Laktoza',
    'Qlüten',
    'Sitrus',
    'Toz',
  ];

  int _step = 0;
  String _gender = 'Kişi';
  DateTime? _birthDate;
  DateTime? _parentBirthDate;
  String? _selectedClass;
  String _bloodGroup = 'A(II) Rh+';
  String? _photoUrl;
  bool _saving = false;
  bool _parentAddressEdited = false;
  bool _useExistingParent = false;
  AppUser? _selectedParent;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _finCtrl.dispose();
    _addressCtrl.dispose();
    _allergiesCtrl.dispose();
    _studentPassCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentFinCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _parentAddressCtrl.dispose();
    _parentPassCtrl.dispose();
    super.dispose();
  }

  String _fullStudentName() => '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

  void _syncParentAddress(String studentAddress) {
    if (!_parentAddressEdited) {
      _parentAddressCtrl.text = studentAddress;
    }
  }

  MapEntry<String, String> _previewEmails(AppState appState) {
    final existing = appState.users
        .map((u) => (u.email ?? '').toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final name = _fullStudentName();
    final studentEmail = _firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty
        ? ''
        : EmailGenerator.generateStudentEmail(
            name,
            EmailGenerator.getYearFromFIN(_finCtrl.text.trim()),
            existingEmails: existing,
          );
    final parentEmail = _parentNameCtrl.text.trim().isEmpty
        ? ''
        : EmailGenerator.generateParentEmail(
            _parentNameCtrl.text.trim(),
            existingEmails: [...existing, if (studentEmail.isNotEmpty) studentEmail],
          );
    return MapEntry(studentEmail, parentEmail);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 14),
      firstDate: DateTime(now.year - 25),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (mounted && picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickParentBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parentBirthDate ?? DateTime(now.year - 40),
      firstDate: DateTime(now.year - 85),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black87,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (mounted && picked != null) setState(() => _parentBirthDate = picked);
  }

  Future<void> _nextOrSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_step == _stepTitles.length - 1 && _useExistingParent && _selectedParent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mövcud valideyn hesabı seçilməlidir'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    if (_step < _stepTitles.length - 1) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    final allergies = _allergiesCtrl.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    setState(() => _saving = true);
    final accounts = appState.registerStudentWithParent(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      fatherName: _fatherNameCtrl.text.trim(),
      gender: _gender,
      birthDate: _birthDate,
      finCode: _finCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      className: _selectedClass!,
      bloodGroup: _bloodGroup,
      allergies: allergies,
      studentPassword: _studentPassCtrl.text.trim(),
      existingParent: _useExistingParent ? _selectedParent : null,
      parentName: _parentNameCtrl.text.trim(),
      parentFinCode: _parentFinCtrl.text.trim(),
      parentBirthDate: _parentBirthDate,
      parentPhone: _parentPhoneCtrl.text.trim(),
      parentAddress: _parentAddressCtrl.text.trim(),
      parentPassword: _parentPassCtrl.text.trim(),
      studentPhotoUrl: _photoUrl,
    );
    setState(() => _saving = false);

    if (!mounted) return;
    final student = accounts['student']!;
    final parent = accounts['parent']!;
    await showCredentialsResultDialog(
      context: context,
      title: _useExistingParent ? 'Şagird Mövcud Valideynə Bağlandı' : 'Şagird və Valideyn Hesabları Yaradıldı',
      sections: [
        CredentialsSection(title: 'Şagird Hesabı', rows: [
          MapEntry('Ad Soyad', student.fullName),
          MapEntry('Sinif', _selectedClass!),
          MapEntry('E-poçt (Login)', student.email ?? ''),
          MapEntry('FIN kod', student.finCode ?? ''),
          MapEntry('İdrak kodu', student.idrakCode),
          MapEntry('Şifrə', student.password),
        ]),
        CredentialsSection(title: 'Valideyn', rows: [
          MapEntry('Ad Soyad', parent.fullName),
          if (_useExistingParent) ...[
            MapEntry('E-poçt (Login)', parent.email ?? ''),
            MapEntry('Mövcud hesab', 'Yeni şagird bu hesaba bağlandı'),
          ] else ...[
            MapEntry('E-poçt (Login)', parent.email ?? ''),
            MapEntry('FIN kod', parent.finCode ?? ''),
            MapEntry('İstifadəçi adı', parent.username),
            MapEntry('İdrak kodu', parent.idrakCode),
            MapEntry('Şifrə', parent.password),
          ],
        ]),
      ],
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final classes = appState.allDistinctClasses;
    if (_selectedClass == null && classes.isNotEmpty) {
      _selectedClass = classes.first;
    }
    final previews = _previewEmails(appState);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Şagird Qeydiyyatı',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.3),
            ),
            Text(
              'Addım ${_step + 1} / 3: ${_stepTitles[_step]}',
              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
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
            // ── Interactive Stepper Ribbon ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
              child: Row(
                children: List.generate(_stepTitles.length, (index) {
                  final isDone = index < _step;
                  final isCurrent = index == _step;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (index < _step) {
                          setState(() => _step = index);
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: index < _stepTitles.length - 1 ? 8 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? const Color(0xFF10B981)
                                        : (isCurrent ? const Color(0xFF38BDF8) : Colors.white.withAlpha(20)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                                        : Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w900,
                                              color: isCurrent ? const Color(0xFF0F172A) : Colors.white70,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _stepTitles[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                      color: isCurrent ? Colors.white : Colors.white60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: isDone ? 1.0 : (isCurrent ? 1.0 : 0.0),
                                minHeight: 4,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDone ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                                ),
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

            // ── Form Body Scrollable Area ──
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // ════════════ ADDIM 1: ŞAGİRD KİMLİYİ ════════════
                  if (_step == 0) ...[
                    // Photo Upload Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
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
                                Text(
                                  'Şagirdin Profil Şəkli',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Rəqəmsal ID kart və elektron jurnalda əks olunacaq fotoşəkil.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Personal Information Card
                    _buildFormCard(
                      title: 'Şəxsi Məlumatlar',
                      icon: Icons.badge_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernInput(
                                  controller: _firstNameCtrl,
                                  label: 'Ad *',
                                  hint: 'Elmir',
                                  icon: Icons.person_rounded,
                                  validator: (v) => (v ?? '').trim().isEmpty ? 'Ad tələb olunur' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildModernInput(
                                  controller: _lastNameCtrl,
                                  label: 'Soyad *',
                                  hint: 'Quliyev',
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) => (v ?? '').trim().isEmpty ? 'Soyad tələb olunur' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildModernInput(
                            controller: _fatherNameCtrl,
                            label: 'Ata adı',
                            hint: 'İlham',
                            icon: Icons.person_pin_rounded,
                          ),
                          const SizedBox(height: 14),

                          // Gender Selection Pills
                          const Text(
                            'Cinsi',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderChoice(
                                  title: 'Kişi (Oğlan)',
                                  icon: Icons.face_rounded,
                                  selected: _gender == 'Kişi',
                                  onTap: () => setState(() => _gender = 'Kişi'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildGenderChoice(
                                  title: 'Qadın (Qız)',
                                  icon: Icons.face_3_rounded,
                                  selected: _gender == 'Qadın',
                                  onTap: () => setState(() => _gender = 'Qadın'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Birth Date Field
                          const Text(
                            'Doğum Tarixi *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          _buildDateField(
                            date: _birthDate,
                            hint: 'Tarixi seçin',
                            icon: Icons.cake_rounded,
                            onTap: _pickBirthDate,
                          ),

                          const SizedBox(height: 14),

                          // FIN Code Field with formatters
                          _buildModernInput(
                            controller: _finCtrl,
                            label: 'FIN Kod *',
                            hint: 'Məs: 7K9Y12A',
                            icon: Icons.fingerprint_rounded,
                            keyboard: TextInputType.text,
                            inputFormatters: finCodeInputFormatters(),
                            validator: (v) {
                              final val = (v ?? '').trim().toUpperCase();
                              final err = validateFinCode(val);
                              if (err != null) return err;
                              if (appState.users.any((u) => (u.finCode ?? '').toUpperCase() == val)) {
                                return 'Bu FIN kod artıq qeydiyyatdadır';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ════════════ ADDIM 2: SİNİF & SƏHİYYƏ ════════════
                  if (_step == 1) ...[
                    // Class Selection Card (Interactive visual chips)
                    _buildFormCard(
                      title: 'Sinif Seçimi *',
                      icon: Icons.school_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Şagirdin təhsil alacağı sinfi seçin:',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: classes.map((cls) {
                              final isSelected = _selectedClass == cls;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedClass = cls),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    cls,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Health and Blood Group Card
                    _buildFormCard(
                      title: 'Səhiyyə & Tibbi Göstəricilər',
                      icon: Icons.local_hospital_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Qan Qrupu',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _bloodGroup,
                            decoration: _inputDeco(icon: Icons.bloodtype_rounded),
                            items: _bloodGroups.map((bg) {
                              return DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)));
                            }).toList(),
                            onChanged: (v) => setState(() => _bloodGroup = v!),
                          ),
                          const SizedBox(height: 14),

                          // Common Allergy Chips
                          const Text(
                            'Alergiyalar (Seçin və ya əlavə edin)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
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
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Text(
                                    '+ $allergy',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          _buildModernInput(
                            controller: _allergiesCtrl,
                            label: 'Alergiyalar siyahısı',
                            hint: 'Məs: Fıstıq, Sitrus',
                            icon: Icons.healing_rounded,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Living Address Card
                    _buildFormCard(
                      title: 'Yaşayış Ünvanı & Avto-Mail',
                      icon: Icons.home_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernInput(
                            controller: _addressCtrl,
                            label: 'Ünvan',
                            hint: 'Bakı şəh., Nəsimi ray., ...',
                            icon: Icons.location_on_rounded,
                            maxLines: 2,
                            onFieldChanged: _syncParentAddress,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sistemdə yaradılacaq rəsmi e-poçt:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          _buildEmailBox(
                            email: previews.key,
                            placeholder: 'ad.soyad.s2026@idrak.edu.az (Avtomatik formalaşacaq)',
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ════════════ ADDIM 3: VALİDEYN & GİRİŞ ════════════
                  if (_step == 2) ...[
                    // Mode Selector: New vs Existing Parent
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useExistingParent = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_useExistingParent ? const Color(0xFF0F172A) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '➕ Yeni Valideyn',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: !_useExistingParent ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _useExistingParent = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _useExistingParent ? const Color(0xFFD4AF37) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '🔗 Mövcud Valideyn',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: _useExistingParent ? Colors.black87 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_useExistingParent) ...[
                      // Select Existing Parent
                      _buildFormCard(
                        title: 'Mövcud Valideyn Seçimi',
                        icon: Icons.person_search_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedParent?.id,
                              decoration: _inputDeco(icon: Icons.family_restroom_rounded).copyWith(hintText: 'Valideyn seçin'),
                              items: appState.users.where((u) => u.role == UserRole.parent).map((p) {
                                final count = p.linkedStudentIds.length + (p.linkedStudentId != null && !p.linkedStudentIds.contains(p.linkedStudentId) ? 1 : 0);
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    '${p.fullName} ($count övlad)',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedParent = appState.users.where((u) => u.id == v).isEmpty ? null : appState.users.firstWhere((u) => u.id == v);
                                });
                              },
                            ),
                            if (_selectedParent != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Seçilmiş Valideyn: ${_selectedParent!.fullName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF78350F))),
                                    const SizedBox(height: 2),
                                    Text('E-poçt: ${_selectedParent!.email ?? "-"} • Tel: ${_selectedParent!.phone}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _buildModernInput(
                              controller: _studentPassCtrl,
                              label: 'Şagird Şifrəsi *',
                              hint: 'Ən azı 6 simvol',
                              icon: Icons.lock_outline_rounded,
                              obscure: true,
                              validator: (v) => PasswordHasher.validate(v, minLength: 6),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Create New Parent
                      _buildFormCard(
                        title: 'Valideyn Şəxsi Məlumatları',
                        icon: Icons.family_restroom_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModernInput(
                              controller: _parentNameCtrl,
                              label: 'Valideynin Adı və Soyadı *',
                              hint: 'Vəli Quliyev',
                              icon: Icons.person_rounded,
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Valideyn adı tələb olunur' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildModernInput(
                              controller: _parentFinCtrl,
                              label: 'Valideynin FIN Kodu *',
                              hint: 'Məs: 5XX8Y12',
                              icon: Icons.fingerprint_rounded,
                              keyboard: TextInputType.text,
                              inputFormatters: finCodeInputFormatters(),
                              validator: (v) {
                                final val = (v ?? '').trim().toUpperCase();
                                final err = validateFinCode(val);
                                if (err != null) return err;
                                if (appState.users.any((u) => (u.finCode ?? '').toUpperCase() == val)) {
                                  return 'Bu FIN kod artıq qeydiyyatdadır';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Valideynin Doğum Tarixi *',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            _buildDateField(
                              date: _parentBirthDate,
                              hint: 'Tarixi seçin',
                              icon: Icons.cake_rounded,
                              onTap: _pickParentBirthDate,
                            ),
                            const SizedBox(height: 12),
                            _buildModernInput(
                              controller: _parentPhoneCtrl,
                              label: 'Əlaqə Telefonu *',
                              hint: '+994 50 123-45-67',
                              icon: Icons.phone_rounded,
                              keyboard: TextInputType.phone,
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Telefon tələb olunur' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildModernInput(
                              controller: _parentAddressCtrl,
                              label: 'Valideyn Ünvanı',
                              hint: 'Bakı şəhəri, ...',
                              icon: Icons.home_work_rounded,
                              maxLines: 2,
                              onFieldChanged: (_) => _parentAddressEdited = true,
                            ),
                            const SizedBox(height: 12),
                            _buildEmailBox(
                              email: previews.value,
                              placeholder: 'valideyn.mail@idrak.edu.az (Avtomatik formalaşacaq)',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Passwords Card
                      _buildFormCard(
                        title: 'İlkin Giriş Şifrələri',
                        icon: Icons.password_rounded,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModernInput(
                                controller: _studentPassCtrl,
                                label: 'Şagird Şifrəsi *',
                                hint: '123456',
                                icon: Icons.lock_outline_rounded,
                                obscure: true,
                                validator: (v) => PasswordHasher.validate(v, minLength: 6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildModernInput(
                                controller: _parentPassCtrl,
                                label: 'Valideyn Şifrəsi *',
                                hint: '123456',
                                icon: Icons.lock_reset_rounded,
                                obscure: true,
                                validator: (v) => PasswordHasher.validate(v, minLength: 6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    _buildSummaryCard(dateFormat),
                  ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
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
                        : Icon(
                            _step == _stepTitles.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _saving ? 'Qeydiyyat edilir...' : (_step == _stepTitles.length - 1 ? 'Şagirdi Qeydiyyata Al' : 'Növbəti Addım'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onFieldChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onFieldChanged,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      decoration: _inputDeco(icon: icon).copyWith(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildGenderChoice({required String title, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? const Color(0xFF1E40AF) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailBox({required String email, required String placeholder}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              email.isNotEmpty ? email : placeholder,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: email.isNotEmpty ? const Color(0xFF1E40AF) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({required DateTime? date, required String hint, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDeco(icon: icon).copyWith(
          suffixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 18),
        ),
        child: Text(
          date != null ? DateFormat('dd.MM.yyyy').format(date) : hint,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: date != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DateFormat dateFormat) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Şagird', _fullStudentName()),
      if (_fatherNameCtrl.text.trim().isNotEmpty) MapEntry('Ata adı', _fatherNameCtrl.text.trim()),
      MapEntry('Sinif', _selectedClass ?? '-'),
      if (_birthDate != null) MapEntry('Doğum tarixi', dateFormat.format(_birthDate!)),
      MapEntry('FIN', _finCtrl.text),
      if (_bloodGroup != 'A(II) Rh+') MapEntry('Qan qrupu', _bloodGroup),
      MapEntry('Valideyn', _parentNameCtrl.text.trim()),
      if (_parentBirthDate != null) MapEntry('Valideyn doğum tarixi', dateFormat.format(_parentBirthDate!)),
      if (_parentPhoneCtrl.text.trim().isNotEmpty) MapEntry('Valideyn telefonu', _parentPhoneCtrl.text.trim()),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fact_check_rounded, size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Qeydiyyat Məlumatlarının Yekun Xülasəsi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.key, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  Text(row.value.isNotEmpty ? row.value : '-', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
            ),
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
}
