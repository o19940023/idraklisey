import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';

class StaffingTablesScreen extends StatefulWidget {
  const StaffingTablesScreen({super.key});

  @override
  State<StaffingTablesScreen> createState() => _StaffingTablesScreenState();
}

class _StaffingTablesScreenState extends State<StaffingTablesScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStaffUnits = [];
  List<Map<String, dynamic>> _filteredStaffUnits = [];
  Map<String, dynamic>? _summary;

  List<Map<String, dynamic>> _structures = [];
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _filials = [];

  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, VACANT, FULL
  int? _selectedFilialFilter;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SchoolApiService.instance.fetchHrStaffingTables(all: true),
        SchoolApiService.instance.fetchHrStaffingTablesSummary(),
        SchoolApiService.instance.fetchHrStructures(all: true),
        SchoolApiService.instance.fetchHrPositions(all: true),
        SchoolApiService.instance.fetchFilials(),
      ]);

      if (mounted) {
        setState(() {
          _allStaffUnits = results[0] as List<Map<String, dynamic>>;
          _summary = results[1] as Map<String, dynamic>?;
          _structures = results[2] as List<Map<String, dynamic>>;
          _positions = results[3] as List<Map<String, dynamic>>;
          _filials = results[4] as List<Map<String, dynamic>>;
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
      _filteredStaffUnits = _allStaffUnits.where((u) {
        final code = (u['code'] ?? '').toString().toLowerCase();
        final structure = (u['structure_title'] ?? '').toString().toLowerCase();
        final position = (u['position_title'] ?? '').toString().toLowerCase();
        final filial = (u['filial_name'] ?? '').toString().toLowerCase();

        final matchesQuery = query.isEmpty ||
            code.contains(query) ||
            structure.contains(query) ||
            position.contains(query) ||
            filial.contains(query);

        if (!matchesQuery) return false;

        if (_selectedFilialFilter != null) {
          final fId = (u['filial_id'] as num?)?.toInt();
          if (fId != _selectedFilialFilter) return false;
        }

        final vacantCount = (u['vacant_count'] as num? ?? 0).toInt();

        switch (_selectedFilter) {
          case 'VACANT':
            return vacantCount > 0;
          case 'FULL':
            return vacantCount == 0;
          case 'ALL':
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final id = (item['id'] as num).toInt();
    final posTitle = item['position_title'] ?? 'Ştat';
    final occupied = (item['occupied_count'] as num? ?? 0).toInt();

    if (occupied > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Silmək mümkün deyil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Bu ştat vahidində $occupied aktiv əməkdaş çalışır. Əvvəlcə əməkdaşların vəzifəsini və ya strukturunu dəyişin.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anladım', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ştat Vahidini Sil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('"$posTitle" ştat vahidini silmək istədiyinizə əminsiniz?'),
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
      final success = await SchoolApiService.instance.deleteHrStaffingTable(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ştat vahidi uğurla silindi'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadAll();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Silinmə zamanı xəta baş verdi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _openFormSheet({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StaffUnitFormSheet(
        existingItem: item,
        structures: _structures,
        positions: _positions,
        filials: _filials,
        onSaved: _loadAll,
      ),
    );
  }

  void _openEmployeesSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StaffUnitEmployeesSheet(staffUnit: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalUnits = _summary?['total_staff_units'] ?? _allStaffUnits.fold<int>(0, (s, u) => s + (u['count'] as num? ?? 0).toInt());
    final totalOccupied = _summary?['total_occupied'] ?? _allStaffUnits.fold<int>(0, (s, u) => s + (u['occupied_count'] as num? ?? 0).toInt());
    final totalVacant = _summary?['total_vacant'] ?? _allStaffUnits.fold<int>(0, (s, u) => s + (u['vacant_count'] as num? ?? 0).toInt());
    final occupancyRate = _summary?['occupancy_rate'] ?? (totalUnits > 0 ? ((totalOccupied / totalUnits) * 100).round() : 0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ştat Cədvəli',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Müəssisə üzrə ştat vahidləri və vakansiyaların idarə edilməsi',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenilə',
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
            tooltip: 'Yeni Ştat Vahidi',
            onPressed: () => _openFormSheet(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF203E70),
        onPressed: () => _openFormSheet(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Ştat Vahidi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: Column(
          children: [
            // Executive Summary Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // 4 Summary Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Ümumi Ştat',
                          value: '$totalUnits',
                          icon: Icons.pie_chart_outline_rounded,
                          color: const Color(0xFF2563EB),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Dolu Ştat',
                          value: '$totalOccupied',
                          icon: Icons.people_alt_outlined,
                          color: Colors.teal,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Vakant Yer',
                          value: '$totalVacant',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Doluluq',
                          value: '$occupancyRate%',
                          icon: Icons.show_chart_rounded,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search input
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Struktur, vəzifə və ya filial üzrə axtar...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Filter Chips & Branch dropdown
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Hamısı (${_allStaffUnits.length})', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Vakant Olanlar', 'VACANT'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Tam Dolu', 'FULL'),
                        const SizedBox(width: 12),

                        // Branch Filter Dropdown
                        if (_filials.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedFilialFilter != null
                                    ? AppPalette.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                isDense: true,
                                value: _selectedFilialFilter,
                                hint: const Text('Bütün filiallar', style: TextStyle(fontSize: 11.5)),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Bütün filiallar', style: TextStyle(fontSize: 11.5)),
                                  ),
                                  ..._filials.map((f) => DropdownMenuItem<int?>(
                                        value: (f['id'] as num).toInt(),
                                        child: Text(
                                          f['name'] ?? '',
                                          style: const TextStyle(fontSize: 11.5),
                                        ),
                                      )),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedFilialFilter = val;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStaffUnits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Uyğun ştat vahidi tapılmadı',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Axtarış və ya filial filtrini dəyişin',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                          itemCount: _filteredStaffUnits.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final unit = _filteredStaffUnits[index];
                            return _buildStaffUnitCard(unit, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = key;
          _applyFilters();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF203E70)
              : Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffUnitCard(Map<String, dynamic> unit, bool isDark) {
    final code = unit['code'] ?? '';
    final filial = unit['filial_name'] ?? '-';
    final structure = unit['structure_title'] ?? '-';
    final position = unit['position_title'] ?? '-';

    final count = (unit['count'] as num? ?? 1).toInt();
    final occupied = (unit['occupied_count'] as num? ?? 0).toInt();
    final vacant = (unit['vacant_count'] as num? ?? 0).toInt();
    final percent = (unit['occupancy_percentage'] as num? ?? 0).toInt();

    final date = unit['date'] ?? '';
    final startDate = unit['start_date'] ?? '';
    final endDate = unit['end_date'] ?? '';

    final hasVacant = vacant > 0;

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badges Row: Code, Filial, Vacancy Status
            Row(
              children: [
                if (code.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF203E70).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF203E70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Filial Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: Colors.blue),
                      const SizedBox(width: 3),
                      Text(
                        filial,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Vacancy Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasVacant
                        ? AppColors.success.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasVacant
                          ? AppColors.success.withValues(alpha: 0.3)
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasVacant ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
                        size: 11,
                        color: hasVacant ? AppColors.success : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasVacant ? '$vacant vakant yer' : 'Tam doludur',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: hasVacant ? AppColors.success : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Structure label (subtle uppercase)
            Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    structure,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Position Main Title
            Text(
              position,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 12),

            // Occupancy Linear Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$occupied / $count ştat vahidi tutulub',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasVacant ? Colors.orange.shade800 : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: count > 0 ? (occupied / count).clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent >= 100
                          ? AppColors.success
                          : (percent > 0 ? Colors.orange : Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Dates info: Date, Start Date, End Date
            Row(
              children: [
                if (date.isNotEmpty) ...[
                  Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text('Əmr: $date', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                  const SizedBox(width: 10),
                ],
                if (startDate.isNotEmpty) ...[
                  Icon(Icons.play_arrow_rounded, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text('Qüvvədədir: $startDate', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                  const SizedBox(width: 10),
                ],
                if (endDate.isNotEmpty) ...[
                  Icon(Icons.stop_rounded, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text('Bitmə: $endDate', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                ],
              ],
            ),

            const Divider(height: 18),

            // Bottom Actions: Employees button & Edit/Delete
            Row(
              children: [
                // Employees Action Button (Flexible to prevent right overflow)
                Flexible(
                  child: InkWell(
                    onTap: () => _openEmployeesSheet(unit),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppPalette.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_rounded, size: 16, color: AppPalette.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$occupied əməkdaş',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 12,
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

                // Compact Edit & Delete Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      tooltip: 'Düzəliş et',
                      onPressed: () => _openFormSheet(item: unit),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      tooltip: 'Sil',
                      onPressed: () => _confirmDelete(unit),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// STAFF UNIT FORM SHEET (ADD / EDIT)
// Web Parity: form.blade.php
// =================================================================

class _StaffUnitFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final List<Map<String, dynamic>> structures;
  final List<Map<String, dynamic>> positions;
  final List<Map<String, dynamic>> filials;
  final VoidCallback onSaved;

  const _StaffUnitFormSheet({
    this.existingItem,
    required this.structures,
    required this.positions,
    required this.filials,
    required this.onSaved,
  });

  @override
  State<_StaffUnitFormSheet> createState() => _StaffUnitFormSheetState();
}

class _StaffUnitFormSheetState extends State<_StaffUnitFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _dateController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _countController;

  int? _selectedStructureId;
  int? _selectedPositionId;
  int? _selectedFilialId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _codeController = TextEditingController(text: item?['code'] ?? '');
    _dateController = TextEditingController(
      text: item?['date'] ?? DateTime.now().toString().substring(0, 10),
    );
    _startDateController = TextEditingController(
      text: item?['start_date'] ?? DateTime.now().toString().substring(0, 10),
    );
    _endDateController = TextEditingController(text: item?['end_date'] ?? '');
    _countController = TextEditingController(text: (item?['count'] ?? 1).toString());

    _selectedStructureId = item?['structure_id'] as int?;
    _selectedPositionId = item?['position_id'] as int?;
    _selectedFilialId = item?['filial_id'] as int?;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _dateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      controller.text = '$y-$m-$d';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStructureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Zəhmət olmasa struktur seçin'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedPositionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Zəhmət olmasa vəzifə seçin'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedFilialId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Zəhmət olmasa filial seçin'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'code': _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      'date': _dateController.text.trim(),
      'start_date': _startDateController.text.trim(),
      'end_date': _endDateController.text.trim().isEmpty ? null : _endDateController.text.trim(),
      'count': int.tryParse(_countController.text.trim()) ?? 1,
      'structure_id': _selectedStructureId,
      'position_id': _selectedPositionId,
      'filial_id': _selectedFilialId,
    };

    try {
      final isEdit = widget.existingItem != null;
      final id = widget.existingItem?['id'] as int?;

      Map<String, dynamic>? res;
      if (isEdit && id != null) {
        res = await SchoolApiService.instance.updateHrStaffingTable(id, payload);
      } else {
        res = await SchoolApiService.instance.createHrStaffingTable(payload);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (res != null) {
          Navigator.pop(context);
          widget.onSaved();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit ? 'Ştat vahidi məlumatları yeniləndi' : 'Yeni ştat vahidi yaradıldı',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Yadda saxlama zamanı xəta baş verdi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xəta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: const Color(0xFF203E70),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'Ştat Vahidini Redaktə Et' : 'Yeni Ştat Vahidi',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // Code
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Unikal Kod (Opsional)',
                      hintText: 'Boş qoysanız avtomatik veriləcək (İDR-STF...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // =========================================================
                  // STRUKTUR VƏ VƏZİFƏ PARAMETRLƏRİ
                  // =========================================================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.business_center_rounded, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text(
                              'Struktur və Təyinat',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filial Dropdown (isExpanded: true to prevent overflow)
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _selectedFilialId,
                          decoration: InputDecoration(
                            labelText: 'Filial *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: widget.filials.map((f) {
                            return DropdownMenuItem<int>(
                              value: (f['id'] as num).toInt(),
                              child: Text(
                                f['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedFilialId = val),
                          validator: (val) => val == null ? 'Filial seçin' : null,
                        ),
                        const SizedBox(height: 12),

                        // Structure Dropdown (isExpanded: true)
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _selectedStructureId,
                          decoration: InputDecoration(
                            labelText: 'Struktur (Şöbə) *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: widget.structures.map((s) {
                            return DropdownMenuItem<int>(
                              value: (s['id'] as num).toInt(),
                              child: Text(
                                s['title'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedStructureId = val),
                          validator: (val) => val == null ? 'Struktur seçin' : null,
                        ),
                        const SizedBox(height: 12),

                        // Position Dropdown (isExpanded: true)
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _selectedPositionId,
                          decoration: InputDecoration(
                            labelText: 'Vəzifə *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: widget.positions.map((p) {
                            return DropdownMenuItem<int>(
                              value: (p['id'] as num).toInt(),
                              child: Text(
                                p['title'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedPositionId = val),
                          validator: (val) => val == null ? 'Vəzifə seçin' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =========================================================
                  // ƏMR VƏ SAY PARAMETRLƏRİ
                  // =========================================================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.format_list_numbered_rounded, size: 18, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Əmr və Say Parametrləri',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Count (Ştat vahidinin sayı)
                        TextFormField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Ştat vahidinin sayı *',
                            hintText: 'Məs: 1, 2, 5...',
                            suffixText: 'vahidi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Sayı daxil edin';
                            }
                            final num = int.tryParse(val.trim());
                            if (num == null || num < 1) {
                              return 'Ən az 1 olmalıdır';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Order Date (Əmr tarixi)
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _pickDate(_dateController),
                          decoration: InputDecoration(
                            labelText: 'Əmr tarixi *',
                            suffixIcon: const Icon(Icons.calendar_month_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Tarix seçin' : null,
                        ),
                        const SizedBox(height: 12),

                        // Start Date (Qüvvəyə minmə tarixi)
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: () => _pickDate(_startDateController),
                          decoration: InputDecoration(
                            labelText: 'Qüvvəyə minmə tarixi *',
                            suffixIcon: const Icon(Icons.calendar_month_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Tarix seçin' : null,
                        ),
                        const SizedBox(height: 12),

                        // End Date (Bitmə tarixi - opsional)
                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          onTap: () => _pickDate(_endDateController),
                          decoration: InputDecoration(
                            labelText: 'Bitmə tarixi (Opsional)',
                            hintText: 'Müddətsizdirsə boş saxlayın',
                            suffixIcon: _endDateController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _endDateController.clear()),
                                  )
                                : const Icon(Icons.calendar_month_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF203E70),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Dəyişiklikləri Saxla' : 'Ştat Vahidini Yarat',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

// =================================================================
// STAFF UNIT EMPLOYEES SHEET
// Shows active employees occupying this staff unit
// =================================================================

class _StaffUnitEmployeesSheet extends StatefulWidget {
  final Map<String, dynamic> staffUnit;

  const _StaffUnitEmployeesSheet({required this.staffUnit});

  @override
  State<_StaffUnitEmployeesSheet> createState() => _StaffUnitEmployeesSheetState();
}

class _StaffUnitEmployeesSheetState extends State<_StaffUnitEmployeesSheet> {
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
    final id = (widget.staffUnit['id'] as num).toInt();
    final res = await SchoolApiService.instance.fetchHrStaffingTableEmployees(
      id,
      includeInactive: _includeInactive,
    );

    if (mounted) {
      final list = (res?['employees'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _employees = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final structure = widget.staffUnit['structure_title'] ?? '-';
    final position = widget.staffUnit['position_title'] ?? '-';
    final count = widget.staffUnit['count'] ?? 1;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppPalette.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '$structure • Ştat: $count vahid',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
          const Divider(height: 1),

          // Inactive toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Text('Passiv müqavilələri də göstər:', style: TextStyle(fontSize: 11.5)),
                const Spacer(),
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

          // List
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
                            const Text(
                              'Bu ştat vahidində əməkdaş yoxdur (Vakantdır)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _employees.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final emp = _employees[index];
                          final name = emp['name'] ?? '-';
                          final fin = emp['fin_code'] ?? '-';
                          final filial = emp['filial'] ?? '';
                          final salary = (emp['gross_salary'] as num? ?? 0).toDouble();
                          final status = (emp['status'] ?? 'active').toString().toLowerCase();
                          final isActive = status == 'active';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isActive
                                      ? AppPalette.primary.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? AppPalette.primary : Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (fin.isNotEmpty && fin != '-') ...[
                                            Text(
                                              'FİN: $fin',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (filial.isNotEmpty)
                                            Flexible(
                                              child: Text(
                                                filial,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (salary > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Əməkhaqqı: ${salary.toStringAsFixed(2)} ₼',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.success.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktiv' : 'Passiv',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? AppColors.success : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
