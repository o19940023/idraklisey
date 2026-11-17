import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../data/models/role_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import 'create_role_dialog.dart';
import 'edit_role_dialog.dart';

/// Rol İdarəetmə Ekranı — GoPanel Web (Spatie Roles & Permissions) ilə 1:1 sinxron
class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  bool _isLoading = true;
  List<Role> _roles = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadRoles();
      if (!mounted) return;
      setState(() {
        _roles = appState.roles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rollar yüklənərkən xəta: $e')),
      );
    }
  }

  List<Role> get _filteredRoles {
    if (_searchQuery.isEmpty) return _roles;
    final query = _searchQuery.toLowerCase();
    return _roles.where((role) {
      return role.name.toLowerCase().contains(query) ||
          role.description.toLowerCase().contains(query);
    }).toList();
  }

  bool get _canManageRoles {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.isPrimaryAdmin || appState.hasPermission('manage_roles') || appState.hasPermission('roles');
  }

  void _showCreateRoleDialog() {
    if (!_canManageRoles) return;
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(
        onRoleCreated: _loadRoles,
      ),
    );
  }

  void _showEditRoleDialog(Role role) {
    if (!_canManageRoles) return;
    showDialog(
      context: context,
      builder: (context) => EditRoleDialog(
        role: role,
        onRoleUpdated: _loadRoles,
      ),
    );
  }

  Future<void> _deleteRole(Role role) async {
    if (!_canManageRoles) return;
    if (!role.isDeletable || role.name.toLowerCase() == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Əsas sistem rolu silinə bilməz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rolu Sil'),
        content: Text(
          '"${role.name}" rolunu silmək istədiyinizə əminsiniz?\n\n'
          'Bu rola malik əməkdaşlardan həmin rol təyinatı silinəcək.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ləğv et'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final ok = await appState.deleteRoleFromBackend(role.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '"${role.name}" rolu silindi' : 'Rol silinə bilmədi'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadRoles();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol silinərkən xəta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final canManage = appState.isPrimaryAdmin ||
        appState.hasPermission('manage_roles') ||
        appState.hasPermission('roles');
    final totalCatalogPerms = DefaultPermissions.all.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Rollar və Səlahiyyətlər (GoPanel)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoles,
            tooltip: 'Yenilə',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_roles.length} Aktiv Rol  •  $totalCatalogPerms GoPanel İcazəsi',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Rol adı və ya açıqlama axtar...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                if (canManage) ...[
                  SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCreateRoleDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.add_moderator_rounded),
                      label: const Text(
                        'Yeni Rol Yarat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRoles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 72,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Hələ rol yaradılmayıb'
                                  : 'Axtarış nəticəsi tapılmadı',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.md),
                        itemCount: _filteredRoles.length,
                        itemBuilder: (context, index) {
                          final role = _filteredRoles[index];
                          return _RoleCard(
                            role: role,
                            onTap: canManage ? () => _showEditRoleDialog(role) : null,
                            onDelete: canManage ? () => _deleteRole(role) : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _RoleCard({
    required this.role,
    this.onTap,
    this.onDelete,
  });

  String _permLabel(String key) {
    for (final p in DefaultPermissions.all) {
      if (p.id == key) return p.name;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final permissionCount = role.permissionIds.length;
    final previewPerms = role.permissionIds.take(6).toList();

    return ModernCard(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                role.name,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (onTap != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                color: AppColors.primary,
                                onPressed: onTap,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Redaktə et',
                              ),
                            if (role.isDeletable &&
                                role.name.toLowerCase() != 'superadmin' &&
                                onDelete != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 19),
                                color: Colors.red,
                                onPressed: onDelete,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Rolu Sil',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'ID: ${role.id.length > 22 ? role.id.substring(0, 20) + "..." : role.id}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '$permissionCount icazə',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (role.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            role.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (previewPerms.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in previewPerms)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _permLabel(p),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (permissionCount > previewPerms.length)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${permissionCount - previewPerms.length} digər',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.security, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$permissionCount Səlahiyyət (GoPanel)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'İcazələrə bax / dəyiş →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
