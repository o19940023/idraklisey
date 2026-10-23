import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';
import '../widgets/edit_employee_sheet.dart';
import 'create_employee_screen.dart';
import 'employee_profile_screen.dart';

enum _StaffFilter { all, teachers, administration }

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  _StaffFilter _filter = _StaffFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final palette = AppPalette.of(context);
    final canAdd = appState.hasPermission('add_users');
    final canEdit = appState.hasPermission('edit_users');

    final staff = appState.users
        .where((user) =>
            user.role != UserRole.student && user.role != UserRole.parent)
        .toList()
      ..sort((a, b) {
        if (a.role != b.role) {
          return a.role == UserRole.teacher ? -1 : 1;
        }
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });
    final teachers =
        staff.where((user) => user.role == UserRole.teacher).toList();
    final administration =
        staff.where((user) => user.role == UserRole.admin).toList();
    final activeCount = staff.where((user) => user.isActive).length;

    final query = _searchCtrl.text.trim().toLowerCase();
    final scoped = switch (_filter) {
      _StaffFilter.teachers => teachers,
      _StaffFilter.administration => administration,
      _StaffFilter.all => staff,
    };
    final filtered = query.isEmpty
        ? scoped
        : scoped.where((user) {
            return user.fullName.toLowerCase().contains(query) ||
                user.username.toLowerCase().contains(query) ||
                (user.email ?? '').toLowerCase().contains(query) ||
                (user.finCode ?? '').toLowerCase().contains(query) ||
                user.idrakCode.toLowerCase().contains(query) ||
                (user.position ?? '').toLowerCase().contains(query) ||
                (user.subject ?? '').toLowerCase().contains(query);
          }).toList();

    final entries = <_DirectoryEntry>[];
    if (_filter == _StaffFilter.all) {
      final visibleTeachers = filtered
          .where((user) => user.role == UserRole.teacher)
          .toList();
      final visibleAdministration = filtered
          .where((user) => user.role == UserRole.admin)
          .toList();
      if (visibleTeachers.isNotEmpty) {
        entries.add(
          _SectionEntry(
            title: 'Müəllimlər',
            count: visibleTeachers.length,
            icon: Icons.psychology_rounded,
            color: const Color(0xFF0D9488),
          ),
        );
        entries.addAll(visibleTeachers.map(_UserEntry.new));
      }
      if (visibleAdministration.isNotEmpty) {
        entries.add(
          _SectionEntry(
            title: 'İnzibatçı və işçilər',
            count: visibleAdministration.length,
            icon: Icons.admin_panel_settings_rounded,
            color: palette.brandRoyal,
          ),
        );
        entries.addAll(visibleAdministration.map(_UserEntry.new));
      }
    } else {
      entries.addAll(filtered.map(_UserEntry.new));
    }

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(
            context,
            palette,
            canAdd,
            teachers.length,
            administration.length,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatCardRow(
                    columns: 3,
                    spacing: 8,
                    children: [
                      StatCard(
                        value: '${teachers.length}',
                        label: 'Müəllim',
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF0D9488),
                        compact: true,
                      ),
                      StatCard(
                        value: '${administration.length}',
                        label: 'İnzibatçı / İşçi',
                        icon: Icons.admin_panel_settings_rounded,
                        color: palette.brandRoyal,
                        compact: true,
                      ),
                      StatCard(
                        value: '$activeCount',
                        label: 'Aktiv hesab',
                        icon: Icons.verified_user_rounded,
                        color: AppColors.success,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppSearchBar(
                    controller: _searchCtrl,
                    hintText: 'Ad, vəzifə, e-poçt və ya İdrak kodu axtar...',
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(palette, staff.length, teachers.length,
                      administration.length),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                context,
                palette,
                canAdd,
                staff.isNotEmpty,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'İşçi heyəti',
                      style: AppTypography.title1(context).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: TextStyle(
                          color: palette.brandRoyal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canEdit)
                      Text(
                        'Redaktə üçün kartdakı qələmi seçin',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    return switch (entry) {
                      _SectionEntry() => _buildSectionHeader(
                          context,
                          palette,
                          entry,
                        ),
                      _UserEntry() => _buildUserCard(
                          context,
                          appState,
                          entry.user,
                          canEdit,
                        ),
                    };
                  },
                  childCount: entries.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    bool canAdd,
    int teacherCount,
    int administrationCount,
  ) {
    return SliverAppBar(
      expandedHeight: 132,
      pinned: true,
      elevation: 0,
      backgroundColor: palette.brandNavy,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      actions: [
        if (canAdd)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Yeni işçi hesabı',
              onPressed: () {
                Navigator.push(
                  context,
                  appRoute(builder: (_) => const CreateEmployeeScreen()),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            final showContent = constraints.maxHeight >= 96;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF11152C),
                    Color(0xFF28326F),
                    Color(0xFF2563EB),
                  ],
                ),
              ),
              child: !showContent
                  ? const SizedBox.expand()
                  : Stack(
                      children: [
                        Positioned(
                          right: -34,
                          top: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.manage_accounts_rounded,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'İstifadəçi Hesabları',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$teacherCount müəllim • '
                                          '$administrationCount inzibatçı / işçi',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.72),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(
    AppPalette palette,
    int allCount,
    int teacherCount,
    int administrationCount,
  ) {
    final items = [
      (label: 'Hamısı', count: allCount, filter: _StaffFilter.all),
      (label: 'Müəllimlər', count: teacherCount, filter: _StaffFilter.teachers),
      (
        label: 'İnzibatçı / İşçi',
        count: administrationCount,
        filter: _StaffFilter.administration,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: GestureDetector(
                onTap: () => setState(() => _filter = item.filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _filter == item.filter
                        ? palette.brandRoyal
                        : palette.surface1,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _filter == item.filter
                          ? palette.brandRoyal
                          : palette.borderHairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          color: _filter == item.filter
                              ? Colors.white
                              : palette.surface1.computeLuminance() > 0.5
                                  ? const Color(0xFF334155)
                                  : Colors.white70,
                          fontSize: 11.5,
                          fontWeight: _filter == item.filter
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _filter == item.filter
                              ? Colors.white.withValues(alpha: 0.18)
                              : palette.surface3,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.count}',
                          style: TextStyle(
                            color: _filter == item.filter
                                ? Colors.white
                                : palette.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    AppPalette palette,
    _SectionEntry entry,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(entry.icon, size: 15, color: entry.color),
          ),
          const SizedBox(width: 8),
          Text(
            entry.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${entry.count}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    AppState appState,
    AppUser user,
    bool canEdit,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTeacher = user.role == UserRole.teacher;
    final assignedRole = appState.getRoleById(user.assignedRoleId);
    final roleColor =
        isTeacher ? const Color(0xFF0D9488) : AppPalette.of(context).brandRoyal;
    final roleLabel = isTeacher
        ? 'Müəllim'
        : (assignedRole?.name ?? 'İnzibatçı / İşçi');
    final secondary = isTeacher
        ? [
            if ((user.subject ?? '').trim().isNotEmpty) user.subject!.trim(),
            if ((user.roomNumber ?? '').trim().isNotEmpty)
              'Otaq ${user.roomNumber!.trim()}',
            if (user.assignedClasses.isNotEmpty)
              user.assignedClasses.join(', '),
          ].join(' • ')
        : [
            if ((user.position ?? '').trim().isNotEmpty) user.position!.trim(),
            if (assignedRole != null) assignedRole.name,
          ].join(' • ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 9),
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: () {
        Navigator.push(
          context,
          appRoute(builder: (_) => EmployeeProfileScreen(user: user)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 11, 8, 11),
        child: Row(
          children: [
            ModernAvatar(
              imageUrl: user.photoUrl,
              name: user.fullName,
              size: 52,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: StatusBadge(
                          label: roleLabel,
                          color: roleColor,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    secondary.isEmpty ? user.idrakCode : secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        user.isActive
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 8,
                        color: user.isActive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Aktiv' : 'Deaktiv',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: user.isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          user.idrakCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppPalette.of(context).textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit)
              IconButton(
                tooltip: 'Redaktə et',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => showEditEmployeeSheet(context, user),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: AppPalette.of(context).brandRoyal,
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppPalette.of(context).textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppPalette palette,
    bool canAdd,
    bool hasStaff,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: palette.brandRoyal.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                hasStaff
                    ? Icons.person_search_rounded
                    : Icons.group_add_outlined,
                size: 34,
                color: palette.brandRoyal,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasStaff ? 'Nəticə tapılmadı' : 'Hələ işçi hesabı yoxdur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasStaff
                  ? 'Axtarış və ya filtrə uyğun işçi tapılmadı.'
                  : 'İlk müəllim və ya işçi hesabını yaratmaqla başlayın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (canAdd && !hasStaff) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    appRoute(builder: (_) => const CreateEmployeeScreen()),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Yeni işçi hesabı'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

sealed class _DirectoryEntry {
  const _DirectoryEntry();
}

class _SectionEntry extends _DirectoryEntry {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SectionEntry({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _UserEntry extends _DirectoryEntry {
  final AppUser user;

  const _UserEntry(this.user);
}
