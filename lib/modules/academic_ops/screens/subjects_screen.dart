import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
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
    final data = await SchoolApiService.instance.fetchSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = data;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _subjects;
    return _subjects.where((s) {
      return (s['name'] ?? '').toString().toLowerCase().contains(q) || (s['code'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? subject}) async {
    final palette = AppPalette.of(context);
    final name = TextEditingController(text: subject?['name']?.toString() ?? '');
    final code = TextEditingController(text: subject?['code']?.toString() ?? '');
    final colorCtrl = TextEditingController(text: '#3b82f6');
    bool isActive = subject?['isActive'] != false;
    bool finalLocked = false;
    bool groupBased = false;

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
                  Text(subject == null ? 'Yeni fənn' : 'Fənn düzəlişi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _tf('Fənn adı *', name),
                  _tf('Kod', code),
                  _tf('Rəng kodu', colorCtrl),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Aktiv', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: isActive, onChanged: (v) => setSheet(() => isActive = v)),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Yekun qiymət kilidli', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: finalLocked, onChanged: (v) => setSheet(() => finalLocked = v)),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Qrup əsaslı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: groupBased, onChanged: (v) => setSheet(() => groupBased = v)),
                  const SizedBox(height: 10),
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
    if (name.text.trim().isEmpty) {
      _snack('Fənn adı tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveSubject({
      'name': name.text.trim(),
      'code': code.text.trim(),
      'colorCode': colorCtrl.text.trim(),
      'isActive': isActive,
      'finalGradingLocked': finalLocked,
      'isGroupBased': groupBased,
    }, id: subject?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fənni sil'),
        content: Text('${s['name']} silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (c != true) return;
    final ok = await SchoolApiService.instance.deleteSubject(s['id'].toString());
    _snack(ok ? 'Fənn silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Widget _tf(String label, TextEditingController c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: _deco(label)));

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
        label: const Text('Fənn əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Fənnlər', style: TextStyle(fontWeight: FontWeight.w900)),
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
                        hintText: 'Fənn adı və ya kodu ilə axtar...',
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
                        StatCard(value: '${_subjects.length}', label: 'Tədris Fənni', icon: Icons.menu_book_rounded, color: palette.brandRoyal),
                        StatCard(value: '${_subjects.where((s) => s['isActive'] != false).length}', label: 'Aktiv', icon: Icons.check_circle_rounded, color: AppColors.emerald),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(title: 'Tədris Fənləri Fondu', subtitle: '${items.length} fənn göstərilir'),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Fənn tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (final s in items) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => _showForm(subject: s),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(s['name'] ?? 'Fənn', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                                StatusBadge(label: '${s['weeklyHours'] ?? 0} saat', color: palette.brandRoyal, fontSize: 10),
                              ]),
                              const SizedBox(height: 3),
                              Text('Kod: ${s['code']}', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(subject: s), icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Düzəliş et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(s), icon: const Icon(Icons.delete_rounded, size: 16), label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
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
