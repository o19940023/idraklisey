import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';

class ParallelLessonsScreen extends StatefulWidget {
  const ParallelLessonsScreen({super.key});

  @override
  State<ParallelLessonsScreen> createState() => _ParallelLessonsScreenState();
}

class _ParallelLessonsScreenState extends State<ParallelLessonsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Data from backend
  Map<String, dynamic> _kpi = {};
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _filials = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _parallelTypes = [];
  Map<String, dynamic> _permissions = {};

  // Filters
  int? _selectedYearId;
  int? _selectedFilialId;
  String _selectedParallelType = 'all';
  int? _selectedClassId;
  int? _selectedSubjectId;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Safe converters
  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString().trim();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SchoolApiService.instance.fetchParallelLessonsPage(
        academicYearId: _selectedYearId,
        filialId: _selectedFilialId,
        parallelType: _selectedParallelType,
        classId: _selectedClassId,
        subjectId: _selectedSubjectId,
      );

      if (!mounted) return;

      if (res != null) {
        final filters = (res['filters'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _kpi = (res['kpi'] as Map<String, dynamic>?) ?? {};
          _groups = (res['groups'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _academicYears = (filters['academic_years'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _filials = (filters['filials'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _classes = (filters['classes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _subjects = (filters['subjects'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _teachers = (filters['teachers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _parallelTypes = (filters['parallel_types'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _permissions = (res['permissions'] as Map<String, dynamic>?) ?? {};

          if (_selectedYearId == null && filters['current_academic_year_id'] != null) {
            _selectedYearId = _asInt(filters['current_academic_year_id']);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Məlumatları yükləmək mümkün olmadı.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Xəta baş verdi: $e';
        _isLoading = false;
      });
    }
  }

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _canCreate(SessionController session) {
    if (_permissions['can_create'] == false) return false;
    return session.can('gopanel.academic.parallel_lessons.create');
  }

  bool _canUpdate(SessionController session) {
    if (_permissions['can_update'] == false) return false;
    return session.can('gopanel.academic.parallel_lessons.update');
  }

  bool _canDelete(SessionController session) {
    if (_permissions['can_delete'] == false) return false;
    return session.can('gopanel.academic.parallel_lessons.delete');
  }

  List<Map<String, dynamic>> get _filteredGroups {
    if (_searchQuery.isEmpty) return _groups;
    final q = _searchQuery.toLowerCase();
    return _groups.where((g) {
      final className = _asString(g['class_name']).toLowerCase();
      final typeLabel = _asString(g['type_label']).toLowerCase();
      if (className.contains(q) || typeLabel.contains(q)) return true;

      final items = (g['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final it in items) {
        final teacher = _asString(it['teacher_name']).toLowerCase();
        final subject = _asString(it['subject_title']).toLowerCase();
        final group = _asString(it['group_name']).toLowerCase();
        if (teacher.contains(q) || subject.contains(q) || group.contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final canCreate = _canCreate(session);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Text(
          'Paralel Dərslər',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: palette.textPrimary),
        ),
        backgroundColor: palette.surface1,
        elevation: 0,
        actions: [
          if (canCreate)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brandRoyal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _openUpsertSheet(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Yeni Paralel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Yenilə',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(palette)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ResponsiveCenter(
                    child: Column(
                      children: [
                        // 4 KPI Summary Cards
                        _buildKpiHeader(palette),

                        // Search & Filter Bar
                        _buildSearchBar(palette),

                        // List of Parallel Lesson Groups
                        Expanded(
                          child: _filteredGroups.isEmpty
                              ? _buildEmptyView(palette)
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _filteredGroups.length,
                                  itemBuilder: (context, idx) {
                                    return _buildGroupCard(palette, _filteredGroups[idx], session);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView(AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Xəta baş verdi',
              style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenidən yoxla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(AppPalette palette) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_clear_rounded, size: 52, color: palette.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Uyğun paralel dərs təyinatı tapılmadı',
            style: TextStyle(color: palette.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (_searchQuery.isNotEmpty || _selectedParallelType != 'all') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _searchQuery = '';
                  _selectedParallelType = 'all';
                  _selectedClassId = null;
                  _selectedSubjectId = null;
                });
                _loadData();
              },
              child: const Text('Filtrləri sıfırla'),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 4 KPI HEADER =====
  Widget _buildKpiHeader(AppPalette palette) {
    final total = _asInt(_kpi['total_parallel_groups']);
    final split = _asInt(_kpi['group_split_count']);
    final subjects = _asInt(_kpi['parallel_subjects_count']);
    final merged = _asInt(_kpi['separated_or_merged_count']);

    return Container(
      color: palette.surface1,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildKpiCard(
              palette: palette,
              label: 'Cəmi Paralel Qrup',
              value: '$total',
              icon: Icons.layers_rounded,
              color: palette.brandRoyal,
              bgColor: palette.surface2,
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              palette: palette,
              label: '1-4 / 2-3 Qrupları',
              value: '$split',
              icon: Icons.people_alt_rounded,
              color: AppColors.emerald,
              bgColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFD1FAE5),
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              palette: palette,
              label: 'Paralel Fənlər',
              value: '$subjects',
              icon: Icons.view_column_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFE0F2FE),
            ),
            const SizedBox(width: 8),
            _buildKpiCard(
              palette: palette,
              label: 'Bölünmüş / Birləşmiş',
              value: '$merged',
              icon: Icons.call_split_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFEF3C7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required AppPalette palette,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? palette.borderHairline),
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
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  // ===== SEARCH & FILTER BAR =====
  Widget _buildSearchBar(AppPalette palette) {
    final hasActiveFilters = _selectedParallelType != 'all' || _selectedClassId != null || _selectedSubjectId != null || _selectedFilialId != null;

    return Container(
      color: palette.surface1,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Sinif, fənn və ya müəllim axtar...',
                      hintStyle: TextStyle(fontSize: 12, color: palette.textTertiary),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: palette.textTertiary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton.outlined(
                    tooltip: 'Filtrlər',
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: _showFilterModal,
                    icon: Icon(Icons.tune_rounded, size: 18, color: palette.brandRoyal),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Active Filter Chips
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (_selectedParallelType != 'all') ...[
                    _buildActiveChip(
                      palette,
                      'Növ: ${_asString(_parallelTypes.firstWhere((p) => p['value'] == _selectedParallelType, orElse: () => {})['label'], fallback: _selectedParallelType)}',
                      () {
                        setState(() => _selectedParallelType = 'all');
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedClassId != null) ...[
                    _buildActiveChip(
                      palette,
                      'Sinif: ${_asString(_classes.firstWhere((c) => _asInt(c['id']) == _selectedClassId, orElse: () => {})['class_name'])}',
                      () {
                        setState(() => _selectedClassId = null);
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedSubjectId != null) ...[
                    _buildActiveChip(
                      palette,
                      'Fənn: ${_asString(_subjects.firstWhere((s) => _asInt(s['id']) == _selectedSubjectId, orElse: () => {})['title'])}',
                      () {
                        setState(() => _selectedSubjectId = null);
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedParallelType = 'all';
                        _selectedClassId = null;
                        _selectedSubjectId = null;
                        _selectedFilialId = null;
                      });
                      _loadData();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Hamısını təmizlə', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveChip(AppPalette palette, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 2, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: palette.brandRoyal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.brandRoyal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.brandRoyal)),
          InkWell(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 13, color: palette.brandRoyal),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final palette = AppPalette.of(ctx);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ətraflı Filtrlər', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Tədris İli
                Text('Tədris İli', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedYearId,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _academicYears.map((y) {
                    final id = _asInt(y['id']);
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(_asString(y['title'])),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => _selectedYearId = val),
                ),
                const SizedBox(height: 12),

                // Paralel Növü
                Text('Paralel Növü', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedParallelType,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _parallelTypes.map((pt) {
                    return DropdownMenuItem<String>(
                      value: _asString(pt['value']),
                      child: Text(_asString(pt['label'])),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => _selectedParallelType = val ?? 'all'),
                ),
                const SizedBox(height: 12),

                // Sinif
                Text('Sinif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedClassId,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Bütün Siniflər')),
                    ..._classes.map((c) {
                      final id = _asInt(c['id']);
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(_asString(c['class_name'])),
                      );
                    }),
                  ],
                  onChanged: (val) => setModalState(() => _selectedClassId = val),
                ),
                const SizedBox(height: 12),

                // Fənn
                Text('Fənn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedSubjectId,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Bütün Fənlər')),
                    ..._subjects.map((s) {
                      final id = _asInt(s['id']);
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(_asString(s['title'])),
                      );
                    }),
                  ],
                  onChanged: (val) => setModalState(() => _selectedSubjectId = val),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedParallelType = 'all';
                            _selectedClassId = null;
                            _selectedSubjectId = null;
                            _selectedFilialId = null;
                          });
                          Navigator.pop(ctx);
                          _loadData();
                        },
                        child: const Text('Təmizlə'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: palette.brandRoyal),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                          _loadData();
                        },
                        child: const Text('Tətbiq Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== PARALLEL LESSON BUNDLE CARD =====
  Widget _buildGroupCard(AppPalette palette, Map<String, dynamic> g, SessionController session) {
    final primaryId = _asInt(g['primary_id']);
    final className = _asString(g['class_name']);
    final typeLabel = _asString(g['type_label']);
    final typeBadge = _asString(g['type_badge']);
    final weeklyHours = _asString(g['weekly_hours']);
    final hoursPerDay = _asInt(g['hours_per_day'], fallback: 1);
    final items = (g['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final canUpdate = _canUpdate(session);
    final canDelete = _canDelete(session);

    Color badgeBg;
    Color badgeFg;
    if (typeBadge == 'success') {
      badgeBg = const Color(0xFFECFDF5);
      badgeFg = AppColors.emerald;
    } else if (typeBadge == 'warning') {
      badgeBg = const Color(0xFFFFFBEB);
      badgeFg = const Color(0xFFD97706);
    } else if (typeBadge == 'dark') {
      badgeBg = const Color(0xFFF3F4F6);
      badgeFg = const Color(0xFF374151);
    } else {
      badgeBg = const Color(0xFFEFF6FF);
      badgeFg = palette.brandRoyal;
    }

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Class & Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.meeting_room_rounded, size: 14, color: palette.brandRoyal),
                    const SizedBox(width: 4),
                    Text(
                      className,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: badgeFg),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Sub-lessons (Simultaneous Teachers & Subjects)
          Column(
            children: items.map((it) {
              final subjectTitle = _asString(it['subject_title'], fallback: 'Fənn');
              final teacherName = _asString(it['teacher_name'], fallback: 'Müəllim təyin olunmayıb');
              final groupName = _asString(it['group_name']);
              final studentsCount = _asInt(it['students_count']);
              final subWeekly = _asDouble(it['weekly_hours']);
              final classId = _asInt(it['class_id'], fallback: _asInt(g['class_id']));
              final groupId = _asInt(it['group_id']);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surface2.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.book_outlined, size: 14, color: palette.brandRoyal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  subjectTitle,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: palette.surface1,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: palette.borderHairline),
                          ),
                          child: Text(
                            '${subWeekly.toStringAsFixed(0)} saat',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: palette.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            teacherName,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (groupName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              groupName,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: palette.brandRoyal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: (groupId > 0 && classId > 0 && canUpdate)
                                ? () => _openAssignStudentsSheet(classId, groupId, groupName)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: palette.brandRoyal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school_rounded, size: 11, color: palette.brandRoyal),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$studentsCount şagird',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: palette.brandRoyal),
                                  ),
                                  if (canUpdate) ...[
                                    const SizedBox(width: 2),
                                    Icon(Icons.edit_rounded, size: 10, color: palette.brandRoyal),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Footer: Hours and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE0F2FE)),
                    ),
                    child: Text(
                      '$hoursPerDay saat/gün',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      weeklyHours,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: palette.brandRoyal),
                    ),
                  ),
                ],
              ),

              // Actions
              if (canUpdate || canDelete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canUpdate)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Redaktə et',
                        visualDensity: VisualDensity.compact,
                        color: palette.brandRoyal,
                        onPressed: () => _openUpsertSheet(primaryId: primaryId),
                      ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        tooltip: 'Sil',
                        visualDensity: VisualDensity.compact,
                        color: AppColors.danger,
                        onPressed: () => _confirmDelete(primaryId, className),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== STUDENT ASSIGNMENT MODAL =====
  Future<void> _openAssignStudentsSheet(int classId, int groupId, String groupName) async {
    final palette = AppPalette.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isLoadingStudents = true;
        List<Map<String, dynamic>> students = [];
        Set<int> selectedIds = {};
        String studentSearch = '';

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (isLoadingStudents) {
              SchoolApiService.instance.fetchGroupAssignmentStudents(classId, groupId).then((res) {
                if (!mounted) return;
                setSheetState(() {
                  students = res;
                  selectedIds = res.where((s) => s['selected'] == true).map((s) => _asInt(s['id'])).toSet();
                  isLoadingStudents = false;
                });
              });
            }

            final filteredStudents = studentSearch.isEmpty
                ? students
                : students.where((s) => _asString(s['text']).toLowerCase().contains(studentSearch.toLowerCase())).toList();

            return Container(
              height: MediaQuery.sizeOf(ctx).height * 0.75,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qrup Tələbələri',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.textPrimary),
                            ),
                            Text(
                              groupName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.brandRoyal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 6),

                  // Search students
                  SizedBox(
                    height: 36,
                    child: TextField(
                      onChanged: (val) => setSheetState(() => studentSearch = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Şagird axtar...',
                        hintStyle: TextStyle(fontSize: 12, color: palette.textTertiary),
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Selection summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seçilib: ${selectedIds.length} / ${students.length}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textSecondary),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                selectedIds = students.map((s) => _asInt(s['id'])).toSet();
                              });
                            },
                            child: const Text('Hamısını seç', style: TextStyle(fontSize: 11)),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => selectedIds.clear());
                            },
                            child: const Text('Təmizlə', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // List
                  Expanded(
                    child: isLoadingStudents
                        ? const Center(child: CircularProgressIndicator())
                        : filteredStudents.isEmpty
                            ? Center(child: Text('Şagird tapılmadı', style: TextStyle(color: palette.textSecondary)))
                            : ListView.builder(
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, i) {
                                  final s = filteredStudents[i];
                                  final sId = _asInt(s['id']);
                                  final sName = _asString(s['text']);
                                  final isChecked = selectedIds.contains(sId);

                                  return CheckboxListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                    title: Text(sName, style: TextStyle(fontSize: 13, fontWeight: isChecked ? FontWeight.w800 : FontWeight.w500)),
                                    value: isChecked,
                                    activeColor: palette.brandRoyal,
                                    onChanged: (bool? val) {
                                      setSheetState(() {
                                        if (val == true) {
                                          selectedIds.add(sId);
                                        } else {
                                          selectedIds.remove(sId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                  ),

                  const SizedBox(height: 10),

                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandRoyal,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      final ok = await SchoolApiService.instance.saveGroupAssignmentStudents(
                        classId,
                        groupId,
                        selectedIds.toList(),
                      );
                      if (!mounted) return;
                      nav.pop();
                      _snack(ok ? 'Tələbə siyahısı uğurla yadda saxlanıldı!' : 'Xəta baş verdi', ok: ok);
                      if (ok) _loadData();
                    },
                    child: const Text('Yadda Saxla', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== CREATE / EDIT PARALLEL BUNDLE MODAL =====
  Future<void> _openUpsertSheet({int? primaryId}) async {
    final palette = AppPalette.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isLoadingForm = true;
        int? filialId = _selectedFilialId ?? (_filials.isNotEmpty ? _asInt(_filials.first['id']) : 1);
        int academicYearId = _selectedYearId ?? 4;
        List<Map<String, dynamic>> formClasses = _classes;
        List<Map<String, dynamic>> formSubjects = _subjects;
        List<Map<String, dynamic>> formTeachers = _teachers;
        Map<String, dynamic> teacherSubjectsMap = {};

        List<Map<String, dynamic>> rows = [
          {'teacher_id': null, 'subject_id': null, 'class_ids': <int>[], 'group_name': '', 'weekly_hours': 2, 'hours_per_day': 1},
          {'teacher_id': null, 'subject_id': null, 'class_ids': <int>[], 'group_name': '', 'weekly_hours': 2, 'hours_per_day': 1},
        ];

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (isLoadingForm) {
              SchoolApiService.instance.fetchParallelLessonForm(
                id: primaryId,
                academicYearId: academicYearId,
                filialId: filialId,
              ).then((res) {
                if (!mounted) return;
                setSheetState(() {
                  if (res != null) {
                    final data = (res['data'] as Map<String, dynamic>?) ?? res;
                    filialId = _asInt(data['filial_id'], fallback: filialId ?? 1);
                    academicYearId = _asInt(data['academic_year_id'], fallback: academicYearId);
                    formClasses = (data['classes'] as List?)?.cast<Map<String, dynamic>>() ?? formClasses;
                    formSubjects = (data['subjects'] as List?)?.cast<Map<String, dynamic>>() ?? formSubjects;
                    formTeachers = (data['teachers'] as List?)?.cast<Map<String, dynamic>>() ?? formTeachers;
                    teacherSubjectsMap = (data['teacher_subjects_map'] as Map<String, dynamic>?) ?? {};

                    final bundleLoads = (data['bundle_loads'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    if (bundleLoads.isNotEmpty) {
                      rows = bundleLoads.map((b) => {
                        'id': b['id'],
                        'teacher_id': _asInt(b['teacher_id']),
                        'subject_id': _asInt(b['subject_id']),
                        'class_ids': (b['class_ids'] as List?)?.map((c) => _asInt(c)).toList() ?? <int>[],
                        'group_name': _asString(b['group_name']),
                        'weekly_hours': _asDouble(b['weekly_hours'], fallback: 2.0),
                        'hours_per_day': _asInt(b['hours_per_day'], fallback: 1),
                      }).toList();
                      while (rows.length < 2) {
                        rows.add({'teacher_id': null, 'subject_id': null, 'class_ids': <int>[], 'group_name': '', 'weekly_hours': 2, 'hours_per_day': 1});
                      }
                    }
                  }
                  isLoadingForm = false;
                });
              });
            }

            return Container(
              height: MediaQuery.sizeOf(ctx).height * 0.88,
              padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.viewInsetsOf(ctx).bottom + 18),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: isLoadingForm
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primaryId == null ? 'Yeni Paralel Dərs Təyinatı' : 'Paralel Dərsi Redaktə Et',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.textPrimary),
                                ),
                                Text(
                                  'Eyni saatda keçirilən dərsləri və müəllimləri birləşdirir',
                                  style: TextStyle(fontSize: 11, color: palette.textSecondary),
                                ),
                              ],
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 6),

                        // Filial dropdown
                        if (_filials.isNotEmpty) ...[
                          Row(
                            children: [
                              Text('Filial: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: filialId,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _filials.map((f) => DropdownMenuItem(value: _asInt(f['id']), child: Text(_asString(f['name']), style: const TextStyle(fontSize: 12)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        filialId = val;
                                        isLoadingForm = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Rows header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paralel Dərslər / Qruplar (${rows.length})',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  rows.add({
                                    'teacher_id': null,
                                    'subject_id': null,
                                    'class_ids': <int>[],
                                    'group_name': '',
                                    'weekly_hours': 2,
                                    'hours_per_day': 1,
                                  });
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                              label: const Text('+ Dərs Əlavə Et', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Dynamic rows list
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, rIdx) {
                              final row = rows[rIdx];
                              final teacherId = row['teacher_id'] as int?;
                              final subjectId = row['subject_id'] as int?;
                              final classIds = (row['class_ids'] as List?)?.cast<int>() ?? [];
                              final weeklyHours = row['weekly_hours'] ?? 2;

                              // Teacher-specific subjects
                              List<Map<String, dynamic>> rowSubjects = formSubjects;
                              if (teacherId != null && teacherSubjectsMap.containsKey(teacherId.toString())) {
                                rowSubjects = (teacherSubjectsMap[teacherId.toString()] as List?)?.cast<Map<String, dynamic>>() ?? formSubjects;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: palette.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: palette.borderHairline),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: palette.brandRoyal.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${rIdx + 1}-ci Müəllim və Dərs',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: palette.brandRoyal),
                                          ),
                                        ),
                                        if (rows.length > 2)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setSheetState(() => rows.removeAt(rIdx));
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // 1. Müəllim
                                    DropdownButtonFormField<int?>(
                                      initialValue: teacherId,
                                      isDense: true,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Müəllim *',
                                        labelStyle: TextStyle(fontSize: 11, color: palette.textSecondary),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: formTeachers.map((t) => DropdownMenuItem<int?>(
                                        value: _asInt(t['id']),
                                        child: Text(_asString(t['full_name']), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      )).toList(),
                                      onChanged: (val) {
                                        setSheetState(() {
                                          row['teacher_id'] = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // 2. Fənn
                                    DropdownButtonFormField<int?>(
                                      initialValue: subjectId,
                                      isDense: true,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Fənn *',
                                        labelStyle: TextStyle(fontSize: 11, color: palette.textSecondary),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: rowSubjects.map((s) => DropdownMenuItem<int?>(
                                        value: _asInt(s['id']),
                                        child: Text(_asString(s['title']), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      )).toList(),
                                      onChanged: (val) {
                                        setSheetState(() {
                                          row['subject_id'] = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // 3. Sinif seçimi (tək və ya çoxlu patok)
                                    DropdownButtonFormField<int?>(
                                      initialValue: classIds.isNotEmpty ? classIds.first : null,
                                      isDense: true,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Sinif *',
                                        labelStyle: TextStyle(fontSize: 11, color: palette.textSecondary),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: formClasses.map((c) => DropdownMenuItem<int?>(
                                        value: _asInt(c['id']),
                                        child: Text(_asString(c['class_name']), style: const TextStyle(fontSize: 12)),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setSheetState(() {
                                            row['class_ids'] = [val];
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // 4. Həftəlik saat & Qrup Adı
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            initialValue: _asString(row['group_name']),
                                            decoration: InputDecoration(
                                              labelText: 'Qrup Adı',
                                              labelStyle: TextStyle(fontSize: 11, color: palette.textSecondary),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            style: const TextStyle(fontSize: 12),
                                            onChanged: (v) => row['group_name'] = v.trim(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: '$weeklyHours',
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Həftəlik saat',
                                              labelStyle: TextStyle(fontSize: 10, color: palette.textSecondary),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            style: const TextStyle(fontSize: 12),
                                            onChanged: (v) => row['weekly_hours'] = double.tryParse(v) ?? 2.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.brandRoyal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            // Validation
                            for (int i = 0; i < rows.length; i++) {
                              final r = rows[i];
                              if (r['teacher_id'] == null || r['subject_id'] == null || (r['class_ids'] as List).isEmpty) {
                                _snack('${i + 1}-ci sətirdə müəllim, fənn və sinif seçilməlidir!', ok: false);
                                return;
                              }
                            }

                            final payload = {
                              'academic_year_id': academicYearId,
                              'filial_id': filialId,
                              'rows': rows.map((r) => {
                                'teacher_id': r['teacher_id'],
                                'subject_id': r['subject_id'],
                                'class_ids': r['class_ids'],
                                'group_name': r['group_name']?.toString().isNotEmpty == true
                                    ? r['group_name']
                                    : null,
                                'weekly_hours': r['weekly_hours'] ?? 2,
                                'hours_per_day': r['hours_per_day'] ?? 1,
                              }).toList(),
                            };

                            final nav = Navigator.of(ctx);
                            final res = await SchoolApiService.instance.saveParallelLessonBundle(payload, id: primaryId);
                            if (!mounted) return;
                            nav.pop();
                            _snack(res['message']?.toString() ?? 'Əməliyyat tamamlandı', ok: res['success'] == true);
                            if (res['success'] == true) _loadData();
                          },
                          child: const Text('Yadda Saxla', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(int primaryId, String className) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paralel dərsi sil'),
        content: Text('$className sinfinə aid paralel dərs təyinatı və əlaqəli qruplar silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final deleted = await SchoolApiService.instance.deleteParallelLessonBundle(primaryId);
    if (!mounted) return;
    _snack(deleted ? 'Paralel dərs uğurla silindi!' : 'Silinmə zamanı xəta baş verdi', ok: deleted);
    if (deleted) _loadData();
  }
}
