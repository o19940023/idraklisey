import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/role_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';
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
    return text.isEmpty ? _empty : text;
  }

  String _formatSalary(double? salary) {
    if (salary == null) return _empty;
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final palette = AppPalette.of(context);
    final user = appState.users.firstWhere(
      (item) => item.id == widget.user.id,
      orElse: () => widget.user,
    );
    final isTeacher = user.role == UserRole.teacher;
    final assignedRole = appState.getRoleById(user.assignedRoleId);
    final roleLabel = isTeacher
        ? 'Müəllim'
        : (assignedRole?.name ?? 'İnzibatçı / İşçi');
    final roleColor =
        isTeacher ? const Color(0xFF0D9488) : palette.brandRoyal;
    final canEdit = appState.hasPermission('edit_users');
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
                  Tab(text: 'Profil'),
                  Tab(text: 'İş'),
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
      bottomNavigationBar: canEdit
          ? _buildActionBar(context, palette, appState, user)
          : null,
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
    final subtitle = isTeacher
        ? [
            if ((user.subject ?? '').trim().isNotEmpty) user.subject!.trim(),
            if ((user.roomNumber ?? '').trim().isNotEmpty)
              'Otaq ${user.roomNumber!.trim()}',
          ].join(' · ')
        : ((user.position ?? '').trim().isNotEmpty
            ? user.position!.trim()
            : (user.email ?? '').trim());

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
                  _backButton(context),
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
                          size: 78,
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
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
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
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.72),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _headerStat(
                          label: isTeacher ? 'Siniflər' : 'Rol',
                          value: isTeacher
                              ? '${user.assignedClasses.length}'
                              : roleLabel,
                          icon: isTeacher
                              ? Icons.class_rounded
                              : Icons.badge_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _headerStat(
                          label: 'Təcrübə',
                          value: _experience(user.hireDate),
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
                    fontSize: 13,
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
    final colorScheme = Theme.of(context).colorScheme;

    return [
      _SectionCard(
        icon: Icons.badge_rounded,
        title: 'Şəxsi məlumatlar',
        accent: palette.brandRoyal,
        child: _InfoRows(
          rows: [
            MapEntry('Ad, Soyad', user.fullName),
            MapEntry('Ata adi', _value(user.fatherName)),
            MapEntry('Cins', _value(user.gender)),
            MapEntry(
              'Doğum tarixi',
              user.birthDate == null
                  ? _empty
                  : dateFormat.format(user.birthDate!),
            ),
            MapEntry('FIN kod', _value(user.finCode)),
            MapEntry('Vətəndaşlıq', _value(user.citizenship)),
            MapEntry('SV seriyası', _value(user.idCardSerial)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        icon: Icons.contact_phone_rounded,
        title: 'Əlaqə',
        accent: const Color(0xFF0D9488),
        child: _InfoRows(
          rows: [
            MapEntry('Telefon', _value(user.phone)),
            MapEntry('E-poçt', _value(user.email)),
            MapEntry('Ünvan', _value(user.address)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.brandRoyal.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.brandRoyal.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: palette.brandRoyal,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'İşçi məlumatları yalnız səlahiyyətli idarəetmə heyəti tərəfindən redaktə olunur.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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

    return [
      _SectionCard(
        icon: Icons.work_rounded,
        title: 'Vəzifə və əmək haqqı',
        accent: roleColor,
        child: _InfoRows(
          rows: [
            MapEntry('Vəzifə', _value(user.position)),
            MapEntry('Təhsil dərəcəsi', _value(user.educationLevel)),
            MapEntry('Bank', _value(user.bankName)),
            MapEntry('Əmək haqqı', _formatSalary(user.salary)),
            MapEntry(
              'İşə qəbul',
              user.hireDate == null
                  ? _empty
                  : dateFormat.format(user.hireDate!),
            ),
            MapEntry(
              'Müqavilə başlanğıcı',
              user.contractStart == null
                  ? _empty
                  : dateFormat.format(user.contractStart!),
            ),
            MapEntry(
              'Müqavilə bitməsi',
              user.contractEnd == null
                  ? 'Müddətsiz'
                  : dateFormat.format(user.contractEnd!),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (isTeacher)
        _SectionCard(
          icon: Icons.school_rounded,
          title: 'Tədris məlumatları',
          accent: const Color(0xFF0D9488),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRows(
                rows: [
                  MapEntry('Fənn', _value(user.subject)),
                  MapEntry('Dərs otağı', _value(user.roomNumber)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: palette.borderHairline, height: 1),
              const SizedBox(height: 12),
              Text(
                'Təyin olunan siniflər',
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
        )
      else
        _SectionCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Rol və səlahiyyətlər',
          accent: palette.brandRoyal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRows(
                rows: [
                  MapEntry('Rol', assignedRole?.name ?? _empty),
                  MapEntry(
                    'Səlahiyyət sayı',
                    '${assignedRole?.permissionIds.length ?? 0}',
                  ),
                ],
              ),
              if (assignedRole != null &&
                  assignedRole.permissionIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: palette.borderHairline, height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final permissionId
                        in assignedRole.permissionIds.take(12))
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
                    if (assignedRole.permissionIds.length > 12)
                      Text(
                        '+${assignedRole.permissionIds.length - 12}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      if (isTeacher) ...[
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.key_rounded,
          title: 'Pedaqoji əlavə səlahiyyətlər',
          accent: palette.brandGold,
          trailing: canEdit
              ? TextButton(
                  onPressed: () =>
                      _showEditPermissionsDialog(context, appState, user),
                  child: const Text('Dəyiş'),
                )
              : null,
          child: Column(
            children: [
              _PermissionRow(
                label: 'Yeməkxana menyusu',
                enabled:
                    user.teacherPermissions?.canManageCafeteria ?? false,
              ),
              const SizedBox(height: 8),
              _PermissionRow(
                label: 'Tibbi qeydlər',
                enabled: user.teacherPermissions?.canManageMedical ?? false,
              ),
              const SizedBox(height: 8),
              _PermissionRow(
                label: 'İnventar və QR biletlər',
                enabled:
                    user.teacherPermissions?.canManageInventory ?? false,
              ),
            ],
          ),
        ),
      ],
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
            MapEntry('Idrak kodu', user.idrakCode),
            MapEntry(
              'Şifrə',
              _showPassword ? user.password : '•' * user.password.length,
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
              const SizedBox(width: 10),
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
                  onPressed: () =>
                      _showResetPasswordDialog(context, appState, user),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text('Şifrə'),
                ),
              ),
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

  Future<void> _showEditPermissionsDialog(
    BuildContext context,
    AppState appState,
    AppUser user,
  ) async {
    var cafeteria = user.teacherPermissions?.canManageCafeteria ?? false;
    var medical = user.teacherPermissions?.canManageMedical ?? false;
    var inventory = user.teacherPermissions?.canManageInventory ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Pedaqoji səlahiyyətlər'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Yeməkxana menyusu'),
                  value: cafeteria,
                  onChanged: (value) =>
                      setDialogState(() => cafeteria = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tibbi qeydlər'),
                  value: medical,
                  onChanged: (value) => setDialogState(() => medical = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('İnventar və QR biletlər'),
                  value: inventory,
                  onChanged: (value) =>
                      setDialogState(() => inventory = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Ləğv et'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Yadda saxla'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    appState.updateTeacherPermissions(
      user.id,
      TeacherPermissions(
        canManageCafeteria: cafeteria,
        canManageMedical: medical,
        canManageInventory: inventory,
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
                width: 118,
                child: Text(
                  rows[index].key,
                  style: TextStyle(
                    fontSize: 11,
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

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool enabled;

  const _PermissionRow({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = enabled ? AppColors.success : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
          size: 17,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          enabled ? 'İcazəli' : 'Bağlı',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
