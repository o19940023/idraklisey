import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';

class FinalGradingScreen extends StatefulWidget {
  const FinalGradingScreen({super.key});

  @override
  State<FinalGradingScreen> createState() => _FinalGradingScreenState();
}

class _FinalGradingScreenState extends State<FinalGradingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classes = [];

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
      SchoolApiService.instance.fetchFinalGrading(),
      SchoolApiService.instance.fetchStudents(),
      SchoolApiService.instance.fetchSubjects(),
      SchoolApiService.instance.fetchClassesFull(),
    ]);
    if (!mounted) return;
    setState(() {
      _grades = results[0];
      _students = results[1];
      _subjects = results[2];
      _classes = results[3];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _grades;
    return _grades.where((g) {
      return (g['studentName'] ?? '').toString().toLowerCase().contains(q) ||
          (g['className'] ?? '').toString().toLowerCase().contains(q) ||
          (g['subjectName'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? grade}) async {
    final palette = AppPalette.of(context);
    final gradeCtrl = TextEditingController(text: (grade?['grade'] ?? '').toString());
    final note = TextEditingController(text: grade?['note']?.toString() ?? '');
    final dateCtrl = TextEditingController(text: grade?['date']?.toString() ?? '');
    String type = grade?['type']?.toString() ?? 'KSQ';
    String? studentId;
    String? subjectId;
    String? classId;
    if (grade != null) {
      final st = _students.where((s) => (s['fullName']?.toString() ?? '') == (grade['studentName']?.toString() ?? '')).toList();
      studentId = st.isNotEmpty ? st.first['id']?.toString() : null;
      final subj = _subjects.where((s) => (s['name']?.toString() ?? '') == (grade['subjectName']?.toString() ?? '')).toList();
      subjectId = subj.isNotEmpty ? subj.first['id']?.toString() : null;
      final cls = _classes.where((c) => (c['className']?.toString() ?? '') == (grade['className']?.toString() ?? '')).toList();
      classId = cls.isNotEmpty ? cls.first['id']?.toString() : null;
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
                  Text(grade == null ? 'Yeni qiymət' : 'Qiyməti düzəliş et', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  if (grade == null)
                    DropdownButtonFormField<String>(
                      initialValue: studentId,
                      decoration: _deco('Şagird *'),
                      isExpanded: true,
                      items: _students.take(300).map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text('${s['fullName']} (${s['className']})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setSheet(() => studentId = v),
                    )
                  else
                    InputDecorator(decoration: _deco('Şagird'), child: Text(grade['studentName']?.toString() ?? '—')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: subjectId,
                    decoration: _deco('Fənn *'),
                    isExpanded: true,
                    items: _subjects.map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text(s['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setSheet(() => subjectId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: classId,
                    decoration: _deco('Sinif'),
                    isExpanded: true,
                    items: _classes.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['className']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setSheet(() => classId = v),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _tf('Qiymət / bal *', gradeCtrl, keyboard: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: _deco('Növ'),
                        items: const ['KSQ', 'BSQ', 'regular', 'final'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setSheet(() => type = v ?? 'KSQ'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _tf('Tarix (YYYY-MM-DD)', dateCtrl),
                  _tf('Qeyd', note, maxLines: 2),
                  const SizedBox(height: 6),
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
    if ((grade == null && studentId == null) || subjectId == null || gradeCtrl.text.trim().isEmpty) {
      _snack('Şagird, fənn və qiymət tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveGrade({
      'studentId': studentId,
      'subjectId': subjectId,
      'classId': classId,
      'grade': double.tryParse(gradeCtrl.text.replaceAll(',', '.')) ?? 0,
      'type': type,
      'date': dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
      'note': note.text.trim(),
    }, id: grade?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> g) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qiyməti sil'),
        content: Text('${g['studentName']} — ${g['subjectName']} qiyməti silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (c != true) return;
    final ok = await SchoolApiService.instance.deleteGrade(g['id'].toString());
    _snack(ok ? 'Qiymət silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Widget _tf(String label, TextEditingController c, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, maxLines: maxLines, keyboardType: keyboard, decoration: _deco(label)));

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
        label: const Text('Qiymət əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Yekun qiymətləndirmə', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveCenter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Şagird, sinif və ya fənn ilə axtar...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: palette.surface1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    StatCardRow(
                      columns: 2,
                      children: [
                        StatCard(value: '${_grades.length}', label: 'Cəmi Qiymət', icon: Icons.stars_rounded, color: palette.brandRoyal),
                        StatCard(value: 'KSQ / BSQ', label: 'Qiymətləndirmə', icon: Icons.grading_rounded, color: AppColors.emerald),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(title: 'Yekun Qiymət Qeydləri', subtitle: '${items.length} qiymət göstərilir'),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Qiymət tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (final g in items) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => _showForm(grade: g),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(g['studentName'] ?? 'Şagird', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: palette.brandRoyal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                  child: Text('${(g['grade'] as num? ?? 0).toStringAsFixed(1)} bal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
                                ),
                              ]),
                              const SizedBox(height: 3),
                              Text('${g['className']} • ${g['subjectName']}', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Növ: ${g['type']} • Tarix: ${g['date']}', style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(grade: g), icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Düzəliş et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(g), icon: const Icon(Icons.delete_rounded, size: 16), label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
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
