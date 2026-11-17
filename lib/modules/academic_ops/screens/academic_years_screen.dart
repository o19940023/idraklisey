import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';

class AcademicYearsScreen extends StatefulWidget {
  const AcademicYearsScreen({super.key});

  @override
  State<AcademicYearsScreen> createState() => _AcademicYearsScreenState();
}

class _AcademicYearsScreenState extends State<AcademicYearsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _years = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await SchoolApiService.instance.fetchAcademicYears();
    if (!mounted) return;
    setState(() {
      _years = data;
      _isLoading = false;
    });
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? year}) async {
    final palette = AppPalette.of(context);
    final start = TextEditingController(text: year?['startDate']?.toString() ?? '');
    final end = TextEditingController(text: year?['endDate']?.toString() ?? '');
    bool isCurrent = year?['isCurrent'] == true;
    bool admissionOpen = year?['isAdmissionOpen'] == true;

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
                  Text(year == null ? 'Yeni tədris ili' : 'Tədris ilini düzəliş et', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _tf('Başlama tarixi (YYYY-MM-DD) *', start),
                  _tf('Bitmə tarixi (YYYY-MM-DD) *', end),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Cari aktiv il', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: isCurrent, onChanged: (v) => setSheet(() => isCurrent = v)),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Qəbul açıqdır', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: admissionOpen, onChanged: (v) => setSheet(() => admissionOpen = v)),
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
    if (start.text.trim().isEmpty || end.text.trim().isEmpty) {
      _snack('Başlama və bitmə tarixləri tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveAcademicYear({
      'startDate': start.text.trim(),
      'endDate': end.text.trim(),
      'isCurrent': isCurrent,
      'isAdmissionOpen': admissionOpen,
    }, id: year?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> y) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tədris ilini sil'),
        content: Text('${y['name']} silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (c != true) return;
    final ok = await SchoolApiService.instance.deleteAcademicYear(y['id'].toString());
    _snack(ok ? 'Silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Widget _tf(String label, TextEditingController c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: _deco(label)));

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    final parts = raw.split('-');
    if (parts.length != 3) return raw;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.brandRoyal,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text('Tədris ili əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Tədris İlləri', style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveCenter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    SectionHeader(title: 'Tədris Təqvimi İlləri', subtitle: '${_years.length} real tədris dövrü göstərilir'),
                    const SizedBox(height: 6),
                    if (_years.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Tədris ili tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      ..._years.map((y) {
                        final isCurrent = y['isCurrent'] == true;
                        final admissionOpen = y['isAdmissionOpen'] == true;
                        return ModernCard(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          onTap: () => _showForm(year: y),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(y['name']?.toString() ?? 'Tədris İli', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                                StatusBadge(label: isCurrent ? 'Cari Aktiv İl' : 'Arxiv', color: isCurrent ? AppColors.success : Colors.grey, fontSize: 10),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Icon(Icons.date_range_rounded, size: 16, color: palette.brandRoyal),
                                const SizedBox(width: 8),
                                Text('${_formatDate(y['startDate']?.toString() ?? '')} — ${_formatDate(y['endDate']?.toString() ?? '')}', style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Icon(admissionOpen ? Icons.lock_open_rounded : Icons.lock_rounded, size: 16, color: admissionOpen ? AppColors.emerald : palette.textTertiary),
                                const SizedBox(width: 8),
                                Text(admissionOpen ? 'Qəbul açıqdır' : 'Qəbul bağlıdır', style: TextStyle(color: palette.textTertiary, fontSize: 12)),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(year: y), icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Düzəliş et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(y), icon: const Icon(Icons.delete_rounded, size: 16), label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                              ]),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
