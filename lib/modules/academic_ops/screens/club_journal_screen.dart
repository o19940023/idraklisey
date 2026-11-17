import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class ClubJournalScreen extends StatefulWidget {
  const ClubJournalScreen({super.key});

  @override
  State<ClubJournalScreen> createState() => _ClubJournalScreenState();
}

class _ClubJournalScreenState extends State<ClubJournalScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _clubs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await SchoolApiService.instance.fetchClubJournal();
    if (!mounted) return;
    setState(() {
      _clubs = data;
      _isLoading = false;
    });
  }

  Future<void> _openJournal(Map<String, dynamic> club) async {
    final palette = AppPalette.of(context);
    DateTime date = DateTime.now();
    Map<String, dynamic>? data;
    bool loading = true;
    bool saving = false;
    bool initiated = false;
    final grades = <String, TextEditingController>{};
    final attendance = <String, String>{};
    String? topicId;

    Future<void> loadData(StateSetter setSheet) async {
      setSheet(() => loading = true);
      final d = await SchoolApiService.instance.fetchClubJournalData(
        club['id'].toString(),
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
      for (final c in grades.values) {
        c.dispose();
      }
      grades.clear();
      attendance.clear();
      if (d != null) {
        topicId = (d['selectedTopicId']?.toString().isNotEmpty == true) ? d['selectedTopicId'].toString() : null;
        for (final s in (d['students'] as List? ?? [])) {
          final id = s['id'].toString();
          attendance[id] = s['status']?.toString() ?? 'present';
          grades[id] = TextEditingController(text: s['grade']?.toString() ?? '');
        }
      }
      if (!mounted) return;
      setSheet(() {
        data = d;
        loading = false;
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (!initiated) {
            initiated = true;
            Future.microtask(() => loadData(setSheet));
          }
          final students = (data?['students'] as List? ?? []);
          final rawTopics = (data?['topics'] as List? ?? []);
          final uniqueTopics = <String, Map<String, dynamic>>{};
          for (final t in rawTopics) {
            final tid = t['id']?.toString();
            if (tid != null && tid.isNotEmpty && !uniqueTopics.containsKey(tid)) {
              uniqueTopics[tid] = Map<String, dynamic>.from(t as Map);
            }
          }
          final validTopicList = uniqueTopics.values.toList();
          final effectiveTopicId = (topicId != null && uniqueTopics.containsKey(topicId)) ? topicId : null;
          final scheduleId = data?['scheduleId']?.toString() ?? '';

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.92,
            padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.viewInsetsOf(ctx).bottom + 16),
            decoration: BoxDecoration(color: palette.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: SafeArea(
              child: Column(
                children: [
                  Container(width: 44, height: 4, decoration: BoxDecoration(color: palette.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text(club['name']?.toString() ?? 'Dərnək jurnalı', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (picked != null) {
                            date = picked;
                            await loadData(setSheet);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: Text('${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (data == null || scheduleId.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Bu dərnək üçün cədvəl (club_schedule) tapılmadı.\nWeb paneldə dərnək cədvəlini yaradın.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.5),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: effectiveTopicId,
                            decoration: InputDecoration(
                              labelText: 'Mövzu (Tədris planı)',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            isExpanded: true,
                            items: validTopicList.map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['title']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setSheet(() => topicId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emerald,
                            side: const BorderSide(color: AppColors.emerald),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Hamısı İştirak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          onPressed: () {
                            setSheet(() {
                              for (final s in students) {
                                attendance[s['id'].toString()] = 'present';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
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
                                Text(s['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                Text(s['code']?.toString() ?? '', style: TextStyle(fontSize: 10.5, color: palette.textTertiary)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        children: [
                                          for (final st in [('present', 'İştirak'), ('absent', 'Qayıb'), ('excused', 'Üzürlü')])
                                            ChoiceChip(
                                              label: Text(st.$2, style: const TextStyle(fontSize: 10.5)),
                                              selected: (attendance[id] ?? 'present') == st.$1,
                                              onSelected: (_) => setSheet(() => attendance[id] = st.$1),
                                              selectedColor: st.$1 == 'present' ? AppColors.emerald.withValues(alpha: 0.2) : (st.$1 == 'absent' ? AppColors.danger.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.2)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 64,
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
                                final hasGrades = grades.values.any((c) => c.text.trim().isNotEmpty);
                                if (hasGrades && (topicId == null || topicId!.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Qiymət yazmaq üçün zəhmət olmasa tədris mövzusunu seçin.'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }

                                setSheet(() => saving = true);
                                final payload = {
                                  'club_id': club['id'].toString(),
                                  'club_schedule_id': scheduleId,
                                  'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                                  'curriculum_topic_id': topicId,
                                  'attendance': attendance,
                                  'grades': {
                                    for (final e in grades.entries)
                                      if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
                                  },
                                };
                                final ok = await SchoolApiService.instance.saveClubJournalData(payload);
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
                ],
              ),
            ),
          );
        },
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
        title: const Text('Dərnək jurnalı', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveCenter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    StatCardRow(
                      columns: 2,
                      children: [
                        StatCard(value: '${_clubs.length}', label: 'Aktiv Dərnək', icon: Icons.sports_soccer_rounded, color: palette.brandRoyal),
                        StatCard(value: '${_clubs.fold<int>(0, (s, c) => s + ((c['enrolledCount'] as num?)?.toInt() ?? 0))}', label: 'Üzv', icon: Icons.groups_rounded, color: AppColors.emerald),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(title: 'Dərnək Davamiyyət Jurnalları', subtitle: '${_clubs.length} dərnək qrupu'),
                    const SizedBox(height: 10),
                    if (_clubs.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Dərnək tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (final c in _clubs) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => _openJournal(c),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(c['name']?.toString() ?? 'Dərnək', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                                StatusBadge(label: '${c['enrolledCount']} şagird', color: AppColors.emerald, fontSize: 10),
                              ]),
                              const SizedBox(height: 4),
                              Text('Məkan: ${c['room']} • Qrafik: ${c['schedule']}', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: palette.brandRoyal,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _openJournal(c),
                                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                                  label: const Text('Jurnalı aç', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ),
    );
  }
}
