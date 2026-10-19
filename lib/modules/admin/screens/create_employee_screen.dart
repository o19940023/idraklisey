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

/// Detallı işçi və müəllim yaradılması — Müasir 4 addımlı İR (HR) Sehrbazı:
/// 1) Şəxsi Kimlik & Foto
/// 2) Əlaqə & Bank
/// 3) Vəzifə, Rol & Tədris İcazələri
/// 4) Hesab & Giriş Şifrəsi
class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: '123456');

  static const _citizenships = ['Azərbaycan', 'Türkiyə', 'Rusiya', 'Gürcüstan', 'Ukrayna', 'İran', 'Digər'];
  static const _educationLevels = ['Orta təhsil', 'Orta ixtisas', 'Bakalavr', 'Magistr', 'PhD / Doktorantura'];

  static const _stepTitles = ['Şəxsi Kimlik', 'Əlaqə & Bank', 'Vəzifə & Rol', 'Hesab & Giriş'];

  int _step = 0;
  String _gender = 'Kişi';
  String _citizenship = 'Azərbaycan';
  String _educationLevel = 'Bakalavr';
  DateTime? _birthDate;
  DateTime? _hireDate;
  DateTime? _contractStart;
  DateTime? _contractEnd;
  bool _isTeacher = true;
  String? _selectedRoleId;
  String? _photoUrl;
  bool _saving = false;
  final Set<String> _assignedClasses = {};
  bool _permCafeteria = false;
  bool _permMedical = false;
  bool _permInventory = true;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    if (appState.roles.isEmpty) {
      appState.loadRoles();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _finCtrl.dispose();
    _idCardCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    _bankCtrl.dispose();
    _subjectCtrl.dispose();
    _roomCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _previewEmail(AppState appState) {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) return '';
    final existing = appState.users
        .map((u) => (u.email ?? '').toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    return EmailGenerator.generateStaffEmail('$first $last', existingEmails: existing);
  }

  Future<void> _pickDate(DateTime? current, int minYearsAgo, int maxYearsAgo, ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - minYearsAgo),
      firstDate: DateTime(now.year - maxYearsAgo),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (mounted && picked != null) setState(() => onPicked(picked));
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
    final role = _isTeacher ? null : appState.getRoleById(_selectedRoleId);

    final user = appState.createEmployeeAccount(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      fatherName: _fatherNameCtrl.text.trim(),
      gender: _gender,
      birthDate: _birthDate,
      finCode: _finCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      citizenship: _citizenship,
      idCardSerial: _idCardCtrl.text.trim(),
      educationLevel: _educationLevel,
      bankName: _bankCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      photoUrl: _photoUrl,
      isTeacher: _isTeacher,
      position: _positionCtrl.text.trim(),
      hireDate: _hireDate,
      salary: double.tryParse(_salaryCtrl.text.trim().replaceAll(',', '.')),
      contractStart: _contractStart,
      contractEnd: _contractEnd,
      subject: _isTeacher ? _subjectCtrl.text.trim() : null,
      roomNumber: _isTeacher ? _roomCtrl.text.trim() : null,
      assignedClasses: _assignedClasses.toList(),
      teacherPermissions: _isTeacher
          ? TeacherPermissions(
              canManageCafeteria: _permCafeteria,
              canManageMedical: _permMedical,
              canManageInventory: _permInventory,
            )
          : null,
      assignedRoleId: _selectedRoleId,
    );
    setState(() => _saving = false);

    if (!mounted) return;
    await showCredentialsResultDialog(
      context: context,
      title: 'İşçi Hesabı Yaradıldı',
      sections: [
        CredentialsSection(title: 'Hesab Məlumatları', rows: [
          MapEntry('Ad Soyad', user.fullName),
          MapEntry('Vəzifə', _isTeacher ? 'Müəllim' : (role?.name ?? 'İşçi')),
          if (user.position != null && user.position!.isNotEmpty) MapEntry('Vəzifə adı', user.position!),
          MapEntry('E-poçt (Login)', user.email ?? ''),
          MapEntry('İstifadəçi adı', user.username),
          MapEntry('FIN kod', user.finCode ?? ''),
          MapEntry('İdrak kodu', user.idrakCode),
          MapEntry('Şifrə', user.password),
        ]),
      ],
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final classes = appState.allDistinctClasses;
    final emailPreview = _previewEmail(appState);
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
              'Yeni Əməkdaş Qeydiyyatı',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.3),
            ),
            Text(
              'Addım ${_step + 1} / 4: ${_stepTitles[_step]}',
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
                        margin: EdgeInsets.only(right: index < _stepTitles.length - 1 ? 6 : 0),
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
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: isCurrent ? const Color(0xFF0F172A) : Colors.white70,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _stepTitles[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
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
                  // ════════════ ADDIM 1: ŞƏXSİ KİMLİK ════════════
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
                            folder: 'idrak/profiles/teachers',
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Əməkdaşın Profil Şəkli',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Məktəb portalı, rəqəmsal vəsiqə və rəsmi siyahılarda əks olunacaq fotoşəkil.',
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
                      icon: Icons.badge_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernInput(
                                  controller: _firstNameCtrl,
                                  label: 'Ad *',
                                  hint: 'Ayşə',
                                  icon: Icons.person_rounded,
                                  validator: (v) => (v ?? '').trim().isEmpty ? 'Ad tələb olunur' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildModernInput(
                                  controller: _lastNameCtrl,
                                  label: 'Soyad *',
                                  hint: 'Məmmədova',
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
                            hint: 'Eldar',
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
                                  title: 'Kişi',
                                  icon: Icons.face_rounded,
                                  selected: _gender == 'Kişi',
                                  onTap: () => setState(() => _gender = 'Kişi'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildGenderChoice(
                                  title: 'Qadın',
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
                            onTap: () => _pickDate(_birthDate, 30, 75, (d) => _birthDate = d),
                          ),

                          const SizedBox(height: 14),

                          // FIN Code Field with formatters
                          _buildModernInput(
                            controller: _finCtrl,
                            label: 'FIN Kod *',
                            hint: 'Məs: 6XX7UVH',
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

                          const SizedBox(height: 14),

                          // Citizenship & ID Card Serial
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _citizenship,
                                  decoration: _inputDeco(icon: Icons.flag_rounded).copyWith(labelText: 'Vətəndaşlıq'),
                                  items: _citizenships.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
                                  onChanged: (v) => setState(() => _citizenship = v!),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildModernInput(
                                  controller: _idCardCtrl,
                                  label: 'ŞV Seriyası',
                                  hint: 'AA1234567',
                                  icon: Icons.badge_outlined,
                                  inputFormatters: [LengthLimitingTextInputFormatter(12)],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ════════════ ADDIM 2: ƏLAQƏ & BANK ════════════
                  if (_step == 1) ...[
                    _buildFormCard(
                      title: 'Əlaqə & Bank Məlumatları',
                      icon: Icons.contact_mail_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernInput(
                            controller: _phoneCtrl,
                            label: 'Telefon Nömrəsi *',
                            hint: '+994 50 123-45-67',
                            icon: Icons.phone_rounded,
                            keyboard: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildModernInput(
                            controller: _addressCtrl,
                            label: 'Yaşayış Ünvanı',
                            hint: 'Bakı şəh., Nərimanov ray., ...',
                            icon: Icons.home_rounded,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                          _buildModernInput(
                            controller: _bankCtrl,
                            label: 'Maaş Kartının Bankı',
                            hint: 'Məs: Kapital Bank / Paşa Bank',
                            icon: Icons.account_balance_rounded,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sistemdə yaradılacaq rəsmi e-poçt:',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          _buildEmailBox(
                            email: emailPreview ?? '',
                            placeholder: 'ad.soyad@idrak.edu.az (Ad daxil edildikdə yaranır)',
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ════════════ ADDIM 3: VƏZİFƏ & ROL ════════════
                  if (_step == 2) ...[
                    // Role Type Selector (Teacher vs Other Staff)
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
                              onTap: () => setState(() => _isTeacher = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isTeacher ? const Color(0xFF0F172A) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '👨‍🏫 Müəllim (Pedaqoji)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: _isTeacher ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isTeacher = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isTeacher ? const Color(0xFF2563EB) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '💼 İnzibati / Digər İşçi',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: !_isTeacher ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isTeacher) ...[
                      // Teacher specific fields
                      _buildFormCard(
                        title: 'Tədris Sahəsi & Otaq',
                        icon: Icons.menu_book_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernInput(
                                    controller: _subjectCtrl,
                                    label: 'Tədris Fənni *',
                                    hint: 'Riyaziyyat',
                                    icon: Icons.school_rounded,
                                    validator: (v) => (v ?? '').trim().isEmpty ? 'Fənn tələb olunur' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildModernInput(
                                    controller: _roomCtrl,
                                    label: 'Dərs Otağı',
                                    hint: 'Otaq 204',
                                    icon: Icons.meeting_room_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Class Multi-select
                            if (classes.isNotEmpty) ...[
                              const Text(
                                'Tədris Edəcəyi Siniflər (Çoxlu seçim):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: classes.map((cls) {
                                  final isAssigned = _assignedClasses.contains(cls);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isAssigned) {
                                          _assignedClasses.remove(cls);
                                        } else {
                                          _assignedClasses.add(cls);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isAssigned ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isAssigned ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                                      ),
                                      child: Text(
                                        cls,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isAssigned ? FontWeight.w900 : FontWeight.w600,
                                          color: isAssigned ? Colors.white : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Additional Teacher Permissions
                            const Text(
                              'Pedaqoji Əlavə İcazələr:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            _buildPermToggle('Yeməkxana Menyu İdarəsi', _permCafeteria, (v) => setState(() => _permCafeteria = v)),
                            _buildPermToggle('Tibbi Qeydlər İdarəsi', _permMedical, (v) => setState(() => _permMedical = v)),
                            _buildPermToggle('İnventar & QR Biletlər', _permInventory, (v) => setState(() => _permInventory = v)),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Non-teacher role fields
                      _buildFormCard(
                        title: 'İnzibati Rol Seçimi *',
                        icon: Icons.admin_panel_settings_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRoleId,
                              decoration: _inputDeco(icon: Icons.admin_panel_settings_rounded).copyWith(labelText: 'Təyin edilən Rol *'),
                              items: appState.roles.map((r) {
                                return DropdownMenuItem(
                                  value: r.id,
                                  child: Text('${r.name} (${r.permissionIds.length} səlahiyyət)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedRoleId = v),
                              validator: (v) => v == null ? 'Rol seçilməlidir' : null,
                            ),
                            if (_selectedRoleId != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                appState.getRoleById(_selectedRoleId)?.description ?? '',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Employment & Contract Card
                    _buildFormCard(
                      title: 'Müqavilə & Əmək Haqqı',
                      icon: Icons.payments_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernInput(
                            controller: _positionCtrl,
                            label: 'Rəsmi Vəzifə Adı',
                            hint: 'Məs: Baş Müəllim / İT Mütəxəssis',
                            icon: Icons.work_history_rounded,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _educationLevel,
                                  decoration: _inputDeco(icon: Icons.school_rounded).copyWith(labelText: 'Təhsil Səviyyəsi'),
                                  items: _educationLevels.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)))).toList(),
                                  onChanged: (v) => setState(() => _educationLevel = v!),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildModernInput(
                                  controller: _salaryCtrl,
                                  label: 'Əmək Haqqı (AZN)',
                                  hint: '1500',
                                  icon: Icons.attach_money_rounded,
                                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'İşə Qəbul Tarixi',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          _buildDateField(
                            date: _hireDate,
                            hint: 'Tarixi seçin',
                            icon: Icons.event_available_rounded,
                            onTap: () => _pickDate(_hireDate, 1, 50, (d) => _hireDate = d),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Müqavilə Başlanğıc', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                    const SizedBox(height: 5),
                                    _buildDateField(
                                      date: _contractStart,
                                      hint: 'Seçilməyib',
                                      icon: Icons.play_arrow_rounded,
                                      onTap: () => _pickDate(_contractStart, 1, 50, (d) => _contractStart = d),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Müqavilə Bitmə', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                    const SizedBox(height: 5),
                                    _buildDateField(
                                      date: _contractEnd,
                                      hint: 'Müddətsiz',
                                      icon: Icons.event_busy_rounded,
                                      onTap: () => _pickDate(_contractEnd, 1, 50, (d) => _contractEnd = d),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ════════════ ADDIM 4: HESAB & ŞİFRƏ ════════════
                  if (_step == 3) ...[
                    _buildFormCard(
                      title: 'Giriş Hesabı & Təhlükəsizlik',
                      icon: Icons.key_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEmailBox(
                            email: emailPreview ?? '',
                            placeholder: 'ad.soyad@idrak.edu.az',
                          ),
                          const SizedBox(height: 14),
                          _buildModernInput(
                            controller: _passCtrl,
                            label: 'İlkin Giriş Şifrəsi *',
                            hint: '123456',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) => PasswordHasher.validate(v, minLength: 6),
                          ),
                        ],
                      ),
                    ),

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
                            _step == _stepTitles.length - 1 ? Icons.person_add_rounded : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _saving ? 'Yaradılır...' : (_step == _stepTitles.length - 1 ? 'Əməkdaşı Yarat' : 'Növbəti Addım'),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
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

  Widget _buildPermToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ],
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
    final salary = double.tryParse(_salaryCtrl.text.trim().replaceAll(',', '.'));
    final rows = <MapEntry<String, String>>[
      MapEntry('Ad Soyad', '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim()),
      if (_fatherNameCtrl.text.trim().isNotEmpty) MapEntry('Ata adı', _fatherNameCtrl.text.trim()),
      MapEntry('Cins', _gender),
      if (_birthDate != null) MapEntry('Doğum tarixi', dateFormat.format(_birthDate!)),
      MapEntry('FIN', _finCtrl.text),
      if (_phoneCtrl.text.trim().isNotEmpty) MapEntry('Telefon', _phoneCtrl.text.trim()),
      MapEntry('Təyinat', _isTeacher ? 'Müəllim${_subjectCtrl.text.trim().isNotEmpty ? " (${_subjectCtrl.text.trim()})" : ""}' : 'İnzibati Heyət'),
      if (_positionCtrl.text.trim().isNotEmpty) MapEntry('Vəzifə adı', _positionCtrl.text.trim()),
      if (salary != null) MapEntry('Əmək haqqı', '${_salaryCtrl.text.trim()} AZN'),
      if (_hireDate != null) MapEntry('İşə qəbul', dateFormat.format(_hireDate!)),
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
                'Əməkdaş Məlumatlarının Yekun İcmalı',
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
