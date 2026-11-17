import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class TransitionExceptionsScreen extends StatefulWidget {
  const TransitionExceptionsScreen({super.key});

  @override
  State<TransitionExceptionsScreen> createState() => _TransitionExceptionsScreenState();
}

class _TransitionExceptionsScreenState extends State<TransitionExceptionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _tab = 'all';
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic> _counts = {};
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _years = [];

  static const _fullTabs = [
    ('all', 'Hamısı', Color(0xFF2563EB)),
    ('pending', 'Gözləyən', Color(0xFFD97706)),
    ('exam', 'İmtahan', Color(0xFF0284C7)),
    ('medical', 'Tibb', Color(0xFF059669)),
    ('psychology', 'Psixoloq', Color(0xFF8B5CF6)),
    ('approved', 'Təsdiqlənib', Color(0xFF10B981)),
    ('rejected', 'Rədd edilib', Color(0xFFEF4444)),
  ];

  static const _deptTabs = [
    ('all', 'Hamısı', Color(0xFF2563EB)),
    ('pending', 'Dəyərləndirmə gözləyən', Color(0xFFD97706)),
    ('completed', 'Tamamlananlar', Color(0xFF10B981)),
  ];

  static const _types = [
    ('section_change', 'Bölmə dəyişikliyi'),
    ('class_change', 'Sinif dəyişikliyi'),
    ('school_transfer', 'Məktəb transferi'),
    ('stay_in_class', 'Sinifdə saxlama'),
    ('waiting_9th_grade', '9-cu sinif gözləmə'),
    ('custom_discount', 'Xüsusi güzəşt'),
    ('left_school', 'Məktəbdən ayrılma'),
  ];

  @override
  void initState() {
    super.initState();
    _loadStatic();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatic() async {
    final results = await Future.wait([
      SchoolApiService.instance.fetchStudents(),
      SchoolApiService.instance.fetchClassesFull(),
      SchoolApiService.instance.fetchAcademicYears(),
    ]);
    if (!mounted) return;
    setState(() {
      _students = results[0];
      _classes = results[1];
      _years = results[2];
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final session = context.read<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canAcademic = isSuper || session.can('gopanel.academic.transitions.exceptions.view');
    String? dept;
    if (!canAcademic) {
      if (session.can('gopanel.exams.transition_exceptions.view')) {
        dept = 'exam';
      } else if (session.can('gopanel.psicology.transition_exceptions.view')) {
        dept = 'psychology';
      } else if (session.can('gopanel.medical.transition_exceptions.view')) {
        dept = 'medical';
      }
    }
    final payload = await SchoolApiService.instance.fetchTransitionsPayload(tab: _tab, department: dept);
    if (!mounted) return;
    setState(() {
      _records = payload != null && payload['data'] is List
          ? List<Map<String, dynamic>>.from(payload['data'])
          : [];
      _counts = payload != null && payload['counts'] is Map
          ? Map<String, dynamic>.from(payload['counts'])
          : {};
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records.where((r) {
      final name = (r['studentName'] ?? '').toString().toLowerCase();
      final fin = (r['finCode'] ?? '').toString().toLowerCase();
      final code = (r['studentCode'] ?? '').toString().toLowerCase();
      final fromC = (r['fromClass'] ?? '').toString().toLowerCase();
      final toC = (r['toClass'] ?? '').toString().toLowerCase();
      return name.contains(q) || fin.contains(q) || code.contains(q) || fromC.contains(q) || toC.contains(q);
    }).toList();
  }

  int _count(String key) => (_counts[key] as num?)?.toInt() ?? 0;

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _statusColor(String? status, String? approval) {
    if (approval == 'approved' || status == 'transition_completed' || status == 'transition_approved') return AppColors.emerald;
    if (approval == 'rejected' || status == 'transition_rejected') return AppColors.danger;
    return const Color(0xFFD97706);
  }

  String _statusLabel(Map<String, dynamic> r) {
    final status = r['status']?.toString() ?? '';
    if (status == 'transition_completed' || status == 'transition_approved') return 'Təsdiqlənib';
    if (status == 'transition_rejected') return 'Rədd edilib';
    if (status == 'transition_in_progress') return 'İcradadır';
    return 'Gözləyir';
  }

  String _typeLabel(Map<String, dynamic> r) {
    final type = r['type']?.toString() ?? '';
    for (final t in _types) {
      if (t.$1 == type) return t.$2;
    }
    return r['typeLabel']?.toString() ?? type;
  }

  Widget _stageBadge(String label, String status, {double? score}) {
    final color = switch (status) {
      'passed' => AppColors.emerald,
      'failed' => AppColors.danger,
      'exempt' => const Color(0xFF0284C7),
      _ => const Color(0xFFD97706),
    };
    final text = switch (status) {
      'passed' => score != null ? 'Keçib ($score%)' : 'Keçib',
      'failed' => score != null ? 'Keçməyib ($score%)' : 'Keçməyib',
      'exempt' => 'Azad',
      _ => 'Gözləyir',
    };
    return StatusBadge(label: '$label: $text', color: color, fontSize: 9.5);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;

    final canAcademic = isSuper || session.can('gopanel.academic.transitions.exceptions.view');
    final canCreate = isSuper || session.can('gopanel.academic.transitions.exceptions.create');
    final canEdit = isSuper || session.can('gopanel.academic.transitions.exceptions.edit');
    final canApprove = isSuper || session.can('gopanel.academic.transitions.exceptions.approve');
    final canDelete = isSuper || session.can('gopanel.academic.transitions.exceptions.delete');

    final isExamOnly = !canAcademic && session.can('gopanel.exams.transition_exceptions.view');
    final isPsychologyOnly = !canAcademic && session.can('gopanel.psicology.transition_exceptions.view');
    final isMedicalOnly = !canAcademic && session.can('gopanel.medical.transition_exceptions.view');

    final isDeptOnly = isExamOnly || isPsychologyOnly || isMedicalOnly;
    final tabs = isDeptOnly ? _deptTabs : _fullTabs;

    final screenTitle = isExamOnly
        ? 'Bölmə Dəyişiklikləri (İmtahan)'
        : isPsychologyOnly
            ? 'Bölmə Dəyişiklikləri (Psixoloq)'
            : isMedicalOnly
                ? 'Bölmə Dəyişiklikləri (Tibbi)'
                : 'Bölmə dəyişiklikləri';

    final items = _filtered;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: Text(screenTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Yenilə'),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Yeni Müraciət', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: Column(
        children: [
          // Filter Tabs (Clean solid styling with NO invisible white bugs)
          Container(
            color: palette.brandNavy,
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (key, label, tabColor) = tabs[i];
                  final isSelected = _tab == key;
                  final count = _count(key);
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (_tab != key) {
                        setState(() => _tab = key);
                        _load();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? tabColor : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white.withOpacity(0.3) : const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Search & Summary Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Şagird adı, FİN, İdrak kodu və ya sinif ilə axtar...',
                    hintStyle: TextStyle(fontSize: 13, color: palette.textTertiary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: palette.surface1,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: palette.brandRoyal, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text('Keçid Müraciətləri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('${items.length} müraciət göstərilir', style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 80),
                      children: [
                        if (!isDeptOnly) ...[
                          StatCardRow(
                            columns: 3,
                            spacing: 8,
                            children: [
                              StatCard(value: '${_count('all')}', label: 'Hamısı', icon: Icons.sync_alt_rounded, color: palette.brandRoyal, compact: true),
                              StatCard(value: '${_count('pending')}', label: 'Gözləyən', icon: Icons.hourglass_top_rounded, color: const Color(0xFFD97706), compact: true),
                              StatCard(value: '${_count('approved')}', label: 'Təsdiqlənib', icon: Icons.verified_rounded, color: AppColors.emerald, compact: true),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.alt_route_rounded, size: 54, color: palette.textTertiary),
                                  const SizedBox(height: 12),
                                  Text('Keçid müraciəti tapılmadı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final r in items) ...[
                            _buildTransitionCard(r, palette, canEdit: canEdit, canApprove: canApprove, canDelete: canDelete, isDeptOnly: isDeptOnly, isExamOnly: isExamOnly, isPsychologyOnly: isPsychologyOnly, isMedicalOnly: isMedicalOnly),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionCard(
    Map<String, dynamic> r,
    AppPalette palette, {
    required bool canEdit,
    required bool canApprove,
    required bool canDelete,
    required bool isDeptOnly,
    required bool isExamOnly,
    required bool isPsychologyOnly,
    required bool isMedicalOnly,
  }) {
    final studentName = r['studentName']?.toString() ?? 'Şagird';
    final approvalStatus = r['approvalStatus']?.toString();
    final isApproved = approvalStatus == 'approved' || r['status'] == 'transition_completed' || r['status'] == 'transition_approved';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, FIN, Type and Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: palette.brandRoyal.withOpacity(0.12),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'Ş',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          r['studentCode'] ?? '',
                          style: TextStyle(fontSize: 11.5, color: palette.textTertiary, fontWeight: FontWeight.w600),
                        ),
                        if ((r['studentCode'] ?? '').toString().isNotEmpty && (r['finCode'] ?? '').toString().isNotEmpty)
                          Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: palette.textTertiary)),
                        Text(
                          'FİN: ${r['finCode'] ?? '—'}',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: _statusLabel(r),
                color: _statusColor(r['status'], r['approvalStatus']),
                fontSize: 10,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Transition Route Box: From Class -> To Class
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cari sinif / bölmə', style: TextStyle(fontSize: 10, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${r['fromClass'] ?? '—'} (${r['fromSection'] ?? ''})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: palette.brandRoyal),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hədəf sinif / bölmə', style: TextStyle(fontSize: 10, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${r['toClass'] ?? '—'} (${r['toSection'] ?? ''})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: palette.brandRoyal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((r['note'] ?? '').toString().isNotEmpty) ...[
                  const Divider(height: 12),
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 13, color: palette.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r['note'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Stage Badges (İmtahan, Tibb, Psixoloq)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _stageBadge('İmtahan', r['examStatus']?.toString() ?? 'pending', score: r['examScore'] != null ? (r['examScore'] as num).toDouble() : null),
              _stageBadge('Tibb', r['medicalStatus']?.toString() ?? 'pending'),
              _stageBadge('Psixoloq', r['psychologyStatus']?.toString() ?? 'pending'),
            ],
          ),

          const SizedBox(height: 12),

          // Department-Specific Actions or Full Actions
          if (isDeptOnly) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.brandRoyal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showStageSheet(r, fixedStage: isExamOnly ? 'exam' : (isPsychologyOnly ? 'psychology' : 'medical')),
                icon: const Icon(Icons.rate_review_rounded, size: 17),
                label: Text(
                  isExamOnly ? 'İmtahan balı daxil et' : (isPsychologyOnly ? 'Psixoloji rəy daxil et' : 'Tibbi rəy daxil et'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isApproved ? palette.brandNavy : AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isApproved || !canApprove ? null : () => _approve(r),
                    icon: Icon(isApproved ? Icons.verified_rounded : Icons.check_circle_rounded, size: 17),
                    label: Text(
                      isApproved ? 'Təsdiqlənib' : 'Təsdiqlə və tətbiq et',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.brandNavy,
                      side: BorderSide(color: palette.borderHairline),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showActions(r, canEdit: canEdit, canApprove: canApprove, canDelete: canDelete),
                    icon: const Icon(Icons.more_horiz_rounded, size: 17),
                    label: const Text('Ətraflı', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showActions(
    Map<String, dynamic> r, {
    required bool canEdit,
    required bool canApprove,
    required bool canDelete,
  }) async {
    final palette = AppPalette.of(context);
    final isApproved = r['approvalStatus'] == 'approved' || r['status'] == 'transition_completed';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(color: palette.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: palette.textTertiary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: palette.brandRoyal.withOpacity(0.12),
                    child: Text(
                      (r['studentName']?.toString() ?? 'Ş').isNotEmpty ? r['studentName'].toString()[0].toUpperCase() : 'Ş',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['studentName'] ?? 'Şagird', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        Text('${_typeLabel(r)} • ${r['studentCode'] ?? ''}', style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  StatusBadge(label: _statusLabel(r), color: _statusColor(r['status'], r['approvalStatus'])),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showStageSheet(r);
                      },
                      icon: const Icon(Icons.fact_check_rounded, size: 17),
                      label: const Text('Mərhələlər', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  if (canEdit) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.brandAzure,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showForm(record: r);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('Düzəliş et', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ],
              ),
              if (canApprove && !isApproved) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approve(r);
                        },
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Təsdiqlə və tətbiq et', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reject(r);
                        },
                        icon: const Icon(Icons.close_rounded, size: 17),
                        label: const Text('Rədd et', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
              if (canDelete) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _delete(r);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Müraciəti sil', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStageSheet(Map<String, dynamic> r, {String? fixedStage}) async {
    final palette = AppPalette.of(context);
    String stage = fixedStage ?? 'exam';
    String status = (r['${stage}Status']?.toString() ?? 'pending');
    final score = TextEditingController(text: r['examScore']?.toString() ?? '');
    final note = TextEditingController(text: r['${stage}Note']?.toString() ?? '');
    final date = TextEditingController(text: r['${stage}Date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10));

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(ctx).bottom + 22),
          decoration: BoxDecoration(color: palette.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: palette.textTertiary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 14),
                  Text(
                    fixedStage == null ? 'Mərhələni yenilə' : (fixedStage == 'exam' ? 'İmtahan Qiymətləndirməsi' : (fixedStage == 'psychology' ? 'Psixoloji Qiymətləndirmə' : 'Tibbi Qiymətləndirmə')),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(r['studentName'] ?? '', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                  const SizedBox(height: 14),
                  if (fixedStage == null) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'exam', label: Text('İmtahan')),
                        ButtonSegment(value: 'medical', label: Text('Tibb')),
                        ButtonSegment(value: 'psychology', label: Text('Psixoloq')),
                      ],
                      selected: {stage},
                      onSelectionChanged: (v) => setSheet(() {
                        stage = v.first;
                        status = r['${stage}Status']?.toString() ?? 'pending';
                        note.text = r['${stage}Note']?.toString() ?? '';
                        date.text = r['${stage}Date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10);
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: _deco('Nəticə'),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Gözlənilir')),
                      DropdownMenuItem(value: 'passed', child: Text('Keçib (Müsbət)')),
                      DropdownMenuItem(value: 'failed', child: Text('Keçməyib (Uyğunsuz)')),
                      DropdownMenuItem(value: 'exempt', child: Text('Azad')),
                    ],
                    onChanged: (v) => setSheet(() => status = v ?? 'pending'),
                  ),
                  const SizedBox(height: 10),
                  if (stage == 'exam') ...[
                    _tf('İmtahan balı (%)', score, keyboard: TextInputType.number),
                    _tf('İmtahan tarixi (YYYY-MM-DD)', date),
                  ],
                  _tf('Qeyd / Rəy', note, maxLines: 2),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: palette.brandNavy, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    final payload = <String, dynamic>{
      'stage': stage,
      '${stage}_status': status,
      '${stage}Status': status,
    };
    if (stage == 'exam' && score.text.trim().isNotEmpty) {
      final s = double.tryParse(score.text.replaceAll(',', '.'));
      payload['exam_score'] = s;
      payload['examScore'] = s;
    }
    if (date.text.trim().isNotEmpty) {
      payload['${stage}_date'] = date.text.trim();
      payload['${stage}Date'] = date.text.trim();
    }
    if (note.text.trim().isNotEmpty) {
      payload['${stage}_note'] = note.text.trim();
      payload['${stage}Note'] = note.text.trim();
    }

    final ok = await SchoolApiService.instance.updateTransitionStage(r['id'].toString(), payload);
    _snack(ok ? 'Mərhələ yeniləndi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _approve(Map<String, dynamic> r) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keçidi təsdiqlə və tətbiq et', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r['studentName']} üçün keçid təsdiqlənsin və şagirdin sinfi avtomatik yenilənsin?'),
            const SizedBox(height: 12),
            TextField(controller: note, maxLines: 2, decoration: _deco('Təsdiq qeydi (istəyə bağlı)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Təsdiqlə', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await SchoolApiService.instance.updateTransitionDecision(r['id'].toString(), approved: true, note: note.text.trim());
    _snack(success ? 'Keçid təsdiqləndi və şagirdin sinfi dəyişdirildi' : 'Əməliyyat alınmadı', ok: success);
    if (success) _load();
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keçidi rədd et', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(controller: reason, maxLines: 3, autofocus: true, decoration: _deco('Rədd səbəbini qeyd edin *')),
      ),
    );
    if (ok != true || reason.text.trim().isEmpty) return;
    final success = await SchoolApiService.instance.updateTransitionDecision(r['id'].toString(), approved: false, reason: reason.text.trim());
    _snack(success ? 'Müraciət rədd edildi' : 'Əməliyyat alınmadı', ok: success);
    if (success) _load();
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Müraciəti sil', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('${r['studentName']} keçid müraciəti silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok != true) return;
    final success = await SchoolApiService.instance.deleteTransition(r['id'].toString());
    _snack(success ? 'Müraciət silindi' : 'Əməliyyat alınmadı', ok: success);
    if (success) _load();
  }

  Future<void> _showForm({Map<String, dynamic>? record}) async {
    final palette = AppPalette.of(context);
    final isEdit = record != null;
    String type = record?['type']?.toString() ?? 'section_change';
    String? studentId = record?['studentId']?.toString();
    String? fromClassId = record?['fromClassId']?.toString();
    String? toClassId = record?['toClassId']?.toString();
    String currentYearId = (record?['currentAcademicYearId']?.toString().isNotEmpty == true)
        ? record!['currentAcademicYearId'].toString()
        : (_years.where((y) => y['isCurrent'] == true).isNotEmpty ? _years.where((y) => y['isCurrent'] == true).first['id'].toString() : (_years.isNotEmpty ? _years.first['id'].toString() : '4'));
    String targetYearId = (record?['targetAcademicYearId']?.toString().isNotEmpty == true) ? record!['targetAcademicYearId'].toString() : currentYearId;
    final fromSection = TextEditingController(text: record?['fromSection']?.toString() ?? '');
    final toSection = TextEditingController(text: record?['toSection']?.toString() ?? '');
    final fromSchool = TextEditingController(text: record?['fromSchoolName']?.toString() ?? '');
    final note = TextEditingController(text: record?['note']?.toString() ?? '');
    final discountPercent = TextEditingController(text: record?['discountPercentage']?.toString() ?? '');
    final discountAmount = TextEditingController(text: record?['discountAmount']?.toString() ?? '');
    final examScore = TextEditingController(text: record?['examScore']?.toString() ?? '');
    String examStatus = record?['examStatus']?.toString() ?? 'pending';
    String medicalStatus = record?['medicalStatus']?.toString() ?? 'pending';
    String psychologyStatus = record?['psychologyStatus']?.toString() ?? 'pending';
    final search = TextEditingController();
    String studentQuery = '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final studentResults = _students.where((s) {
            if (studentQuery.isEmpty) return true;
            final q = studentQuery.toLowerCase();
            return (s['fullName'] ?? '').toString().toLowerCase().contains(q) || (s['code'] ?? '').toString().toLowerCase().contains(q) || (s['finCode'] ?? '').toString().toLowerCase().contains(q);
          }).take(30).toList();

          return Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(ctx).bottom + 22),
            decoration: BoxDecoration(color: palette.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: palette.textTertiary.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    Text(isEdit ? 'Keçid müraciətini düzəliş et' : 'Yeni Keçid / Bölmə Dəyişikliyi', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    if (!isEdit) ...[
                      TextField(
                        controller: search,
                        onChanged: (v) => setSheet(() => studentQuery = v.trim()),
                        decoration: _deco('Şagird axtar (ad, İdrak kodu, FİN)'),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(12)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: studentResults.length,
                          itemBuilder: (_, i) {
                            final s = studentResults[i];
                            final selected = studentId == s['id']?.toString();
                            return ListTile(
                              dense: true,
                              selected: selected,
                              title: Text(s['fullName']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              subtitle: Text('${s['className']} • ${s['code']}', style: const TextStyle(fontSize: 10.5)),
                              trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 18) : null,
                              onTap: () => setSheet(() {
                                studentId = s['id']?.toString();
                                fromClassId = s['classId']?.toString();
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else
                      InputDecorator(decoration: _deco('Şagird'), child: Text(record['studentName']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: _deco('Keçid növü *'),
                      items: _types.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2, style: const TextStyle(fontSize: 12.5)))).toList(),
                      onChanged: (v) => setSheet(() => type = v ?? 'section_change'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currentYearId,
                            decoration: _deco('Cari tədris ili'),
                            isExpanded: true,
                            items: _years.map((y) => DropdownMenuItem(value: y['id']?.toString(), child: Text(y['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (v) => setSheet(() => currentYearId = v ?? currentYearId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: targetYearId,
                            decoration: _deco('Hədəf tədris ili'),
                            isExpanded: true,
                            items: _years.map((y) => DropdownMenuItem(value: y['id']?.toString(), child: Text(y['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (v) => setSheet(() => targetYearId = v ?? targetYearId),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: fromClassId,
                            decoration: _deco('Cari sinif'),
                            isExpanded: true,
                            items: _classes.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['className']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (v) => setSheet(() => fromClassId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: toClassId,
                            decoration: _deco('Hədəf sinif'),
                            isExpanded: true,
                            items: _classes.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['className']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (v) => setSheet(() => toClassId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _tf('Cari bölmə (Məs: az)', fromSection)),
                        const SizedBox(width: 8),
                        Expanded(child: _tf('Hədəf bölmə (Məs: rus, en)', toSection)),
                      ],
                    ),
                    if (type == 'school_transfer') _tf('Köhnə məktəb', fromSchool),
                    if (type == 'custom_discount') ...[
                      Row(
                        children: [
                          Expanded(child: _tf('Güzəşt %', discountPercent, keyboard: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: _tf('Güzəşt məbləği (AZN)', discountAmount, keyboard: TextInputType.number)),
                        ],
                      ),
                    ],
                    if (!isEdit) ...[
                      const SizedBox(height: 6),
                      const Text('İlkin yoxlanış statusları', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      _stageDropdown('İmtahan statusu', examStatus, (v) => setSheet(() => examStatus = v)),
                      const SizedBox(height: 8),
                      _stageDropdown('Tibbi status', medicalStatus, (v) => setSheet(() => medicalStatus = v)),
                      const SizedBox(height: 8),
                      _stageDropdown('Psixoloji status', psychologyStatus, (v) => setSheet(() => psychologyStatus = v)),
                      const SizedBox(height: 8),
                      _tf('İmtahan balı (%)', examScore, keyboard: TextInputType.number),
                    ],
                    _tf('Qeyd', note, maxLines: 2),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: palette.brandNavy, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
    if (studentId == null && !isEdit) {
      _snack('Şagird seçilməlidir', ok: false);
      return;
    }
    final payload = <String, dynamic>{
      'student_id': studentId,
      'studentId': studentId,
      'type': type,
      'current_academic_year_id': currentYearId,
      'currentAcademicYearId': currentYearId,
      'target_academic_year_id': targetYearId,
      'targetAcademicYearId': targetYearId,
      'from_class_id': fromClassId,
      'fromClassId': fromClassId,
      'to_class_id': toClassId,
      'toClassId': toClassId,
      'from_section': fromSection.text.trim(),
      'fromSection': fromSection.text.trim(),
      'to_section': toSection.text.trim(),
      'toSection': toSection.text.trim(),
      'from_school_name': fromSchool.text.trim(),
      'fromSchoolName': fromSchool.text.trim(),
      'note': note.text.trim(),
      'exam_status': examStatus,
      'examStatus': examStatus,
      'medical_status': medicalStatus,
      'medicalStatus': medicalStatus,
      'psychology_status': psychologyStatus,
      'psychologyStatus': psychologyStatus,
      'exam_score': double.tryParse(examScore.text.replaceAll(',', '.')),
      'examScore': double.tryParse(examScore.text.replaceAll(',', '.')),
      'discount_percentage': double.tryParse(discountPercent.text.replaceAll(',', '.')),
      'discountPercentage': double.tryParse(discountPercent.text.replaceAll(',', '.')),
      'discount_amount': double.tryParse(discountAmount.text.replaceAll(',', '.')),
      'discountAmount': double.tryParse(discountAmount.text.replaceAll(',', '.')),
    };
    final ok = await SchoolApiService.instance.saveTransition(payload, id: isEdit ? record['id'].toString() : null);
    _snack(ok ? 'Müraciət uğurla saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Widget _stageDropdown(String label, String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _deco(label),
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Gözlənilir')),
        DropdownMenuItem(value: 'passed', child: Text('Keçib (Müsbət)')),
        DropdownMenuItem(value: 'failed', child: Text('Keçməyib (Uyğunsuz)')),
        DropdownMenuItem(value: 'exempt', child: Text('Azad')),
      ],
      onChanged: (v) => onChanged(v ?? 'pending'),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11.5),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      );

  Widget _tf(String label, TextEditingController c, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, maxLines: maxLines, keyboardType: keyboard, decoration: _deco(label)),
      );
}
