import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';

class TimeSlotsScreen extends StatefulWidget {
  const TimeSlotsScreen({super.key});

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await SchoolApiService.instance.fetchTimeSlots();
    data.sort((a, b) => ((a['lessonNumber'] as num?)?.toInt() ?? 0).compareTo((b['lessonNumber'] as num?)?.toInt() ?? 0));
    if (!mounted) return;
    setState(() {
      _slots = data;
      _isLoading = false;
    });
  }

  int _minutes(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger));
  }

  Future<void> _showForm({Map<String, dynamic>? slot}) async {
    final palette = AppPalette.of(context);
    final number = TextEditingController(text: (slot?['lessonNumber'] ?? 1).toString());
    final start = TextEditingController(text: slot?['startTime']?.toString() ?? '08:30');
    final end = TextEditingController(text: slot?['endTime']?.toString() ?? '09:15');
    String queue = slot?['queue']?.toString() ?? 'first_queue';
    bool show = slot?['showInSchedule'] != false;

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
                  Text(slot == null ? 'Yeni zəng saatı' : 'Zəng saatını düzəliş et', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _tf('Dərs nömrəsi *', number, keyboard: TextInputType.number),
                  Row(children: [
                    Expanded(child: _tf('Başlama (HH:MM)', start)),
                    const SizedBox(width: 8),
                    Expanded(child: _tf('Bitmə (HH:MM)', end)),
                  ]),
                  DropdownButtonFormField<String>(
                    initialValue: queue,
                    decoration: _deco('Növbə'),
                    items: const [
                      DropdownMenuItem(value: 'first_queue', child: Text('1-ci növbə')),
                      DropdownMenuItem(value: 'second_queue', child: Text('2-ci növbə')),
                      DropdownMenuItem(value: 'third_queue', child: Text('3-cü növbə')),
                      DropdownMenuItem(value: 'forth_queue', child: Text('4-cü növbə')),
                    ],
                    onChanged: (v) => setSheet(() => queue = v ?? 'first_queue'),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Cədvəldə göstər', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), value: show, onChanged: (v) => setSheet(() => show = v)),
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
    final ok = await SchoolApiService.instance.saveTimeSlot({
      'lessonNumber': int.tryParse(number.text.trim()) ?? 1,
      'startTime': start.text.trim(),
      'endTime': end.text.trim(),
      'queue': queue,
      'showInSchedule': show,
    }, id: slot?['id']?.toString());
    _snack(ok ? 'Yadda saxlanıldı' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zəng saatını sil'),
        content: Text('${s['periodName']} silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (c != true) return;
    final ok = await SchoolApiService.instance.deleteTimeSlot(s['id'].toString());
    _snack(ok ? 'Silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  InputDecoration _deco(String label) => InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Widget _tf(String label, TextEditingController c, {TextInputType keyboard = TextInputType.text, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, maxLines: maxLines, keyboardType: keyboard, decoration: _deco(label)));

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
        label: const Text('Saat əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Zəng Cədvəli və Dərs Saatları', style: TextStyle(fontWeight: FontWeight.w900)),
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
                    SectionHeader(title: 'Məktəb Gündəlik Rejimi', subtitle: '${_slots.length} real zəng saatı göstərilir'),
                    const SizedBox(height: 6),
                    if (_slots.isEmpty)
                      Padding(padding: const EdgeInsets.all(36), child: Center(child: Text('Zəng cədvəli tapılmadı', style: TextStyle(color: palette.textSecondary))))
                    else
                      for (int i = 0; i < _slots.length; i++) ...[
                        if (i > 0) _buildBreak(palette, _slots[i - 1], _slots[i]),
                        _buildSlot(palette, _slots[i]),
                      ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSlot(AppPalette palette, Map<String, dynamic> s) {
    final start = s['startTime']?.toString() ?? '';
    final end = s['endTime']?.toString() ?? '';
    final number = (s['lessonNumber'] as num?)?.toInt() ?? 0;
    final duration = (_minutes(end) - _minutes(start)).clamp(0, 600);

    return ModernCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      onTap: () => _showForm(slot: s),
      child: Column(
        children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: palette.brandRoyal.withValues(alpha: 0.12),
              child: Text('$number', style: TextStyle(color: palette.brandRoyal, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['periodName']?.toString() ?? '$number-ci dərs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text('Müddət: $duration dəqiqə', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            StatusBadge(label: '$start — $end', color: palette.brandAzure, fontSize: 11),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showForm(slot: s), icon: const Icon(Icons.edit_rounded, size: 15), label: const Text('Düzəliş et', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _delete(s), icon: const Icon(Icons.delete_rounded, size: 15), label: const Text('Sil', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)))),
          ]),
        ],
      ),
    );
  }

  Widget _buildBreak(AppPalette palette, Map<String, dynamic> prev, Map<String, dynamic> next) {
    final prevEnd = prev['endTime']?.toString() ?? '';
    final nextStart = next['startTime']?.toString() ?? '';
    final gap = _minutes(nextStart) - _minutes(prevEnd);
    if (gap <= 0) return const SizedBox.shrink();
    final isLunch = gap >= 30;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLunch ? palette.brandRoyal.withValues(alpha: 0.08) : palette.surface2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLunch ? palette.brandRoyal.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Row(children: [
        Icon(isLunch ? Icons.restaurant_rounded : Icons.coffee_rounded, size: 16, color: isLunch ? palette.brandRoyal : palette.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(isLunch ? 'Böyük nahar tənəffüsü' : 'Tənəffüs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isLunch ? palette.brandRoyal : palette.textSecondary))),
        Text('$prevEnd - $nextStart ($gap dəq)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textTertiary)),
      ]),
    );
  }
}
