import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';

class ApiNotificationsScreen extends StatefulWidget {
  const ApiNotificationsScreen({super.key});

  @override
  State<ApiNotificationsScreen> createState() => _ApiNotificationsScreenState();
}

class _ApiNotificationsScreenState extends State<ApiNotificationsScreen> {
  final _client = ApiClient.instance;

  List<Map<String, dynamic>> _items = [];
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
      final response = await _client.get('common/notifications', query: {'per_page': 50});
      final page = parsePage(response);
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _client.post('common/notifications/$id/read');
      setState(() {
        final index = _items.indexWhere((e) => e['id'] == id);
        if (index >= 0) {
          _items[index] = {..._items[index], 'is_read': true, 'read_at': DateTime.now().toIso8601String()};
        }
      });
    } on ApiException catch (_) {}
  }

  Future<void> _markAll() async {
    try {
      await _client.post('common/notifications/read-all');
      setState(() {
        _items = _items.map((e) => {...e, 'is_read': true}).toList();
      });
    } on ApiException catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirişlər'),
        actions: [
          IconButton(
            tooltip: 'Hamısını oxu',
            onPressed: _markAll,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(child: FilledButton.tonal(onPressed: _load, child: const Text('Yenidən cəhd et'))),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Center(child: Text('Bildiriş yoxdur.', style: TextStyle(color: AppColors.textMuted))),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        final isRead = item['is_read'] == true;

        return Material(
          color: isRead
              ? Theme.of(context).colorScheme.surface
              : AppColors.primaryAccent.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _markRead(item['id'] as int? ?? 0),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isRead ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                    color: isRead ? AppColors.textMuted : AppColors.primaryAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? 'Bildiriş',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (item['message'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item['message'].toString(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          item['created_at']?.toString() ?? '',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
