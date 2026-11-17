import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/stat_card.dart';

class GraduationsScreen extends StatefulWidget {
  const GraduationsScreen({super.key});

  @override
  State<GraduationsScreen> createState() => _GraduationsScreenState();
}

class _GraduationsScreenState extends State<GraduationsScreen> {
  bool _isLoading = true;
  String? _selectedYearId;
  String _selectedCategory = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _graduates = [];
  List<Map<String, dynamic>> _years = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final payload = await SchoolApiService.instance.fetchGraduationsData(
      academicYearId: _selectedYearId,
      search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
    );
    if (!mounted) return;

    final rawData = payload?['data'];
    final rawYears = payload?['years'];

    setState(() {
      _graduates = rawData is List ? List<Map<String, dynamic>>.from(rawData) : [];
      _years = rawYears is List ? List<Map<String, dynamic>>.from(rawYears) : [];
      _isLoading = false;
    });
  }

  void _snack(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> g) async {
    final palette = AppPalette.of(context);
    String educationType = (g['educationType'] ?? 'none').toString();
    bool isStateOrder = g['isStateOrder'] == true;
    final institution = TextEditingController(text: g['institution']?.toString() ?? '');
    final faculty = TextEditingController(text: g['faculty']?.toString() ?? '');
    final speciality = TextEditingController(text: g['speciality']?.toString() ?? '');
    final admissionScore = TextEditingController(text: g['admissionScore']?.toString() ?? '');
    final stateScore = TextEditingController(text: g['stateExamScore']?.toString() ?? '');
    final admissionExamScore = TextEditingController(text: g['admissionExamScore']?.toString() ?? '');
    final totalScore = TextEditingController(text: g['totalScore']?.toString() ?? '');
    final notes = TextEditingController(text: g['notes']?.toString() ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final isNone = educationType == 'none';
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 22),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.borderHairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Məzun məlumatlarını düzəliş et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                              Text(g['studentName']?.toString() ?? '', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: educationType,
                      decoration: const InputDecoration(
                        labelText: 'Təhsil növü *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'higher', child: Text('Yerli Ali Məktəb')),
                        DropdownMenuItem(value: 'college', child: Text('Orta İxtisas (Kollec)')),
                        DropdownMenuItem(value: 'abroad', child: Text('Beynəlxalq / Xarici')),
                        DropdownMenuItem(value: 'vocational', child: Text('Peşə Təhsili')),
                        DropdownMenuItem(value: 'none', child: Text('Qəbul Olmayıb / Digər')),
                      ],
                      onChanged: (v) => setSheet(() => educationType = v ?? 'none'),
                    ),
                    if (!isNone) ...[
                      const SizedBox(height: 12),
                      _tf('Təhsil Müəssisəsi *', institution, hint: 'Məs: BDU, ADA, Oksford və s.'),
                      Row(
                        children: [
                          Expanded(child: _tf('Fakültə', faculty)),
                          const SizedBox(width: 10),
                          Expanded(child: _tf('İxtisas', speciality)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _tf('Qəbul Balı', admissionScore, isNumber: true)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Dövlət Sifarişi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              value: isStateOrder,
                              onChanged: (v) => setSheet(() => isStateOrder = v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _tf('Dövlət İmtahanı', stateScore, isNumber: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _tf('Qəbul İmtahanı', admissionExamScore, isNumber: true)),
                        ],
                      ),
                      _tf('Ümumi bal', totalScore, isNumber: true),
                    ],
                    _tf('Qeydlər', notes, maxLines: 2),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved != true) return;

    final data = {
      'education_type': educationType,
      'institution': institution.text.trim(),
      'faculty': faculty.text.trim(),
      'speciality': speciality.text.trim(),
      'admission_score': double.tryParse(admissionScore.text.replaceAll(',', '.')),
      'state_exam_score': double.tryParse(stateScore.text.replaceAll(',', '.')),
      'admission_exam_score': double.tryParse(admissionExamScore.text.replaceAll(',', '.')),
      'total_score': double.tryParse(totalScore.text.replaceAll(',', '.')),
      'is_state_order': isStateOrder,
      'notes': notes.text.trim(),
      if (g['academicYearId'] != null) 'academic_year_id': g['academicYearId'],
    };

    final ok = await SchoolApiService.instance.updateGraduation(g['id'].toString(), data);
    _snack(ok ? 'Məzun məlumatları uğurla yeniləndi' : 'Əməliyyat zamanı xəta baş verdi', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> g) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Məzun qeydini sil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('${g['studentName']} adlı şagirdin məzun qeydi silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ləğv et')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SchoolApiService.instance.deleteGraduation(g['id'].toString());
    _snack(ok ? 'Məzun qeydi silindi' : 'Silinmə zamanı xəta baş verdi', ok: ok);
    if (ok) _load();
  }

  Widget _tf(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    // Apply category filter & search filter
    final filtered = _graduates.where((g) {
      if (_selectedCategory != 'all') {
        if ((g['educationType'] ?? 'none') != _selectedCategory) return false;
      }
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final name = (g['studentName'] ?? '').toString().toLowerCase();
        final code = (g['studentCode'] ?? '').toString().toLowerCase();
        final inst = (g['institution'] ?? '').toString().toLowerCase();
        final spec = (g['speciality'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !code.contains(q) && !inst.contains(q) && !spec.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Stats
    final higherCount = _graduates.where((g) => g['educationType'] == 'higher').length;
    final collegeCount = _graduates.where((g) => g['educationType'] == 'college').length;
    final abroadCount = _graduates.where((g) => g['educationType'] == 'abroad').length;
    final vocationalCount = _graduates.where((g) => g['educationType'] == 'vocational').length;
    final noneCount = _graduates.where((g) => g['educationType'] == 'none').length;

    final selectedYearLabel = _years.firstWhere(
      (y) => y['id'].toString() == _selectedYearId,
      orElse: () => {'label': 'Bütün illər'},
    )['label'];

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 132,
            pinned: true,
            elevation: 0,
            backgroundColor: palette.brandNavy,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Yenilə',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF07152B),
                      Color(0xFF132C5E),
                      Color(0xFF2563EB),
                    ],
                  ),
                ),
                child: SafeArea(
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
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Məzunlar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_graduates.length} məzun qeydi • $selectedYearLabel',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
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
              ),
            ),
          ),
          // Overview & Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stat cards
                  StatCardRow(
                    columns: 4,
                    spacing: 8,
                    children: [
                      StatCard(
                        value: '${_graduates.length}',
                        label: 'Cəmi',
                        icon: Icons.groups_rounded,
                        color: palette.brandRoyal,
                        compact: true,
                      ),
                      StatCard(
                        value: '$higherCount',
                        label: 'Yerli Ali',
                        icon: Icons.account_balance_rounded,
                        color: const Color(0xFF2563EB),
                        compact: true,
                      ),
                      StatCard(
                        value: '$collegeCount',
                        label: 'Kollec',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF0284C7),
                        compact: true,
                      ),
                      StatCard(
                        value: '$abroadCount',
                        label: 'Xarici',
                        icon: Icons.public_rounded,
                        color: const Color(0xFF059669),
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search
                  AppSearchBar(
                    controller: _searchCtrl,
                    hintText: 'Şagird adı, İdrak kodu, ali məktəb və ya ixtisas...',
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() {});
                      _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  // Quick Academic Year selector pills
                  _buildYearPills(palette),
                  const SizedBox(height: 10),
                  // Category Filter Chips
                  _buildCategoryFilters(palette, {
                    'all': _graduates.length,
                    'higher': higherCount,
                    'college': collegeCount,
                    'abroad': abroadCount,
                    'vocational': vocationalCount,
                    'none': noneCount,
                  }),
                ],
              ),
            ),
          ),
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(palette),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildGraduateCard(context, palette, filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYearPills(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _yearPill(palette, label: 'Bütün illər', yearId: null),
          for (final y in _years)
            _yearPill(
              palette,
              label: y['label']?.toString() ?? 'İl',
              yearId: y['id']?.toString(),
            ),
        ],
      ),
    );
  }

  Widget _yearPill(AppPalette palette, {required String label, required String? yearId}) {
    final selected = _selectedYearId == yearId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedYearId = yearId);
          _load();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? palette.brandRoyal : palette.surface1,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? palette.brandRoyal : palette.borderHairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: selected ? Colors.white : palette.brandRoyal,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(AppPalette palette, Map<String, int> counts) {
    final categories = <(String, String)>[
      ('all', 'Hamısı'),
      ('higher', 'Yerli Ali Məktəb'),
      ('college', 'Kollec'),
      ('abroad', 'Beynəlxalq / Xarici'),
      ('vocational', 'Peşə'),
      ('none', 'Qəbul olmayıb'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final (key, label) in categories)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedCategory == key ? palette.brandRoyal : palette.surface1,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _selectedCategory == key ? palette.brandRoyal : palette.borderHairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _selectedCategory == key ? FontWeight.w800 : FontWeight.w600,
                          color: _selectedCategory == key ? Colors.white : palette.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _selectedCategory == key
                              ? Colors.white.withValues(alpha: 0.2)
                              : palette.surface3,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${counts[key] ?? 0}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _selectedCategory == key ? Colors.white : palette.textMuted,
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

  Widget _buildGraduateCard(BuildContext context, AppPalette palette, Map<String, dynamic> g) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = g['studentName']?.toString() ?? 'Məzun';
    final code = g['studentCode']?.toString() ?? '';
    final className = g['className']?.toString() ?? '';
    final year = g['academicYear']?.toString() ?? '';
    final type = g['educationType']?.toString() ?? 'none';
    final typeLabel = g['educationTypeLabel']?.toString() ?? 'Təhsil növü';
    final isStateOrder = g['isStateOrder'] == true;

    final institution = g['institution']?.toString() ?? '';
    final faculty = g['faculty']?.toString() ?? '';
    final speciality = g['speciality']?.toString() ?? '';
    final admissionScore = g['admissionScore'];
    final stateScore = g['stateExamScore'];
    final totalScore = g['totalScore'];
    final notes = g['notes']?.toString() ?? '';

    // Badge styling based on education type
    Color typeBg;
    Color typeColor;
    switch (type) {
      case 'higher':
        typeBg = const Color(0xFF2563EB).withValues(alpha: 0.1);
        typeColor = const Color(0xFF2563EB);
        break;
      case 'college':
        typeBg = const Color(0xFF0284C7).withValues(alpha: 0.1);
        typeColor = const Color(0xFF0284C7);
        break;
      case 'abroad':
        typeBg = const Color(0xFF059669).withValues(alpha: 0.1);
        typeColor = const Color(0xFF059669);
        break;
      case 'vocational':
        typeBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        typeColor = const Color(0xFFD97706);
        break;
      default:
        typeBg = const Color(0xFF64748B).withValues(alpha: 0.1);
        typeColor = const Color(0xFF64748B);
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Code & Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModernAvatar(name: name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${className.isNotEmpty ? className : "Sinifsiz"}${code.isNotEmpty ? " • $code" : ""}${year.isNotEmpty ? " • $year" : ""}',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons (Edit & Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: palette.brandRoyal),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Düzəliş et',
                    onPressed: () => _edit(g),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Sil',
                    onPressed: () => _delete(g),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Badges row: Education type + State Order
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(color: typeColor, fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
              if (isStateOrder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                      SizedBox(width: 3),
                      Text(
                        'Dövlət Sifarişi',
                        style: TextStyle(color: Color(0xFFD97706), fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Institution & Speciality box
          if (institution.isNotEmpty || speciality.isNotEmpty || faculty.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.borderHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (institution.isNotEmpty)
                    Text(
                      institution,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  if (faculty.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('Fakültə: $faculty', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                    ),
                  if (speciality.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('İxtisas: $speciality', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                    ),
                ],
              ),
            ),
          ],
          // Scores Chips Row
          if (totalScore != null || admissionScore != null || stateScore != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (totalScore != null) ...[
                  _scoreBadge('Ümumi bal', '$totalScore', const Color(0xFF059669)),
                  const SizedBox(width: 8),
                ],
                if (admissionScore != null) ...[
                  _scoreBadge('Qəbul balı', '$admissionScore', palette.brandRoyal),
                  const SizedBox(width: 8),
                ],
                if (stateScore != null) ...[
                  _scoreBadge('Dövlət balı', '$stateScore', const Color(0xFF7C3AED)),
                ],
              ],
            ),
          ],
          // Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Qeyd: $notes',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreBadge(String label, String score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
          Text(score, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.brandRoyal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_outlined, size: 40, color: palette.brandRoyal),
            ),
            const SizedBox(height: 14),
            const Text(
              'Məzun qeydi tapılmadı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Seçilmiş il və ya axtarış parametrinə uyğun heç bir məzun məlumatı mövcud deyil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
