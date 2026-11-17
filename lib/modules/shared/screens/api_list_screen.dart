import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import 'api_detail_screen.dart';

/// A real, paginated, searchable list backed by the mobile API.
///
/// Used for modules whose bespoke UI is not built yet, so no screen ever shows
/// mock data or a dead placeholder.
class ApiListScreen extends StatefulWidget {
  const ApiListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    this.query = const {},
    this.searchHint = 'Axtar...',
    this.searchParam = 'q',
    this.titleKeys = const ['full_name', 'name', 'title', 'subject', 'student', 'code'],
    this.subtitleKeys = const ['class_name', 'position', 'category', 'email', 'author'],
    this.badgeKey = 'status',
    this.emptyText = 'Məlumat tapılmadı.',
    this.permission,
  });

  final String title;
  final String endpoint;
  final Map<String, dynamic> query;
  final String searchHint;
  final String searchParam;
  final List<String> titleKeys;
  final List<String> subtitleKeys;
  final String badgeKey;
  final String emptyText;
  final String? permission;

  @override
  State<ApiListScreen> createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen> {
  final _client = ApiClient.instance;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];

  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

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
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 320) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoadingMore) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _client.get(
        widget.endpoint,
        query: {
          ...widget.query,
          'page': reset ? 1 : _page + 1,
          'per_page': AppConfig.defaultPageSize,
          if (_searchController.text.trim().isNotEmpty)
            widget.searchParam: _searchController.text.trim(),
        },
      );

      final page = parsePage(response);

      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Məlumat yüklənə bilmədi.';
      });
    }
  }

  String _valueOf(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(reset: true),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Axtar',
                    onPressed: () => _load(reset: true),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            Expanded(child: _body(theme)),
          ],
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_isLoading && _items.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 74,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(
              onPressed: () => _load(reset: true),
              child: const Text('Yenidən cəhd et'),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Center(
            child: Text(
              widget.emptyText,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final item = _items[index];
        final title = _valueOf(item, widget.titleKeys);
        final subtitle = _valueOf(item, widget.subtitleKeys);
        final badge = item[widget.badgeKey]?.toString();

        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ApiDetailScreen(title: title, data: item),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryAccent.withAlpha(24),
                    child: Text(
                      title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (subtitle != '—') ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null && badge.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _StatusBadge(label: badge, rawValue: badge),
                  ],
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.rawValue});

  final String label;
  final String rawValue;

  @override
  Widget build(BuildContext context) {
    final lower = rawValue.toLowerCase();
    Color color = AppColors.info;
    if (lower.contains('approved') || lower.contains('active') || lower.contains('təsdiq') || lower.contains('aktiv')) {
      color = AppColors.success;
    } else if (lower.contains('pending') || lower.contains('gözl') || lower.contains('warning')) {
      color = AppColors.warning;
    } else if (lower.contains('reject') || lower.contains('rədd') || lower.contains('cancel') || lower.contains('deaktiv')) {
      color = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
