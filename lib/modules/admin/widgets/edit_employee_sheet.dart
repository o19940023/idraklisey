import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/fin_code_formatter.dart';
import '../../../core/utils/password_hasher.dart';
import '../../../core/widgets/profile_photo_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';

Future<void> showEditEmployeeSheet(BuildContext context, AppUser user) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditEmployeeForm(user: user),
  );
}

class _EditEmployeeForm extends StatefulWidget {
  final AppUser user;

  const _EditEmployeeForm({required this.user});

  @override
  State<_EditEmployeeForm> createState() => _EditEmployeeFormState();
}

class _EditEmployeeFormState extends State<_EditEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _fatherName;
  late final TextEditingController _fin;
  late final TextEditingController _idCard;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _position;
  late final TextEditingController _salary;
  late final TextEditingController _bank;
  late final TextEditingController _subject;
  late final TextEditingController _room;
  late final TextEditingController _pass;

  late String _gender;
  String _citizenship = 'Azərbaycan';
  String _educationLevel = 'Bakalavr';
  DateTime? _birthDate;
  DateTime? _hireDate;
  DateTime? _contractStart;
  DateTime? _contractEnd;
  String? _selectedRoleId;
  String? _photoUrl;
  bool _saving = false;
  final Set<String> _assignedClasses = {};

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    final nameParts = user.fullName.split(' ');
    _firstName =
        TextEditingController(text: user.firstName ?? nameParts.first);
    _lastName = TextEditingController(
      text: user.lastName ?? nameParts.skip(1).join(' '),
    );
    _fatherName = TextEditingController(text: user.fatherName ?? '');
    _fin = TextEditingController(text: user.finCode ?? '');
    _idCard = TextEditingController(text: user.idCardSerial ?? '');
    _address = TextEditingController(text: user.address ?? '');
    _phone = TextEditingController(text: user.phone);
    _position = TextEditingController(text: user.position ?? '');
    _salary = TextEditingController(text: user.salary?.toString() ?? '');
    _bank = TextEditingController(text: user.bankName ?? '');
    _subject = TextEditingController(text: user.subject ?? '');
    _room = TextEditingController(text: user.roomNumber ?? '');
    _pass = TextEditingController(text: user.password);
    _gender = user.gender ?? 'Kişi';
    _citizenship = user.citizenship ?? 'Azərbaycan';
    _educationLevel = user.educationLevel ?? 'Bakalavr';
    _birthDate = user.birthDate;
    _hireDate = user.hireDate;
    _contractStart = user.contractStart;
    _contractEnd = user.contractEnd;
    _selectedRoleId = user.assignedRoleId;
    _photoUrl = user.photoUrl;
    _assignedClasses.addAll(user.assignedClasses);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _fatherName.dispose();
    _fin.dispose();
    _idCard.dispose();
    _address.dispose();
    _phone.dispose();
    _position.dispose();
    _salary.dispose();
    _bank.dispose();
    _subject.dispose();
    _room.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get _isTeacher => widget.user.role == UserRole.teacher;

  Future<void> _pick(
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 75),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        final palette = AppPalette.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: palette.brandRoyal,
                ),
          ),
          child: child!,
        );
      },
    );
    if (mounted && picked != null) setState(() => onPicked(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    setState(() => _saving = true);

    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    await appState.updateUserAccount(
      widget.user.copyWith(
        firstName: first,
        lastName: last,
        fullName: '$first $last'.trim(),
        fatherName: _fatherName.text.trim(),
        gender: _gender,
        birthDate: _birthDate,
        finCode: _fin.text.trim(),
        address: _address.text.trim(),
        citizenship: _citizenship,
        idCardSerial: _idCard.text.trim(),
        educationLevel: _educationLevel,
        bankName: _bank.text.trim(),
        phone: _phone.text.trim(),
        position: _position.text.trim(),
        hireDate: _hireDate,
        salary: double.tryParse(_salary.text.trim().replaceAll(',', '.')),
        contractStart: _contractStart,
        contractEnd: _contractEnd,
        subject: _isTeacher ? _subject.text.trim() : null,
        roomNumber: _isTeacher ? _room.text.trim() : null,
        assignedClasses: _isTeacher ? _assignedClasses.toList() : const [],
        password: _pass.text.trim(),
        assignedRoleId: _selectedRoleId,
        photoUrl: _photoUrl ?? '',
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İşçi məlumatları yeniləndi'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: palette.borderHairline,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İşçi profilini redaktə et',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.idrakCode,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        children: [
                          ProfilePhotoPicker(
                            initialPhotoUrl: _photoUrl,
                            size: 78,
                            folder: 'idrak/profiles/staff',
                            onPhotoUploaded: (url) =>
                                setState(() => _photoUrl = url),
                            onPhotoRemoved: () =>
                                setState(() => _photoUrl = null),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_firstName.text} ${_lastName.text}'.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isTeacher
                                      ? 'Müəllim profili'
                                      : (appState
                                              .getRoleById(_selectedRoleId)
                                              ?.name ??
                                          'İşçi profili'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.brandRoyal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Fotoşəkil kartlarda və rəqəmsal vəsiqədə görünəcək.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.3,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _section(
                      context,
                      palette,
                      title: 'Şəxsi məlumatlar',
                      icon: Icons.badge_rounded,
                      children: [
                        _rowFields([
                          Expanded(
                            child: _field(
                              _firstName,
                              'Ad *',
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              _lastName,
                              'Soyad *',
                              validator: _required,
                            ),
                          ),
                        ]),
                        _field(_fatherName, 'Ata adı'),
                        _label('Cins'),
                        Row(
                          children: [
                            _chip(
                              'Kişi',
                              _gender == 'Kişi',
                              () => setState(() => _gender = 'Kişi'),
                            ),
                            const SizedBox(width: 8),
                            _chip(
                              'Qadın',
                              _gender == 'Qadın',
                              () => setState(() => _gender = 'Qadın'),
                            ),
                          ],
                        ),
                        _label('Doğum tarixi'),
                        _dateField(
                          _birthDate,
                          dateFormat,
                          () => _pick(_birthDate, (date) => _birthDate = date),
                        ),
                        _field(
                          _fin,
                          'FIN kod',
                          inputFormatters: finCodeInputFormatters(),
                          validator: (value) {
                            final text =
                                (value ?? '').trim().toUpperCase();
                            if (text.isNotEmpty) {
                              final error = validateFinCode(text);
                              if (error != null) return error;
                              if (appState.users.any(
                                (user) =>
                                    (user.finCode ?? '').toUpperCase() ==
                                        text &&
                                    user.id != widget.user.id,
                              )) {
                                return 'Bu FIN başqa hesabda istifadə olunur';
                              }
                            }
                            return null;
                          },
                        ),
                        _label('Vətəndaşlıq'),
                        _dropdown(
                          value: _citizenship,
                          icon: Icons.flag_rounded,
                          items: const [
                            'Azərbaycan',
                            'Türkiyə',
                            'Rusiya',
                            'Gürcüstan',
                            'Ukrayna',
                            'Digər',
                          ],
                          onChanged: (value) =>
                              setState(() => _citizenship = value!),
                        ),
                        _field(
                          _idCard,
                          'ŞV seriyası',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(12),
                          ],
                        ),
                        _field(_address, 'Ünvan'),
                        _field(
                          _phone,
                          'Telefon',
                          keyboard: TextInputType.phone,
                        ),
                      ],
                    ),
                    _section(
                      context,
                      palette,
                      title: 'İş məlumatları',
                      icon: Icons.work_rounded,
                      children: [
                        _field(_position, 'Vəzifə adı'),
                        if (_isTeacher) ...[
                          _rowFields([
                            Expanded(
                              child: _field(_subject, 'Fənn'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _field(_room, 'Otaq')),
                          ]),
                          _label('Təyin olunan siniflər'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final className
                                  in appState.allDistinctClasses)
                                FilterChip(
                                  label: Text(
                                    className,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected:
                                      _assignedClasses.contains(className),
                                  onSelected: (selected) => setState(
                                    () => selected
                                        ? _assignedClasses.add(className)
                                        : _assignedClasses.remove(className),
                                  ),
                                  selectedColor:
                                      palette.brandRoyal.withValues(alpha: 0.16),
                                  checkmarkColor: palette.brandRoyal,
                                  backgroundColor: palette.surface2,
                                  side: BorderSide(
                                    color: _assignedClasses.contains(className)
                                        ? palette.brandRoyal
                                        : palette.borderHairline,
                                  ),
                                ),
                            ],
                          ),
                        ] else ...[
                          _label('Rol'),
                          _dropdown(
                            value: _selectedRoleId,
                            icon: Icons.admin_panel_settings_rounded,
                            items: [
                              for (final role in appState.roles)
                                role.id,
                            ],
                            labels: {
                              for (final role in appState.roles)
                                role.id:
                                    '${role.name} (${role.permissionIds.length})',
                            },
                            onChanged: (value) =>
                                setState(() => _selectedRoleId = value),
                          ),
                        ],
                        _dropdown(
                          value: _educationLevel,
                          icon: Icons.school_rounded,
                          items: const [
                            'Orta təhsil',
                            'Orta ixtisas',
                            'Bakalavr',
                            'Magistr',
                            'PhD / Doktorantura',
                          ],
                          onChanged: (value) =>
                              setState(() => _educationLevel = value!),
                        ),
                        _field(_bank, 'Bank adı'),
                        _field(
                          _salary,
                          'Əmək haqqı (AZN)',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                        ),
                        _label('İşə qəbul tarixi'),
                        _dateField(
                          _hireDate,
                          dateFormat,
                          () => _pick(_hireDate, (date) => _hireDate = date),
                        ),
                        _rowFields([
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Müqavilə başlanğıc'),
                                _dateField(
                                  _contractStart,
                                  dateFormat,
                                  () => _pick(
                                    _contractStart,
                                    (date) => _contractStart = date,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Müqavilə bitmə'),
                                _dateField(
                                  _contractEnd,
                                  dateFormat,
                                  () => _pick(
                                    _contractEnd,
                                    (date) => _contractEnd = date,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ),
                    _section(
                      context,
                      palette,
                      title: 'Hesab təhlükəsizliyi',
                      icon: Icons.key_rounded,
                      children: [
                        _field(
                          _pass,
                          'Şifrə *',
                          obscure: true,
                          validator: (value) =>
                              PasswordHasher.validate(value, minLength: 6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İstifadəçi bu şifrə ilə sistemə daxil olur.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: palette.surface1,
                  border: Border(
                    top: BorderSide(color: palette.borderHairline),
                  ),
                  boxShadow: AppShadows.adaptiveModal(context),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandRoyal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                      label: const Text(
                        'Yadda saxla',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _section(
    BuildContext context,
    AppPalette palette, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: palette.brandRoyal),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final child in children) child,
        ],
      ),
    );
  }

  Widget _rowFields(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Tələb olunur' : null;

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 5),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppPalette.of(context).textMuted,
          ),
        ),
      );

  InputDecoration _deco(IconData icon) {
    final palette = AppPalette.of(context);
    return InputDecoration(
      filled: true,
      fillColor: palette.surface1,
      prefixIcon: Icon(icon, color: palette.brandRoyal, size: 18),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: palette.borderHairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: palette.borderHairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: palette.brandRoyal, width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        obscureText: obscure,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        decoration: _deco(Icons.edit_rounded).copyWith(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 12,
            color: AppPalette.of(context).textMuted,
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Map<String, String>? labels,
  }) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final safeValue = value != null && items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        isExpanded: true,
        dropdownColor: palette.surface1,
        decoration: _deco(icon),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(
                labels?[item] ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField(
    DateTime? date,
    DateFormat format,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: InputDecorator(
          decoration: _deco(Icons.calendar_month_rounded).copyWith(
            suffixIcon: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppPalette.of(context).brandRoyal,
            ),
          ),
          child: Text(
            date != null ? format.format(date) : 'Seçilməyib',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: date != null
                  ? colorScheme.onSurface
                  : AppPalette.of(context).textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? palette.brandRoyal.withValues(alpha: 0.12)
                : palette.surface1,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? palette.brandRoyal : palette.borderHairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? palette.brandRoyal
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
