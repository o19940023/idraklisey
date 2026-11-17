import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_page.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import '../../students/screens/api_students_screen.dart';
import '../../students/services/academic_meta.dart';

class ApiAdmissionsScreen extends StatefulWidget {
  const ApiAdmissionsScreen({super.key});

  @override
  State<ApiAdmissionsScreen> createState() => _ApiAdmissionsScreenState();
}

class _ApiAdmissionsScreenState extends State<ApiAdmissionsScreen> with SingleTickerProviderStateMixin {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  late final TabController _tabController;

  static const _tabs = [
    ('pending', 'Gözləyən'),
    ('contracted', 'Müqaviləli'),
    ('rejected_psychology', 'Psixoloq rəddi'),
    ('all', 'Hamısı'),
  ];

  final Map<String, List<Map<String, dynamic>>> _cache = {};
  String _activeTab = 'pending';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final tab = _tabs[_tabController.index].$1;
      if (tab != _activeTab) {
        setState(() => _activeTab = tab);
        _load();
      }
    });
    AcademicMeta.instance.load().catchError((_) {});
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client.get('academic/admissions', query: {
        'tab': _activeTab,
        'per_page': 50,
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
        if (AcademicMeta.instance.currentYear?['id'] != null)
          'academic_year_id': AcademicMeta.instance.currentYear!['id'],
      });

      setState(() {
        _cache[_activeTab] = parsePage(response).items;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _updateStage(Map<String, dynamic> student) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        String stage = 'exam';
        String status = 'passed';
        final scoreController = TextEditingController();
        final noteController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mərhələ: ${student['full_name'] ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'exam', label: Text('İmtahan')),
                    ButtonSegment(value: 'medical', label: Text('Tibbi')),
                    ButtonSegment(value: 'psychology', label: Text('Psixoloq')),
                  ],
                  selected: {stage},
                  onSelectionChanged: (values) => setSheetState(() => stage = values.first),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Nəticə', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Gözləyir')),
                    DropdownMenuItem(value: 'passed', child: Text('Keçdi')),
                    DropdownMenuItem(value: 'failed', child: Text('Keçmədi')),
                    DropdownMenuItem(value: 'exempt', child: Text('Azad')),
                  ],
                  onChanged: (value) => setSheetState(() => status = value ?? 'passed'),
                ),
                const SizedBox(height: 12),
                if (stage == 'exam')
                  TextField(
                    controller: scoreController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'İmtahan balı', border: OutlineInputBorder()),
                  ),
                if (stage == 'exam') const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Qeyd', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, {
                    'stage': stage,
                    'status': status,
                    'exam_score': double.tryParse(scoreController.text.replaceAll(',', '.')),
                    'exam_date': DateTime.now().toIso8601String().substring(0, 10),
                    'note': noteController.text.trim(),
                    'exam_status': status,
                  }),
                  child: const Text('Yadda saxla'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await _client.post('academic/admissions/${student['id']}/stage', data: result);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mərhələ yeniləndi.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> student) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Qəbuldan imtina'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Səbəb *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ləğv et')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, reasonController.text.trim()),
            child: const Text('İmtina et'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await _client.post('academic/admissions/${student['id']}/reject', data: {'reason': reason});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Qəbuldan imtina edildi.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final canManage = session.can('gopanel.academic.students.admissions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qəbul'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab.$2)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Ad, soyad, kod və ya FİN',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          Expanded(child: _body(canManage)),
        ],
      ),
    );
  }

  Widget _body(bool canManage) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _load, child: const Text('Yenidən cəhd et')),
          ],
        ),
      );
    }

    final items = _cache[_activeTab] ?? const <Map<String, dynamic>>[];
    if (items.isEmpty) {
      return Center(child: Text('Müraciət yoxdur.', style: TextStyle(color: AppColors.textMuted)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final student = items[index];
          final contractStatus = student['contract_status']?.toString();
          final examScore = student['exam_score'];

          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApiStudentDetailScreen(studentId: student['id'] as int? ?? 0),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student['full_name']?.toString() ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                        ),
                        if (student['status'] != null)
                          _pill(student['status'].toString()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (student['target_grade_level'] != null)
                          '${student['target_grade_level']}-ci sinif',
                        if (contractStatus != null) contractStatus,
                        if (examScore != null) 'Bal: $examScore',
                      ].join(' · '),
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (canManage) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () => _updateStage(student),
                              icon: const Icon(Icons.fact_check_rounded, size: 17),
                              label: const Text('Mərhələ', style: TextStyle(fontSize: 12.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                              onPressed: () => _reject(student),
                              icon: const Icon(Icons.block_rounded, size: 17),
                              label: const Text('İmtina', style: TextStyle(fontSize: 12.5)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pill(String label) {
    final lower = label.toLowerCase();
    final color = lower.contains('rədd')
        ? AppColors.danger
        : lower.contains('gözl')
            ? AppColors.warning
            : lower.contains('təsdiq')
                ? AppColors.success
                : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(7)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}
