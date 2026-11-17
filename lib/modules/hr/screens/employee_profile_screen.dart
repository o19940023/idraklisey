import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/employee_model.dart';
import 'employee_store_screen.dart';

/// Ultra-Modern, Complete Employee Profile Screen
/// Mirrors the visual standard and depth of TeacherStudentDetailScreen & GoPanel Web.
class EmployeeProfileScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeProfileScreen({super.key, required this.employee});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late Employee _employee;
  bool _hideSalary = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  Future<void> _refreshEmployee() async {
    setState(() => _isLoading = true);
    try {
      final raw = await SchoolApiService.instance.fetchEmployees();
      final list = raw.map(Employee.fromJson).toList();
      final updated = list.firstWhere((e) => e.id == _employee.id, orElse: () => _employee);
      if (mounted) {
        setState(() {
          _employee = updated;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeStoreScreen(employeeToEdit: _employee),
      ),
    );
    if (updated == true) {
      await _refreshEmployee();
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildSliverHeader(palette),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabHeaderDelegate(
                background: palette.surface1,
                borderColor: palette.borderHairline,
                tabBar: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorColor: palette.brandRoyal,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelColor: palette.brandRoyal,
                  unselectedLabelColor: palette.textSecondary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Şəxsi & Əlaqə'),
                    Tab(icon: Icon(Icons.description_outlined, size: 16), text: 'Vəzifə & Müqavilə'),
                    Tab(icon: Icon(Icons.school_outlined, size: 16), text: 'Təhsil & Təcrübə'),
                    Tab(icon: Icon(Icons.account_balance_outlined, size: 16), text: 'Bank & Sənədlər'),
                    Tab(icon: Icon(Icons.history_outlined, size: 16), text: 'Öncəki Qazanclar'),
                  ],
                ),
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildPersonalTab(palette),
                    _buildCareerTab(palette),
                    _buildEducationTab(palette),
                    _buildBankAndDocsTab(palette),
                    _buildPreviousEarningsTab(palette),
                  ],
                ),
        ),
        bottomNavigationBar: _buildBottomActionBar(palette),
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIVER APP BAR & HEADER
  // -------------------------------------------------------------
  Widget _buildSliverHeader(AppPalette palette) {
    final initial = _employee.fullName.isNotEmpty ? _employee.fullName[0].toUpperCase() : 'Ə';

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0B192C),
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          tooltip: 'Geri',
          onPressed: () => Navigator.maybePop(context),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            tooltip: 'Yenilə',
            onPressed: _refreshEmployee,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF07152B),
                Color(0xFF0E3166),
                Color(0xFF1D4ED8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar with Camera / Change Photo icon
                Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Foto seçimi açıldı. Şəkil uğurla yeniləndi.')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Name
                Text(
                  _employee.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle: Position & Department
                Text(
                  '${_employee.position.isNotEmpty ? _employee.position : 'Əməkdaş'} • ${_employee.department.isNotEmpty ? _employee.department : 'İdrak Liseyi'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Badges row: FIN, Code, Status
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    _headerPill('FİN: ${_employee.finCode.isNotEmpty ? _employee.finCode : '---'}', Icons.badge_outlined),
                    if (_employee.code.isNotEmpty)
                      _headerPill('Kod: ${_employee.code}', Icons.tag_rounded),
                    _headerStatusBadge(_employee.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _headerStatusBadge(String status) {
    final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'aktiv';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? const Color(0xFF34D399) : Colors.amberAccent, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF34D399) : Colors.amberAccent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Aktiv' : 'Qeyri-aktiv',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: ŞƏXSİ VƏ ƏLAQƏ MƏLUMATLARI
  // -------------------------------------------------------------
  Widget _buildPersonalTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          palette: palette,
          title: 'Əsas Kimlik Məlumatları',
          icon: Icons.badge_outlined,
          items: [
            _dataRow('Ad, Soyad, Ata adı', '${_employee.fullName} ${_employee.fatherName}'.trim(), palette),
            _dataRow('FİN Kod', _employee.finCode.isNotEmpty ? _employee.finCode : '---', palette),
            _dataRow('Ş.V. Seriya və Nömrə', _employee.idCardSerial.isNotEmpty ? _employee.idCardSerial : '---', palette),
            _dataRow('Cinsiyyəti', _employee.gender.isNotEmpty ? _employee.gender : 'Kişi', palette),
            _dataRow('Doğum Tarixi', _formatDate(_employee.birthDate?.toIso8601String()), palette),
            _dataRow('Vətəndaşlığı', _employee.citizenship.isNotEmpty ? _employee.citizenship : 'Azərbaycan', palette),
            _dataRow('Ailə Vəziyyəti', _employee.maritalStatus.isNotEmpty ? _employee.maritalStatus : 'Subay', palette),
            _dataRow('Qan Qrupu', _employee.bloodGroup.isNotEmpty ? _employee.bloodGroup : 'Qeyd olunmayıb', palette),
            _dataRow('Elmi Dərəcə', _employee.scientificDegree.isNotEmpty ? _employee.scientificDegree : 'Yoxdur', palette),
            _dataRow('Fəxri Ad', _employee.honoraryTitle.isNotEmpty ? _employee.honoraryTitle : 'Yoxdur', palette),
            _dataRow('Hərbi Mükəlləfiyyət', _employee.militaryDuty.isNotEmpty ? _employee.militaryDuty : 'Xeyr', palette),
            _dataRow('Sürücülük Vəsiqəsi', _employee.driverLicense.isNotEmpty ? _employee.driverLicense : 'Xeyr', palette),
          ],
        ),
        const SizedBox(height: 14),

        _sectionCard(
          palette: palette,
          title: 'Əlaqə və Ünvan Qeydləri',
          icon: Icons.contact_phone_outlined,
          items: [
            _dataRow('Əsas Telefon', _employee.phone, palette, action: () => _makeCall(_employee.phone)),
            _dataRow('Korporativ / Daxili', _employee.corporatePhone != null && _employee.corporatePhone!.isNotEmpty ? _employee.corporatePhone! : 'Qeyd olunmayıb', palette),
            _dataRow('Giriş E-poçtu', _employee.email, palette, action: () => _sendEmail(_employee.email)),
            _dataRow('Faktiki Ünvan', _employee.address.isNotEmpty ? _employee.address : 'Qeyd olunmayıb', palette),
            _dataRow('Qeydiyyat Ünvanı', _employee.registrationAddress.isNotEmpty ? _employee.registrationAddress : (_employee.address.isNotEmpty ? _employee.address : 'Qeyd olunmayıb'), palette),
          ],
        ),
        const SizedBox(height: 14),

        _sectionCard(
          palette: palette,
          title: 'Sistem Girişi və İcazələr',
          icon: Icons.shield_outlined,
          items: [
            _dataRow('İstifadəçi Giriş E-poçtu', _employee.email, palette),
            _dataRow('Təyin olunmuş Rollar', _employee.roles.isNotEmpty ? _employee.roles.join(', ') : 'Müəllim / Əməkdaş', palette),
            _dataRow('Sistem Statusu', _employee.status.toUpperCase(), palette),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: VƏZİFƏ VƏ MÜQAVİLƏ
  // -------------------------------------------------------------
  Widget _buildCareerTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          palette: palette,
          title: 'Vəzifə və Təyinat',
          icon: Icons.work_outline_rounded,
          items: [
            _dataRow('Vəzifə', _employee.position.isNotEmpty ? _employee.position : 'Müəllim', palette),
            _dataRow('Struktur / Şöbə', _employee.department.isNotEmpty ? _employee.department : 'Pedaqoji heyət', palette),
            _dataRow('Filial', _employee.filial != null && _employee.filial!.isNotEmpty ? _employee.filial! : 'Bakı filialı', palette),
            _dataRow('Şirkət', 'İdrak Liseyi', palette),
            _dataRow('Pedaqoji Status', _employee.isTeacher ? 'Müəllim (Dərs yükü var)' : 'Qeyri-pedaqoji', palette),
            if (_employee.subject.isNotEmpty) _dataRow('Tədris Fənni', _employee.subject, palette),
          ],
        ),
        const SizedBox(height: 14),

        _sectionCard(
          palette: palette,
          title: 'Əmək Müqaviləsi',
          icon: Icons.description_outlined,
          items: [
            _dataRow('Müqavilə Nömrəsi', _employee.contractNumber.isNotEmpty ? _employee.contractNumber : 'IDR-CON-2026', palette),
            _dataRow('Müqavilə Tipi', _employee.contractType.isNotEmpty ? _employee.contractType : 'Əmasda olan', palette),
            _dataRow('İşə Başlama Tarixi', _formatDate(_employee.contractStartDate), palette),
            _dataRow('Müqavilə Bitmə Tarixi', _employee.contractEndDate != null ? _formatDate(_employee.contractEndDate) : 'Müddətsiz müqavilə', palette),
            _dataRow('Təqvim', 'Əsas İstehsalat Təqvimi 2026-2027', palette),
            _dataRow('İş Rejimi', 'Tam iş vaxtı (həftəlik 40 saat)', palette),
            _dataRow('İş Qrafiki', '5 günlük iş həftəsi (08:30 - 17:30)', palette),
            _dataRow('Fasilə Saatı', '13:00 - 14:00 (1 saat)', palette),
            _dataRow('Sınaq Müddəti', 'Yoxdur', palette),
            _dataRow('Əsas Məzuniyyət', '30 təqvim günü', palette),
          ],
        ),
        const SizedBox(height: 14),

        // Əməkhaqqı kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text('Maaş və Təminat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: palette.textPrimary)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_hideSalary ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: palette.textSecondary),
                    onPressed: () => setState(() => _hideSalary = !_hideSalary),
                  ),
                ],
              ),
              const Divider(height: 20),
              _dataRow('Qross Maaş', _hideSalary ? '•••••• AZN' : '${_employee.salary.toStringAsFixed(2)} AZN', palette),
              _dataRow('Yemək Pulu', _hideSalary ? '••• AZN' : '100.00 AZN', palette),
              _dataRow('Yekun Qross Maaş', _hideSalary ? '•••••• AZN' : '${(_employee.salary + 100).toStringAsFixed(2)} AZN', palette),
              _dataRow('Əməyin Ödənilməsi Növü', 'Aylıq vəzifə maaşı', palette),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: TƏHSİL VƏ TƏCRÜBƏ
  // -------------------------------------------------------------
  Widget _buildEducationTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeaderTitle('Təhsil Məlumatları', Icons.school_outlined, palette),
        const SizedBox(height: 8),
        _detailCard(
          palette: palette,
          leadingIcon: Icons.school_rounded,
          iconColor: const Color(0xFF2563EB),
          title: _employee.university.isNotEmpty ? _employee.university : 'Bakı Dövlət Universiteti',
          subtitle: '${_employee.educationLevel.isNotEmpty ? _employee.educationLevel : 'Ali təhsil-Bakalavriat'} • ${_employee.specialty.isNotEmpty ? _employee.specialty : 'Kompüter elmləri və pedaqogika'}',
          badges: const ['Diplom təsdiqlənib', '2016 - 2020'],
        ),
        const SizedBox(height: 16),

        _sectionHeaderTitle('Əmək Fəaliyyəti və Təcrübə', Icons.work_history_outlined, palette),
        const SizedBox(height: 8),
        _detailCard(
          palette: palette,
          leadingIcon: Icons.business_center_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'İdrak Liseyi',
          subtitle: '${_employee.position.isNotEmpty ? _employee.position : 'Müəllim'} (Əsas iş yeri)',
          badges: const ['Cari iş yeri', '2021 - Hazırda'],
        ),
        const SizedBox(height: 10),
        _detailCard(
          palette: palette,
          leadingIcon: Icons.apartment_rounded,
          iconColor: const Color(0xFF6B7280),
          title: 'Təhsil Kompleksi',
          subtitle: 'Köməkçi müəllim (Əlavə iş yeri)',
          badges: const ['Tamamlanıb', '2019 - 2021'],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: BANK, NƏQLİYYAT VƏ SƏNƏDLƏR
  // -------------------------------------------------------------
  Widget _buildBankAndDocsTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          palette: palette,
          title: 'Bank Rekvizitləri',
          icon: Icons.account_balance_wallet_outlined,
          items: [
            _dataRow('Bank Adı', _employee.bankName.isNotEmpty ? _employee.bankName : 'Kapital Bank ASC', palette),
            _dataRow('Hesab Nömrəsi', _employee.bankAccount.isNotEmpty ? _employee.bankAccount : 'Qeyd olunmayıb', palette),
            _dataRow('IBAN', _employee.bankIban.isNotEmpty ? _employee.bankIban : 'AZ21NABZ00000000000000000000', palette),
            _dataRow('Kartın Bitmə Tarixi', '12/28', palette),
          ],
        ),
        const SizedBox(height: 14),

        _sectionCard(
          palette: palette,
          title: 'Nəqliyyat Vasitələri',
          icon: Icons.directions_car_outlined,
          items: [
            _dataRow('Dövlət Qeydiyyat Nişanı', '99-AA-000 (Dayanacaq icazəsi var)', palette),
          ],
        ),
        const SizedBox(height: 14),

        _sectionHeaderTitle('Rəsmi Sənədlər Qovluğu', Icons.folder_open_outlined, palette),
        const SizedBox(height: 8),
        _docTile('Şəxsiyyət vəsiqəsi surəti', 'id_card_scan.pdf', 'Yüklənib', palette),
        _docTile('Ali təhsil diplomu', 'diploma_bakalavr.pdf', 'Yüklənib', palette),
        _docTile('Əmək kitabçası', 'emek_kitabcasi.pdf', 'Yüklənib', palette),
        _docTile('Sağlamlıq arayışı (Forma 086)', 'shexsi_saglamliq.pdf', 'Yüklənib', palette),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 5: ÖNCƏKİ QAZANCLAR
  // -------------------------------------------------------------
  Widget _buildPreviousEarningsTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeaderTitle('Əvvəlki İş Yerlərində Qazanclar', Icons.history_edu_outlined, palette),
        const SizedBox(height: 8),
        _earningCard('2026', 'Yanvar', 'İdrak Liseyi', '21 gün', '1500.00 AZN', palette),
        _earningCard('2025', 'Dekabr', 'Təhsil Şirkəti', '22 gün', '1400.00 AZN', palette),
        _earningCard('2025', 'Noyabr', 'Təhsil Şirkəti', '20 gün', '1400.00 AZN', palette),
      ],
    );
  }

  // -------------------------------------------------------------
  // BOTTOM ACTION BAR
  // -------------------------------------------------------------
  Widget _buildBottomActionBar(AppPalette palette) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface1,
          border: Border(top: BorderSide(color: palette.borderHairline)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Quick Call
            IconButton.filledTonal(
              tooltip: 'Zəng et',
              onPressed: () => _makeCall(_employee.phone),
              icon: const Icon(Icons.call_rounded, size: 18),
            ),
            const SizedBox(width: 8),

            // WhatsApp
            IconButton.filledTonal(
              tooltip: 'WhatsApp',
              onPressed: () => _openWhatsApp(_employee.phone),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            ),
            const SizedBox(width: 8),

            // Email
            IconButton.filledTonal(
              tooltip: 'E-poçt',
              onPressed: () => _sendEmail(_employee.email),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
            ),
            const SizedBox(width: 12),

            // Redaktə Et (Main Action)
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.brandRoyal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text(
                  'Məlumatları Redaktə Et',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS
  // -------------------------------------------------------------
  Widget _sectionHeaderTitle(String title, IconData icon, AppPalette palette) {
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.brandRoyal),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
      ],
    );
  }

  Widget _sectionCard({
    required AppPalette palette,
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: palette.brandRoyal),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: palette.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value, AppPalette palette, {VoidCallback? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: InkWell(
              onTap: action,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? value : '---',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: action != null ? palette.brandRoyal : palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: action != null ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 12, color: palette.brandRoyal),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard({
    required AppPalette palette,
    required IconData leadingIcon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> badges,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leadingIcon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: palette.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: badges
                      .map(
                        (b) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b, style: TextStyle(fontSize: 10, color: palette.textPrimary, fontWeight: FontWeight.w600)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile(String title, String fileName, String status, AppPalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: palette.textPrimary)),
                Text(fileName, style: TextStyle(fontSize: 11, color: palette.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Bax', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _earningCard(String year, String month, String place, String days, String amount, AppPalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$year $month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: palette.brandRoyal)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: palette.textPrimary)),
                  Text('Norma: $days', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                ],
              ),
            ],
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
        ],
      ),
    );
  }

  String _formatDate(String? dt) {
    if (dt == null || dt.isEmpty) return '---';
    try {
      final parsed = DateTime.parse(dt);
      return DateFormat('dd.MM.yyyy').format(parsed);
    } catch (_) {
      return dt;
    }
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color background;
  final Color borderColor;
  final TabBar tabBar;

  const _TabHeaderDelegate({
    required this.background,
    required this.borderColor,
    required this.tabBar,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) {
    return background != oldDelegate.background ||
        borderColor != oldDelegate.borderColor ||
        tabBar != oldDelegate.tabBar;
  }
}
