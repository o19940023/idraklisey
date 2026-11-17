import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/profile_photo_picker.dart';
import '../../../data/models/employee_model.dart';
import '../../../providers/app_state.dart';

/// Exact 1:1 GoPanel Web Employee Creation & Editing Wizard Screen
/// Corresponds to: `http://localhost:8000/panel/employee/employees/store`
/// 10 Tabs:
/// 1) Şəxsi Məlumatlar (group-tab-1)
/// 2) Təhsil məlumatları (group-tab-2)
/// 3) İş təcrübəsi (group-tab-3)
/// 4) Sosial Status (group-tab-4)
/// 5) Bank kartları (group-tab-5)
/// 6) Nəqliyyat vasitələrim (group-tab-7)
/// 7) Sənədlərin Siyahısı (group-tab-6)
/// 8) Giriş Məlumatları (login-tab)
/// 9) Müqavilə məlumatları (contract-tab)
/// 10) Öncəki qazancları (group-tab-previous_earnings)
class EmployeeStoreScreen extends StatefulWidget {
  final Employee? employeeToEdit;

  const EmployeeStoreScreen({super.key, this.employeeToEdit});

  @override
  State<EmployeeStoreScreen> createState() => _EmployeeStoreScreenState();
}

class _EmployeeStoreScreenState extends State<EmployeeStoreScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _photoUrl;

  // Global / Top Header
  late final TextEditingController _codeCtrl;
  late final TextEditingController _finCtrl;

  // TAB 1: Şəxsi Məlumatlar
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _minifiedNameCtrl;
  String _gender = 'Kişi';
  DateTime? _birthDate;
  String _citizenship = 'Azərbaycan';
  String _scientificDegree = 'Yoxdur';
  String _honoraryTitle = 'Yoxdur';
  String _idCardSerial = 'AA';
  late final TextEditingController _idCardNumberCtrl;
  DateTime? _idCardIssueDate;
  DateTime? _idCardExpiryDate;
  String _maritalStatus = 'Subay';
  String _driverLicense = 'Xeyr';
  String _militaryDuty = 'Xeyr';
  late final TextEditingController _registrationAddressCtrl;
  late final TextEditingController _actualAddressCtrl;
  String _bloodGroup = 'I (0) Rh+';
  late final TextEditingController _personalEmailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _corporatePhoneCtrl;

  // TAB 2: Təhsil məlumatları (Repeater)
  final List<Map<String, dynamic>> _educations = [];

  // TAB 3: İş təcrübəsi (Repeater)
  final List<Map<String, dynamic>> _experiences = [];

  // TAB 4: Sosial Status (Repeater)
  final List<Map<String, dynamic>> _socialStatuses = [];

  // TAB 5: Bank kartları
  String _bankName = 'Kapital Bank';
  late final TextEditingController _bankAccountCtrl;
  late final TextEditingController _bankIbanCtrl;
  DateTime? _cardExpiryDate;

  // TAB 6: Nəqliyyat vasitələrim
  late final TextEditingController _vehicleNumberCtrl;

  // TAB 7: Sənədlər
  final List<Map<String, dynamic>> _documents = [];

  // TAB 8: Giriş Məlumatları
  late final TextEditingController _loginEmailCtrl;
  late final TextEditingController _passwordCtrl;
  final Set<String> _selectedRoles = {'Müəllim'};

  // TAB 9: Müqavilə məlumatları
  late final TextEditingController _contractNumberCtrl;
  DateTime? _contractDate;
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  String _contractType = 'Əmasda olan';
  bool _isIndefinite = false;
  late final TextEditingController _positionCtrl;
  String _company = 'İdrak liseyi';
  String _filial = 'Bakı filialı';
  late final TextEditingController _structureCtrl;
  String _teqvim = 'Əsas İstehsalat Təqvimi 2026-2027';
  late final TextEditingController _grossSalaryCtrl;
  late final TextEditingController _foodPriceCtrl;
  late final TextEditingController _finalGrossSalaryCtrl;
  String _paymentType = 'Aylıq vəzifə maaşı';
  late final TextEditingController _salaryAdditionCtrl;
  String _workRegime = 'Tam iş vaxtı (həftəlik 40 saat)';
  String _workTimeType = 'Gündəlik';
  late final TextEditingController _workRegimeDetailsCtrl;
  String _workSchedule = '5 günlük iş həftəsi';
  bool _hasProbation = false;
  String _probationUnit = 'Ay';
  late final TextEditingController _probationValueCtrl;
  String _workCondition = 'Normal';
  late final TextEditingController _workConditionAdditionCtrl;
  String _workStartTime = '08:30';
  String _workEndTime = '17:30';
  String _breakStartTime = '13:00';
  String _breakEndTime = '14:00';
  late final TextEditingController _vacationDaysCtrl;
  late final TextEditingController _jobDescriptionCtrl;

  // TAB 10: Öncəki qazancları (Repeater)
  final List<Map<String, dynamic>> _previousEarnings = [];

  // Dropdown Constants
  static const _citizenships = [
    'Azərbaycan', 'Rusiya', 'İran', 'Gürcüstan', 'Türkiyə', 'Amerika', 'Almaniya', 'Böyük Britaniya', 'Digər'
  ];

  static const _scientificDegrees = [
    'Yoxdur', 'Elmlər namizədi', 'Fəlsəfə doktoru', 'Elmlər doktoru'
  ];

  static const _honoraryTitles = [
    'Yoxdur',
    'Azadlıq uğrunda mübarizləri',
    'Xalq yazıçıları',
    'Xalq şairləri',
    'Xalq artistləri',
    'Xalq rəssamları',
    'Əməkdar elm xadimləri',
    'Əməkdar incəsənət xadimləri',
    'Əməkdar artistləri',
    'Əməkdar rəssamları',
    'Əməkdar mədəniyyət işçiləri',
    'Əməkdar müəllimləri',
    'Əməkdar həkimləri',
    'Əməkdar memarları',
    'Əməkdar dövlət qulluqçuları',
    'Əməkdar bədən tərbiyəsi və idman işçiləri',
    'Əməkdar jurnalistləri',
    'Əməkdar mühəndisləri',
    'Əməkdar hüquqşünasları',
    'Əməkdar kənd təsərrüfatı işçiləri',
    'Əməkdar pilotları',
    'Əməkdar tibb işçiləri',
    'Əməkdar elm və texnika xadimləri',
    'Əməkdar ixtiraçıları',
    'Əməkdar inşaatçıları',
    'Əməkdar geoloqları',
    'Əməkdar ali məktəb işçiləri',
    'Digər'
  ];

  static const _idSerials = ['AA', 'AZE', 'AR', 'AB', 'AC'];

  static const _bloodGroups = [
    'I (0) Rh+', 'I (0) Rh-',
    'II (A) Rh+', 'II (A) Rh-',
    'III (B) Rh+', 'III (B) Rh-',
    'IV (AB) Rh+', 'IV (AB) Rh-'
  ];

  static const _eduDegrees = [
    'Ali təhsil-Bakalavriat',
    'Magistratura',
    'Doktorantura',
    'Orta ixtisas',
    'Orta təhsil'
  ];

  static const _universities = [
    'Bakı Dövlət Universiteti',
    'Azərbaycan Dövlət Neft və Sənaye Universiteti',
    'Azərbaycan Texniki Universiteti',
    'Azərbaycan Dövlət Pedaqoji Universiteti',
    'Azərbaycan Dövlət İqtisad Universiteti (UNEC)',
    'Azərbaycan Tibb Universiteti',
    'Azərbaycan Dillər Universiteti',
    'Bakı Slavyan Universiteti',
    'Azərbaycan Memarlıq və İnşaat Universiteti',
    'Bakı Mühəndislik Universiteti',
    'Azərbaycan Dövlət Mədəniyyət və İncəsənət Universiteti',
    'ADA Universiteti',
    'Azərbaycan Turizm və Menecment Universiteti',
    'Milli Aviasiya Akademiyası',
    'Azərbaycan Dövlət Dəniz Akademiyası',
    'Dövlət İdarəçilik Akademiyası',
    'Dövlət Gömrük Komitəsinin Akademiyası',
    'DİN-in Polis Akademiyası',
    'FHN Akademiyası',
    'Sumqayıt Dövlət Universiteti',
    'Gəncə Dövlət Universiteti',
    'Qarabağ Universiteti',
    'Türkiyə-Azərbaycan Universiteti',
    'Xəzər Universiteti',
    'Qərbi Kaspi Universiteti',
    'Bakı Avrasiya Universiteti',
    'Odlar Yurdu Universiteti',
    'Azərbaycan Universiteti',
    'Bakı Biznes Universiteti',
    'Digər'
  ];

  static const _docTypes = ['Diplom', 'Sertifikat', 'Attestat', 'Arayış'];

  static const _banks = [
    'Kapital Bank',
    'ABB (Azərbaycan Beynəlxalq Bankı)',
    'PAŞA Bank',
    'Unibank',
    'Bank Respublika',
    'AccessBank',
    'Xalq Bank',
    'Rabitəbank',
    'Yelo Bank',
    'TuranBank',
    'Expressbank',
    'Digər'
  ];

  static const _contractTypes = ['Əmasda olan', 'Əmasda olmayan'];
  static const _companies = ['İdrak liseyi'];
  static const _filials = ['Bakı filialı', 'Sumqayıt filialı'];
  static const _teqvims = ['Əsas İstehsalat Təqvimi 2026-2027'];
  static const _paymentTypes = ['Aylıq vəzifə maaşı', 'Vaxtamuzd', 'İşəmuzd'];
  static const _workRegimes = [
    'Tam iş vaxtı (həftəlik 40 saat)',
    'Qısaldılmış iş vaxtı (həftəlik 36 saat)',
    'Natamam iş vaxtı'
  ];
  static const _workTimeTypes = ['Gündəlik', 'Növbəli', 'Sərbəst'];
  static const _workSchedules = ['5 günlük iş həftəsi', '6 günlük iş həftəsi', 'Növbəli qrafik'];
  static const _probationUnits = ['Ay', 'Həftə', 'Gün'];
  static const _workConditions = ['Normal', 'Zərərli', 'Ağır'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);

    final e = widget.employeeToEdit;
    _photoUrl = e?.photoUrl;

    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _finCtrl = TextEditingController(text: e?.finCode ?? '');

    // Tab 1
    _firstNameCtrl = TextEditingController(text: e?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: e?.lastName ?? '');
    _fatherNameCtrl = TextEditingController(text: e?.fatherName ?? '');
    _minifiedNameCtrl = TextEditingController(
      text: e != null && e.firstName.isNotEmpty ? '${e.lastName} ${e.firstName[0]}.' : '',
    );
    _gender = e?.gender ?? 'Kişi';
    _birthDate = e?.birthDate;
    _citizenship = 'Azərbaycan';
    _scientificDegree = 'Yoxdur';
    _honoraryTitle = 'Yoxdur';

    if (e != null && e.idCardSerial.isNotEmpty) {
      final parts = e.idCardSerial.split(' ');
      if (parts.isNotEmpty && _idSerials.contains(parts.first.toUpperCase())) {
        _idCardSerial = parts.first.toUpperCase();
        _idCardNumberCtrl = TextEditingController(text: parts.sublist(1).join(' '));
      } else {
        _idCardNumberCtrl = TextEditingController(text: e.idCardSerial);
      }
    } else {
      _idCardNumberCtrl = TextEditingController();
    }

    _idCardIssueDate = null;
    _idCardExpiryDate = null;
    _maritalStatus = e?.maritalStatus.isNotEmpty == true ? e!.maritalStatus : 'Subay';
    _driverLicense = 'Xeyr';
    _militaryDuty = 'Xeyr';
    _registrationAddressCtrl = TextEditingController(text: e?.address ?? '');
    _actualAddressCtrl = TextEditingController(text: e?.address ?? '');
    _bloodGroup = e?.bloodGroup.isNotEmpty == true ? e!.bloodGroup : 'I (0) Rh+';
    _personalEmailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _corporatePhoneCtrl = TextEditingController(text: e?.corporatePhone ?? '');

    // Tab 2 default education
    _educations.add({
      'degree': e?.educationLevel.isNotEmpty == true ? e!.educationLevel : 'Ali təhsil-Bakalavriat',
      'university': e?.university.isNotEmpty == true ? e!.university : 'Bakı Dövlət Universiteti',
      'specialty': e?.specialty ?? '',
      'start_year': '2015',
      'end_year': '2019',
      'doc_type': 'Diplom',
      'doc_number': '',
    });

    // Tab 3 default experience
    _experiences.add({
      'company': 'İdrak Liseyi',
      'position': e?.position ?? 'Müəllim',
      'work_type': 'Əsas',
      'reason': '',
      'start_date': '2020-09-01',
      'end_date': '',
    });

    // Tab 4 default social status
    _socialStatuses.add({
      'status': 'Məcburi köçkün deyil',
      'start_date': '',
      'end_date': '',
    });

    // Tab 5
    _bankName = e?.bankName.isNotEmpty == true ? e!.bankName : 'Kapital Bank';
    _bankAccountCtrl = TextEditingController(text: e?.bankAccount ?? '');
    _bankIbanCtrl = TextEditingController(text: e?.bankIban ?? '');
    _cardExpiryDate = null;

    // Tab 6
    _vehicleNumberCtrl = TextEditingController();

    // Tab 7 default document
    _documents.add({
      'title': 'Şəxsiyyət vəsiqəsi',
      'file_name': 'ID_card.pdf',
    });

    // Tab 8
    _loginEmailCtrl = TextEditingController(text: e?.email ?? '');
    _passwordCtrl = TextEditingController(text: e != null ? '' : '123456');
    if (e != null && e.roles.isNotEmpty) {
      _selectedRoles.clear();
      _selectedRoles.addAll(e.roles);
    }

    // Tab 9
    _contractNumberCtrl = TextEditingController(
      text: e?.contractNumber.isNotEmpty == true ? e!.contractNumber : 'IDR-CON-${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
    _contractDate = DateTime.now();
    _contractStartDate = e?.contractStartDate != null ? DateTime.tryParse(e!.contractStartDate!) : DateTime.now();
    _contractEndDate = e?.contractEndDate != null ? DateTime.tryParse(e!.contractEndDate!) : null;
    _contractType = 'Əmasda olan';
    _isIndefinite = e?.contractType == 'indefinite';
    _positionCtrl = TextEditingController(text: e?.position ?? 'Müəllim');
    _company = 'İdrak liseyi';
    _filial = e?.filial ?? 'Bakı filialı';
    _structureCtrl = TextEditingController(text: e?.department ?? 'Pedaqoji heyət');
    _teqvim = 'Əsas İstehsalat Təqvimi 2026-2027';
    _grossSalaryCtrl = TextEditingController(text: e != null && e.salary > 0 ? e.salary.toStringAsFixed(0) : '1500');
    _foodPriceCtrl = TextEditingController(text: '100');
    _finalGrossSalaryCtrl = TextEditingController(
      text: e != null && e.salary > 0 ? (e.salary + 100).toStringAsFixed(2) : '1600.00',
    );
    _grossSalaryCtrl.addListener(_calcFinalSalary);
    _foodPriceCtrl.addListener(_calcFinalSalary);

    _paymentType = 'Aylıq vəzifə maaşı';
    _salaryAdditionCtrl = TextEditingController(text: '0');
    _workRegime = 'Tam iş vaxtı (həftəlik 40 saat)';
    _workTimeType = 'Gündəlik';
    _workRegimeDetailsCtrl = TextEditingController();
    _workSchedule = '5 günlük iş həftəsi';
    _hasProbation = false;
    _probationUnit = 'Ay';
    _probationValueCtrl = TextEditingController(text: '0');
    _workCondition = 'Normal';
    _workConditionAdditionCtrl = TextEditingController(text: '0');
    _vacationDaysCtrl = TextEditingController(text: '30');
    _jobDescriptionCtrl = TextEditingController();

    // Tab 10 default previous earnings
    _previousEarnings.add({
      'year': '2026',
      'month': 'Yanvar',
      'workplace': 'İdrak Liseyi',
      'norm_days': '21',
      'amount': '1500',
    });
  }

  void _calcFinalSalary() {
    final g = double.tryParse(_grossSalaryCtrl.text.replaceAll(',', '.')) ?? 0;
    final f = double.tryParse(_foodPriceCtrl.text.replaceAll(',', '.')) ?? 0;
    _finalGrossSalaryCtrl.text = (g + f).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeCtrl.dispose();
    _finCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _minifiedNameCtrl.dispose();
    _idCardNumberCtrl.dispose();
    _registrationAddressCtrl.dispose();
    _actualAddressCtrl.dispose();
    _personalEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _corporatePhoneCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankIbanCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _loginEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _contractNumberCtrl.dispose();
    _positionCtrl.dispose();
    _structureCtrl.dispose();
    _grossSalaryCtrl.dispose();
    _foodPriceCtrl.dispose();
    _finalGrossSalaryCtrl.dispose();
    _salaryAdditionCtrl.dispose();
    _workRegimeDetailsCtrl.dispose();
    _probationValueCtrl.dispose();
    _workConditionAdditionCtrl.dispose();
    _vacationDaysCtrl.dispose();
    _jobDescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? initial, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zəhmət olmasa məcburi sahələri (FİN, Ad, Soyad, Ata adı, Ünvan və s.) doldurun.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final isEdit = widget.employeeToEdit != null;
    final gross = double.tryParse(_grossSalaryCtrl.text.replaceAll(',', '.')) ?? 1500.0;
    final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

    final payload = <String, dynamic>{
      'avatar': _photoUrl,
      'photo': _photoUrl,
      'photoUrl': _photoUrl,
      'finCode': _finCtrl.text.trim().toUpperCase(),
      'code': _codeCtrl.text.trim(),
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'fullName': fullName,
      'fatherName': _fatherNameCtrl.text.trim(),
      'gender': _gender,
      'birthDate': _birthDate != null ? DateFormat('Y-m-d').format(_birthDate!) : null,
      'citizenship': _citizenship,
      'scientificDegree': _scientificDegree,
      'honoraryTitle': _honoraryTitle,
      'idCardSerial': '$_idCardSerial ${_idCardNumberCtrl.text.trim()}'.trim(),
      'maritalStatus': _maritalStatus,
      'address': _actualAddressCtrl.text.trim().isNotEmpty ? _actualAddressCtrl.text.trim() : _registrationAddressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'corporatePhone': _corporatePhoneCtrl.text.trim(),
      'email': _loginEmailCtrl.text.trim().isNotEmpty ? _loginEmailCtrl.text.trim() : _personalEmailCtrl.text.trim(),
      'bloodGroup': _bloodGroup,
      'educationLevel': _educations.isNotEmpty ? _educations.first['degree'] : 'Ali təhsil-Bakalavriat',
      'university': _educations.isNotEmpty ? _educations.first['university'] : 'Bakı Dövlət Universiteti',
      'specialty': _educations.isNotEmpty ? _educations.first['specialty'] : '',
      'bankName': _bankName,
      'bankAccount': _bankAccountCtrl.text.trim(),
      'bankIban': _bankIbanCtrl.text.trim(),
      'department': _structureCtrl.text.trim().isNotEmpty ? _structureCtrl.text.trim() : 'Pedaqoji heyət',
      'position': _positionCtrl.text.trim().isNotEmpty ? _positionCtrl.text.trim() : 'Müəllim',
      'filial': _filial,
      'salary': gross,
      'password': _passwordCtrl.text.trim(),
      'roleName': _selectedRoles.isNotEmpty ? _selectedRoles.first : 'Müəllim',
      'contractStart': _contractStartDate != null ? DateFormat('Y-m-d').format(_contractStartDate!) : null,
      'contractEnd': !_isIndefinite && _contractEndDate != null ? DateFormat('Y-m-d').format(_contractEndDate!) : null,
      'contractNumber': _contractNumberCtrl.text.trim(),
    };

    try {
      bool ok = false;
      if (isEdit) {
        ok = await SchoolApiService.instance.updateEmployee(widget.employeeToEdit!.id, payload);
      } else {
        final res = await SchoolApiService.instance.createEmployee(payload);
        ok = res != null;
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Əməkdaş məlumatları uğurla yeniləndi.' : 'Yeni əməkdaş bazaya əlavə edildi.'),
              backgroundColor: AppColors.emerald,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Xəta baş verdi. Zəhmət olmasa daxil edilən məlumatları yoxlayın.'),
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

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isEdit = widget.employeeToEdit != null;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Text(
          isEdit ? '${widget.employeeToEdit!.fullName} — Redaktə' : 'Yeni Əməkdaş Əlavə Et',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: palette.surface1,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: palette.brandRoyal,
              unselectedLabelColor: palette.textSecondary,
              indicatorColor: palette.brandRoyal,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.person_outline, size: 16), text: '1. Şəxsi'),
                Tab(icon: Icon(Icons.school_outlined, size: 16), text: '2. Təhsil'),
                Tab(icon: Icon(Icons.work_outline, size: 16), text: '3. İş təcrübəsi'),
                Tab(icon: Icon(Icons.diversity_1_outlined, size: 16), text: '4. Sosial Status'),
                Tab(icon: Icon(Icons.credit_card_outlined, size: 16), text: '5. Bank kartları'),
                Tab(icon: Icon(Icons.directions_car_outlined, size: 16), text: '6. Nəqliyyat'),
                Tab(icon: Icon(Icons.folder_open_outlined, size: 16), text: '7. Sənədlər'),
                Tab(icon: Icon(Icons.lock_outline, size: 16), text: '8. Giriş'),
                Tab(icon: Icon(Icons.description_outlined, size: 16), text: '9. Müqavilə'),
                Tab(icon: Icon(Icons.history_toggle_off_outlined, size: 16), text: '10. Öncəki qazanclar'),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTab1Personal(palette),
            _buildTab2Education(palette),
            _buildTab3Experience(palette),
            _buildTab4SocialStatus(palette),
            _buildTab5BankCards(palette),
            _buildTab6Vehicles(palette),
            _buildTab7Documents(palette),
            _buildTab8Login(palette),
            _buildTab9Contract(palette),
            _buildTab10PreviousEarnings(palette),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface1,
            border: Border(top: BorderSide(color: palette.borderHairline)),
          ),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Əvvəlki addım',
                onPressed: () {
                  if (_tabController.index > 0) {
                    _tabController.animateTo(_tabController.index - 1);
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                style: IconButton.styleFrom(
                  side: BorderSide(color: palette.borderStrong),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              if (_tabController.index < 9) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index + 1);
                  },
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                  label: const Text('Növbəti', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: BorderSide(color: palette.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandRoyal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 17),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isSaving ? 'Saxlanılır...' : (isEdit ? 'Yadda Saxla' : 'Bazada Qeydiyyata Al'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  // -------------------------------------------------------------
  // TAB 1: Şəxsi Məlumatlar (group-tab-1)
  // -------------------------------------------------------------
  Widget _buildTab1Personal(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Şəxsi Məlumatlar', 'Əməkdaşın əsas kimlik və vətəndaşlıq qeydləri'),

        // Profil Şəkli
        Center(
          child: ProfilePhotoPicker(
            initialPhotoUrl: _photoUrl,
            size: 88,
            modelType: 'employee',
            modelId: widget.employeeToEdit?.id != null ? int.tryParse(widget.employeeToEdit!.id) : null,
            onPhotoUploaded: (url) {
              setState(() => _photoUrl = url);
            },
            onPhotoRemoved: () {
              setState(() => _photoUrl = null);
            },
          ),
        ),
        const SizedBox(height: 14),

        // Kod & FİN
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kod',
                  hintText: 'Avtomatik təklif olunur',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _finCtrl,
                maxLength: 7,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'FİN Kod *',
                  counterText: '',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().length != 7 ? '7 simvol olmalıdır' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Ad, Soyad
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adı *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ad mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Soyadı *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Ata adı *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ata adı mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _minifiedNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qısaldılmış ad',
                  hintText: 'məs: M. Əli',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Cinsiyyət & Doğum Tarixi
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyyəti *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Kişi', child: Text('Kişi', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Qadın', child: Text('Qadın', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) => setState(() => _gender = val ?? 'Kişi'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(_birthDate, (dt) => _birthDate = dt),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Doğum Tarixi *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
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

        // Vətəndaşlığı & Elmi dərəcə
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _citizenship,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Vətəndaşlığı',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: _citizenships.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _citizenship = val ?? 'Azərbaycan'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _scientificDegree,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Elmi Dərəcə',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: _scientificDegrees.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _scientificDegree = val ?? 'Yoxdur'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Fəxri ad
        DropdownButtonFormField<String>(
          initialValue: _honoraryTitles.contains(_honoraryTitle) ? _honoraryTitle : 'Yoxdur',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Fəxri ad',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          items: _honoraryTitles.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _honoraryTitle = val ?? 'Yoxdur'),
        ),
        const SizedBox(height: 14),

        // Ş.V. Seriya & Nömrəsi
        Row(
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                initialValue: _idCardSerial,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ş.V. Seriya *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _idSerials.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _idCardSerial = val ?? 'AA'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: TextFormField(
                controller: _idCardNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ş.V. Nömrəsi *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Ş.V. Verilmə və Etibarlılıq tarixi
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(_idCardIssueDate, (dt) => _idCardIssueDate = dt),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ş.V. Verilmə Tarixi',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  child: Text(
                    _idCardIssueDate != null ? DateFormat('dd.MM.yyyy').format(_idCardIssueDate!) : 'Seçin',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(_idCardExpiryDate, (dt) => _idCardExpiryDate = dt),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ş.V. Etibarlılıq tarixi',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  child: Text(
                    _idCardExpiryDate != null ? DateFormat('dd.MM.yyyy').format(_idCardExpiryDate!) : 'Seçin',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Ailə vəziyyəti & Qan qrupu
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _maritalStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ailə Vəziyyəti *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Evli', child: Text('Evli', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Subay', child: Text('Subay', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) => setState(() => _maritalStatus = val ?? 'Subay'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Qan Qrupu',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _bloodGroup = val ?? 'I (0) Rh+'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Sürücülük vəsiqəsi & Hərbi mükəlləfiyyət
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _driverLicense,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sürücülük Vəsiqəsi',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Bəli', child: Text('Bəli', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Xeyr', child: Text('Xeyr', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) => setState(() => _driverLicense = val ?? 'Xeyr'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _militaryDuty,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Hərbi Mükəlləfiyyət',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Bəli', child: Text('Bəli', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'Xeyr', child: Text('Xeyr', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) => setState(() => _militaryDuty = val ?? 'Xeyr'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Ünvanlar
        TextFormField(
          controller: _registrationAddressCtrl,
          decoration: const InputDecoration(labelText: 'Qeydiyyat Ünvanı', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _actualAddressCtrl,
          decoration: const InputDecoration(labelText: 'Faktiki Yaşadığı Ünvan *', border: OutlineInputBorder()),
          validator: (val) => val == null || val.trim().isEmpty ? 'Faktiki ünvan mütləqdir' : null,
        ),
        const SizedBox(height: 14),

        // Qan qrupu & Şəxsi e-poçt
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Qan Qrupu', border: OutlineInputBorder()),
                items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => setState(() => _bloodGroup = val ?? 'I (0) Rh+'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _personalEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Şəxsi e-poçt', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Əlaqə nömrələri
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Əlaqə nömrəsi *', hintText: '+994', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Əlaqə nömrəsi mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _corporatePhoneCtrl,
                decoration: const InputDecoration(labelText: 'Daxili / Korporativ nömrə', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Təhsil məlumatları (group-tab-2)
  // -------------------------------------------------------------
  Widget _buildTab2Education(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Təhsil Məlumatları', 'Ali və ya orta ixtisas təhsili qeydləri'),
        for (int i = 0; i < _educations.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Təhsil məlumatları #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    if (_educations.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => setState(() => _educations.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _educations[i]['degree'],
                  decoration: const InputDecoration(labelText: 'Dərəcə', border: OutlineInputBorder()),
                  items: _eduDegrees.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => _educations[i]['degree'] = val),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _universities.contains(_educations[i]['university']) ? _educations[i]['university'] : 'Digər',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Müəssisə adı', border: OutlineInputBorder()),
                  items: _universities.map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _educations[i]['university'] = val),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _educations[i]['specialty'],
                  decoration: const InputDecoration(labelText: 'İxtisas', border: OutlineInputBorder()),
                  onChanged: (val) => _educations[i]['specialty'] = val,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _educations[i]['start_year'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Başlanğıc İli', border: OutlineInputBorder()),
                        onChanged: (val) => _educations[i]['start_year'] = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _educations[i]['end_year'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bitiş İli', border: OutlineInputBorder()),
                        onChanged: (val) => _educations[i]['end_year'] = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _educations[i]['doc_type'],
                        decoration: const InputDecoration(labelText: 'Sənədin Tipi', border: OutlineInputBorder()),
                        items: _docTypes.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setState(() => _educations[i]['doc_type'] = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _educations[i]['doc_number'],
                        decoration: const InputDecoration(labelText: 'Nömrəsi', border: OutlineInputBorder()),
                        onChanged: (val) => _educations[i]['doc_number'] = val,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _educations.add({
                'degree': 'Ali təhsil-Bakalavriat',
                'university': 'Bakı Dövlət Universiteti',
                'specialty': '',
                'start_year': '2016',
                'end_year': '2020',
                'doc_type': 'Diplom',
                'doc_number': '',
              });
            });
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Təhsil Əlavə Et'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: İş təcrübəsi (group-tab-3)
  // -------------------------------------------------------------
  Widget _buildTab3Experience(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('İş Təcrübəsi', 'Əvvəlki iş yerləri və staj qeydləri'),
        for (int i = 0; i < _experiences.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('İş təcrübəsi #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    if (_experiences.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => setState(() => _experiences.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _experiences[i]['company'],
                  decoration: const InputDecoration(labelText: 'Şirkətin adı', border: OutlineInputBorder()),
                  onChanged: (val) => _experiences[i]['company'] = val,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _experiences[i]['position'],
                  decoration: const InputDecoration(labelText: 'Vəzifə', border: OutlineInputBorder()),
                  onChanged: (val) => _experiences[i]['position'] = val,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _experiences[i]['work_type'],
                  decoration: const InputDecoration(labelText: 'İş yeri (əsas/əlavə)', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Əsas', child: Text('Əsas')),
                    DropdownMenuItem(value: 'Əlavə', child: Text('Əlavə')),
                  ],
                  onChanged: (val) => setState(() => _experiences[i]['work_type'] = val),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _experiences[i]['reason'],
                  decoration: const InputDecoration(labelText: 'İşdən çıxma səbəbi', border: OutlineInputBorder()),
                  onChanged: (val) => _experiences[i]['reason'] = val,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _experiences[i]['start_date'],
                        decoration: const InputDecoration(labelText: 'Başlanğıc Tarixi', hintText: 'YYYY-MM-DD', border: OutlineInputBorder()),
                        onChanged: (val) => _experiences[i]['start_date'] = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _experiences[i]['end_date'],
                        decoration: const InputDecoration(labelText: 'Bitiş Tarixi', hintText: 'YYYY-MM-DD', border: OutlineInputBorder()),
                        onChanged: (val) => _experiences[i]['end_date'] = val,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _experiences.add({
                'company': '',
                'position': '',
                'work_type': 'Əsas',
                'reason': '',
                'start_date': '',
                'end_date': '',
              });
            });
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni İş Təcrübəsi Əlavə Et'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: Sosial Status (group-tab-4)
  // -------------------------------------------------------------
  Widget _buildTab4SocialStatus(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Sosial Status', 'Güzəştlər, kateqoriyalar və sosial imtiyazlar'),
        for (int i = 0; i < _socialStatuses.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sosial Status #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    if (_socialStatuses.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => setState(() => _socialStatuses.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _socialStatuses[i]['status'],
                  decoration: const InputDecoration(labelText: 'Sosial Status kateqoriyası', border: OutlineInputBorder()),
                  onChanged: (val) => _socialStatuses[i]['status'] = val,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _socialStatuses[i]['start_date'],
                        decoration: const InputDecoration(labelText: 'Tarix', hintText: 'YYYY-MM-DD', border: OutlineInputBorder()),
                        onChanged: (val) => _socialStatuses[i]['start_date'] = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _socialStatuses[i]['end_date'],
                        decoration: const InputDecoration(labelText: 'Bitiş Tarixi', hintText: 'YYYY-MM-DD', border: OutlineInputBorder()),
                        onChanged: (val) => _socialStatuses[i]['end_date'] = val,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _socialStatuses.add({'status': '', 'start_date': '', 'end_date': ''});
            });
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Sosial Status Əlavə Et'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 5: Bank kartları (group-tab-5)
  // -------------------------------------------------------------
  Widget _buildTab5BankCards(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Bank Kartları & Rekvizitlər', 'Əməkhaqqının köçürülməsi üçün bank məlumatları'),
        DropdownButtonFormField<String>(
          initialValue: _banks.contains(_bankName) ? _bankName : 'Digər',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Bank Adı', border: OutlineInputBorder()),
          items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _bankName = val ?? 'Kapital Bank'),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _bankAccountCtrl,
          decoration: const InputDecoration(labelText: 'Hesab Nömrəsi', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _bankIbanCtrl,
          decoration: const InputDecoration(labelText: 'Bank IBAN', hintText: 'AZ...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => _pickDate(_cardExpiryDate, (dt) => _cardExpiryDate = dt),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Kartın Bitmə tarixi', border: OutlineInputBorder()),
            child: Text(_cardExpiryDate != null ? DateFormat('MM/yy').format(_cardExpiryDate!) : 'Tarix seçin (Opsional)'),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 6: Nəqliyyat vasitələrim (group-tab-7)
  // -------------------------------------------------------------
  Widget _buildTab6Vehicles(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Nəqliyyat Vasitələri', 'Lisey ərazisinə giriş və dayanacaq icazəsi üçün'),
        TextFormField(
          controller: _vehicleNumberCtrl,
          decoration: const InputDecoration(
            labelText: 'Nəqliyyat nömrəsi',
            hintText: 'məs: 99-AA-999',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 7: Sənədlərin Siyahısı (group-tab-6)
  // -------------------------------------------------------------
  Widget _buildTab7Documents(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Sənədlərin Siyahısı', 'Şəxsiyyət, diplom, tibbi arayış və digər fayllar'),
        for (int i = 0; i < _documents.length; i++) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_present_rounded, color: Color(0xFF2563EB)),
            title: Text(_documents[i]['title'] ?? 'Sənəd', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(_documents[i]['file_name'] ?? 'Fayl seçilməyib', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              onPressed: () => setState(() => _documents.removeAt(i)),
            ),
          ),
          const Divider(),
        ],
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _documents.add({
                'title': 'Diplom surəti',
                'file_name': 'diploma.pdf',
              });
            });
          },
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Yeni Sənəd Əlavə Et'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 8: Giriş Məlumatları (login-tab)
  // -------------------------------------------------------------
  Widget _buildTab8Login(AppPalette palette) {
    final appState = context.watch<AppState>();
    final rolesList = appState.roles.isNotEmpty
        ? appState.roles.map((r) => r.name).toList()
        : ['Müəllim', 'HR', 'İnzibatçı', 'Direktor Müavini', 'Direktor'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Giriş Məlumatları & Rollar', 'Mobil tətbiq və GoPanel veb sisteminə giriş hüquqları'),
        TextFormField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Elektron poçt *', border: OutlineInputBorder()),
          validator: (val) => val == null || val.trim().isEmpty ? 'E-poçt mütləqdir' : null,
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
        const SizedBox(height: 18),
        const Text('Sistem Rolları və Vəzifələr', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rolesList.map((r) {
            final isSelected = _selectedRoles.contains(r);
            return FilterChip(
              label: Text(r),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedRoles.add(r);
                  } else {
                    _selectedRoles.remove(r);
                  }
                });
              },
              selectedColor: palette.brandRoyal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : palette.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 9: Müqavilə məlumatları (contract-tab)
  // -------------------------------------------------------------
  Widget _buildTab9Contract(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Müqavilə Məlumatları', 'Əmək müqaviləsi şərtləri, iş rejimi və qross əməkhaqqı'),

        // Nömrə və Tarix
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _contractNumberCtrl,
                decoration: const InputDecoration(labelText: 'Müqavilə nömrəsi *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Müqavilə nömrəsi mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(_contractDate, (dt) => _contractDate = dt),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Müqavilə tarixi *', border: OutlineInputBorder()),
                  child: Text(_contractDate != null ? DateFormat('dd.MM.yyyy').format(_contractDate!) : 'Tarix seçin'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // İşə başlama və bitmə tarixi
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(_contractStartDate, (dt) => _contractStartDate = dt),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'İşə başlama tarixi *', border: OutlineInputBorder()),
                  child: Text(_contractStartDate != null ? DateFormat('dd.MM.yyyy').format(_contractStartDate!) : 'Tarix seçin'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _isIndefinite ? null : () => _pickDate(_contractEndDate, (dt) => _contractEndDate = dt),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Müqavilənin bitmə tarixi',
                    border: const OutlineInputBorder(),
                    enabled: !_isIndefinite,
                  ),
                  child: Text(_isIndefinite ? 'Müddətsiz' : (_contractEndDate != null ? DateFormat('dd.MM.yyyy').format(_contractEndDate!) : 'Seçin')),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Müqavilə tipi & Müddətsiz müqavilə checkbox
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                initialValue: _contractType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Müqavilə tipi *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _contractTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _contractType = val ?? 'Əmasda olan'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: InkWell(
                onTap: () => setState(() => _isIndefinite = !_isIndefinite),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isIndefinite,
                        visualDensity: VisualDensity.compact,
                        onChanged: (val) => setState(() => _isIndefinite = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Müddətsiz müqavilə',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Vəzifə & Şirkət
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _positionCtrl,
                decoration: const InputDecoration(labelText: 'Vəzifə *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vəzifə mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _company,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Şirkət *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _companies.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _company = val ?? 'İdrak liseyi'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filial & Struktur
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _filial,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filial *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _filials.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _filial = val ?? 'Bakı filialı'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _structureCtrl,
                decoration: const InputDecoration(labelText: 'Struktur *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Struktur mütləqdir' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Təqvim
        DropdownButtonFormField<String>(
          initialValue: _teqvim,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Təqvim *', border: OutlineInputBorder()),
          items: _teqvims.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _teqvim = val ?? 'Əsas İstehsalat Təqvimi 2026-2027'),
        ),
        const SizedBox(height: 14),

        // Qross maaş, Yemək pulu, Yekun qross maaş
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _grossSalaryCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Qross maaş *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Maaş mütləqdir' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _foodPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yemək pulu *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _finalGrossSalaryCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Yekun qross *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Əməyin ödənilməsi növü & Maaşa əlavə
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _paymentType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ödəniş növü',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _paymentTypes.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _paymentType = val ?? 'Aylıq vəzifə maaşı'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _salaryAdditionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Əlavə (AZN)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // İş rejimi & İş vaxtının növü
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _workRegime,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'İş rejimi *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _workRegimes.map((w) => DropdownMenuItem(value: w, child: Text(w, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _workRegime = val ?? 'Tam iş vaxtı (həftəlik 40 saat)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _workTimeType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'İş vaxtının növü *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _workTimeTypes.map((w) => DropdownMenuItem(value: w, child: Text(w, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _workTimeType = val ?? 'Gündəlik'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // İş qrafiki & Əmək şəraiti
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _workSchedule,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'İş qrafiki *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _workSchedules.map((w) => DropdownMenuItem(value: w, child: Text(w, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _workSchedule = val ?? '5 günlük iş həftəsi'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _workCondition,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Əmək şəraiti *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                items: _workConditions.map((w) => DropdownMenuItem(value: w, child: Text(w, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _workCondition = val ?? 'Normal'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Sınaq müddəti
        Row(
          children: [
            Checkbox(
              value: _hasProbation,
              onChanged: (val) => setState(() => _hasProbation = val ?? false),
            ),
            const Text('Sınaq müddəti var', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (_hasProbation) ...[
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _probationUnit,
                  decoration: const InputDecoration(labelText: 'Vahid', border: OutlineInputBorder()),
                  items: _probationUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setState(() => _probationUnit = val ?? 'Ay'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _probationValueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dəyər', border: OutlineInputBorder()),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // İş saatları və məzuniyyət
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _workStartTime,
                decoration: const InputDecoration(labelText: 'İş başlama', hintText: '08:30', border: OutlineInputBorder()),
                onChanged: (val) => _workStartTime = val,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: _workEndTime,
                decoration: const InputDecoration(labelText: 'İş bitmə', hintText: '17:30', border: OutlineInputBorder()),
                onChanged: (val) => _workEndTime = val,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _vacationDaysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Əsas məzuniyyət (gün) *', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Fasilə vaxtı
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _breakStartTime,
                decoration: const InputDecoration(labelText: 'Fasilə başlama', hintText: '13:00', border: OutlineInputBorder()),
                onChanged: (val) => _breakStartTime = val,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: _breakEndTime,
                decoration: const InputDecoration(labelText: 'Fasilə bitmə', hintText: '14:00', border: OutlineInputBorder()),
                onChanged: (val) => _breakEndTime = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Əmək funksiyası
        TextFormField(
          controller: _jobDescriptionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Əmək funksiyası', hintText: 'Vəzifə və əmək funksiyası təsviri...', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 10: Öncəki qazancları (group-tab-previous_earnings)
  // -------------------------------------------------------------
  Widget _buildTab10PreviousEarnings(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabHeader('Öncəki Qazanclar', 'Cari ildə əvvəlki iş yerində qazanılmış gəlirlər'),
        for (int i = 0; i < _previousEarnings.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Öncəki qazanc #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    if (_previousEarnings.length > 1)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => setState(() => _previousEarnings.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _previousEarnings[i]['year'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'İl', border: OutlineInputBorder()),
                        onChanged: (val) => _previousEarnings[i]['year'] = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _previousEarnings[i]['month'],
                        decoration: const InputDecoration(labelText: 'Ay', hintText: 'məs: Yanvar', border: OutlineInputBorder()),
                        onChanged: (val) => _previousEarnings[i]['month'] = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _previousEarnings[i]['workplace'],
                  decoration: const InputDecoration(labelText: 'İş yeri', border: OutlineInputBorder()),
                  onChanged: (val) => _previousEarnings[i]['workplace'] = val,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _previousEarnings[i]['norm_days'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'İş günləri (norma)', border: OutlineInputBorder()),
                        onChanged: (val) => _previousEarnings[i]['norm_days'] = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _previousEarnings[i]['amount'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qazanc (AZN)', border: OutlineInputBorder()),
                        onChanged: (val) => _previousEarnings[i]['amount'] = val,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _previousEarnings.add({
                'year': '2026',
                'month': 'Fevral',
                'workplace': '',
                'norm_days': '20',
                'amount': '0',
              });
            });
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Qazanc Qeydi Əlavə Et'),
        ),
      ],
    );
  }

  Widget _tabHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}
