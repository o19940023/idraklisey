import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import 'api_detail_screen.dart';

/// Fetches an object or non-paginated list and renders it with real data.
class ApiDataScreen extends StatefulWidget {
  const ApiDataScreen({
    super.key,
    required this.title,
    required this.endpoint,
    this.query = const {},
    this.emptyText = 'Məlumat yoxdur.',
  });

  final String title;
  final String endpoint;
  final Map<String, dynamic> query;
  final String emptyText;

  @override
  State<ApiDataScreen> createState() => _ApiDataScreenState();
}

class _ApiDataScreenState extends State<ApiDataScreen> {
  final _client = ApiClient.instance;

  dynamic _data;
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
      final response = await _client.get(widget.endpoint, query: widget.query);
      setState(() {
        _data = response is Map ? response['data'] : response;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(onPressed: _load, child: const Text('Yenidən cəhd et')),
          ),
        ],
      );
    }

    final data = _data;

    if (data == null || (data is List && data.isEmpty)) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Center(child: Text(widget.emptyText, style: TextStyle(color: AppColors.textMuted))),
        ],
      );
    }

    if (data is Map) {
      return ApiDetailBody(data: Map<String, dynamic>.from(data));
    }

    if (data is List) {
      final items = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (items.isEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(widget.emptyText, style: TextStyle(color: AppColors.textMuted))),
          ],
        );
      }
      return ApiDetailBody(
        data: {
          'items': items,
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [Text(data.toString())],
    );
  }
}
