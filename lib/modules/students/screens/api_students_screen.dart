import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_page.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import 'api_student_wizard_screen.dart';
import '../services/academic_meta.dart';

class ApiStudentsScreen extends StatefulWidget {
  const ApiStudentsScreen({super.key, this.initialClassId});

  final int? initialClassId;

  @override
  State<ApiStudentsScreen> createState() => _ApiStudentsScreenState();
}

class _ApiStudentsScreenState extends State<ApiStudentsScreen> {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int? _classId;
  String? _sector;
  bool _activeOnly = true;

  @override
  void initState() {
    super.initState();
    _classId = widget.initialClassId;
    _scrollController.addListener(_onScroll);
    AcademicMeta.instance.load().catchError((_) {});
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 320) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final response = await _client.get('academic/students', query: {
        'page': reset ? 1 : _page + 1,
        'per_page': 20,
        'is_active': _activeOnly ? 1 : 0,
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
        if (_classId != null) 'class_id': _classId,
        if (_sector != null) 'sector': _sector,
      });

      final page = parsePage(response);

      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final canCreate = session.can('gopanel.academic.students.create');

    return Scaffold(
      appBar: AppBar(title: const Text('Şagirdlər')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ApiStudentWizardScreen()),
                );
                if (created == true) _load(reset: true);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Yeni şagird'),
            )
          : null,
      body: Column(
        children: [
          _filters(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _filters() {
    final meta = AcademicMeta.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(70)),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Ad, soyad, kod və ya FİN',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Aktiv', style: TextStyle(fontSize: 12)),
                  selected: _activeOnly,
                  onSelected: (value) {
                    setState(() => _activeOnly = value);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Deaktiv', style: TextStyle(fontSize: 12)),
                  selected: !_activeOnly,
                  onSelected: (value) {
                    setState(() => _activeOnly = !value);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 10),
                if (meta.sectors.isNotEmpty)
                  DropdownButton<String?>(
                    value: _sector,
                    hint: const Text('Sektor', style: TextStyle(fontSize: 12)),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Hamısı', style: TextStyle(fontSize: 12))),
                      ...meta.sectors.map((s) => DropdownMenuItem<String?>(
                            value: s['value']?.toString(),
                            child: Text(s['label']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _sector = value);
                      _load(reset: true);
                    },
                  ),
                const SizedBox(width: 10),
                if (meta.classes.isNotEmpty)
                  DropdownButton<int?>(
                    value: _classId,
                    hint: const Text('Sinif', style: TextStyle(fontSize: 12)),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Hamısı', style: TextStyle(fontSize: 12))),
                      ...meta.classes.map((c) => DropdownMenuItem<int?>(
                            value: (c['id'] as num?)?.toInt(),
                            child: Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _classId = value);
                      _load(reset: true);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: () => _load(reset: true), child: const Text('Yenidən cəhd et')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text('Şagird tapılmadı.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final student = _items[index];
          final className = student['class_name']?.toString();
          final statusLabel = student['status']?.toString();

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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.primaryAccent.withAlpha(24),
                      child: Text(
                        (student['name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['full_name']?.toString() ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              className,
                              student['code'],
                              student['fin_code'],
                            ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (statusLabel != null && statusLabel.isNotEmpty && statusLabel != '—')
                      _pill(statusLabel),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
    final color = label.toLowerCase().contains('rədd') || label.toLowerCase().contains('deaktiv')
        ? AppColors.danger
        : label.toLowerCase().contains('gözl')
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(7)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

// =====================================================================
// Detail
// =====================================================================

class ApiStudentDetailScreen extends StatefulWidget {
  const ApiStudentDetailScreen({super.key, required this.studentId});

  final int studentId;

  @override
  State<ApiStudentDetailScreen> createState() => _ApiStudentDetailScreenState();
}

class _ApiStudentDetailScreenState extends State<ApiStudentDetailScreen> {
  final _client = ApiClient.instance;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AcademicMeta.instance.load().catchError((_) {});
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client.get('academic/students/${widget.studentId}');
      final data = response is Map ? response['data'] : null;
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus() async {
    final meta = AcademicMeta.instance;
    final statuses = meta.studentStatuses;
    if (statuses.isEmpty) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        String? statusKey = _data?['status_key']?.toString();
        final noteController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Status dəyişikliyi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: statusKey,
                  decoration: const InputDecoration(labelText: 'Yeni status', border: OutlineInputBorder()),
                  items: statuses
                      .map((s) => DropdownMenuItem(
                            value: s['key']?.toString(),
                            child: Text(s['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (value) => setSheetState(() => statusKey = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Qeyd', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: statusKey == null
                      ? null
                      : () => Navigator.pop(sheetContext, {
                            'status_key': statusKey,
                            'note': noteController.text.trim(),
                          }),
                  child: const Text('Yadda saxla'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() => _busy = true);
    try {
      await _client.post('academic/students/${widget.studentId}/status', data: selected);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status dəyişdirildi.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final canUpdate = session.can('gopanel.academic.students.update');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şagird profili'),
        actions: [
          if (canUpdate)
            IconButton(
              tooltip: 'Status dəyiş',
              onPressed: _busy ? null : _changeStatus,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          IconButton(tooltip: 'Yenilə', onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
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

    final data = _data;
    if (data == null) return const Center(child: Text('Şagird tapılmadı.'));

    final profile = data['profile'] is Map ? Map<String, dynamic>.from(data['profile'] as Map) : const {};
    final parents = (data['parents'] as List?)?.whereType<Map>().toList() ?? const [];
    final classes = (data['class_history'] as List?)?.whereType<Map>().toList() ?? const [];
    final contracts = (data['contracts'] as List?)?.whereType<Map>().toList() ?? const [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['full_name']?.toString() ?? '—',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    data['class_name'],
                    data['code'],
                    data['status'],
                  ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('Şəxsi məlumat', [
            _row('FİN kod', data['fin_code'] ?? profile['fin_code']),
            _row('Cins', _gender(profile['gender'])),
            _row('Doğum tarixi', profile['birth_date']),
            _row('Qan qrupu', profile['blood_group']),
            _row('Göz rəngi', profile['eye_color']),
            _row('E-poçt', data['email']),
            _row('Telefon', data['phone']),
            _row('Ünvan', profile['actual_address'] ?? profile['address']),
          ]),
          const SizedBox(height: 14),
          _section('Valideynlər', parents.isEmpty
              ? [_row('', 'Qeyd yoxdur')]
              : parents.map((parent) {
                  return _row(
                    parent['parent_type']?.toString() ?? 'Valideyn',
                    '${parent['name'] ?? ''} · ${parent['phone'] ?? ''}',
                  );
                }).toList()),
          const SizedBox(height: 14),
          _section('Sinif tarixçəsi', classes.isEmpty
              ? [_row('', 'Qeyd yoxdur')]
              : classes.map((item) {
                  return _row(
                    item['class_name']?.toString() ?? '—',
                    '${item['start_date'] ?? ''} → ${item['end_date'] ?? 'davam edir'}',
                  );
                }).toList()),
          const SizedBox(height: 14),
          _section('Müqavilələr', contracts.isEmpty
              ? [_row('', 'Müqavilə yoxdur')]
              : contracts.map((contract) {
                  return _row(
                    contract['code']?.toString() ?? 'Müqavilə',
                    '${contract['status']} · ${contract['final_amount']} ₼',
                  );
                }).toList()),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty || text == 'null') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 130,
              child: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String? _gender(dynamic value) {
    if (value == 'male') return 'Kişi';
    if (value == 'female') return 'Qadın';
    return value?.toString();
  }
}
