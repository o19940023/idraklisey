import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_page.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import 'student_payments_screen.dart';

enum FinanceTab { summary, contracts, payments, ledger }

class ApiFinanceScreen extends StatefulWidget {
  const ApiFinanceScreen({super.key, this.initialTab = FinanceTab.contracts});

  final FinanceTab initialTab;

  @override
  State<ApiFinanceScreen> createState() => _ApiFinanceScreenState();
}

class _ApiFinanceScreenState extends State<ApiFinanceScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<FinanceTab> _tabs = const [];

  List<FinanceTab> _availableTabs(SessionController session) {
    final isStaff = session.profile?.isStaff == true;
    final tabs = <FinanceTab>[];
    if (isStaff &&
        (session.can('gopanel.finance.payments.view') ||
            session.can('gopanel.finance.student_contracts.view'))) {
      tabs.add(FinanceTab.summary);
    }
    tabs.add(FinanceTab.contracts);
    if (isStaff && session.can('gopanel.finance.payments.view')) {
      tabs.add(FinanceTab.payments);
    }
    if (isStaff && session.can('gopanel.finance.ledger.view')) {
      tabs.add(FinanceTab.ledger);
    }
    return tabs;
  }

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _tabs = _availableTabs(session);
    final index = _tabs.indexOf(widget.initialTab).clamp(0, _tabs.length - 1);
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: index);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isStaff = session.profile?.isStaff == true;
    final tabs = _availableTabs(session);

    final labels = {
      FinanceTab.summary: 'Xülasə',
      FinanceTab.contracts: isStaff ? 'Müqavilələr' : 'Müqavilələrim',
      FinanceTab.payments: 'Ödənişlər',
      FinanceTab.ledger: 'Baş kitab',
    };

    final body = tabs
        .map((tab) => switch (tab) {
              FinanceTab.summary => const _SummaryTab(),
              FinanceTab.contracts =>
                _ContractsTab(canCreatePayment: _canCreatePayment(session)),
              FinanceTab.payments => const _PaymentsTab(),
              FinanceTab.ledger => const _LedgerTab(),
            })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maliyyə'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final t in tabs) Tab(text: labels[t])],
        ),
      ),
      body: TabBarView(controller: _tabController, children: body),
    );
  }

  bool _canCreatePayment(SessionController session) =>
      session.can('gopanel.finance.payments.create') ||
      session.can('gopanel.finance.invoices.manage_payments');
}

// =====================================================================
// Shared helpers
// =====================================================================

String _money(dynamic value) {
  final amount = (num.tryParse(value?.toString() ?? '') ?? 0).toDouble();
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return '$whole,${parts[1]} ₼';
}

String _shortDate(dynamic value) {
  if (value == null) return '—';
  final raw = value.toString();
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw;
}

String? _resolveDateRangeFrom(String? key) {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  switch (key) {
    case 'month':
      return date(DateTime(now.year, now.month, 1));
    case '30d':
      return date(now.subtract(const Duration(days: 30)));
    case 'year':
      return date(DateTime(now.year, 1, 1));
    case 'all':
      return '2000-01-01';
    default:
      return null;
  }
}

String? _resolveDateRangeTo(String? key) {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  switch (key) {
    case 'month':
      return date(DateTime(now.year, now.month + 1, 0));
    case '30d':
      return date(now);
    case 'year':
      return date(DateTime(now.year, 12, 31));
    case 'all':
      return '2099-12-31';
    default:
      return null;
  }
}

const _dateOptions = {
  'month': 'Bu ay',
  '30d': 'Son 30 gün',
  'year': 'Bu il',
  'all': 'Hamısı',
};

Widget _dateChips(String selected, ValueChanged<String> onSelected) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
    child: Row(
      children: [
        for (final entry in _dateOptions.entries) ...[
          FilterChip(
            label: Text(entry.value, style: const TextStyle(fontSize: 12)),
            selected: selected == entry.key,
            onSelected: (_) => onSelected(entry.key),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

Widget _errorView(String message, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 42, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Yenidən cəhd tətbiq et')),
      ],
    ),
  );
}

String _statusLabel(String? status) {
  switch (status) {
    case 'draft':
      return 'Qaralama';
    case 'signed':
      return 'İmzalanıb';
    case 'active':
      return 'Aktiv';
    case 'cancelled':
      return 'Ləğv edilib';
    case 'completed':
      return 'Tamamlanıb';
    default:
      return status ?? '—';
  }
}

Color _statusColor(String? status) {
  switch (status) {
    case 'active':
    case 'completed':
      return AppColors.success;
    case 'signed':
      return AppColors.info;
    case 'draft':
      return AppColors.warning;
    case 'cancelled':
      return AppColors.danger;
    default:
      return AppColors.textMuted;
  }
}

// =====================================================================
// Summary tab
// =====================================================================

class _SummaryTab extends StatefulWidget {
  const _SummaryTab();

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  final _client = ApiClient.instance;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _range = 'month';

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
      final response = await _client.get('finance/summary', query: {
        'from': _resolveDateRangeFrom(_range),
        'to': _resolveDateRangeTo(_range),
      });
      final data = response['data'];
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Məlumat yüklənə bilmədi.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dateChips(_range, (value) {
            setState(() => _range = value);
            _load();
          }),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: _errorView(_error!, _load),
            )
          else ...[
            _statGrid(),
            const SizedBox(height: 14),
            _rangeInfo(theme),
          ],
        ],
      ),
    );
  }

  Widget _statGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossCount = width >= 720 ? 4 : 2;
        final cards = [
          _StatCard(
            title: 'Müqavilə həcmi',
            value: _money(_data?['contracts_total']),
            icon: Icons.receipt_long_rounded,
            color: AppColors.primaryAccent,
          ),
          _StatCard(
            title: 'Ödənişlər',
            value: _money(_data?['payments_total']),
            icon: Icons.payments_rounded,
            color: AppColors.success,
          ),
          _StatCard(
            title: 'Qalıq borc',
            value: _money(_data?['debt_total']),
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),
          _StatCard(
            title: 'Ödəniş sayı',
            value: '${_data?['payments_count'] ?? 0}',
            subtitle: '${_data?['contracts_count'] ?? 0} müqavilə',
            icon: Icons.receipt_rounded,
            color: AppColors.info,
          ),
        ];

        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: width >= 720 ? 2.6 : 1.35,
          children: cards,
        );
      },
    );
  }

  Widget _rangeInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '${_dateOptions[_range]} (${_data?['from'] ?? '—'} → ${_data?['to'] ?? '—'})',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// Contracts (invoices) tab
// =====================================================================

class _ContractsTab extends StatefulWidget {
  const _ContractsTab({required this.canCreatePayment});

  final bool canCreatePayment;

  @override
  State<_ContractsTab> createState() => _ContractsTabState();
}

class _ContractsTabState extends State<_ContractsTab> {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];

  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 360) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    setState(() {
      if (reset) {
        _loading = true;
        _page = 1;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final response = await _client.get('finance/invoices', query: {
        'page': reset ? 1 : _page + 1,
        'per_page': 25,
        if (_statusFilter != null) 'status': _statusFilter,
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
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
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Məlumat yüklənə bilmədi.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _openDetail(Map<String, dynamic> item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _InvoiceDetailScreen(
          invoiceId: (item['id'] as num).toInt(),
          initialItem: item,
          canCreatePayment: widget.canCreatePayment,
        ),
      ),
    );
    if (changed == true && mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Şagird / müqavilə kodu...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Row(
            children: [
              for (final entry in const {
                null: 'Hamısı',
                'active': 'Aktiv',
                'signed': 'İmzalanıb',
                'draft': 'Qaralama',
                'cancelled': 'Ləğv',
              }.entries) ...[
                FilterChip(
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                  selected: _statusFilter == entry.key,
                  onSelected: (_) {
                    setState(() => _statusFilter = entry.key);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(child: _body(theme)),
      ],
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading && _items.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (_error != null && _items.isEmpty) {
      return _errorView(_error!, () => _load(reset: true));
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, size: 46, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Müqavilə tapılmadı.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final item = _items[index];
          return _ContractCard(item: item, onTap: () => _openDetail(item));
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (num.tryParse(item['final_amount']?.toString() ?? '') ?? 0).toDouble();
    final paid = (num.tryParse(item['paid_amount']?.toString() ?? '') ?? 0).toDouble();
    final remaining = (num.tryParse(item['remaining_amount']?.toString() ?? '') ?? 0).toDouble();
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final status = item['status']?.toString();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['student']?.toString() ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withAlpha(24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${item['code'] ?? ''} · ${item['academic_year'] ?? ''}',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: remaining <= 0 ? AppColors.success : AppColors.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    remaining <= 0 ? 'Ödənilib' : '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: remaining <= 0 ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _money(item['final_amount']),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    remaining > 0 ? 'Qalıq: ${_money(item['remaining_amount'])}' : 'Tam ödənilib',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: remaining > 0 ? AppColors.warning : AppColors.success,
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

// =====================================================================
// Invoice detail
// =====================================================================

class _InvoiceDetailScreen extends StatefulWidget {
  const _InvoiceDetailScreen({
    required this.invoiceId,
    required this.initialItem,
    required this.canCreatePayment,
  });

  final int invoiceId;
  final Map<String, dynamic> initialItem;
  final bool canCreatePayment;

  @override
  State<_InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<_InvoiceDetailScreen> {
  final _client = ApiClient.instance;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

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
      final response = await _client.get('finance/invoices/${widget.invoiceId}');
      final data = response['data'];
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Məlumat yüklənə bilmədi.';
        _loading = false;
      });
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.danger : null),
    );
  }

  Future<void> _openPaymentSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PaymentSheet(invoice: _data ?? widget.initialItem),
    );

    if (saved == true) {
      await _load();
      if (mounted) _toast('Ödəniş uğurla qeydə alındı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _data ?? widget.initialItem;

    final remaining = data['remaining_amount'];

    return Scaffold(
      appBar: AppBar(title: Text(data['code']?.toString() ?? 'Müqavilə')),
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data == null
              ? _errorView(_error!, _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _header(theme, data),
                      const SizedBox(height: 14),
                      _infoCard(theme, data),
                      const SizedBox(height: 14),
                      _scheduleCard(theme, data),
                      const SizedBox(height: 14),
                      _paymentsCard(theme, data),
                      const SizedBox(height: 20),
                      if ((num.tryParse(remaining?.toString() ?? '0') ?? 0) > 0 &&
                          widget.canCreatePayment)
                        FilledButton.icon(
                          onPressed: _openPaymentSheet,
                          icon: const Icon(Icons.add_card_rounded),
                          label: const Text('Ödəniş qeyd et'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _header(ThemeData theme, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryAccent.withAlpha(210)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['student']?.toString() ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          if (data['parent'] != null) ...[
            const SizedBox(height: 2),
            Text(
              'Valideyn: ${data['parent']}',
              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _money(data['final_amount']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ödənilib: ${_money(data['paid_amount'])}  ·  Qalıq: ${_money(data['remaining_amount'])}',
            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoCard(ThemeData theme, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          _infoRow('Status', _statusLabel(data['status']?.toString())),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(70)),
          _infoRow('Müqavilə tipi', (data['contract_type'] ?? '—').toString()),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(70)),
          _infoRow('Təhsil ili', (data['academic_year'] ?? '—').toString()),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(70)),
          _infoRow('Endirim kateqoriyası', (data['discount_category'] ?? '—').toString()),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(70)),
          _infoRow('Ümumi məbləğ', _money(data['total_amount'])),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(70)),
          _infoRow('Endirim', _money(data['discount_amount'])),
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withAlpha(70)),
          _infoRow('Yekun məbləğ', _money(data['final_amount'])),
        ],
      ),
    );
  }

  Widget _scheduleCard(ThemeData theme, Map<String, dynamic> data) {
    final schedule = data['payment_schedule'];
    final items = schedule is List ? schedule : const [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ödəniş qrafiki', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...items.map((item) {
            final row = Map<String, dynamic>.from(item as Map);
            final label = (row['label'] ?? row['title'] ?? row['installment'] ?? '').toString();
            final amount = row['amount'] ?? row['price'] ?? '';
            final date = row['date'] ?? row['due_date'] ?? row['payment_date'] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label.isEmpty ? date.toString() : '$label · $date',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    _money(amount),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _paymentsCard(ThemeData theme, Map<String, dynamic> data) {
    final payments = data['payments'];
    final items = payments is List ? payments.cast<Map>() : <Map>[];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Ödəniş tarixçəsi', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(
                '${items.length} ödəniş',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Bu şagird üzrə ödəniş tarixçəsi yoxdur.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else
            ...items.map((row) {
              final item = Map<String, dynamic>.from(row);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_shortDate(item['payment_date'])} · ${item['payment_method'] ?? ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (item['payer'] != null)
                            Text(
                              item['payer'].toString(),
                              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _money(item['amount']),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// =====================================================================
// Payment entry sheet
// =====================================================================

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.invoice});

  final Map<String, dynamic> invoice;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _client = ApiClient.instance;

  late final TextEditingController _amountController = TextEditingController(
    text: (num.tryParse(widget.invoice['remaining_amount']?.toString() ?? '0') ?? 0)
        .toStringAsFixed(2),
  );
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  String _method = 'cash';
  bool _isProportional = true;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String get _dateFormatted {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_date.year}-${two(_date.month)}-${two(_date.day)}';
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Məbləğ 0-dan böyük olmalıdır.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _client.post('finance/payments', data: {
        'student_id': (widget.invoice['student_id'] as num?)?.toInt(),
        'parent_id': (widget.invoice['parent_id'] as num?)?.toInt(),
        'amount': amount,
        'payment_date': _dateFormatted,
        'payment_method': _method,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
        'is_proportional': _isProportional,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödəniş qeydə alınmadı.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Yeni ödəniş',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              '${widget.invoice['student'] ?? ''} · Qalıq: ${_money(widget.invoice['remaining_amount'])}',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Məbləğ (₼)',
                prefixIcon: const Icon(Icons.payments_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(_dateFormatted),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: InputDecoration(
                      labelText: 'Ödəniş üsulu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Nağd')),
                      DropdownMenuItem(value: 'card', child: Text('Kart')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank köçürməsi')),
                      DropdownMenuItem(value: 'pos', child: Text('POS')),
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                    ],
                    onChanged: (value) => setState(() => _method = value ?? 'cash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Qeyd (istəyə bağlı)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _isProportional,
              onChanged: (value) => setState(() => _isProportional = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Mütənasib bölüşdürme', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Məbləğ bütün borclar üzrə mütənasib bölünür.',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ödənişi qeyd et'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Payments tab
// =====================================================================

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];

  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _range = 'month';
  String? _methodFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 360) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    setState(() {
      if (reset) {
        _loading = true;
        _page = 1;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final response = await _client.get('finance/payments', query: {
        'page': reset ? 1 : _page + 1,
        'per_page': 25,
        'from': _resolveDateRangeFrom(_range),
        'to': _resolveDateRangeTo(_range),
        if (_methodFilter != null) 'payment_method': _methodFilter,
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
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
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Məlumat yüklənə bilmədi.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentPaymentsScreen())),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Şagird və Valideyn Maliyyə Əməliyyatları (Gopanel)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.primary, size: 14),
                ],
              ),
            ),
          ),
        ),
        _dateChips(_range, (value) {
          setState(() => _range = value);
          _load(reset: true);
        }),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Row(
            children: [
              for (final entry in const {
                null: 'Hamısı',
                'cash': 'Nağd',
                'card': 'Kart',
                'bank_transfer': 'Bank',
                'pos': 'POS',
              }.entries) ...[
                FilterChip(
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                  selected: _methodFilter == entry.key,
                  onSelected: (_) {
                    setState(() => _methodFilter = entry.key);
                    _load(reset: true);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Kod / qeyd üzrə axtar...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(child: _body(theme)),
      ],
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _errorView(_error!, () => _load(reset: true));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_rounded, size: 46, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Bu dövr üzrə ödəniş yoxdur.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final item = _items[index];
          return Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.success.withAlpha(26),
                  child: const Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['payer']?.toString() ?? item['code']?.toString() ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '${_shortDate(item['payment_date'])} · ${item['payment_method'] ?? ''}${item['bank_account'] != null ? ' · ${item['bank_account']}' : ''}',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(item['amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// Ledger tab
// =====================================================================

class _LedgerTab extends StatefulWidget {
  const _LedgerTab();

  @override
  State<_LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends State<_LedgerTab> {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];

  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _range = 'month';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 360) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    setState(() {
      if (reset) {
        _loading = true;
        _page = 1;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final response = await _client.get('finance/ledger', query: {
        'page': reset ? 1 : _page + 1,
        'per_page': 25,
        'from': _resolveDateRangeFrom(_range),
        'to': _resolveDateRangeTo(_range),
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
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
        _error = e.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Məlumat yüklənə bilmədi.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _dateChips(_range, (value) {
          setState(() => _range = value);
          _load(reset: true);
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Faktura / qeyd üzrə axtar...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(child: _body(theme)),
      ],
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _errorView(_error!, () => _load(reset: true));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_rounded, size: 46, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Tranzaksiya yoxdur.'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final item = _items[index];
          final type = item['type']?.toString() ?? '';
          final isIncome = type == 'income' || type == 'in' || type.contains('mədaxil');

          return Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: (isIncome ? AppColors.success : AppColors.danger).withAlpha(26),
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 18,
                    color: isIncome ? AppColors.success : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['note'] ?? item['invoice_number'] ?? '—').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '${_shortDate(item['log_date'])} · ${item['account'] ?? '—'} · $type',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(item['amount']),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isIncome ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
