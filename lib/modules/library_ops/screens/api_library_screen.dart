import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_page.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';

class ApiLibraryScreen extends StatefulWidget {
  const ApiLibraryScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ApiLibraryScreen> createState() => _ApiLibraryScreenState();
}

class _ApiLibraryScreenState extends State<ApiLibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isStaff = session.profile?.isStaff == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitabxana'),
        bottom: TabBar(
          controller: _tabController,
          tabs: isStaff
              ? const [
                  Tab(text: 'Rezervasiyalar'),
                  Tab(text: 'İcarələr'),
                  Tab(text: 'Kitablar'),
                ]
              : const [
                  Tab(text: 'Kitablar'),
                  Tab(text: 'İcarələrim'),
                  Tab(text: 'Rezervasiyalarım'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isStaff
            ? [
                _ReservationsTab(onChanged: _reloadAll),
                _LoansTab(onChanged: _reloadAll),
                _BooksTab(isStaff: true, onChanged: _reloadAll),
              ]
            : [
                _BooksTab(isStaff: false, onChanged: _reloadAll),
                _LoansTab(onChanged: _reloadAll),
                _ReservationsTab(onChanged: _reloadAll),
              ],
      ),
    );
  }

  void _reloadAll() {
    // Tabs listen to their own refresh; this hook exists for future cross-tab
    // invalidation (approving a reservation creates a loan).
    setState(() {});
  }
}

// =====================================================================
// Reservations
// =====================================================================

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  final _client = ApiClient.instance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client.get('library/reservations', query: {
        'per_page': 50,
        if (_statusFilter != null) 'status': _statusFilter,
      });
      setState(() {
        _items = parsePage(response).items;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rezervasiyanı təsdiqlə'),
        content: Text(
          '${item['book_title'] ?? 'Kitab'} — ${item['student_name'] ?? 'Şagird'}\n\n'
          'Təsdiqlədikdə kitab icarəyə veriləcək və stok azalacaq.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Ləğv et')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Təsdiqlə')),
        ],
      ),
    );

    if (approved != true) return;

    try {
      await _client.post('library/reservations/${item['id']}/approve', data: {});
      await _load();
      widget.onChanged();
      _toast('Rezervasiya təsdiqləndi və icarə yaradıldı.');
    } on ApiException catch (e) {
      _toast(e.message, isError: true);
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rezervasiyanı rədd et'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Səbəb (istəyə bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ləğv et')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Rədd et'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      await _client.post('library/reservations/${item['id']}/reject', data: {
        if (reason.isNotEmpty) 'reason': reason,
      });
      await _load();
      widget.onChanged();
      _toast('Rezervasiya rədd edildi.');
    } on ApiException catch (e) {
      _toast(e.message, isError: true);
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final canManage = session.can('gopanel.library.reservations.manage');

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              _chip('Hamısı', null),
              const SizedBox(width: 8),
              _chip('Gözləyir', 'pending'),
              const SizedBox(width: 8),
              _chip('Təsdiqlənib', 'approved'),
              const SizedBox(width: 8),
              _chip('Rədd edilib', 'rejected'),
            ],
          ),
        ),
        Expanded(child: _body(canManage)),
      ],
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _load();
      },
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
    if (_items.isEmpty) {
      return Center(child: Text('Rezervasiya yoxdur.', style: TextStyle(color: AppColors.textMuted)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          final status = item['status']?.toString() ?? '';
          final isPending = status == 'pending';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                        item['book_title']?.toString() ?? 'Kitab',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ),
                    _statusPill(item['status_label']?.toString() ?? status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    item['author'],
                    item['inventory_code'],
                  ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['student_name']?.toString() ?? '—',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    if (item['due_date'] != null)
                      Text(
                        'Son: ${item['due_date']}',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                  ],
                ),
                if (isPending && canManage) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: () => _approve(item),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Təsdiqlə'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                          onPressed: () => _reject(item),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rədd et'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// Loans
// =====================================================================

class _LoansTab extends StatefulWidget {
  const _LoansTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<_LoansTab> {
  final _client = ApiClient.instance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _onlyOverdue = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client.get('library/loans', query: {
        'per_page': 50,
        if (_onlyOverdue) 'overdue': 1,
      });
      setState(() {
        _items = parsePage(response).items;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _return(Map<String, dynamic> item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String type = 'normal';
        final noteController = TextEditingController();
        final fineController = TextEditingController(text: '0');

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kitabı təhvil al',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  item['book_title']?.toString() ?? '',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'normal', label: Text('Normal')),
                    ButtonSegment(value: 'damaged', label: Text('Zədəli')),
                    ButtonSegment(value: 'lost', label: Text('İtirilib')),
                  ],
                  selected: {type},
                  onSelectionChanged: (values) => setSheetState(() => type = values.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Qeyd (istəyə bağlı)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cərimə (₼)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, {
                    'return_type': type,
                    'return_note': noteController.text.trim(),
                    'fine_amount': double.tryParse(fineController.text.replaceAll(',', '.')) ?? 0,
                  }),
                  child: const Text('Təhvil al'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await _client.post('library/loans/${item['id']}/return', data: result);
      await _load();
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kitab təhvil alındı.')),
      );
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
    final canReturn = session.can('gopanel.library.loans.return');

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Yalnız gecikmişlər', style: TextStyle(fontSize: 12)),
                selected: _onlyOverdue,
                onSelected: (value) {
                  setState(() => _onlyOverdue = value);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? Center(child: Text('İcarə yoxdur.', style: TextStyle(color: AppColors.textMuted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isOnLoan = item['status'] == 'on_loan';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item['is_overdue'] == true
                                ? AppColors.danger.withAlpha(90)
                                : Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['book_title']?.toString() ?? 'Kitab',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                  ),
                                ),
                                _statusPill(
                                  item['status_label']?.toString() ?? '',
                                  danger: item['is_overdue'] == true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['student_name'] ?? '—'} · ${item['inventory_code'] ?? ''}',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Verilib: ${item['loan_date'] ?? '—'}', style: const TextStyle(fontSize: 11.5)),
                                const SizedBox(width: 12),
                                Text('Son: ${item['due_date'] ?? '—'}', style: const TextStyle(fontSize: 11.5)),
                                if (item['is_overdue'] == true) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item['days_overdue']} gün gecikib',
                                    style: const TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                            if (isOnLoan && canReturn) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAccent),
                                  onPressed: () => _return(item),
                                  icon: const Icon(Icons.assignment_return_rounded, size: 18),
                                  label: const Text('Geri təhvil al'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// =====================================================================
// Books
// =====================================================================

class _BooksTab extends StatefulWidget {
  const _BooksTab({required this.isStaff, required this.onChanged});

  final bool isStaff;
  final VoidCallback onChanged;

  @override
  State<_BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<_BooksTab> {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _groupByTitle = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client.get('library/books', query: {
        'per_page': 500,
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
      });
      setState(() {
        _items = parsePage(response).items;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _displayItems {
    if (!_groupByTitle) return _items;

    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in _items) {
      final titleKey = (item['title'] ?? '').toString().trim().toLowerCase();
      final authorKey = (item['author'] ?? '').toString().trim().toLowerCase();
      final key = '$titleKey|$authorKey';
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups.values.map((group) {
      // Find an available copy first, or default to first copy
      final availableCopy = group.firstWhere(
        (b) => b['is_available'] == true && ((b['available_copies'] as num?)?.toInt() ?? 0) > 0,
        orElse: () => group.first,
      );

      final totalCopies = group.fold<int>(
        0,
        (sum, b) => sum + ((b['total_copies'] as num?)?.toInt() ?? 1),
      );
      final availableCopies = group.fold<int>(
        0,
        (sum, b) => sum + ((b['available_copies'] as num?)?.toInt() ?? 0),
      );
      final isAvailable = availableCopies > 0;

      return {
        ...availableCopy,
        'group_total_copies': totalCopies,
        'group_available_copies': availableCopies,
        'group_is_available': isAvailable,
        'physical_count': group.length,
      };
    }).toList();
  }

  Future<void> _reserve(Map<String, dynamic> book) async {
    final session = context.read<SessionController>();
    String? childId;

    if (session.profile?.isParent == true) {
      final children = (session.linked['children'] as List?)?.whereType<Map>().toList() ?? [];
      if (children.isEmpty) {
        _toast('Övlad tapılmadı.', isError: true);
        return;
      }

      childId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Hansı övlad üçün?'),
          children: children
              .map((child) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogContext, child['id'].toString()),
                    child: Text(child['name']?.toString() ?? '—'),
                  ))
              .toList(),
        ),
      );

      if (childId == null) return;
    }

    try {
      await _client.post('library/reservations', data: {
        'book_id': book['id'],
        if (childId != null) 'student_id': int.tryParse(childId),
      });
      widget.onChanged();
      _toast('Rezervasiya sorğusu göndərildi.');
    } on ApiException catch (e) {
      _toast(e.message, isError: true);
    }
  }

  Future<void> _createBook() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();
    final copiesController = TextEditingController(text: '1');
    final categories = await _fetchCategories();
    int? categoryId;

    if (!mounted) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Yeni kitab',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Kitabın adı *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: 'Müəllif', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: isbnController,
                  decoration: const InputDecoration(labelText: 'ISBN', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Kateqoriya', border: OutlineInputBorder()),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as int?,
                            child: Text(c['title']?.toString() ?? '—'),
                          ))
                      .toList(),
                  onChanged: (value) => setSheetState(() => categoryId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: copiesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nüsxə sayı', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final copies = int.tryParse(copiesController.text) ?? 1;
                    try {
                      await _client.post('library/books', data: {
                        'title': titleController.text.trim(),
                        'author': authorController.text.trim().isEmpty ? null : authorController.text.trim(),
                        'isbn': isbnController.text.trim().isEmpty ? null : isbnController.text.trim(),
                        'category_id': categoryId,
                        'total_copies': copies,
                        'quantity': copies,
                      });
                      if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                    } on ApiException catch (e) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
                        );
                      }
                    }
                  },
                  child: const Text('Yadda saxla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) {
      await _load();
      widget.onChanged();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      final response = await _client.get('library/categories');
      final data = response is Map ? response['data'] : null;
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } on ApiException catch (_) {}
    return [];
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final canCreate = widget.isStaff && session.can('gopanel.library.books.create');
    final canReserve = !widget.isStaff;

    final displayCount = _displayItems.length;
    final totalInventory = _items.length;

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _createBook,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Kitab əlavə et'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Ad, müəllif, ISBN və ya kod',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Axtar',
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (!_loading && _error == null && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Çeşidlər üzrə', style: TextStyle(fontSize: 12)),
                    selected: _groupByTitle,
                    onSelected: (val) {
                      if (val) setState(() => _groupByTitle = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Bütün fond (İnventar)', style: TextStyle(fontSize: 12)),
                    selected: !_groupByTitle,
                    onSelected: (val) {
                      if (val) setState(() => _groupByTitle = false);
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _groupByTitle
                          ? '$displayCount çeşid • $totalInventory fond'
                          : '$totalInventory nüsxə',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _body(canReserve)),
        ],
      ),
    );
  }

  Widget _body(bool canReserve) {
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
    final items = _displayItems;
    if (items.isEmpty) {
      return Center(child: Text('Kitab tapılmadı.', style: TextStyle(color: AppColors.textMuted)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final available = _groupByTitle
              ? (item['group_is_available'] == true)
              : (item['is_available'] == true);
          final availCopies = _groupByTitle
              ? (item['group_available_copies'] ?? 0)
              : (item['available_copies'] ?? 0);
          final physicalCount = item['physical_count'] ?? 1;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          item['author'],
                          item['category'] is Map ? (item['category'] as Map)['title'] : null,
                          if (!_groupByTitle) item['code'],
                        ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _groupByTitle
                            ? (available
                                ? 'Mövcud: $availCopies nüsxə ($physicalCount fond nüsxəsi)'
                                : 'Mövcud deyil ($physicalCount nüsxənin hamısı icarədədir)')
                            : (available ? 'Mövcud: $availCopies nüsxə' : 'Mövcud deyil'),
                        style: TextStyle(
                          color: available ? AppColors.success : AppColors.danger,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canReserve)
                  FilledButton.tonal(
                    onPressed: available ? () => _reserve(item) : null,
                    child: const Text('Rezerv et', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _statusPill(String label, {bool danger = false}) {
  final color = danger
      ? AppColors.danger
      : label.contains('Təsdiq') || label.contains('İcarədə')
          ? AppColors.success
          : label.contains('Gözl') 
              ? AppColors.warning
              : label.contains('Rədd')
                  ? AppColors.danger
                  : AppColors.info;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
