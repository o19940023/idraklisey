import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';

class OrganizationalStructureScreen extends StatefulWidget {
  const OrganizationalStructureScreen({super.key});

  @override
  State<OrganizationalStructureScreen> createState() => _OrganizationalStructureScreenState();
}

class _OrganizationalStructureScreenState extends State<OrganizationalStructureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStructures = [];
  List<Map<String, dynamic>> _filteredStructures = [];
  List<Map<String, dynamic>> _treeData = [];
  Map<String, dynamic>? _diagramData;

  final TransformationController _diagramTransformController = TransformationController();
  bool _isDiagramView = true;

  bool _isLoading = true;
  String _selectedTypeFilter = 'ALL';
  bool _onlyActiveFilter = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _diagramTransformController.value = Matrix4.diagonal3Values(0.42, 0.42, 1.0);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _diagramTransformController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SchoolApiService.instance.fetchHrStructures(all: true),
        SchoolApiService.instance.fetchHrStructureTree(),
        SchoolApiService.instance.fetchHrStructureDiagram(),
      ]);

      if (mounted) {
        setState(() {
          _allStructures = results[0] as List<Map<String, dynamic>>;
          _treeData = results[1] as List<Map<String, dynamic>>;
          _diagramData = results[2] as Map<String, dynamic>?;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Məlumat yüklənərkən xəta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredStructures = _allStructures.where((s) {
        final title = (s['title'] ?? '').toString().toLowerCase();
        final code = (s['code'] ?? '').toString().toLowerCase();
        final type = (s['type_of_structure'] ?? '').toString();
        final isActive = s['is_active'] == true;

        final matchesQuery = query.isEmpty || title.contains(query) || code.contains(query);
        final matchesType = _selectedTypeFilter == 'ALL' || type.toUpperCase() == _selectedTypeFilter.toUpperCase();
        final matchesActive = !_onlyActiveFilter || isActive;

        return matchesQuery && matchesType && matchesActive;
      }).toList();
    });
  }

  int get _totalStaffCount {
    int sum = 0;
    for (final s in _allStructures) {
      sum += (s['employees_count'] as num? ?? 0).toInt();
    }
    return sum;
  }

  // =================================================================
  // ACTION: TOGGLE STATUS
  // =================================================================
  Future<void> _toggleStatus(Map<String, dynamic> structure) async {
    final id = (structure['id'] as num).toInt();
    final currentStatus = structure['is_active'] == true;
    final res = await SchoolApiService.instance.toggleHrStructureStatus(id);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus
                ? '"${structure['title']}" deaktiv edildi'
                : '"${structure['title']}" aktivləşdirildi',
          ),
          backgroundColor: currentStatus ? Colors.orange : AppColors.success,
        ),
      );
      _loadData();
    }
  }

  // =================================================================
  // ACTION: DELETE STRUCTURE
  // =================================================================
  Future<void> _confirmDelete(Map<String, dynamic> structure) async {
    final id = (structure['id'] as num).toInt();
    final title = structure['title'] ?? 'Struktur';
    final employeesCount = (structure['employees_count'] as num? ?? 0).toInt();
    final childrenCount = (structure['children_count'] as num? ?? 0).toInt();

    if (employeesCount > 0) {
      _showWarningDialog(
        title: 'Silmək mümkün deyil',
        message:
            'Bu struktura bağlı $employeesCount aktiv əməkdaş müqaviləsi var. Əvvəlcə əməkdaşların strukturunu dəyişin və ya müqavilələrə xitam verin.',
      );
      return;
    }

    if (childrenCount > 0) {
      _showWarningDialog(
        title: 'Silmək mümkün deyil',
        message:
            'Bu strukturun $childrenCount alt strukturu var. Əvvəlcə alt strukturların tabeliyini dəyişin.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Strukturu Sil'),
          ],
        ),
        content: Text('"$title" strukturunu silmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İmtina'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bəli, Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SchoolApiService.instance.deleteHrStructure(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$title" uğurla silindi.'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Struktur silinərkən xəta baş verdi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showWarningDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // ACTION: EMPLOYEES SHEET (Web Parity: _employee_list_modal_content)
  // =================================================================
  void _openEmployeesSheet(Map<String, dynamic> structure) {
    final id = (structure['id'] as num).toInt();
    final title = structure['title'] ?? 'Struktur';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StructureEmployeesSheet(
        structureId: id,
        structureTitle: title,
      ),
    );
  }

  // =================================================================
  // ACTION: CONNECTIONS SHEET (Web Parity: _connections_modal)
  // =================================================================
  void _openConnectionsSheet(Map<String, dynamic> structure) {
    final id = (structure['id'] as num).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StructureConnectionsSheet(
        structureId: id,
        onChanged: _loadData,
      ),
    );
  }

  // =================================================================
  // ACTION: ADD / EDIT STRUCTURE DIALOG (Web Parity: form.blade.php)
  // =================================================================
  void _openStructureFormDialog({Map<String, dynamic>? structure}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StructureFormSheet(
        existingStructure: structure,
        allStructures: _allStructures,
        onSaved: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canCreate = isSuper ||
        session.can('gopanel.structure.structures.create') ||
        session.can('gopanel.structure.structures.store');
    final canEdit = isSuper || session.can('gopanel.structure.structures.update');
    final canDelete = isSuper || session.can('gopanel.structure.structures.delete');

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Təşkilati Struktur',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Strukturlar, şöbələr və heyət bölgüsü',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Yenilə',
            onPressed: _loadData,
          ),
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              tooltip: 'Yeni Struktur',
              onPressed: () => _openStructureFormDialog(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.view_list_rounded, size: 20),
              text: 'Siyahı (${_allStructures.length})',
            ),
            const Tab(
              icon: Icon(Icons.account_tree_rounded, size: 20),
              text: 'Sxem (Ağac)',
            ),
            const Tab(
              icon: Icon(Icons.insights_rounded, size: 20),
              text: 'İcmal',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(isDark, canEdit: canEdit, canDelete: canDelete),
                _buildTreeView(isDark),
                _buildOverviewView(isDark),
              ],
            ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Struktur', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _openStructureFormDialog(),
            )
          : null,
    );
  }

  // =================================================================
  // TAB 1: LIST VIEW (DATATABLE CARDS)
  // =================================================================
  Widget _buildListView(bool isDark, {required bool canEdit, required bool canDelete}) {
    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Struktur adı və ya kod üzrə axtar...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Hamısı (${_allStructures.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('DEPARTMENT', 'Departamentlər'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ADMINISTRATION', 'Rəhbərlik'),
                    const SizedBox(width: 8),
                    _buildFilterChip('BRANCH', 'Filiallar'),
                    const SizedBox(width: 8),
                    _buildFilterChip('METODIST', 'Metodbirləşmələr'),
                    const SizedBox(width: 12),
                    FilterChip(
                      selected: _onlyActiveFilter,
                      label: const Text('Yalnız Aktivlər', style: TextStyle(fontSize: 12)),
                      onSelected: (val) {
                        setState(() {
                          _onlyActiveFilter = val;
                          _applyFilters();
                        });
                      },
                      selectedColor: AppPalette.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppPalette.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of structures
        Expanded(
          child: _filteredStructures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun struktur tapılmadı',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _filteredStructures.length,
                  itemBuilder: (ctx, index) {
                    final item = _filteredStructures[index];
                    return _buildStructureCard(item, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _selectedTypeFilter == type;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onSelected: (sel) {
        if (sel) {
          setState(() {
            _selectedTypeFilter = type;
            _applyFilters();
          });
        }
      },
      selectedColor: AppPalette.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
    );
  }

  Widget _buildStructureCard(Map<String, dynamic> item, bool isDark) {
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canEdit = isSuper || session.can('gopanel.structure.structures.update');
    final canDelete = isSuper || session.can('gopanel.structure.structures.delete');

    final title = item['title'] ?? 'Adsız Struktur';
    final code = item['code'] ?? '';
    final typeLabel = item['type_label'] ?? item['type_of_structure'] ?? 'Bölmə';
    final isActive = item['is_active'] == true;
    final parentTitle = item['parent_title'];
    final employeesCount = (item['employees_count'] as num? ?? 0).toInt();
    final totalEmployeesCount = (item['total_employees_count'] as num? ?? 0).toInt();
    final parents = (item['parents'] as List?) ?? [];

    Color typeColor = Colors.blue;
    if (item['type_of_structure'] == 'ADMINISTRATION') {
      typeColor = Colors.purple;
    } else if (item['type_of_structure'] == 'BRANCH') {
      typeColor = Colors.teal;
    } else if (item['type_of_structure'] == 'METODIST' || item['type_of_structure'] == 'metodist') {
      typeColor = Colors.amber.shade800;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Code, Type Badge, Active Switch
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      code.isNotEmpty ? code : '#${item['id']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Active Status Switch
                  InkWell(
                    onTap: () => _toggleStatus(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: isActive ? AppColors.success : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktiv' : 'Deaktiv',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.success : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              if (item['description'] != null && (item['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),

              // Parent Info (Hierarchy)
              if (parents.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    const Text('Üst Tabeçilik:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ...parents.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p['title'] ?? '',
                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (parentTitle != null) ...[
                Row(
                  children: [
                    const Text('Üst Tabeçilik: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      parentTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Əsas Kök Səviyyə (Birbaşa İdarəetmə)',
                      style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const Divider(height: 16),

              // Bottom Actions: Employees button & Compact Action Buttons
              Row(
                children: [
                  // Employees Action Button (Expanded with internal Expanded to prevent any right overflow)
                  Expanded(
                    child: InkWell(
                      onTap: () => _openEmployeesSheet(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppPalette.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_rounded, size: 15, color: AppPalette.primary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '$employeesCount əməkdaş${totalEmployeesCount > employeesCount ? ' ($totalEmployeesCount)' : ''}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Actions row (compact to never overflow)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Connections Button
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.account_tree_outlined, size: 17, color: Colors.indigo),
                        tooltip: 'Tabeçilik və Bağlantılar',
                        onPressed: () => _openConnectionsSheet(item),
                      ),

                      // Edit Button
                      if (canEdit)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 17, color: Colors.blue),
                          tooltip: 'Düzəliş et',
                          onPressed: () => _openStructureFormDialog(structure: item),
                        ),

                      // Delete Button
                      if (canDelete)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Colors.red),
                          tooltip: 'Sil',
                          onPressed: () => _confirmDelete(item),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================================================================
  // TAB 2: SXEM (EXECUTIVE DIAGRAM & HIERARCHY TREE)
  // Designed per Structur Maker Pro / GoPanel Web Executive Chart
  // =================================================================
  Widget _buildTreeView(bool isDark) {
    if (_diagramData == null && _treeData.isEmpty) {
      return const Center(child: Text('Təşkilat sxemi məlumatı tapılmadı'));
    }

    return Stack(
      children: [
        // Content: either Visual Executive Diagram or Hierarchy Tree
        _isDiagramView
            ? _buildExecutiveDiagramView(isDark)
            : _buildHierarchyListView(isDark),

        // Floating Control Toolbar in top right corner
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isDiagramView) ...[
                  // Zoom In
                  IconButton(
                    icon: const Icon(Icons.zoom_in_rounded, size: 20),
                    tooltip: 'Yaxınlaşdır',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      final current = _diagramTransformController.value;
                      _diagramTransformController.value = Matrix4.copy(current)..multiply(Matrix4.diagonal3Values(1.25, 1.25, 1.0));
                    },
                  ),
                  // Zoom Out
                  IconButton(
                    icon: const Icon(Icons.zoom_out_rounded, size: 20),
                    tooltip: 'Uzaqlaşdır',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      final current = _diagramTransformController.value;
                      _diagramTransformController.value = Matrix4.copy(current)..multiply(Matrix4.diagonal3Values(0.8, 0.8, 1.0));
                    },
                  ),
                  // Fit / Reset
                  IconButton(
                    icon: const Icon(Icons.fit_screen_rounded, size: 20),
                    tooltip: 'Mərkəzləşdir',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      _diagramTransformController.value = Matrix4.diagonal3Values(0.42, 0.42, 1.0);
                    },
                  ),
                  const SizedBox(
                    height: 18,
                    child: VerticalDivider(width: 12, thickness: 1),
                  ),
                ],
                // Toggle between Diagram and Hierarchy List
                InkWell(
                  onTap: () => setState(() => _isDiagramView = !_isDiagramView),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isDiagramView
                          ? const Color(0xFF203E70)
                          : AppPalette.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDiagramView ? Icons.view_quilt_rounded : Icons.account_tree_rounded,
                          size: 14,
                          color: _isDiagramView ? Colors.white : AppPalette.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isDiagramView ? 'Diaqram' : 'Siyahı',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isDiagramView ? Colors.white : AppPalette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =================================================================
  // STRUCTUR MAKER PRO: EXECUTIVE 2D DIAGRAM CANVAS
  // =================================================================
  Widget _buildExecutiveDiagramView(bool isDark) {
    final d = _diagramData ?? {};
    final tesisci = d['tesisci'] as Map<String, dynamic>?;
    final sura = d['sura'] as Map<String, dynamic>?;
    final saglamliq = d['saglamliq'] as Map<String, dynamic>?;
    final huquq = d['huquq'] as Map<String, dynamic>?;
    final deptRow1 = (d['departmentsRow1'] as List?) ?? [];
    final deptRow2 = (d['departmentsRow2'] as List?) ?? [];
    final direktor = d['direktor'] as Map<String, dynamic>?;
    final secDeputies = (d['sectionDeputies'] as List?) ?? [];
    final sharedUnits = (d['sharedUnits'] as List?) ?? [];
    final telim = d['telimDeputy'] as Map<String, dynamic>?;
    final usaqBirliyi = d['usaqBirliyi'] as Map<String, dynamic>?;
    final metodbirlesme = d['metodbirlesme'] as Map<String, dynamic>?;
    final subjRow1 = (d['subjectsRow1'] as List?) ?? [];
    final subjRow2 = (d['subjectsRow2'] as List?) ?? [];
    final bottomSpec = (d['bottomSpecialists'] as List?) ?? [];

    return InteractiveViewer(
      transformationController: _diagramTransformController,
      boundaryMargin: const EdgeInsets.all(800),
      minScale: 0.15,
      maxScale: 2.5,
      constrained: false,
      child: Container(
        width: 1480,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 60),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF203E70).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF203E70).withValues(alpha: 0.2)),
              ),
              child: const Text(
                '“İDRAK” LİSEYİNİN STRUKTUR CƏDVƏLİ',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Color(0xFF203E70),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ROOT LEVEL: TƏSİSÇİ
            _buildDiagramNavyCard(
              data: tesisci,
              fallbackTitle: 'Təsisçi',
              subtitle: 'Ali idarəetmə və strateji rəhbərlik',
              width: 320,
            ),

            // Root Stem Down
            _buildStemVertical(height: 20),

            // Horizontal Split Bar between Left Wing and Right Wing
            _buildHorizontalLine(width: 760),

            // Connectors dropping into Left and Right Wings
            SizedBox(
              width: 760,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStemVertical(height: 20),
                  _buildStemVertical(height: 20),
                ],
              ),
            ),

            // TWO MAIN WINGS ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // =========================================================
                // LEFT WING: STRATEGİYA VƏ İNKİŞAF ŞURASI
                // =========================================================
                SizedBox(
                  width: 680,
                  child: Column(
                    children: [
                      // Sura Header
                      _buildDiagramNavyCard(
                        data: sura,
                        fallbackTitle: 'Strategiya və inkişaf şurası',
                        width: 300,
                      ),
                      _buildStemVertical(height: 16),

                      // Support Staff Row (Tibb Məntəqəsi & Hüquqşünas)
                      _buildHorizontalLine(width: 340),
                      SizedBox(
                        width: 340,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStemVertical(height: 12),
                            _buildStemVertical(height: 12),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDiagramWhiteCard(
                            data: saglamliq,
                            fallbackTitle: 'Tibb Məntəqəsi',
                            width: 160,
                          ),
                          const SizedBox(width: 20),
                          _buildDiagramWhiteCard(
                            data: huquq,
                            fallbackTitle: 'Hüquqşünas',
                            width: 160,
                          ),
                        ],
                      ),
                      _buildStemVertical(height: 20),

                      // 8 Departments Block (2 rows of 4 columns)
                      _buildDepartmentGridRow(deptRow1),
                      const SizedBox(height: 18),
                      _buildDepartmentGridRow(deptRow2),
                    ],
                  ),
                ),

                // Vertical Divider between Wings
                Container(
                  width: 1.5,
                  height: 720,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFCBD5E1),
                        Color(0xFF94A3B8),
                        Color(0xFFCBD5E1),
                      ],
                    ),
                  ),
                ),

                // =========================================================
                // RIGHT WING: DİREKTOR & AKADEMİK QURUM
                // =========================================================
                SizedBox(
                  width: 680,
                  child: Column(
                    children: [
                      // Direktor Header
                      _buildDiagramNavyCard(
                        data: direktor,
                        fallbackTitle: 'Direktor',
                        subtitle: 'İcraedici rəhbər',
                        width: 300,
                      ),
                      _buildStemVertical(height: 16),

                      // Deputies Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3 Section Deputies cluster
                          Column(
                            children: [
                              Row(
                                children: [
                                  for (int i = 0; i < secDeputies.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    _buildDiagramDepartmentCard(
                                      data: secDeputies[i] is Map<String, dynamic>
                                          ? secDeputies[i] as Map<String, dynamic>
                                          : Map<String, dynamic>.from(secDeputies[i] as Map),
                                      fallbackTitle: 'Direktor müavini',
                                      width: 125,
                                    ),
                                  ],
                                ],
                              ),
                              _buildStemVertical(height: 10),
                              // Shared Units Bracket
                              _buildHorizontalLine(width: 260),
                              SizedBox(
                                width: 260,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStemVertical(height: 10),
                                    _buildStemVertical(height: 10),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  for (int i = 0; i < sharedUnits.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    _buildDiagramWhiteCard(
                                      data: sharedUnits[i] is Map<String, dynamic>
                                          ? sharedUnits[i] as Map<String, dynamic>
                                          : Map<String, dynamic>.from(sharedUnits[i] as Map),
                                      fallbackTitle: 'Tədris vahidi',
                                      width: 125,
                                      isBold: true,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // 4th Deputy: Təlim-tərbiyə
                          Column(
                            children: [
                              _buildDiagramDepartmentCard(
                                data: telim,
                                fallbackTitle: 'Direktor müavini',
                                width: 135,
                              ),
                              _buildStemVertical(height: 10),
                              _buildDiagramWhiteCard(
                                data: usaqBirliyi,
                                fallbackTitle: 'Uşaq Birliyi',
                                width: 135,
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildStemVertical(height: 20),

                      // Metodbirləşmə Header
                      _buildDiagramNavyCard(
                        data: metodbirlesme,
                        fallbackTitle: 'Metodbirləşmə Rəhbəri',
                        width: 280,
                      ),
                      _buildStemVertical(height: 16),

                      // 8 Subject Departments Grid (2 rows of 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < subjRow1.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            _buildDiagramWhiteCard(
                              data: subjRow1[i] is Map<String, dynamic>
                                  ? subjRow1[i] as Map<String, dynamic>
                                  : Map<String, dynamic>.from(subjRow1[i] as Map),
                              fallbackTitle: 'Fənn kafedrası',
                              width: 155,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < subjRow2.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            _buildDiagramWhiteCard(
                              data: subjRow2[i] is Map<String, dynamic>
                                  ? subjRow2[i] as Map<String, dynamic>
                                  : Map<String, dynamic>.from(subjRow2[i] as Map),
                              fallbackTitle: 'Fənn kafedrası',
                              width: 155,
                            ),
                          ],
                        ],
                      ),
                      _buildStemVertical(height: 20),

                      // Bottom Specialists
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < bottomSpec.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            _buildDiagramWhiteCard(
                              data: bottomSpec[i] is Map<String, dynamic>
                                  ? bottomSpec[i] as Map<String, dynamic>
                                  : Map<String, dynamic>.from(bottomSpec[i] as Map),
                              fallbackTitle: 'Mütəxəssis',
                              width: 205,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentGridRow(List<dynamic> depts) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < depts.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _buildDepartmentColumn(
            depts[i] is Map<String, dynamic>
                ? depts[i] as Map<String, dynamic>
                : Map<String, dynamic>.from(depts[i] as Map),
          ),
        ],
      ],
    );
  }

  Widget _buildDepartmentColumn(Map<String, dynamic> dept) {
    final rawSubunits = dept['subunits'];
    final subunits = (rawSubunits is List) ? rawSubunits : [];

    return SizedBox(
      width: 158,
      child: Column(
        children: [
          _buildDiagramDepartmentCard(
            data: dept,
            fallbackTitle: 'Departament',
            width: 158,
          ),
          if (subunits.isNotEmpty) ...[
            _buildStemVertical(height: 8),
            for (final sub in subunits) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildDiagramWhiteCard(
                  data: sub is Map<String, dynamic>
                      ? sub
                      : (sub is Map ? Map<String, dynamic>.from(sub) : null),
                  fallbackTitle: (sub is Map ? sub['title'] : sub).toString(),
                  width: 158,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDiagramNavyCard({
    required Map<String, dynamic>? data,
    required String fallbackTitle,
    String? subtitle,
    double width = 280,
  }) {
    final title = data?['title']?.toString() ?? fallbackTitle;
    final empCount = (data?['employees_count'] as num? ?? 0).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (data != null) {
            _openEmployeesSheet(data);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF203E70),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF203E70), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF203E70).withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$empCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD9E2F3),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagramDepartmentCard({
    required Map<String, dynamic>? data,
    required String fallbackTitle,
    double width = 155,
  }) {
    final title = data?['title']?.toString() ?? fallbackTitle;
    final empCount = (data?['employees_count'] as num? ?? 0).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (data != null) {
            _openEmployeesSheet(data);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB8CBEA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF557CB8), width: 1.2),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Color(0xFF14243D),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF557CB8).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$empCount',
                    style: const TextStyle(
                      color: Color(0xFF14243D),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiagramWhiteCard({
    required Map<String, dynamic>? data,
    required String fallbackTitle,
    double width = 155,
    bool isBold = false,
  }) {
    final title = data?['title']?.toString() ?? fallbackTitle;
    final empCount = (data?['employees_count'] as num? ?? 0).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (data != null) {
            _openEmployeesSheet(data);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF557CB8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: const Color(0xFF14243D),
                      fontSize: 9.5,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($empCount)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStemVertical({
    double height = 20,
    Color color = const Color(0xFF557CB8),
    double width = 2,
  }) {
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }

  Widget _buildHorizontalLine({
    required double width,
    Color color = const Color(0xFF557CB8),
    double height = 2,
  }) {
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }

  // =================================================================
  // SAFE HIERARCHICAL RECURSIVE SXEM (NO OVERFLOWS)
  // =================================================================
  Widget _buildHierarchyListView(bool isDark) {
    if (_treeData.isEmpty) {
      return const Center(child: Text('Təşkilat sxemi məlumatı tapılmadı'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Tree Info Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu siyahı rəhbərlikdən departamentlərə və alt şöbələrə qədər canlı iyerarxik tabeçiliyi əks etdirir.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recursive tree rendering
        ..._treeData.map((node) => _buildTreeNodeWidget(node, 0, isDark)),
      ],
    );
  }

  Widget _buildTreeNodeWidget(Map<String, dynamic> node, int depth, bool isDark) {
    final title = node['title'] ?? 'Adsız';
    final code = node['code'] ?? '';
    final typeLabel = node['type_label'] ?? 'Bölmə';
    final employeesCount = (node['employees_count'] as num? ?? 0).toInt();
    final children = (node['children'] as List?) ?? [];
    final hasChildren = children.isNotEmpty;

    // Single step indentation (10px) to prevent right overflow on nested hierarchy
    final double leftIndent = depth == 0 ? 0.0 : (depth > 3 ? 4.0 : 10.0);

    return Padding(
      padding: EdgeInsets.only(left: leftIndent, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernCard(
            child: InkWell(
              onTap: () => _openEmployeesSheet(node),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Node icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: depth == 0
                            ? Colors.purple.withValues(alpha: 0.15)
                            : AppPalette.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        depth == 0 ? Icons.business_center_rounded : Icons.account_tree_rounded,
                        size: 15,
                        color: depth == 0 ? Colors.purple : AppPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (code.isNotEmpty) ...[
                                Text(
                                  code,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  typeLabel,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Staff Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: employeesCount > 0
                            ? AppColors.success.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 12,
                            color: employeesCount > 0 ? AppColors.success : Colors.grey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$employeesCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: employeesCount > 0 ? AppColors.success : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Render Children
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children
                    .map((childNode) => _buildTreeNodeWidget(childNode, depth + 1, isDark))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // =================================================================
  // TAB 3: OVERVIEW & STATS VIEW
  // =================================================================
  Widget _buildOverviewView(bool isDark) {
    int departmentsCount = 0;
    int adminCount = 0;
    int branchesCount = 0;
    int metodistCount = 0;

    for (final s in _allStructures) {
      final t = (s['type_of_structure'] ?? '').toString().toUpperCase();
      if (t == 'DEPARTMENT') {
        departmentsCount++;
      } else if (t == 'ADMINISTRATION') {
        adminCount++;
      } else if (t == 'BRANCH') {
        branchesCount++;
      } else if (t == 'METODIST') {
        metodistCount++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Hero Gradient Card
        ModernCard(
          gradient: LinearGradient(
            colors: [
              AppPalette.primary.withValues(alpha: 0.9),
              AppPalette.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İdrak Təhsil Kompleksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Təşkilati İdarəetmə Aparatı',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroStat('${_allStructures.length}', 'Cəmi Struktur'),
                    Container(width: 1, height: 35, color: Colors.white24),
                    _buildHeroStat('$_totalStaffCount', 'Aktiv Əməkdaş'),
                    Container(width: 1, height: 35, color: Colors.white24),
                    _buildHeroStat('$departmentsCount', 'Departament'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Struktur Növləri Üzrə Bölgü',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _buildStatTile(
          icon: Icons.domain_rounded,
          color: Colors.blue,
          title: 'Departamentlər',
          subtitle: 'Akademik, Maliyyə, IT, Təsərrüfat və digər əsas bölmələr',
          count: departmentsCount,
        ),
        _buildStatTile(
          icon: Icons.admin_panel_settings_rounded,
          color: Colors.purple,
          title: 'Rəhbərlik & İnzibati Aparat',
          subtitle: 'Direktorluq, Təsisçilər Şurası, Müavinlər',
          count: adminCount,
        ),
        _buildStatTile(
          icon: Icons.location_city_rounded,
          color: Colors.teal,
          title: 'Filiallar və Korpuslar',
          subtitle: 'Bakı və Sumqayıt filialları',
          count: branchesCount,
        ),
        _buildStatTile(
          icon: Icons.school_rounded,
          color: Colors.amber.shade800,
          title: 'Metodbirləşmələr və Kafedralar',
          subtitle: 'Fənn kafedraları və metodik mərkəzlər',
          count: metodistCount,
        ),

        const SizedBox(height: 20),
        const Text(
          'Ən Çox Heyəti Olan Departamentlər',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...(_allStructures.toList()
              ..sort((a, b) => ((b['employees_count'] as num? ?? 0))
                  .compareTo((a['employees_count'] as num? ?? 0))))
            .take(5)
            .map((s) {
          final count = (s['employees_count'] as num? ?? 0).toInt();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ModernCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppPalette.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.people_rounded, color: AppPalette.primary, size: 20),
                ),
                title: Text(
                  s['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  s['type_label'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Text(
                  '$count nəfər',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.primary,
                    fontSize: 13,
                  ),
                ),
                onTap: () => _openEmployeesSheet(s),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// SUB-SHEET 1: STRUCTURE EMPLOYEES (Web _employee_list_modal_content)
// ===================================================================
class _StructureEmployeesSheet extends StatefulWidget {
  final int structureId;
  final String structureTitle;

  const _StructureEmployeesSheet({
    required this.structureId,
    required this.structureTitle,
  });

  @override
  State<_StructureEmployeesSheet> createState() => _StructureEmployeesSheetState();
}

class _StructureEmployeesSheetState extends State<_StructureEmployeesSheet> {
  bool _isLoading = true;
  bool _includeInactive = false;
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final res = await SchoolApiService.instance.fetchHrStructureEmployees(
      widget.structureId,
      includeInactive: _includeInactive,
    );
    if (mounted) {
      setState(() {
        if (res != null && res['employees'] is List) {
          _employees = List<Map<String, dynamic>>.from(res['employees']);
        } else {
          _employees = [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: AppPalette.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.structureTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_employees.length} əməkdaş müqaviləsi',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Switch: Passiv müqavilələri göstər (Web Parity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Passiv müqavilələri göstər',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Switch.adaptive(
                      value: _includeInactive,
                      onChanged: (val) {
                        setState(() => _includeInactive = val);
                        _fetch();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _employees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'Bu strukturda əməkdaş tapılmadı',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _employees.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final emp = _employees[index];
                            final name = emp['name'] ?? '-';
                            final fin = emp['fin_code'] ?? '-';
                            final position = emp['position'] ?? '-';
                            final status = emp['contract_status'] ?? 'active';
                            final isActive = status == 'active';

                            return ModernCard(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isActive
                                      ? AppPalette.primary.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: isActive ? AppPalette.primary : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      position,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      'FİN: $fin',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktiv' : 'Deaktiv',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? AppColors.success : Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// SUB-SHEET 2: CONNECTIONS MANAGER (Web _connections_modal)
// ===================================================================
class _StructureConnectionsSheet extends StatefulWidget {
  final int structureId;
  final VoidCallback onChanged;

  const _StructureConnectionsSheet({
    required this.structureId,
    required this.onChanged,
  });

  @override
  State<_StructureConnectionsSheet> createState() => _StructureConnectionsSheetState();
}

class _StructureConnectionsSheetState extends State<_StructureConnectionsSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  int? _selectedTargetParentId;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final res = await SchoolApiService.instance.fetchHrStructureConnections(widget.structureId);
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _attachParent(String mode) async {
    if (_selectedTargetParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa üst struktur seçin')),
      );
      return;
    }
    final res = await SchoolApiService.instance.attachHrStructureParent(
      widget.structureId,
      parentId: _selectedTargetParentId,
      mode: mode,
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı uğurla yeniləndi'), backgroundColor: AppColors.success),
      );
      widget.onChanged();
      _fetch();
    }
  }

  Future<void> _makeRoot() async {
    final res = await SchoolApiService.instance.attachHrStructureParent(
      widget.structureId,
      parentId: 0,
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struktur kök səviyyəyə keçirildi'), backgroundColor: AppColors.success),
      );
      widget.onChanged();
      _fetch();
    }
  }

  Future<void> _detachParent(int parentId) async {
    final res = await SchoolApiService.instance.detachHrStructureParent(
      widget.structureId,
      parentId,
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Əlaqə kəsildi'), backgroundColor: Colors.orange),
      );
      widget.onChanged();
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final structureInfo = _data?['structure'] as Map<String, dynamic>?;
    final parents = (_data?['parents'] as List?) ?? [];
    final available = (_data?['available'] as List?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(Icons.account_tree_rounded, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          structureInfo?['title'] ?? 'Struktur Bağlantıları',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),

                  // SECTION 1: Mövcud Üst Tabeçilik
                  const Text(
                    'Mövcud Üst Strukturlar (Valideynlər)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  if (parents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Bu struktur hazırda kök səviyyədədir (Üst bağ yoxdur)',
                            style: TextStyle(fontSize: 12, color: Colors.amber),
                          ),
                        ],
                      ),
                    )
                  else
                    ...parents.map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.link_rounded, color: Colors.blue),
                          title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p['code'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.link_off_rounded, color: Colors.red),
                            tooltip: 'Əlaqəni kəs',
                            onPressed: () => _detachParent((p['id'] as num).toInt()),
                          ),
                        )),

                  const SizedBox(height: 20),
                  const Divider(),

                  // SECTION 2: Yeni Üst Struktur Seç və Bağla
                  const Text(
                    'Yeni Üst Struktur Bağla',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qeyd: Dövrü asılılıq yarada biləcək alt strukturlar avtomatik gizlədilib.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedTargetParentId,
                    decoration: InputDecoration(
                      labelText: 'Üst Struktur Seçin',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: available.map<DropdownMenuItem<int>>((item) {
                      final pId = (item['id'] as num).toInt();
                      final pTitle = item['title'] ?? '';
                      final isParent = item['is_parent'] == true;
                      return DropdownMenuItem<int>(
                        value: pId,
                        child: Text(
                          isParent ? '$pTitle (Artıq bağlıdır)' : pTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(color: isParent ? Colors.grey : null),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTargetParentId = val),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add_link_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Əlavə Bağla (+)',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _attachParent('add'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Tək Dəyiş',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _attachParent('replace'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // SECTION 3: Kök Səviyyə
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.vertical_align_top_rounded),
                    label: const Text('Bütün üst bağları sil (Kök səviyyə et)'),
                    onPressed: _makeRoot,
                  ),
                ],
              ),
      ),
    );
  }
}

// ===================================================================
// SUB-SHEET 3: STRUCTURE FORM (Add / Edit Form Sheet)
// ===================================================================
class _StructureFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingStructure;
  final List<Map<String, dynamic>> allStructures;
  final VoidCallback onSaved;

  const _StructureFormSheet({
    this.existingStructure,
    required this.allStructures,
    required this.onSaved,
  });

  @override
  State<_StructureFormSheet> createState() => _StructureFormSheetState();
}

class _StructureFormSheetState extends State<_StructureFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _descController;

  String _type = 'DEPARTMENT';
  bool _isActive = true;
  List<int> _selectedParentIds = [];
  int? _showOnDocumentsId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingStructure;
    _titleController = TextEditingController(text: item?['title'] ?? '');
    _codeController = TextEditingController(text: item?['code'] ?? '');
    _descController = TextEditingController(text: item?['description'] ?? '');

    if (item != null) {
      _type = (item['type_of_structure'] ?? 'DEPARTMENT').toString();
      _isActive = item['is_active'] == true;
      _showOnDocumentsId = item['show_on_documents_id'] != null
          ? (item['show_on_documents_id'] as num).toInt()
          : null;

      if (item['parents'] is List) {
        _selectedParentIds = (item['parents'] as List)
            .map((p) => (p['id'] as num).toInt())
            .toList();
      } else if (item['parent_id'] != null) {
        _selectedParentIds = [(item['parent_id'] as num).toInt()];
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'code': _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
      'type_of_structure': _type,
      'is_active': _isActive,
      'parent_ids': _selectedParentIds,
      if (_selectedParentIds.isNotEmpty) 'parent_id': _selectedParentIds.first,
      if (_showOnDocumentsId != null) 'show_on_documents_id': _showOnDocumentsId,
    };

    try {
      if (widget.existingStructure != null) {
        final id = (widget.existingStructure!['id'] as num).toInt();
        await SchoolApiService.instance.updateHrStructure(id, payload);
      } else {
        await SchoolApiService.instance.createHrStructure(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingStructure != null
                ? 'Struktur uğurla yeniləndi'
                : 'Yeni struktur uğurla yaradıldı'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta baş verdi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStructure != null;
    final availableParents = widget.allStructures.where((s) {
      if (!isEditing) return true;
      return (s['id'] as num).toInt() != (widget.existingStructure!['id'] as num).toInt();
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                    color: AppPalette.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Strukturu Redaktə Et' : 'Yeni Struktur Əlavə Et',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Title (Adı)
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Strukturun Adı *',
                  hintText: 'Məs: İnformasiya Texnologiyaları Şöbəsi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Struktur adı daxil edilməlidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Code (Kod)
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Unikal Kod',
                  hintText: 'Boş buraxsanız avtomatik yaranacaq (STR-...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Description (Təsvir)
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Təsvir / Qeyd',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Type of Structure Dropdown
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: 'Struktur Növü *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'DEPARTMENT', child: Text('Departament (Şöbə)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'ADMINISTRATION', child: Text('Rəhbərlik (İnzibati)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'BRANCH', child: Text('Filial (Korpus)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'METODIST', child: Text('Metodbirləşmə (Kafedra)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 14),

              // Parent Structures selector
              const Text(
                'Üst Tabeçilik (Valideyn Struktur)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Bu strukturun tabe olduğu şöbələri seçin (çoxlu seçim dəstəklənir)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  title: Text(
                    _selectedParentIds.isEmpty
                        ? 'Üst struktur seçin (Kök səviyyə)'
                        : '${_selectedParentIds.length} üst struktur seçilib',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedParentIds.isEmpty ? Colors.grey : AppPalette.primary,
                    ),
                  ),
                  children: availableParents.map((parent) {
                    final pId = (parent['id'] as num).toInt();
                    final isSelected = _selectedParentIds.contains(pId);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      title: Text(parent['title'] ?? '', overflow: TextOverflow.ellipsis, maxLines: 1),
                      subtitle: Text(parent['code'] ?? '', style: const TextStyle(fontSize: 11)),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedParentIds.add(pId);
                          } else {
                            _selectedParentIds.remove(pId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Show on documents ID selector (isExpanded & ellipsis to prevent 215px overflow)
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _showOnDocumentsId,
                decoration: InputDecoration(
                  labelText: 'Sənədlərdə Görünəcək Struktur (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Öz adı çıxsın'),
                  ),
                  ...availableParents.map((s) => DropdownMenuItem<int>(
                        value: (s['id'] as num).toInt(),
                        child: Text(
                          s['title'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                ],
                onChanged: (val) => setState(() => _showOnDocumentsId = val),
              ),
              const SizedBox(height: 14),

              // Active switch
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Status: Aktiv', style: TextStyle(fontWeight: FontWeight.bold)),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Yadda Saxla' : 'Strukturu Yarat',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
