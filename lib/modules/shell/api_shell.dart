import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../academic_ops/screens/ambulatory_requests_screen.dart';
import '../admin/screens/student_management_screen.dart';
import '../dashboard/screens/api_dashboard_screen.dart';
import '../exams/screens/student_applications_screen.dart';
import '../finance/screens/api_finance_screen.dart';
import '../hr/screens/api_salary_calculator_screen.dart';
import '../library_ops/screens/api_library_screen.dart';
import '../shared/screens/api_data_screen.dart';
import '../shared/screens/api_list_screen.dart';
import '../shared/screens/api_notifications_screen.dart';
import '../shell/modules.dart';

class ApiShell extends StatefulWidget {
  const ApiShell({super.key});

  @override
  State<ApiShell> createState() => _ApiShellState();
}

class _ApiShellState extends State<ApiShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = session.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final modules = profile.isStudent
        ? ModuleCatalog.forStudent()
        : profile.isParent
            ? ModuleCatalog.forParent()
            : ModuleCatalog.forStaff();

    final visible = modules.where((m) {
      if (m.permission == null && m.anyOf == null) return true;
      if (m.permission != null) return session.can(m.permission!);
      return session.canAny(m.anyOf ?? const []);
    }).toList();

    final grouped = <String, List<ModuleEntry>>{};
    for (final module in visible) {
      grouped.putIfAbsent(module.group, () => []).add(module);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Menyu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('İDRAK Liseyi'),
        actions: [
          IconButton(
            tooltip: 'Bildirişlər',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ApiNotificationsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Hesab',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showContextSheet(context, session),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DrawerHeader(session: session, onTap: () => _showContextSheet(context, session)),
              ...grouped.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    ...entry.value.map(
                      (module) => ListTile(
                        dense: true,
                        leading: Icon(module.icon, size: 21, color: AppColors.primaryAccent),
                        title: Text(module.title, style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openModule(context, module);
                        },
                      ),
                    ),
                  ]),
              const Divider(height: 24),
              if (session.can('gopanel.dashboard.salary_calculator'))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.calculate_rounded, size: 21, color: AppColors.primaryAccent),
                  title: const Text('Əməkhaqqı kalkulyatoru', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ApiSalaryCalculatorScreen()),
                    );
                  },
                ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.primaryAccent),
                title: const Text('Bildirişlər', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ApiNotificationsScreen()),
                  );
                },
              ),
              const Divider(height: 24),
              ListTile(
                dense: true,
                leading: const Icon(Icons.logout_rounded, size: 21, color: AppColors.danger),
                title: const Text('Çıxış', style: TextStyle(fontSize: 14, color: AppColors.danger)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await session.logout();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: const ApiDashboardScreen(),
    );
  }

  void _openModule(BuildContext context, ModuleEntry module) {
    if (module.customBuilder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: module.customBuilder!));
      return;
    }

    if (module.endpoint == 'academic/students') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
      );
      return;
    }

    if (module.endpoint == 'academic/admissions') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StudentApplicationsScreen()),
      );
      return;
    }

    if (module.endpoint == 'academic/ambulatory-requests' || module.endpoint == 'medical/ambulatory') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AmbulatoryRequestsScreen()),
      );
      return;
    }

    if (module.endpoint.startsWith('finance/')) {
      final tab = module.endpoint == 'finance/payments'
          ? FinanceTab.payments
          : module.endpoint == 'finance/ledger'
              ? FinanceTab.ledger
              : FinanceTab.contracts;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ApiFinanceScreen(initialTab: tab)),
      );
      return;
    }

    if (module.endpoint.startsWith('library/')) {
      final isStaff = context.read<SessionController>().profile?.isStaff == true;
      final tab = module.endpoint == 'library/books'
          ? (isStaff ? 2 : 0)
          : module.endpoint == 'library/loans'
              ? 1
              : 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ApiLibraryScreen(initialTab: tab)),
      );
      return;
    }

    if (module.isDataView) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApiDataScreen(
            title: module.title,
            endpoint: module.endpoint,
            query: module.query,
            emptyText: module.emptyText,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApiListScreen(
          title: module.title,
          endpoint: module.endpoint,
          query: module.query,
          titleKeys: module.titleKeys,
          subtitleKeys: module.subtitleKeys,
          badgeKey: module.badgeKey,
          emptyText: module.emptyText,
        ),
      ),
    );
  }

  Future<void> _showContextSheet(BuildContext context, SessionController session) async {
    final profile = session.profile;
    if (profile == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(
                '${profile.type.toUpperCase()} · ${profile.activeRole ?? ''}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (profile.roles.length > 1) ...[
                const Text('Aktiv rol', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.roles
                      .map((role) => ChoiceChip(
                            label: Text(role, style: const TextStyle(fontSize: 12)),
                            selected: profile.activeRole == role,
                            onSelected: (_) async {
                              await session.changeContext(role: role);
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (profile.branches.length > 1) ...[
                const Text('Filial', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.branches
                      .map((branch) => ChoiceChip(
                            label: Text(branch.name, style: const TextStyle(fontSize: 12)),
                            selected: profile.filialId == branch.id,
                            onSelected: (_) async {
                              await session.changeContext(filialId: branch.id);
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            },
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await session.refresh();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Yenilə'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await session.logout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Çıxış'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.session, required this.onTap});

  final SessionController session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = session.profile;
    final name = profile?.name ?? 'İstifadəçi';
    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'İ';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withAlpha(40),
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile?.activeRole ?? profile?.type ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
