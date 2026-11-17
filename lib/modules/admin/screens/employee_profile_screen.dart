import '../../../core/services/school_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/role_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';
import '../../hr/screens/contracts_screen.dart';
import '../../hr/screens/salary_calculator_screen.dart';
import '../widgets/edit_employee_sheet.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final AppUser user;

  const EmployeeProfileScreen({super.key, required this.user});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _showPassword = false;
  late final TabController _tabController;
  int _tabIndex = 0;

  static const _empty = 'Daxil edilməyib';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging &&
        _tabIndex != _tabController.index) {
      setState(() => _tabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String _value(String? value) {
    final text = value?.trim() ?? '';
    return (text.isEmpty || text == '-') ? _empty : text;
  }

  String _formatSalary(double? salary) {
    if (salary == null || salary <= 0) return _empty;
    final text = salary == salary.roundToDouble()
        ? salary.toStringAsFixed(0)
        : salary.toStringAsFixed(2);
    return '$text AZN';
  }

  String _experience(DateTime? hireDate) {
    if (hireDate == null) return '-';
    final now = DateTime.now();
    var months = (now.year - hireDate.year) * 12 + now.month - hireDate.month;
    if (now.day < hireDate.day) months--;
    if (months < 0) months = 0;
    final years = months ~/ 12;
    if (years > 0) return '$years il';
    return '$months ay';
  }

  String _permissionName(String id) {
    for (final permission in DefaultPermissions.all) {
      if (permission.id == id) return permission.name;
    }
    return id;
  }


  void _openEmployeePermissionsSheet(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeePermissionsSheet(user: user),
    );
  }

  void _openEmployeeContract(BuildContext context, AppUser user) {
    Navigator.push(
      context,
      appRoute(
        builder: (_) => ContractsScreen(
          employeeId: user.id,
          employeeCode: user.idrakCode,
          employeeName: user.fullName,
          autoOpenFirstContract: true,
        ),
      ),
    );
  }

  void _openEmployeeSalaryCalculator(BuildContext context, AppUser user) {
    Navigator.push(
      context,
      appRoute(
        builder: (_) => SalaryCalculatorScreen(
          initialGrossSalary: user.salary,
          employeeName: user.fullName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final palette = AppPalette.of(context);
    final user = appState.users.firstWhere(
      (item) =>
          item.id == widget.user.id ||
          (item.idrakCode.isNotEmpty &&
              item.idrakCode == widget.user.idrakCode),
      orElse: () => widget.user,
    );
    final isTeacher = user.role == UserRole.teacher;
    final assignedRole = appState.getRoleById(user.assignedRoleId);
    final roleLabel = user.roleNames.isNotEmpty
        ? user.roleNames.join(' · ')
        : (isTeacher
            ? 'Müəllim'
            : (assignedRole?.name ?? user.department ?? 'İnzibatçı / İşçi'));
    final roleColor =
        isTeacher ? const Color(0xFF0D9488) : palette.brandRoyal;
    final canEdit = appState.hasPermission('edit_users') ||
        appState.hasPermission('view_employees');
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: Column(
        children: [
          _buildHeader(
            context,
            palette,
            user,
            roleLabel,
            roleColor,
            isTeacher,
          ),
          Material(
            color: palette.surface1,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: palette.borderHairline)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorColor: roleColor,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2.5,
                labelColor: roleColor,
                unselectedLabelColor: palette.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Profil & Kimlik'),
                  Tab(text: 'İş & Müqavilə'),
                  Tab(text: 'Hesab'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: _buildProfileTab(context, palette, user, dateFormat),
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: _buildWorkTab(
                    context,
                    palette,
                    appState,
                    user,
                    assignedRole,
                    isTeacher,
                    roleColor,
                    dateFormat,
                    canEdit,
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: _buildAccountTab(
                    context,
                    palette,
                    user,
                    dateFormat,
                    canEdit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context, palette, appState, user, canEdit),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    AppUser user,
    String roleLabel,
    Color roleColor,
    bool isTeacher,
  ) {
    final subtitle = [
      if ((user.position ?? '').trim().isNotEmpty) user.position!.trim(),
      if ((user.department ?? '').trim().isNotEmpty) user.department!.trim(),
      if ((user.subject ?? '').trim().isNotEmpty) user.subject!.trim(),
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTeacher
              ? const [
                  Color(0xFF042F2E),
                  Color(0xFF0F766E),
                  Color(0xFF14B8A6),
                ]
              : [
                  const Color(0xFF11152C),
                  const Color(0xFF28326F),
                  roleColor,
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -48,
              top: 34,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              left: -34,
              bottom: -54,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _backButton(context),
                      Row(
                        children: [
                          _headerActionPill(
                            icon: Icons.description_rounded,
                            label: 'Müqavilə',
                            onTap: () => _openEmployeeContract(context, user),
                          ),
                          const SizedBox(width: 8),
                          _headerActionPill(
                            icon: Icons.calculate_rounded,
                            label: 'Maaş & Vergi',
                            onTap: () =>
                                _openEmployeeSalaryCalculator(context, user),
                          ),
                          const SizedBox(width: 8),
                          _headerActionPill(
                            icon: Icons.security_rounded,
                            label: 'Xüsusi İcazələr',
                            onTap: () => _openEmployeePermissionsSheet(context, user),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: ModernAvatar(
                          imageUrl: user.photoUrl,
                          name: user.fullName,
                          size: 74,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if ((user.fatherName ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Ata adı: ${user.fatherName}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _headerPill(
                                  icon: isTeacher
                                      ? Icons.psychology_rounded
                                      : Icons.admin_panel_settings_rounded,
                                  label: roleLabel,
                                ),
                                _headerPill(
                                  icon: Icons.badge_rounded,
                                  label: user.idrakCode,
                                ),
                              ],
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _headerStat(
                          label: isTeacher && user.assignedClasses.isNotEmpty
                              ? 'Siniflər'
                              : 'FİN Kod',
                          value: isTeacher && user.assignedClasses.isNotEmpty
                              ? '${user.assignedClasses.length} sinif'
                              : _value(user.finCode),
                          icon: isTeacher && user.assignedClasses.isNotEmpty
                              ? Icons.class_rounded
                              : Icons.pin_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _headerStat(
                          label: 'Təcrübə',
                          value: _experience(user.hireDate ?? user.contractStart),
                          icon: Icons.timeline_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _headerStat(
                          label: 'Status',
                          value: user.isActive ? 'Aktiv' : 'Deaktiv',
                          icon: user.isActive
                              ? Icons.verified_rounded
                              : Icons.block_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: 'Geri',
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.maybePop(context),
        icon: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _headerPill({required IconData icon, required String label}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.86)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.76)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileTab(
    BuildContext context,
    AppPalette palette,
    AppUser user,
    DateFormat dateFormat,
  ) {
    return [
      _SectionCard(
        icon: Icons.badge_rounded,
        title: 'Şəxsi və Kimlik Məlumatları',
        accent: palette.brandRoyal,
        child: _InfoRows(
          rows: [
            MapEntry('İşçi kodu', user.idrakCode),
            MapEntry('Ad', _value(user.firstName)),
            MapEntry('Soyad', _value(user.lastName)),
            MapEntry('Ata adı', _value(user.fatherName)),
            MapEntry('Cinsi', _value(user.gender)),
            MapEntry(
              'Doğum tarixi',
              user.birthDate == null
                  ? _empty
                  : dateFormat.format(user.birthDate!),
            ),
            MapEntry('FİN kod', _value(user.finCode)),
            MapEntry('Vətəndaşlıq', _value(user.citizenship)),
            MapEntry('Ş.V. seriya və nömrəsi', _value(user.idCardSerial)),
            MapEntry('Ailə vəziyyəti', _value(user.maritalStatus)),
            MapEntry('Qan qrupu', _value(user.bloodGroup)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        icon: Icons.contact_phone_rounded,
        title: 'Əlaqə və Ünvan Məlumatları',
        accent: const Color(0xFF0D9488),
        child: _InfoRows(
          rows: [
            MapEntry('Əlaqə nömrəsi', _value(user.phone)),
            MapEntry('Rəsmi E-poçt', _value(user.email)),
            MapEntry('Faktiki ünvan', _value(user.address)),
            if ((user.registrationAddress ?? '').trim().isNotEmpty)
              MapEntry('Qeydiyyat ünvanı', _value(user.registrationAddress)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        icon: Icons.workspace_premium_rounded,
        title: 'Təhsil və Elmi Dərəcə',
        accent: const Color(0xFF7C3AED),
        child: _InfoRows(
          rows: [
            MapEntry('Təhsil dərəcəsi', _value(user.educationLevel)),
            MapEntry('Təhsil müəssisəsi', _value(user.university)),
            MapEntry('İxtisas', _value(user.specialty)),
            MapEntry('Elmi dərəcə', _value(user.scientificDegree)),
            MapEntry('Fəxri ad', _value(user.honoraryTitle)),
            if ((user.eduDocNumber ?? '').trim().isNotEmpty)
              MapEntry('Diplom / Sənəd №', _value(user.eduDocNumber)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildWorkTab(
    BuildContext context,
    AppPalette palette,
    AppState appState,
    AppUser user,
    Role? assignedRole,
    bool isTeacher,
    Color roleColor,
    DateFormat dateFormat,
    bool canEdit,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final contractStart = user.contractStart ?? user.hireDate;

    return [
      _SectionCard(
        icon: Icons.apartment_rounded,
        title: 'Struktur, Vəzifə və Bölmə',
        accent: roleColor,
        child: _InfoRows(
          rows: [
            MapEntry('Filial', _value(user.filial ?? 'Bakı filialı')),
            MapEntry(
              'Struktur / Departament',
              _value(
                user.department ??
                    (isTeacher ? 'Pedaqoji heyət' : 'İnzibati heyət'),
              ),
            ),
            MapEntry('Vəzifə', _value(user.position)),
            MapEntry('Bölmə (Sektor)', _value(user.sector ?? 'Azərbaycan')),
            MapEntry(
              'Sistem rolları',
              user.roleNames.isNotEmpty
                  ? user.roleNames.join(', ')
                  : (assignedRole?.name ?? (isTeacher ? 'Müəllim' : 'İşçi')),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        icon: Icons.description_rounded,
        title: 'Əmək Müqaviləsi və Əməkhaqqı',
        accent: AppColors.emerald,
        trailing: TextButton.icon(
          onPressed: () => _openEmployeeContract(context, user),
          icon: const Icon(Icons.open_in_new_rounded, size: 15),
          label: const Text(
            'Müqaviləni Aç',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoRows(
              rows: [
                MapEntry('Müqavilə №', _value(user.contractNumber)),
                MapEntry(
                  'Müqavilə növü',
                  (user.contractType == 'fixed' && user.contractEnd != null)
                      ? 'Müddətli əmək müqaviləsi'
                      : 'Müddətsiz (Daimi)',
                ),
                MapEntry(
                  'Başlama tarixi',
                  contractStart == null
                      ? _empty
                      : dateFormat.format(contractStart),
                ),
                MapEntry(
                  'Bitmə tarixi',
                  user.contractEnd == null
                      ? 'Müddətsiz'
                      : dateFormat.format(user.contractEnd!),
                ),
                MapEntry('Gross əməkhaqqı', _formatSalary(user.salary)),
                if (user.netSalary != null && user.netSalary! > 0)
                  MapEntry('Xalis (Net) maaş', _formatSalary(user.netSalary)),
                MapEntry('Bank adı', _value(user.bankName)),
                if ((user.bankAccount ?? '').trim().isNotEmpty)
                  MapEntry('Hesab nömrəsi', _value(user.bankAccount)),
                if ((user.bankIban ?? '').trim().isNotEmpty)
                  MapEntry('Bank IBAN', _value(user.bankIban)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandRoyal,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _openEmployeeContract(context, user),
                    icon: const Icon(Icons.description_rounded, size: 17),
                    label: const Text(
                      'Müqaviləyə Bax',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.brandRoyal,
                      side: BorderSide(
                        color: palette.brandRoyal.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _openEmployeeSalaryCalculator(context, user),
                    icon: const Icon(Icons.calculate_rounded, size: 17),
                    label: const Text(
                      'Maaş & Vergi',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (isTeacher || user.assignedClasses.isNotEmpty || (user.subject ?? '').isNotEmpty)
        _SectionCard(
          icon: Icons.school_rounded,
          title: 'Tədris Məlumatları',
          accent: const Color(0xFF0D9488),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRows(
                rows: [
                  MapEntry('Tədris etdiyi fənn', _value(user.subject)),
                  if ((user.roomNumber ?? '').trim().isNotEmpty)
                    MapEntry('Dərs otağı', _value(user.roomNumber)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: palette.borderHairline, height: 1),
              const SizedBox(height: 12),
              Text(
                'Təyin olunan siniflər (${user.assignedClasses.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (user.assignedClasses.isEmpty)
                Text(
                  'Sinif təyin edilməyib',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final className in user.assignedClasses)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          className,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      _SectionCard(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Rollar və Xüsusi İcazələr (GoPanel)',
        accent: palette.brandRoyal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRows(
              rows: [
                MapEntry(
                  'Təyin olunan rollar',
                  user.roleNames.isNotEmpty
                      ? user.roleNames.join(', ')
                      : (assignedRole?.name ?? (isTeacher ? 'Müəllim' : 'İnzibatçı')),
                ),
                MapEntry(
                  'Ümumi aktiv icazələr',
                  '${user.directPermissions.isNotEmpty ? user.directPermissions.length : (assignedRole?.permissionIds.length ?? 0)} səlahiyyət',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: palette.borderHairline, height: 1),
            const SizedBox(height: 10),
            if ((user.directPermissions.isNotEmpty
                    ? user.directPermissions
                    : (assignedRole?.permissionIds ?? const <String>[]))
                .isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final permissionId in (user.directPermissions.isNotEmpty
                          ? user.directPermissions
                          : (assignedRole?.permissionIds ?? const <String>[]))
                      .take(14))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _permissionName(permissionId),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (canEdit)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandRoyal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openEmployeePermissionsSheet(context, user),
                  icon: const Icon(Icons.verified_user_rounded, size: 17),
                  label: const Text('Rollar və Xüsusi İcazələri İdarə Et'),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildAccountTab(
    BuildContext context,
    AppPalette palette,
    AppUser user,
    DateFormat dateFormat,
    bool canEdit,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      _SectionCard(
        icon: Icons.key_rounded,
        title: 'Hesab məlumatları',
        accent: palette.brandRoyal,
        child: _InfoRows(
          rows: [
            MapEntry('E-poçt (login)', _value(user.email)),
            MapEntry('İstifadəçi adı', user.username),
            MapEntry('İdrak kodu', user.idrakCode),
            MapEntry(
              'Şifrə',
              _showPassword
                  ? (user.password.isEmpty ? '123456' : user.password)
                  : '••••••',
            ),
            MapEntry('Qeydiyyat', dateFormat.format(user.createdAt)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.brandRoyal.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: palette.brandRoyal,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giriş şifrəsi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _showPassword
                        ? 'Şifrə ekranda göstərilir'
                        : 'Şifrə gizlədilib',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _showPassword,
              onChanged: (value) => setState(() => _showPassword = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        icon: user.isActive
            ? Icons.check_circle_rounded
            : Icons.block_rounded,
        title: 'Hesab statusu',
        accent: user.isActive ? AppColors.success : AppColors.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.isActive
                        ? 'Hesab aktivdir və sistemə giriş mümkündür.'
                        : 'Hesab deaktivdir və sistemə giriş bağlıdır.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: user.isActive ? 'Aktiv' : 'Deaktiv',
                  color:
                      user.isActive ? AppColors.success : AppColors.danger,
                  fontSize: 10,
                ),
              ],
            ),
            if (canEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _toggleUserStatus(context, user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        user.isActive ? AppColors.danger : AppColors.success,
                    side: BorderSide(
                      color: (user.isActive
                              ? AppColors.danger
                              : AppColors.success)
                          .withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    user.isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 17,
                  ),
                  label: Text(
                    user.isActive ? 'Hesabı deaktiv et' : 'Hesabı aktivləşdir',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildActionBar(
    BuildContext context,
    AppPalette palette,
    AppState appState,
    AppUser user,
    bool canEdit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        border: Border(top: BorderSide(color: palette.borderHairline)),
        boxShadow: AppShadows.adaptiveModal(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (canEdit) ...[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandRoyal,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    onPressed: () => showEditEmployeeSheet(context, user),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Redaktə et'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.brandRoyal,
                    side: BorderSide(
                      color: palette.brandRoyal.withValues(alpha: 0.34),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => _openEmployeeContract(context, user),
                  icon: const Icon(Icons.description_rounded, size: 18),
                  label: const Text('Müqavilə'),
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Şifrəni sıfırla',
                  onPressed: () =>
                      _showResetPasswordDialog(context, appState, user),
                  icon: Icon(Icons.lock_reset_rounded, color: palette.brandRoyal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResetPasswordDialog(
    BuildContext context,
    AppState appState,
    AppUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Şifrəni sıfırla'),
        content: Text(
          '${user.fullName} üçün şifrə "123456" olaraq sıfırlansın?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ləğv et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await appState.resetUserPasswordByAdmin(
      user.id,
      newPassword: '123456',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Şifrə "123456" olaraq sıfırlandı.'
              : 'İstifadəçi tapılmadı.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _toggleUserStatus(BuildContext context, AppUser user) async {
    final appState = context.read<AppState>();
    final wasActive = user.isActive;
    appState.toggleUserStatus(user.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasActive
              ? 'Hesab deaktiv edildi.'
              : 'Hesab aktivləşdirildi.',
        ),
        backgroundColor: wasActive ? AppColors.danger : AppColors.success,
      ),
    );
  }
}

class _InfoRows extends StatelessWidget {
  final List<MapEntry<String, String>> rows;

  const _InfoRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0)
            Divider(color: palette.borderHairline, height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 126,
                child: Text(
                  rows[index].key,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  rows[index].value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}


class _EmployeePermissionsSheet extends StatefulWidget {
  final AppUser user;
  const _EmployeePermissionsSheet({required this.user});

  @override
  State<_EmployeePermissionsSheet> createState() => _EmployeePermissionsSheetState();
}

class _EmployeePermissionsSheetState extends State<_EmployeePermissionsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _loading = true;
  bool _saving = false;
  String _search = '';

  List<Map<String, dynamic>> _allRoles = [];
  final Set<String> _selectedRoles = {};
  final Set<String> _directPermissions = {};
  final Set<String> _rolePermissions = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    if (appState.roles.isEmpty) {
      await appState.loadRoles();
    }
    final res = await SchoolApiService.instance.fetchEmployeePermissions(widget.user.id);
    if (!mounted) return;
    setState(() {
      _allRoles = appState.roles
          .map((r) => {'id': r.id, 'name': r.name, 'description': r.description, 'perms': r.permissionIds})
          .toList();
      if (res != null) {
        final rNames = (res['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final dPerms = (res['directPermissions'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final rPerms = (res['rolePermissions'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _selectedRoles
          ..clear()
          ..addAll(rNames);
        _directPermissions
          ..clear()
          ..addAll(dPerms);
        _rolePermissions
          ..clear()
          ..addAll(rPerms);
      } else {
        _selectedRoles
          ..clear()
          ..addAll(widget.user.roleNames);
        _directPermissions
          ..clear()
          ..addAll(widget.user.directPermissions);
      }
      _loading = false;
    });
  }

  void _recomputeRolePerms() {
    _rolePermissions.clear();
    final appState = context.read<AppState>();
    for (final r in appState.roles) {
      if (_selectedRoles.contains(r.name)) {
        _rolePermissions.addAll(r.permissionIds);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await SchoolApiService.instance.updateEmployeePermissions(
      widget.user.id,
      roles: _selectedRoles.toList(),
      directPermissions: _directPermissions.toList(),
    );
    if (!mounted) return;
    if (ok) {
      await context.read<AppState>().syncEmployeesFromApi();
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${widget.user.fullName} üçün rollar və xüsusi icazələr yeniləndi!'
              : 'Xəta baş verdi.',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final byCategory = DefaultPermissions.byCategory;
    final query = _search.trim().toLowerCase();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: palette.textMuted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.brandRoyal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.security_rounded, color: palette.brandRoyal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Rollar (${_selectedRoles.length}) • Xüsusi İcazələr (${_directPermissions.length})',
                        style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            labelColor: palette.brandRoyal,
            unselectedLabelColor: palette.textMuted,
            indicatorColor: palette.brandRoyal,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [
              Tab(text: 'Rollar (${_selectedRoles.length})'),
              Tab(text: 'Xüsusi İcazələr (${_directPermissions.length})'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      // TAB 1: ROLES
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _allRoles.length,
                        itemBuilder: (context, i) {
                          final role = _allRoles[i];
                          final name = role['name'].toString();
                          final desc = role['description']?.toString() ?? '';
                          final permsCount = (role['perms'] as List?)?.length ?? 0;
                          final checked = _selectedRoles.contains(name);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: checked ? palette.brandRoyal : palette.borderHairline,
                                width: checked ? 1.5 : 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: checked,
                              activeColor: palette.brandRoyal,
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              subtitle: Text(
                                '$permsCount icazə  •  $desc',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedRoles.add(name);
                                  } else {
                                    _selectedRoles.remove(name);
                                  }
                                  _recomputeRolePerms();
                                });
                              },
                            ),
                          );
                        },
                      ),
                      // TAB 2: DIRECT SPECIAL PERMISSIONS (XÜSUSİ İCAZƏLƏR)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: TextField(
                              onChanged: (val) => setState(() => _search = val),
                              decoration: InputDecoration(
                                hintText: 'Xüsusi icazə axtar (məs: dərnək, kitab, otaq, jurnal)...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                isDense: true,
                                filled: true,
                                fillColor: palette.bgBase,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: palette.borderHairline),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              children: [
                                for (final entry in byCategory.entries) ...[
                                  Builder(
                                    builder: (context) {
                                      final filteredPerms = entry.value.where((p) {
                                        if (query.isEmpty) return true;
                                        return p.name.toLowerCase().contains(query) ||
                                            p.id.toLowerCase().contains(query) ||
                                            entry.key.toLowerCase().contains(query);
                                      }).toList();
                                      if (filteredPerms.isEmpty) return const SizedBox.shrink();
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          side: BorderSide(color: palette.borderHairline),
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: query.isNotEmpty,
                                          title: Text(
                                            entry.key,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                          ),
                                          subtitle: Text(
                                            '${filteredPerms.length} icazə',
                                            style: TextStyle(fontSize: 11, color: palette.textSecondary),
                                          ),
                                          children: [
                                            for (final p in filteredPerms)
                                              Builder(
                                                builder: (context) {
                                                  final fromRole = _rolePermissions.contains(p.id);
                                                  final isDirect = _directPermissions.contains(p.id);
                                                  return CheckboxListTile(
                                                    dense: true,
                                                    value: isDirect || fromRole,
                                                    activeColor: isDirect ? palette.brandRoyal : Colors.teal,
                                                    title: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            p.name,
                                                            style: const TextStyle(
                                                              fontSize: 12.5,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ),
                                                        if (fromRole)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.teal.withValues(alpha: 0.12),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: const Text(
                                                              'Roldan gəlir',
                                                              style: TextStyle(
                                                                color: Colors.teal,
                                                                fontSize: 9.5,
                                                                fontWeight: FontWeight.w800,
                                                              ),
                                                            ),
                                                          ),
                                                        if (isDirect) ...[
                                                          const SizedBox(width: 4),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: palette.brandRoyal.withValues(alpha: 0.12),
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              'Xüsusi İcazə',
                                                              style: TextStyle(
                                                                color: palette.brandRoyal,
                                                                fontSize: 9.5,
                                                                fontWeight: FontWeight.w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    subtitle: Text(
                                                      p.id,
                                                      style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        if (isDirect) {
                                                          _directPermissions.remove(p.id);
                                                        } else {
                                                          _directPermissions.add(p.id);
                                                        }
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: palette.surface1,
                border: Border(top: BorderSide(color: palette.borderHairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Ləğv et'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_saving ? 'Saxlanılır...' : 'Yadda Saxla (GoPanel)'),
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
}
