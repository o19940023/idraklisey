import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/network/api_client.dart';
import '../../shared/widgets/school_hero_background.dart';

class ApiDashboardScreen extends StatefulWidget {
  const ApiDashboardScreen({super.key});

  @override
  State<ApiDashboardScreen> createState() => _ApiDashboardScreenState();
}

class _ApiDashboardScreenState extends State<ApiDashboardScreen> {
  final _client = ApiClient.instance;

  Map<String, dynamic> _data = const {};
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
      final response = await _client.get('dashboard');
      final data = response is Map ? response['data'] : null;
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : const {};
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
    final session = context.watch<SessionController>();
    final profile = session.profile;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _greeting(profile?.name ?? '', profile?.activeRole ?? profile?.type ?? '', theme),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _errorCard(theme)
          else ...[
            if (profile?.isStudent == true) _studentContent(theme),
            if (profile?.isParent == true) _parentContent(theme),
            if (profile?.isStaff == true) _staffContent(theme),
            const SizedBox(height: 8),
            Text(
              'Məlumatlar canlı olaraq idrak_panel_2026_2027 bazasından gəlir.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _greeting(String name, String role, ThemeData theme) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Sabahınız xeyir' : (hour < 18 ? 'Günortanız xeyir' : 'Axşamınız xeyir');

    return SchoolHeroBackground(
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  name.isEmpty ? 'İstifadəçi' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.isEmpty ? 'İstifadəçi' : role,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: Colors.white24, size: 64),
        ],
      ),
    ),
  ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04);
  }

  Widget _errorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withAlpha(60)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 36),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: _load, child: const Text('Yenidən cəhd et')),
        ],
      ),
    );
  }

  Widget _staffContent(ThemeData theme) {
    final stations = _data['stations'];
    if (stations is! Map) return const SizedBox.shrink();

    final cards = <Widget>[];

    void addCard(String title, IconData icon, List<MapEntry<String, dynamic>> entries) {
      if (entries.isEmpty) return;
      cards.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primaryAccent),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_label(entry.key), style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                      Text(
                        _format(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void addStation(String key, String title, IconData icon) {
      final station = stations[key];
      if (station is Map) {
        addCard(
          title,
          icon,
          station.entries.where((e) => e.value != null).map((e) => MapEntry(e.key.toString(), e.value)).toList(),
        );
      }
    }

    addStation('students', 'Akademik', Icons.school_rounded);
    addStation('employees', 'İnsan resursları', Icons.badge_rounded);
    addStation('library', 'Kitabxana', Icons.menu_book_rounded);
    addStation('finance', 'Maliyyə', Icons.payments_rounded);
    addStation('tickets', 'Dəstək biletləri', Icons.support_agent_rounded);
    addStation('activity', 'Sistem aktivliyi', Icons.history_rounded);

    if (cards.isEmpty) {
      return Text(
        'Bu rol üçün göstəriləcək statistika yoxdur.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map((card) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 44) / 2,
                child: card,
              ))
          .toList(),
    );
  }

  Widget _studentContent(ThemeData theme) {
    final stats = _data['stats'];
    final classInfo = _data['class'];
    final upcoming = _data['upcoming_assignments'];
    final grades = _data['recent_grades'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (classInfo is Map)
          _infoTile(
            theme,
            icon: Icons.meeting_room_rounded,
            title: 'Sinif',
            value: classInfo['name']?.toString() ?? '—',
          ),
        if (stats is Map) ...[
          const SizedBox(height: 12),
          _statsWrap(theme, stats),
        ],
        if (upcoming is List && upcoming.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Yaxınlaşan tapşırıqlar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ...upcoming.take(5).map((item) => _simpleTile(
                theme,
                title: item['title']?.toString() ?? 'Tapşırıq',
                subtitle: item['due_date']?.toString() ?? '',
                icon: Icons.assignment_rounded,
              )),
        ],
        if (grades is List && grades.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Son qiymətlər', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ...grades.take(5).map((item) => _simpleTile(
                theme,
                title: 'Qiymət: ${item['grade'] ?? '—'}',
                subtitle: item['date']?.toString() ?? '',
                icon: Icons.grading_rounded,
              )),
        ],
      ],
    );
  }

  Widget _parentContent(ThemeData theme) {
    final stats = _data['stats'];
    final children = _data['children'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (children is List && children.isNotEmpty) ...[
          const Text('Övladlar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children
                .whereType<Map>()
                .map((child) => Chip(
                      avatar: const Icon(Icons.person_rounded, size: 16),
                      label: Text(child['name']?.toString() ?? '—'),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (stats is Map) _statsWrap(theme, stats),
      ],
    );
  }

  Widget _statsWrap(ThemeData theme, Map stats) {
    final entries = stats.entries.where((e) => e.value != null && e.value is! Map && e.value is! List).toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((entry) {
        return Container(
          width: (MediaQuery.sizeOf(context).width - 52) / 2,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(70)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_label(entry.key), style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
              const SizedBox(height: 6),
              Text(
                _format(entry.value),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoTile(ThemeData theme, {required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _simpleTile(ThemeData theme, {required String title, required String subtitle, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(String key) {
    const labels = {
      'active': 'Aktiv',
      'total': 'Cəmi',
      'books': 'Kitablar',
      'pending_reservations': 'Gözləyən rezervasiya',
      'active_loans': 'Aktiv icarə',
      'payments_this_month': 'Bu ay ödənişlər',
      'contracts_total': 'Müqavilələr cəmi',
      'open': 'Açıq',
      'entries_today': 'Bugünkü qeydlər',
      'children_count': 'Övlad sayı',
      'paid_total': 'Ödənilib',
      'debt_total': 'Borc',
      'grades_count': 'Qiymət sayı',
      'class_id': 'Sinif ID',
      'present': 'İştirak edib',
      'absent': 'İştirak etməyib',
      'late': 'Gecikib',
      'excused': 'Üzrlü',
    };
    return labels[key] ?? key;
  }

  String _format(dynamic value) {
    if (value is num) {
      if (value == value.roundToDouble() && value.abs() < 100000) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    if (value is Map) return value.length.toString();
    if (value is List) return value.length.toString();
    return value?.toString() ?? '—';
  }
}
