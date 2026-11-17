import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../providers/app_state.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Hamısı';
  bool _loading = true;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    final list = await SchoolApiService.instance.fetchRooms();
    if (!mounted) return;
    setState(() {
      _rooms = list;
      _loading = false;
    });
  }

  List<String> get _types {
    final set = <String>{'Hamısı'};
    for (final r in _rooms) {
      final t = (r['roomType'] ?? '').toString().trim();
      if (t.isNotEmpty) set.add(t);
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredRooms {
    final query = _searchController.text.trim().toLowerCase();
    return _rooms.where((r) {
      final rType = (r['roomType'] ?? '').toString();
      final matchesType = _selectedType == 'Hamısı' || rType == _selectedType;
      final rNum = (r['roomNumber'] ?? '').toString().toLowerCase();
      final rName = (r['name'] ?? '').toString().toLowerCase();
      final rWing = (r['wing'] ?? '').toString().toLowerCase();
      final matchesSearch = query.isEmpty ||
          rNum.contains(query) ||
          rName.contains(query) ||
          rWing.contains(query);
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoomDetailsSheet(Map<String, dynamic> rm, bool canManage) {
    final palette = AppPalette.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.borderHairline),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.meeting_room_rounded, color: palette.brandRoyal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (rm['name'] ?? rm['roomNumber'] ?? '').toString(),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Otaq №: ${rm['roomNumber']} • ${rm['roomType']}',
                          style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: (rm['status'] == 'active' || rm['status'] == null) ? 'Aktiv' : rm['status'].toString(),
                    color: AppColors.emerald,
                    fontSize: 11,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _infoRow('Otaq Nömrəsi', (rm['roomNumber'] ?? '-').toString(), palette),
              _infoRow('Otaq Növü', (rm['roomType'] ?? 'Sinif otağı').toString(), palette),
              _infoRow('Korpus / Bina', (rm['wing'] ?? 'Əsas Korpus').toString(), palette),
              _infoRow('Mərtəbə', '${rm['floor'] ?? 1}-ci mərtəbə', palette),
              _infoRow('Maksimum Tutum', '${rm['capacity'] ?? 24} nəfər', palette, isBold: true),
              _infoRow('Smart Lövhə', rm['hasSmartBoard'] == true ? 'Var' : 'Yoxdur', palette),
              _infoRow('Proyektor', rm['hasProjector'] == true ? 'Var' : 'Yoxdur', palette),
              _infoRow('Kondisioner (AC)', rm['hasAc'] == true ? 'Var' : 'Yoxdur', palette),
              if ((rm['notes'] ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Qeyd: ${rm['notes']}',
                  style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
                ),
              ],
              if (canManage) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final ok = await SchoolApiService.instance.deleteRoom(rm['id'].toString());
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Otaq silindi' : 'Silinmə zamanı xəta'),
                              backgroundColor: ok ? AppColors.success : AppColors.danger,
                            ),
                          );
                          _loadRooms();
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Sil'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.brandRoyal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRoomEditorDialog(existing: rm);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Otağı Redaktə Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, AppPalette palette, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRoomEditorDialog({Map<String, dynamic>? existing}) {
    final numberCtrl = TextEditingController(text: existing?['roomNumber']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final floorCtrl = TextEditingController(text: (existing?['floor'] ?? 1).toString());
    final capCtrl = TextEditingController(text: (existing?['capacity'] ?? 24).toString());
    final wingCtrl = TextEditingController(text: existing?['wing']?.toString() ?? 'Əsas Korpus');
    final notesCtrl = TextEditingController(text: existing?['notes']?.toString() ?? '');
    String roomTypeKey = (existing?['roomTypeKey'] ?? 'classroom').toString();
    bool hasSmartBoard = existing?['hasSmartBoard'] == true;
    bool hasProjector = existing?['hasProjector'] == true;
    bool hasAc = existing?['hasAc'] != false;

    const typeOptions = {
      'classroom': 'Sinif otağı',
      'lab': 'Laboratoriya',
      'computer_lab': 'Kompüter zalı',
      'gym': 'İdman zalı',
      'library': 'Kitabxana',
      'auditorium': 'Akt zalı',
      'teacher_room': 'Müəllimlər otağı',
      'other': 'Digər',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Yeni Dərs Otağı Əlavə Et' : 'Otağı Redaktə Et'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Otaq Nömrəsi * (məs: 302)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Otaq Adı * (məs: Riyaziyyat Kabineti)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: typeOptions.containsKey(roomTypeKey) ? roomTypeKey : 'classroom',
                  decoration: const InputDecoration(
                    labelText: 'Otaq Növü',
                    border: OutlineInputBorder(),
                  ),
                  items: typeOptions.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => roomTypeKey = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: floorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Mərtəbə',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: capCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tutum (nəfər)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: wingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Korpus / Bina',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Əlavə Qeyd',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Smart Lövhə'),
                  value: hasSmartBoard,
                  onChanged: (v) => setDialogState(() => hasSmartBoard = v),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Proyektor'),
                  value: hasProjector,
                  onChanged: (v) => setDialogState(() => hasProjector = v),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kondisioner (AC)'),
                  value: hasAc,
                  onChanged: (v) => setDialogState(() => hasAc = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ləğv et'),
            ),
            FilledButton(
              onPressed: () async {
                if (numberCtrl.text.trim().isEmpty && nameCtrl.text.trim().isEmpty) return;
                final payload = {
                  'roomNumber': numberCtrl.text.trim().isNotEmpty ? numberCtrl.text.trim() : nameCtrl.text.trim(),
                  'name': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Otaq ${numberCtrl.text.trim()}',
                  'roomTypeKey': roomTypeKey,
                  'floor': int.tryParse(floorCtrl.text.trim()) ?? 1,
                  'capacity': int.tryParse(capCtrl.text.trim()) ?? 24,
                  'wing': wingCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                  'hasSmartBoard': hasSmartBoard,
                  'hasProjector': hasProjector,
                  'hasAc': hasAc,
                };
                Navigator.pop(ctx);
                final res = await SchoolApiService.instance.saveRoom(
                  payload,
                  id: existing?['id']?.toString(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res ? 'Otaq yadda saxlanıldı!' : 'Xəta baş verdi'),
                    backgroundColor: res ? AppColors.success : AppColors.danger,
                  ),
                );
                _loadRooms();
              },
              child: const Text('Yadda Saxla'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();
    final canManage = appState.isSuperAdmin ||
        appState.hasPermission('gopanel.academic.foundations.rooms.create') ||
        appState.hasPermission('gopanel.academic.foundations.rooms.store') ||
        appState.hasPermission('gopanel.academic.foundations.rooms.update') ||
        appState.hasPermission('gopanel.academic.foundations.rooms.delete') ||
        appState.hasPermission('gopanel.academic.rooms.store') ||
        appState.hasPermission('manage_rooms');
    final rooms = _filteredRooms;
    final types = _types;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Otaqlar (GoPanel)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRooms,
            tooltip: 'Yenilə',
          ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => _showRoomEditorDialog(),
              tooltip: 'Yeni Otaq Əlavə Et',
            ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showRoomEditorDialog(),
              backgroundColor: palette.brandRoyal,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Yeni Otaq', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            )
          : null,
      body: ResponsiveCenter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'Otaq nömrəsi, ad və ya korpus ilə axtar...',
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: types.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final t = types[index];
                  final isSelected = t == _selectedType;
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = t);
                    },
                    selectedColor: palette.brandRoyal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : palette.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: palette.surface1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      side: BorderSide(color: isSelected ? palette.brandRoyal : palette.borderHairline),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SectionHeader(
              title: 'Məktəb Otaq Fondu',
              subtitle: '${rooms.length} otaq və laboratoriya göstərilir (toxunaraq detallara baxın)',
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : rooms.isEmpty
                      ? Center(
                          child: Text(
                            'Axtarışa uyğun otaq tapılmadı',
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 84),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final rm = rooms[index];
                            return ModernCard(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              padding: const EdgeInsets.all(14),
                              onTap: () => _showRoomDetailsSheet(rm, canManage),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Otaq ${rm['roomNumber']}',
                                        style: TextStyle(
                                          color: palette.brandRoyal,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          StatusBadge(
                                            label: (rm['roomType'] ?? 'Sinif otağı').toString(),
                                            color: palette.brandAzure,
                                            fontSize: 11,
                                          ),
                                          if (canManage) ...[
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _showRoomEditorDialog(existing: rm),
                                              child: Icon(Icons.edit_outlined, size: 18, color: palette.brandRoyal),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (rm['name'] ?? '').toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '${rm['wing'] ?? 'Əsas Korpus'}  •  ${rm['floor'] ?? 1}-ci mərtəbə  •  Tutum: ${rm['capacity'] ?? 24} nəfər',
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (rm['hasSmartBoard'] == true)
                                        const StatusBadge(
                                          label: 'Smart Lövhə',
                                          color: AppColors.emerald,
                                          icon: Icons.tv_rounded,
                                          fontSize: 10,
                                        ),
                                      if (rm['hasProjector'] == true)
                                        const StatusBadge(
                                          label: 'Proyektor',
                                          color: AppColors.gold,
                                          icon: Icons.videocam_rounded,
                                          fontSize: 10,
                                        ),
                                      if (rm['hasAc'] == true)
                                        StatusBadge(
                                          label: 'AC',
                                          color: palette.brandRoyal,
                                          icon: Icons.ac_unit_rounded,
                                          fontSize: 10,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
