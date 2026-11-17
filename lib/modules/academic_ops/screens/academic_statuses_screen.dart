import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class AcademicStatusesScreen extends StatefulWidget {
  const AcademicStatusesScreen({super.key});

  @override
  State<AcademicStatusesScreen> createState() => _AcademicStatusesScreenState();
}

class _AcademicStatusesScreenState extends State<AcademicStatusesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _statuses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await SchoolApiService.instance.fetchStatuses();
    if (!mounted) return;
    setState(() {
      _statuses = data;
      _isLoading = false;
    });
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? status}) async {
    final palette = AppPalette.of(context);
    final key = TextEditingController(text: status?['key']?.toString() ?? '');
    final color = TextEditingController(text: status?['color']?.toString() ?? '#3498db');
    final badge = TextEditingController(text: status?['classBadge']?.toString() ?? 'bg-info');
    bool isActive = status?['isActive'] != false;

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
                  Text(status == null ? 'Yeni status' : 'Status düzəlişi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _tf('Status açarı (məs: student_active) *', key),
                  _tf('Rəng (hex)', color),
                  _tf('Bootstrap badge sinfi', badge),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Aktiv', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: isActive, onChanged: (v) => setSheet(() => isActive = v)),
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
    if (key.text.trim().isEmpty) {
      _snack('Status açarı tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveStatus({
      'key': key.text.trim(),
      'color': color.text.trim(),
      'classBadge': badge.text.trim(),
      'isActive': isActive,
    }, id: status?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Statusu sil'),
        content: Text('${s['name']} silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (c != true) return;
    final ok = await SchoolApiService.instance.deleteStatus(s['id'].toString());
    _snack(ok ? 'Status silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Widget _tf(String label, TextEditingController c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: _deco(label)));

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;
    final canCreate = isSuper || session.can('gopanel.academic.foundations.statuses.create');
    final canEdit = isSuper || session.can('gopanel.academic.foundations.statuses.update');
    final canDelete = isSuper || session.can('gopanel.academic.foundations.statuses.delete');

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Status əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Statuslar', style: TextStyle(fontWeight: FontWeight.w900)),
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
                    StatCardRow(
                      columns: 2,
                      children: [
                        StatCard(value: '${_statuses.length}', label: 'Cəmi Status', icon: Icons.toggle_on_rounded, color: palette.brandRoyal),
                        StatCard(value: '${_statuses.where((s) => s['isActive'] == true).length}', label: 'Aktiv', icon: Icons.check_circle_rounded, color: AppColors.emerald),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(title: 'Sistem Statusları', subtitle: '${_statuses.length} təyin edilmiş status'),
                    const SizedBox(height: 10),
                    if (_statuses.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Status tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (final s in _statuses) ...[
                        ModernCard(
                          padding: const EdgeInsets.all(14),
                          onTap: canEdit ? () => _showForm(status: s) : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: palette.brandRoyal)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(s['name'] ?? 'Status', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
                                StatusBadge(label: s['isActive'] == true ? 'Aktiv' : 'Passiv', color: s['isActive'] == true ? AppColors.emerald : AppColors.warning, fontSize: 10),
                              ]),
                              const SizedBox(height: 3),
                              Text('Açar: ${s['key']}', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                              if (canEdit || canDelete) ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  if (canEdit)
                                    Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(status: s), icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Düzəliş et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                  if (canEdit && canDelete)
                                    const SizedBox(width: 8),
                                  if (canDelete)
                                    Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(s), icon: const Icon(Icons.delete_rounded, size: 16), label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
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
