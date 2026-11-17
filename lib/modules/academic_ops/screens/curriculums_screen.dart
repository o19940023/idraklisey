import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';

class CurriculumsScreen extends StatefulWidget {
  const CurriculumsScreen({super.key});

  @override
  State<CurriculumsScreen> createState() => _CurriculumsScreenState();
}

class _CurriculumsScreenState extends State<CurriculumsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _curriculums = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];

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
    setState(() => _isLoading = true);
    final results = await Future.wait([
      SchoolApiService.instance.fetchCurriculums(),
      SchoolApiService.instance.fetchClassesFull(),
      SchoolApiService.instance.fetchSubjects(),
    ]);
    if (!mounted) return;
    setState(() {
      _curriculums = results[0];
      _classes = results[1];
      _subjects = results[2];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _curriculums;
    return _curriculums.where((c) {
      return (c['subjectName'] ?? '').toString().toLowerCase().contains(q) ||
          (c['className'] ?? '').toString().toLowerCase().contains(q) ||
          (c['program'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? curriculum}) async {
    final palette = AppPalette.of(context);
    final hours = TextEditingController(text: (curriculum?['weeklyHours'] ?? 2).toString());
    String? classId;
    String? subjectId;
    if (curriculum != null) {
      final cls = _classes.where((c) => (c['className']?.toString() ?? '') == (curriculum['className']?.toString() ?? '')).toList();
      classId = cls.isNotEmpty ? cls.first['id']?.toString() : null;
      final subj = _subjects.where((s) => (s['name']?.toString() ?? '') == (curriculum['subjectName']?.toString() ?? '')).toList();
      subjectId = subj.isNotEmpty ? subj.first['id']?.toString() : null;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 22),
          decoration: BoxDecoration(color: palette.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: palette.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 14),
                  Text(curriculum == null ? 'Yeni kurikulum' : 'Kurikulumu düzəliş et', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: classId,
                    decoration: const InputDecoration(labelText: 'Sinif', isDense: true, border: OutlineInputBorder()),
                    isExpanded: true,
                    items: _classes.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['className']?.toString() ?? '', style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setSheet(() => classId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: subjectId,
                    decoration: const InputDecoration(labelText: 'Fənn *', isDense: true, border: OutlineInputBorder()),
                    isExpanded: true,
                    items: _subjects.map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text(s['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setSheet(() => subjectId = v),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: hours,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Həftəlik saat', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: palette.brandNavy, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    if (subjectId == null) {
      _snack('Fənn tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveCurriculum({
      'classId': classId,
      'subjectId': subjectId,
      'weeklyHours': int.tryParse(hours.text.trim()) ?? 2,
    }, id: curriculum?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kurikulumu sil'),
        content: Text('${c['subjectName']} — ${c['className']} silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SchoolApiService.instance.deleteCurriculum(c['id'].toString());
    _snack(ok ? 'Silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final items = _filtered;

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.brandRoyal,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text('Kurikulum əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Kurikulum', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveCenter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Fənn, sinif və ya proqram ilə axtar...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: palette.surface1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionHeader(title: 'Fənn Kurikulumları', subtitle: '${items.length} kurikulum göstərilir'),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Kurikulum tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (final c in items) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => _showForm(curriculum: c),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(c['subjectName'] ?? 'Fənn', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                                StatusBadge(label: '${c['weeklyHours']} saat/həftə', color: palette.brandRoyal, fontSize: 10),
                              ]),
                              const SizedBox(height: 4),
                              Text('${c['className']} • ${c['program'] ?? ''}', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Mövzular: ${c['topicsCount']} • Ümumi saat: ${c['totalHours']}', style: TextStyle(fontSize: 11.5, color: palette.textTertiary)),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(curriculum: c), icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Düzəliş et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(c), icon: const Icon(Icons.delete_rounded, size: 16), label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                              ]),
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
