import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

class ApiJournalScreen extends StatefulWidget {
  final String? initialClassId;
  const ApiJournalScreen({super.key, this.initialClassId});

  @override
  State<ApiJournalScreen> createState() => _ApiJournalScreenState();
}

class _ApiJournalScreenState extends State<ApiJournalScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _lessons = [];
  String? _classId;
  int _day = DateTime.now().weekday;

  static const _days = [
    (1, 'B.E'),
    (2, 'Ç.A'),
    (3, 'Ç'),
    (4, 'C.A'),
    (5, 'C'),
    (6, 'Ş'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _dateString {
    final now = DateTime.now();
    final delta = _day - now.weekday;
    final d = now.add(Duration(days: delta));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final classes = await SchoolApiService.instance.fetchClassesFull();
    if (!mounted) return;
    _classes = classes;
    if (widget.initialClassId != null && classes.any((c) => c['id']?.toString() == widget.initialClassId)) {
      _classId = widget.initialClassId;
    } else {
      _classId ??= classes.isNotEmpty ? classes.first['id']?.toString() : null;
    }
    await _loadLessons();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadLessons() async {
    if (_classId == null) {
      setState(() => _lessons = []);
      return;
    }
    final data = await SchoolApiService.instance.fetchSchedules(classId: _classId);
    if (!mounted) return;
    setState(() {
      _lessons = data;
      final hasToday = data.any((l) => (l['dayOfWeek'] as num?)?.toInt() == _day);
      if (!hasToday && data.isNotEmpty) {
        final days = data.map((l) => (l['dayOfWeek'] as num?)?.toInt() ?? 0).where((d) => d > 0).toSet().toList()..sort();
        if (days.isNotEmpty) _day = days.first;
      }
    });
  }

  List<Map<String, dynamic>> get _dayLessons {
    final list = _lessons.where((l) => (l['dayOfWeek'] as num?)?.toInt() == _day).toList();
    list.sort((a, b) => (a['startTime'] ?? '').toString().compareTo((b['startTime'] ?? '').toString()));
    return list;
  }

  Future<void> _openLesson(Map<String, dynamic> lesson) async {
    final palette = AppPalette.of(context);
    final data = await SchoolApiService.instance.fetchJournalLesson(lesson['id'].toString(), date: _dateString);
    if (!mounted) return;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal məlumatı yüklənə bilmədi'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final attendance = <String, String>{};
    final grades = <String, TextEditingController>{};
    for (final s in (data['students'] as List? ?? [])) {
      final id = s['id'].toString();
      attendance[id] = s['status']?.toString() ?? 'not_marked';
      grades[id] = TextEditingController(text: s['grade']?.toString() ?? '');
    }
    String? topicId = data['selectedTopicId']?.toString().isNotEmpty == true ? data['selectedTopicId'].toString() : null;
    bool saving = false;
    final topics = data['topics'] as List? ?? [];
    final students = data['students'] as List? ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(ctx).size.height * 0.93,
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.viewInsetsOf(ctx).bottom + 16),
          decoration: BoxDecoration(color: palette.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
            child: Column(
              children: [
                Container(width: 44, height: 4, decoration: BoxDecoration(color: palette.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['subjectName']?.toString() ?? 'Dərs', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          Text('${data['className']} • ${data['startTime']}-${data['endTime']} • ${data['roomName']}', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                        ],
                      ),
                    ),
                    StatusBadge(label: '${students.length} şagird', color: palette.brandRoyal, fontSize: 10),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: topicId,
                  decoration: InputDecoration(labelText: 'Mövzu', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  isExpanded: true,
                  items: topics.map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['title']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setSheet(() => topicId = v),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: students.isEmpty
                      ? Center(child: Text('Bu dərsdə şagird tapılmadı', style: TextStyle(color: palette.textSecondary)))
                      : ListView.separated(
                          itemCount: students.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final s = students[i];
                            final id = s['id'].toString();
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(s['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                                      Text(s['code']?.toString() ?? '', style: TextStyle(fontSize: 10, color: palette.textTertiary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 5,
                                          runSpacing: 4,
                                          children: [
                                            for (final st in [('present', 'İştirak'), ('absent', 'Qayıb'), ('late', 'Gecikmə'), ('excused', 'Üzürlü')])
                                              ChoiceChip(
                                                label: Text(st.$2, style: const TextStyle(fontSize: 10.5)),
                                                selected: (attendance[id] ?? 'not_marked') == st.$1,
                                                onSelected: (_) => setSheet(() => attendance[id] = st.$1),
                                                selectedColor: st.$1 == 'present'
                                                    ? AppColors.emerald.withValues(alpha: 0.2)
                                                    : st.$1 == 'absent'
                                                        ? AppColors.danger.withValues(alpha: 0.15)
                                                        : AppColors.warning.withValues(alpha: 0.2),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 62,
                                        child: TextField(
                                          controller: grades[id],
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(labelText: 'Bal', isDense: true, border: OutlineInputBorder()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            final ok = await SchoolApiService.instance.saveJournalLesson(lesson['id'].toString(), {
                              'date': _dateString,
                              'topicId': topicId,
                              'attendance': [
                                for (final e in attendance.entries)
                                  if (e.value != 'not_marked') {'studentId': e.key, 'status': e.value},
                              ],
                              'grades': {
                                for (final e in grades.entries)
                                  if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
                              },
                            });
                            if (!mounted) return;
                            setSheet(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? 'Jurnal yadda saxlanıldı' : 'Yadda saxlamaq alınmadı'), backgroundColor: ok ? AppColors.emerald : AppColors.danger),
                            );
                            if (ok) Navigator.pop(ctx);
                          },
                    style: FilledButton.styleFrom(backgroundColor: palette.brandNavy, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Jurnalı yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Jurnal', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DropdownButtonFormField<String>(
                    initialValue: _classId,
                    decoration: InputDecoration(
                      labelText: 'Sinif seçin',
                      filled: true,
                      fillColor: palette.surface1,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    isExpanded: true,
                    items: _classes.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['className']?.toString() ?? '', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) async {
                      setState(() => _classId = v);
                      await _loadLessons();
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final (d, label) = _days[i];
                      final selected = _day == d;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _day = d),
                        selectedColor: palette.brandRoyal,
                        labelStyle: TextStyle(color: selected ? Colors.white : palette.textSecondary, fontWeight: FontWeight.w800, fontSize: 12),
                        backgroundColor: palette.surface1,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ResponsiveCenter(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          SectionHeader(
                            title: 'Dərs Jurnalı',
                            subtitle: '${_dayLessons.length} dərs • $_dateString',
                          ),
                          const SizedBox(height: 8),
                          if (_dayLessons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(child: Text('Bu gün üçün dərs tapılmadı', style: TextStyle(color: palette.textSecondary))),
                            )
                          else
                            for (final l in _dayLessons) ...[
                              ModernCard(
                                padding: const EdgeInsets.all(14),
                                onTap: () => _openLesson(l),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(color: palette.brandRoyal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                      child: Column(
                                        children: [
                                          Text(l['startTime']?.toString() ?? '', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
                                          Text(l['endTime']?.toString() ?? '', style: TextStyle(fontSize: 10, color: palette.textTertiary)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l['subjectName']?.toString() ?? 'Fənn', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                                          Text('${l['teacherName']} • ${l['roomName']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: palette.textTertiary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
