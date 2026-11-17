import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';

class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allPositions = [];
  List<Map<String, dynamic>> _filteredPositions = [];
  bool _isLoading = true;

  // Filters: ALL, TEACHING, SERVANT, WORKER, ACTIVE
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    setState(() => _isLoading = true);
    try {
      final data = await SchoolApiService.instance.fetchHrPositions(all: true);
      if (mounted) {
        setState(() {
          _allPositions = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vəzifələr yüklənərkən xəta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredPositions = _allPositions.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final code = (p['code'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        final matchesQuery = query.isEmpty ||
            title.contains(query) ||
            code.contains(query) ||
            desc.contains(query);

        if (!matchesQuery) return false;

        final isTeaching = p['is_teaching_staff'] == true;
        final workerType = (p['worker_type'] ?? 'SERVANT').toString().toUpperCase();
        final isActive = p['is_active'] == true;

        switch (_selectedFilter) {
          case 'TEACHING':
            return isTeaching;
          case 'SERVANT':
            return workerType == 'SERVANT';
          case 'WORKER':
            return workerType == 'WORKER';
          case 'ACTIVE':
            return isActive;
          case 'ALL':
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> _toggleStatus(Map<String, dynamic> pos) async {
    final id = (pos['id'] as num).toInt();
    final currentStatus = pos['is_active'] == true;

    // Optimistic UI update
    setState(() {
      pos['is_active'] = !currentStatus;
    });

    final res = await SchoolApiService.instance.toggleHrPositionStatus(id);
    if (res == null) {
      // Revert if failed
      if (mounted) {
        setState(() {
          pos['is_active'] = currentStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Status dəyişdirilərkən xəta baş verdi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus
                  ? 'Vəzifə aktivləşdirildi'
                  : 'Vəzifə deaktiv edildi',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> pos) async {
    final id = (pos['id'] as num).toInt();
    final title = pos['title'] ?? 'Bu vəzifə';
    final employeesCount = (pos['employees_count'] as num? ?? 0).toInt();

    if (employeesCount > 0) {
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
            'Bu vəzifəyə bağlı $employeesCount aktiv əməkdaş müqaviləsi mövcuddur. Əvvəlcə əməkdaşların vəzifəsini dəyişin və ya müqavilələrə xitam verin.',
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
        title: const Text('Vəzifəni Sil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('"$title" vəzifəsini silmək istədiyinizə əminsiniz?'),
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
      final success = await SchoolApiService.instance.deleteHrPosition(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vəzifə uğurla silindi'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadPositions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Silinmə zamanı xəta baş verdi (bağlı məlumatlar ola bilər)'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _openPositionForm({Map<String, dynamic>? position}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PositionFormSheet(
        existingPosition: position,
        onSaved: _loadPositions,
      ),
    );
  }

  void _openEmployeesSheet(Map<String, dynamic> pos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PositionEmployeesSheet(position: pos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate Summary Stats
    final totalCount = _allPositions.length;
    final activeCount = _allPositions.where((p) => p['is_active'] == true).length;
    final teachingCount = _allPositions.where((p) => p['is_teaching_staff'] == true).length;
    final servantsCount = _allPositions.where((p) => (p['worker_type'] ?? '') == 'SERVANT').length;
    final workersCount = _allPositions.where((p) => (p['worker_type'] ?? '') == 'WORKER').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vəzifələr',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Təşkilati struktur üzrə vəzifələr və məzuniyyət normaları',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenilə',
            onPressed: _loadPositions,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
            tooltip: 'Yeni Vəzifə',
            onPressed: () => _openPositionForm(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF203E70),
        onPressed: () => _openPositionForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Vəzifə',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPositions,
        child: Column(
          children: [
            // Stats Header Banner
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
                        child: _buildStatItem(
                          label: 'Ümumi',
                          value: '$totalCount',
                          icon: Icons.badge_outlined,
                          color: const Color(0xFF2563EB),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Aktiv',
                          value: '$activeCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Pedaqoji',
                          value: '$teachingCount',
                          icon: Icons.school_outlined,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Qulluqçu/Fəhlə',
                          value: '$servantsCount/$workersCount',
                          icon: Icons.engineering_outlined,
                          color: const Color(0xFFF59E0B),
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
                      hintText: 'Vəzifə adı və ya kodu üzrə axtar...',
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

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Hamısı ($totalCount)', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pedaqoji ($teachingCount)', 'TEACHING'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Qulluqçu ($servantsCount)', 'SERVANT'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Fəhlə ($workersCount)', 'WORKER'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Yalnız Aktivlər ($activeCount)', 'ACTIVE'),
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
                  : _filteredPositions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Uyğun vəzifə tapılmadı',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Axtarış və ya filter meyarlarını dəyişin',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                          itemCount: _filteredPositions.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final pos = _filteredPositions[index];
                            return _buildPositionCard(pos, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
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

  Widget _buildPositionCard(Map<String, dynamic> pos, bool isDark) {
    final title = pos['title'] ?? '-';
    final code = pos['code'] ?? '';
    final desc = pos['description'] ?? '';
    final isActive = pos['is_active'] == true;
    final isTeaching = pos['is_teaching_staff'] == true;
    final workerType = (pos['worker_type'] ?? 'SERVANT').toString();
    final workerTypeLabel = pos['worker_type_label'] ?? (workerType == 'WORKER' ? 'Fəhlə' : 'Qulluqçu');

    final baseVacation = (pos['base_vacation_days'] as num? ?? 21).toInt();
    final minVacation = (pos['min_vacation_part'] as num? ?? 14).toInt();
    final hasBenefits = pos['has_additional_benefits'] == true;
    final benefitDays = (pos['additional_benefits_days'] as num? ?? 0).toInt();
    final workHours = (pos['work_hours_per_week'] as num? ?? 40).toInt();

    final activeEmpCount = (pos['employees_count'] as num? ?? 0).toInt();
    final totalContracts = (pos['total_contracts_count'] as num? ?? 0).toInt();

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row: Code, Teaching Staff, Worker Type, Status Switch
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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

                // Teaching Staff Badge
                if (isTeaching) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 11, color: Colors.purple),
                        SizedBox(width: 3),
                        Text(
                          'Pedaqoji',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Worker Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: workerType == 'WORKER'
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    workerTypeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: workerType == 'WORKER' ? Colors.orange.shade800 : Colors.blue.shade800,
                    ),
                  ),
                ),

                const Spacer(),

                // Status Switch
                InkWell(
                  onTap: () => _toggleStatus(pos),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                          size: 13,
                          color: isActive ? AppColors.success : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Aktiv' : 'Deaktiv',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.success : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Main Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),

            // Description
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.2,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Metrics Row: Vacation, Work Hours, Benefits
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetricPill(
                  icon: Icons.beach_access_rounded,
                  label: 'Əsas:',
                  value: '$baseVacation gün',
                  color: const Color(0xFF2563EB),
                ),
                _buildMetricPill(
                  icon: Icons.date_range_rounded,
                  label: 'Min:',
                  value: '$minVacation gün',
                  color: Colors.indigo,
                ),
                if (hasBenefits && benefitDays > 0)
                  _buildMetricPill(
                    icon: Icons.star_rounded,
                    label: 'Əlavə:',
                    value: '+$benefitDays gün',
                    color: const Color(0xFF10B981),
                  ),
                _buildMetricPill(
                  icon: Icons.access_time_filled_rounded,
                  label: 'İş rejimi:',
                  value: '$workHours saat/həftə',
                  color: Colors.teal,
                ),
              ],
            ),

            const Divider(height: 20),

            // Bottom Actions: Employees button & Edit/Delete
            Row(
              children: [
                // Employees Action Button (Wrapped in Flexible so it never overflows)
                Flexible(
                  child: InkWell(
                    onTap: () => _openEmployeesSheet(pos),
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
                              '$activeEmpCount əməkdaş${totalContracts > activeEmpCount ? ' ($totalContracts)' : ''}',
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
                      onPressed: () => _openPositionForm(position: pos),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      tooltip: 'Sil',
                      onPressed: () => _confirmDelete(pos),
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

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// POSITION FORM SHEET (ADD / EDIT)
// Web Parity: form.blade.php
// =================================================================

class _PositionFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingPosition;
  final VoidCallback onSaved;

  const _PositionFormSheet({
    this.existingPosition,
    required this.onSaved,
  });

  @override
  State<_PositionFormSheet> createState() => _PositionFormSheetState();
}

class _PositionFormSheetState extends State<_PositionFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _descController;
  late TextEditingController _baseVacationController;
  late TextEditingController _minVacationController;
  late TextEditingController _benefitDaysController;
  late TextEditingController _workHoursController;

  bool _hasAdditionalBenefits = false;
  String _workerType = 'SERVANT';
  bool _isTeachingStaff = false;
  bool _isActive = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPosition;

    _titleController = TextEditingController(text: p?['title'] ?? '');
    _codeController = TextEditingController(text: p?['code'] ?? '');
    _descController = TextEditingController(text: p?['description'] ?? '');
    _baseVacationController = TextEditingController(
      text: (p?['base_vacation_days'] ?? 21).toString(),
    );
    _minVacationController = TextEditingController(
      text: (p?['min_vacation_part'] ?? 14).toString(),
    );
    _benefitDaysController = TextEditingController(
      text: (p?['additional_benefits_days'] ?? 0).toString(),
    );
    _workHoursController = TextEditingController(
      text: (p?['work_hours_per_week'] ?? 40).toString(),
    );

    _hasAdditionalBenefits = p?['has_additional_benefits'] == true;
    _workerType = (p?['worker_type'] ?? 'SERVANT').toString().toUpperCase();
    if (_workerType != 'WORKER' && _workerType != 'SERVANT') {
      _workerType = 'SERVANT';
    }
    _isTeachingStaff = p?['is_teaching_staff'] == true;
    _isActive = p?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _baseVacationController.dispose();
    _minVacationController.dispose();
    _benefitDaysController.dispose();
    _workHoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'code': _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      'description': _descController.text.trim(),
      'base_vacation_days': int.tryParse(_baseVacationController.text.trim()) ?? 21,
      'min_vacation_part': int.tryParse(_minVacationController.text.trim()) ?? 14,
      'has_additional_benefits': _hasAdditionalBenefits,
      'additional_benefits_days': _hasAdditionalBenefits
          ? (int.tryParse(_benefitDaysController.text.trim()) ?? 0)
          : 0,
      'work_hours_per_week': int.tryParse(_workHoursController.text.trim()) ?? 40,
      'worker_type': _workerType,
      'is_teaching_staff': _isTeachingStaff,
      'is_active': _isActive,
    };

    try {
      final isEdit = widget.existingPosition != null;
      final id = widget.existingPosition?['id'] as int?;

      Map<String, dynamic>? res;
      if (isEdit && id != null) {
        res = await SchoolApiService.instance.updateHrPosition(id, payload);
      } else {
        res = await SchoolApiService.instance.createHrPosition(payload);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (res != null) {
          Navigator.pop(context);
          widget.onSaved();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit ? 'Vəzifə məlumatları yeniləndi' : 'Yeni vəzifə yaradıldı',
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
    final isEdit = widget.existingPosition != null;
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
                  isEdit ? 'Vəzifəni Redaktə Et' : 'Yeni Vəzifə Yarat',
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
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Vəzifənin Adı *',
                      hintText: 'Məs: İnformatika müəllimi, Baş Mühasib...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vəzifə adını daxil edin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Code
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Unikal Kod (Opsional)',
                      hintText: 'Boş qoysanız sistem avtomatik verəcək (İDR-POS...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Təsvir / Qeydlər',
                      hintText: 'Vəzifə haqqında əlavə qeydlər...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // =========================================================
                  // MƏZUNİYYƏT HÜQUQLARI BÖLMƏSİ (Web Parity)
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
                            Icon(Icons.beach_access_rounded, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text(
                              'Məzuniyyət Hüquqları',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // Base Vacation Days
                            Expanded(
                              child: TextFormField(
                                controller: _baseVacationController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Əsas gün *',
                                  suffixText: 'gün',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Gün daxil edin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Min Vacation Part Days
                            Expanded(
                              child: TextFormField(
                                controller: _minVacationController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Min. hissə *',
                                  suffixText: 'gün',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Gün daxil edin';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Switch: Additional benefits
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Əlavə məzuniyyət hüququ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Zərərli və ya xüsusi əmək şəraitinə görə',
                            style: TextStyle(fontSize: 11),
                          ),
                          value: _hasAdditionalBenefits,
                          onChanged: (val) => setState(() => _hasAdditionalBenefits = val),
                        ),

                        if (_hasAdditionalBenefits) ...[
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _benefitDaysController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Əlavə məzuniyyət günləri',
                              suffixText: 'gün',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =========================================================
                  // İŞ REJİMİ VƏ PARAMETRLƏR
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
                            Icon(Icons.tune_rounded, size: 18, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'İş Rejimi və Parametrlər',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Work hours per week
                        TextFormField(
                          controller: _workHoursController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Həftəlik iş saatları *',
                            suffixText: 'saat',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Həftəlik iş saatını daxil edin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Worker Type Dropdown (isExpanded: true to prevent right overflow)
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _workerType,
                          decoration: InputDecoration(
                            labelText: 'İşçi Tipi *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'SERVANT',
                              child: Text(
                                'Qulluqçu (İnzibati / Rəhbər / Müəllim heyəti)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'WORKER',
                              child: Text(
                                'Fəhlə (Texniki / Xidmətedici heyət)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _workerType = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Switch: Is Teaching Staff (Müəllim vakansiyasıdır?)
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Pedaqoji heyət (Müəllim vakansiyası)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Dərs yükü və tədris modulları ilə inteqrasiya üçün',
                            style: TextStyle(fontSize: 11),
                          ),
                          value: _isTeachingStaff,
                          onChanged: (val) => setState(() => _isTeachingStaff = val),
                        ),

                        // Switch: Is Active
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Status: Aktiv',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
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
                            isEdit ? 'Dəyişiklikləri Saxla' : 'Vəzifəni Yarat',
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
// POSITION EMPLOYEES BOTTOM SHEET
// Displays live list of employees in this position
// =================================================================

class _PositionEmployeesSheet extends StatefulWidget {
  final Map<String, dynamic> position;

  const _PositionEmployeesSheet({required this.position});

  @override
  State<_PositionEmployeesSheet> createState() => _PositionEmployeesSheetState();
}

class _PositionEmployeesSheetState extends State<_PositionEmployeesSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _includeInactive = false;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    final id = (widget.position['id'] as num).toInt();
    final res = await SchoolApiService.instance.fetchHrPositionEmployees(
      id,
      includeInactive: _includeInactive,
    );

    if (mounted) {
      final list = (res?['employees'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _employees = list;
        _applySearch();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((e) {
        final name = (e['name'] ?? '').toString().toLowerCase();
        final fin = (e['fin_code'] ?? '').toString().toLowerCase();
        final structure = (e['structure'] ?? '').toString().toLowerCase();
        return q.isEmpty || name.contains(q) || fin.contains(q) || structure.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.position['title'] ?? 'Vəzifə';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Bu vəzifəni daşıyan əməkdaşlar (${_employees.length})',
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

          // Filters row: Search & Inactive switch
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applySearch(),
                  decoration: InputDecoration(
                    hintText: 'Əməkdaş adı və ya FİN üzrə axtar...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Passiv müqavilələri də göstər:', style: TextStyle(fontSize: 11.5)),
                    const Spacer(),
                    Switch.adaptive(
                      value: _includeInactive,
                      onChanged: (val) {
                        setState(() => _includeInactive = val);
                        _fetchEmployees();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              'Bu vəzifədə əməkdaş tapılmadı',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filteredEmployees.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final emp = _filteredEmployees[index];
                          final name = emp['name'] ?? '-';
                          final fin = emp['fin_code'] ?? '-';
                          final filial = emp['filial'] ?? '';
                          final structure = emp['structure'] ?? '';
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
                                // Avatar circle with initial
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

                                // Details
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
                                      if (structure.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          structure,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Status Badge
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
