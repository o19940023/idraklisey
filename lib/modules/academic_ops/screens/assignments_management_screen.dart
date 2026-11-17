import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class AssignmentsManagementScreen extends StatefulWidget {
  const AssignmentsManagementScreen({super.key});

  @override
  State<AssignmentsManagementScreen> createState() => _AssignmentsManagementScreenState();
}

class _AssignmentsManagementScreenState extends State<AssignmentsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignments = [];
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
      SchoolApiService.instance.fetchAssignments(),
      SchoolApiService.instance.fetchSubjects(),
      SchoolApiService.instance.fetchClassesFull(),
    ]);
    if (!mounted) return;
    setState(() {
      _assignments = results[0];
      _subjects = results[1];
      _classes = results[2];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _assignments;
    return _assignments.where((a) {
      return (a['title'] ?? '').toString().toLowerCase().contains(q) ||
          (a['className'] ?? '').toString().toLowerCase().contains(q) ||
          (a['subjectName'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? item}) async {
    final palette = AppPalette.of(context);
    final title = TextEditingController(text: item?['title']?.toString() ?? '');
    final description = TextEditingController(text: item?['description']?.toString() ?? '');
    final dueDate = TextEditingController(text: item?['dueDate']?.toString() ?? '');
    final maxScore = TextEditingController(text: '100');
    String? subjectId;
    String? classId;
    if (item != null) {
      final subj = _subjects.where((s) => (s['name']?.toString() ?? '') == (item['subjectName']?.toString() ?? '')).toList();
      subjectId = subj.isNotEmpty ? subj.first['id']?.toString() : null;
      final cls = _classes.where((c) => (c['className']?.toString() ?? '') == (item['className']?.toString() ?? '')).toList();
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
                  Text(item == null ? 'Yeni tapşırıq' : 'Tapşırığı düzəliş et', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _tf('Başlıq *', title),
                  _tf('Təsvir', description, maxLines: 4),
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
                    Expanded(child: _tf('Son tarix (YYYY-MM-DD)', dueDate)),
                    const SizedBox(width: 8),
                    Expanded(child: _tf('Maks. bal', maxScore, keyboard: TextInputType.number)),
                  ]),
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
    if (title.text.trim().isEmpty || subjectId == null) {
      _snack('Başlıq və fənn tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveAssignment({
      'title': title.text.trim(),
      'description': description.text.trim(),
      'subjectId': subjectId,
      'classId': classId,
      'dueDate': dueDate.text.trim().isEmpty ? null : dueDate.text.trim(),
      'maxScore': int.tryParse(maxScore.text.trim()) ?? 100,
    }, id: item?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> a) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tapşırığı sil'),
        content: Text('${a['title']} silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (c != true) return;
    final ok = await SchoolApiService.instance.deleteAssignment(a['id'].toString());
    _snack(ok ? 'Tapşırıq silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Widget _tf(String label, TextEditingController c, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, maxLines: maxLines, keyboardType: keyboard, decoration: _deco(label)));

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canCreate = isSuper || session.can('gopanel.academic.ejournal.assignments.create');
    final canEdit = isSuper || session.can('gopanel.academic.ejournal.assignments.update');
    final canDelete = isSuper || session.can('gopanel.academic.ejournal.assignments.delete');
    final items = _filtered;

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Tapşırıq əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Tapşırıqlar', style: TextStyle(fontWeight: FontWeight.w900)),
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
                        hintText: 'Tapşırıq başlığı, sinif və ya fənn ilə axtar...',
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
                        StatCard(value: '${_assignments.length}', label: 'Cəmi Tapşırıq', icon: Icons.assignment_rounded, color: palette.brandRoyal),
                        StatCard(value: '${_assignments.where((a) => (a['dueDate'] ?? '').toString().isNotEmpty).length}', label: 'Tarixli', icon: Icons.verified_rounded, color: AppColors.emerald),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(title: 'Məktəb Tapşırıqları', subtitle: '${items.length} tapşırıq göstərilir'),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Tapşırıq tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (final a in items) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(14),
                          onTap: canEdit ? () => _showForm(item: a) : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(a['title'] ?? 'Ev tapşırığı', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                                StatusBadge(label: 'Son: ${a['dueDate']}', color: palette.brandRoyal, fontSize: 9),
                              ]),
                              const SizedBox(height: 4),
                              Text('Sinif: ${a['className']} • Fənn: ${a['subjectName']}', style: TextStyle(fontSize: 12, color: palette.brandRoyal, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(a['description'] ?? '', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                              if (canEdit || canDelete) ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  if (canEdit)
                                    Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(item: a), icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Düzəliş et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                  if (canEdit && canDelete)
                                    const SizedBox(width: 8),
                                  if (canDelete)
                                    Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(a), icon: const Icon(Icons.delete_rounded, size: 16), label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                ]),
                              ],
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
