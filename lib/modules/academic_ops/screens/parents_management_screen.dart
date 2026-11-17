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
import 'parent_edit_screen.dart';
import 'parent_profile_screen.dart';

class ParentsManagementScreen extends StatefulWidget {
  const ParentsManagementScreen({super.key});

  @override
  State<ParentsManagementScreen> createState() => _ParentsManagementScreenState();
}

class _ParentChildItem {
  final String studentId;
  final String name;
  final String className;
  String parentType;

  _ParentChildItem({
    required this.studentId,
    required this.name,
    required this.className,
    this.parentType = 'father',
  });
}

class _ParentsManagementScreenState extends State<ParentsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _parents = [];
  Map<String, dynamic> _stats = {};
  String _statusFilter = 'all'; // all, active, admission, expelled

  static const _parentTypes = [
    ('father', 'Ata'),
    ('mother', 'Ana'),
    ('step_father', 'Ögey ata'),
    ('step_mother', 'Ögey ana'),
    ('grand_father', 'Baba'),
    ('grand_mother', 'Nənə'),
    ('emi', 'Əmi/Dayı'),
    ('guardian', 'Vəsi'),
    ('other', 'Digər'),
  ];

  static String _formatRelation(String key) {
    for (final t in _parentTypes) {
      if (t.$1 == key) return t.$2;
    }
    return key.isEmpty ? 'Valideyn' : key;
  }

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
    final parentsPayload = await SchoolApiService.instance.fetchParentsPayload(query: _searchController.text.trim());

    if (!mounted) return;

    List<Map<String, dynamic>> pList = [];
    Map<String, dynamic> stats = {};

    if (parentsPayload != null) {
      if (parentsPayload['data'] is List) {
        pList = List<Map<String, dynamic>>.from(parentsPayload['data']);
      }
      if (parentsPayload['stats'] is Map) {
        stats = Map<String, dynamic>.from(parentsPayload['stats']);
      }
    }

    setState(() {
      _parents = pList;
      _stats = stats;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _parents.where((p) {
      // Status filter
      if (_statusFilter == 'active') {
        final hasActive = (p['children'] as List? ?? []).any((c) => c['isActive'] == true);
        if (!hasActive && (p['children'] as List? ?? []).isNotEmpty) return false;
      } else if (_statusFilter == 'admission') {
        final hasAdmission = (p['children'] as List? ?? []).any((c) =>
            (c['statusKey'] ?? '').toString().contains('admission') ||
            (c['statusKey'] ?? '').toString().contains('contract'));
        if (!hasAdmission) return false;
      } else if (_statusFilter == 'expelled') {
        final hasExpelled = (p['children'] as List? ?? []).any((c) =>
            (c['statusKey'] ?? '').toString().contains('expelled') ||
            (c['statusKey'] ?? '').toString().contains('leave') ||
            c['isActive'] == false);
        if (!hasExpelled) return false;
      }

      if (q.isEmpty) return true;

      final name = (p['name'] ?? '').toString().toLowerCase();
      final father = (p['fatherName'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      final code = (p['code'] ?? '').toString().toLowerCase();
      final fin = (p['finCode'] ?? '').toString().toLowerCase();
      final serial = '${p['serialType'] ?? ''} ${p['serialNumber'] ?? ''}'.toLowerCase();
      final children = (p['children'] as List? ?? []).map((c) => (c['name'] ?? '').toString().toLowerCase()).join(' ');

      return name.contains(q) ||
          father.contains(q) ||
          phone.contains(q) ||
          code.contains(q) ||
          fin.contains(q) ||
          serial.contains(q) ||
          children.contains(q);
    }).toList();
  }

  void _snack(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===========================================================================
  // 1. GİRİŞ MƏLUMATLARI (LOGIN DETAILS MODAL)
  // ===========================================================================
  Future<void> _showLoginDetails(Map<String, dynamic> parent) async {
    final parentId = parent['id'].toString();
    final palette = AppPalette.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final details = await SchoolApiService.instance.fetchParentLoginDetails(parentId);
    if (mounted) Navigator.pop(context); // close loader

    if (!mounted) return;

    final finCtrl = TextEditingController(text: details?['finCode']?.toString() ?? parent['finCode']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: details?['email']?.toString() ?? parent['email']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final plainPass = details?['plainPassword']?.toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 22),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.key_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giriş Məlumatları',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              parent['name'] ?? '',
                              style: TextStyle(fontSize: 12, color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: finCtrl,
                    maxLength: 7,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'FİN Kod *',
                      isDense: true,
                      prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-poçt ünvanı *',
                      isDense: true,
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Yeni şifrə (boş saxlasanız dəyişməz)',
                      isDense: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (plainPass != null && plainPass.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.vpn_key_outlined, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          const Text('Cari şifrə: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            plainPass,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0B192C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (finCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                        _snack('FİN və e-poçt tələb olunur', ok: false);
                        return;
                      }
                      Navigator.pop(ctx);
                      final ok = await SchoolApiService.instance.saveParentLoginDetails(parentId, {
                        'fin_code': finCtrl.text.trim().toUpperCase(),
                        'email': emailCtrl.text.trim(),
                        if (passCtrl.text.trim().isNotEmpty) 'password': passCtrl.text.trim(),
                      });
                      _snack(ok ? 'Giriş məlumatları yeniləndi' : 'Xəta baş verdi', ok: ok);
                      if (ok) _load();
                    },
                    child: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 2. ÖVLADLARIN İDARƏ EDİLMƏSİ (CHILDREN MODAL)
  // ===========================================================================
  Future<void> _showChildrenModal(Map<String, dynamic> parent, {required bool canManage}) async {
    final parentId = parent['id'].toString();
    final palette = AppPalette.of(context);
    final children = List<Map<String, dynamic>>.from(parent['children'] as List? ?? []);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.people_alt_rounded, color: palette.brandRoyal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valideynin Övladları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('${parent['name']} (${children.length} övlad)', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (canManage) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.brandRoyal,
                      side: BorderSide(color: palette.brandRoyal),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final selected = await _pickStudent(ctx, children.map((c) => c['id'].toString()).toSet());
                      if (selected != null) {
                        final ok = await SchoolApiService.instance.addParentChild(
                          parentId,
                          studentId: selected.studentId,
                          parentType: selected.parentType,
                        );
                        _snack(ok ? 'Övlad əlavə edildi' : 'Xəta baş verdi', ok: ok);
                        if (ok && mounted) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        }
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Yeni övlad əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: children.isEmpty
                      ? Center(
                          child: Text('Heç bir övlad tapılmadı', style: TextStyle(color: palette.textSecondary)),
                        )
                      : ListView.separated(
                          itemCount: children.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final c = children[i];
                            final stId = c['id'].toString();
                            final cName = c['name'] ?? 'Şagird';
                            final cClass = c['className'] ?? '—';
                            final rel = _formatRelation(c['relation']?.toString() ?? '');
                            final isActive = c['isActive'] == true;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: palette.brandRoyal.withValues(alpha: 0.15),
                                    child: Text(
                                      cName.isNotEmpty ? cName[0].toUpperCase() : 'Ş',
                                      style: TextStyle(fontWeight: FontWeight.w800, color: palette.brandRoyal, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: palette.brandRoyal.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(cClass, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.brandRoyal)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: palette.textSecondary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(rel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isActive ? AppColors.emerald : AppColors.danger).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isActive ? 'Aktiv' : 'Xaric edilib',
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isActive ? AppColors.emerald : AppColors.danger),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canManage) ...[
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                                      onSelected: (val) async {
                                        if (val == 'detach') {
                                          final ok = await SchoolApiService.instance.detachParentChild(parentId, stId);
                                          _snack(ok ? 'Övlad əlaqəsi kəsildi' : 'Xəta baş verdi', ok: ok);
                                          if (ok && mounted) {
                                            if (ctx.mounted) Navigator.pop(ctx);
                                            _load();
                                          }
                                        } else if (val == 'transfer') {
                                          _showTransferChildDialog(parentId, stId, cName);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'transfer', child: Text('Başqa valideynə köçür')),
                                        PopupMenuItem(value: 'detach', child: Text('Valideyndən çıxar', style: TextStyle(color: AppColors.danger))),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. UŞAQ KÖÇÜRMƏ (TRANSFER CHILD DIALOG)
  // ===========================================================================
  Future<void> _showTransferChildDialog(String sourceParentId, String studentId, String studentName) async {
    final otherParents = _parents.where((p) => p['id'].toString() != sourceParentId).toList();
    String? selectedTargetParentId;
    String parentType = 'father';

    await showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          return AlertDialog(
            title: Text('$studentName adlı şagirdi köçür'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Hədəf valideyn seçin', isDense: true),
                  initialValue: selectedTargetParentId,
                  items: otherParents.take(50).map((p) {
                    final pName = '${p['name'] ?? ''} (${p['code'] ?? ''})';
                    return DropdownMenuItem(value: p['id'].toString(), child: Text(pName, maxLines: 1, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) => setD(() => selectedTargetParentId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Əlaqə növü', isDense: true),
                  initialValue: parentType,
                  items: _parentTypes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                  onChanged: (v) => setD(() => parentType = v ?? 'father'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Ləğv et')),
              FilledButton(
                onPressed: selectedTargetParentId == null
                    ? null
                    : () async {
                        Navigator.pop(dlgCtx);
                        final ok = await SchoolApiService.instance.transferParentChild(
                          sourceParentId,
                          studentId: studentId,
                          targetParentId: selectedTargetParentId,
                          parentType: parentType,
                        );
                        _snack(ok ? 'Şagird uğurla köçürüldü' : 'Xəta baş verdi', ok: ok);
                        if (ok) _load();
                      },
                child: const Text('Köçür'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. VALİDEYN BİRLƏŞDİRMƏ (MERGE PARENTS MODAL)
  // ===========================================================================
  Future<void> _showMergeModal(Map<String, dynamic> targetParent) async {
    final targetId = targetParent['id'].toString();
    final otherParents = _parents.where((p) => p['id'].toString() != targetId).toList();
    final palette = AppPalette.of(context);

    String? selectedSourceId;
    bool isLoadingPreview = false;
    Map<String, dynamic>? previewData;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          Future<void> loadPreview(String sId) async {
            setM(() {
              selectedSourceId = sId;
              isLoadingPreview = true;
              previewData = null;
            });
            final res = await SchoolApiService.instance.parentMergePreview(
              targetId: targetId,
              sourceId: sId,
            );
            if (mounted) {
              setM(() {
                isLoadingPreview = false;
                previewData = res;
              });
            }
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.compress_rounded, color: palette.brandRoyal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valideyn Birləşdirmə (Merge)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Dublikat profilin məlumatlarını əsas valideynə köçürün', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 14),
                // Target parent banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.brandRoyal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.brandRoyal.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.brandRoyal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ƏSAS VALİDEYN (MƏLUMATLAR BURA KÖÇÜRÜLƏCƏK)', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 6),
                      Text(targetParent['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text('ID: ${targetParent['id']} • Kod: ${targetParent['code'] ?? '—'} • Tel: ${targetParent['phone'] ?? '—'}', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Köçürüləcək dublikat valideyni seçin *',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  initialValue: selectedSourceId,
                  items: otherParents.take(100).map((p) {
                    final title = '${p['name']} (${p['code'] ?? 'ID: ${p['id']}'})';
                    return DropdownMenuItem(value: p['id'].toString(), child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) loadPreview(v);
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: isLoadingPreview
                      ? const Center(child: CircularProgressIndicator())
                      : previewData == null
                          ? Center(
                              child: Text('Dublikat valideyni seçin ki, köçürüləcək məlumatların xülasəsi göstərilsin', textAlign: TextAlign.center, style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Köçürüləcək Əlaqəli Məlumatlar:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _statPill(palette, 'Övladlar', '${(previewData?['source']?['children_count'] ?? 0)}'),
                                            _statPill(palette, 'Müqavilələr', '${(previewData?['transfer_counts']?['contracts'] ?? 0)}'),
                                            _statPill(palette, 'Sənədlər', '${(previewData?['transfer_counts']?['documents'] ?? 0)}'),
                                            _statPill(palette, 'Qeydlər', '${(previewData?['transfer_counts']?['notes'] ?? 0)}'),
                                            _statPill(palette, 'Ödənişlər', '${(previewData?['transfer_counts']?['payments'] ?? 0)}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Birləşdirmə icra edildikdə bütün əlaqələr (övladlar, müqavilələr, sənədlər) əsas valideynə köçürüləcək və dublikat profil deaktiv ediləcək. Bu əməliyyat geri qaytarıla bilməz!',
                                            style: TextStyle(fontSize: 11.5, color: AppColors.danger, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B192C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: selectedSourceId == null || isLoadingPreview
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final ok = await SchoolApiService.instance.executeParentMerge(
                            targetId: targetId,
                            sourceId: selectedSourceId!,
                          );
                          _snack(ok ? 'Valideynlər uğurla birləşdirildi' : 'Birləşdirmə alınmadı', ok: ok);
                          if (ok) _load();
                        },
                  child: const Text('Birləşdirməni Təsdiq Et', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statPill(AppPalette palette, String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('$label: $val', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }

  // ===========================================================================
  // 5. YARAT / REDAKTƏ FORMASI (FULL PARENT FORM)
  // ===========================================================================
  Future<void> _showForm({Map<String, dynamic>? parent}) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ParentEditScreen(parentToEdit: parent),
      ),
    );
    if (updated == true && mounted) {
      _load();
    }
    return;
  }

  // ===========================================================================
  // 6. SİLMƏ ƏMƏLİYYATI (DELETE)
  // ===========================================================================
  Future<void> _delete(Map<String, dynamic> parent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valideyni sil'),
        content: Text('${parent['name']} adlı valideyn silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ləğv et')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SchoolApiService.instance.deleteParent(parent['id'].toString());
    _snack(ok ? 'Valideyn silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<_ParentChildItem?> _pickStudent(BuildContext ctx, Set<String> existingIds) async {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool loading = false;

    return showModalBottomSheet<_ParentChildItem>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Text('Şagird Seçin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Şagird adı və ya kodu...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      final q = searchCtrl.text.trim();
                      if (q.isEmpty) return;
                      setSheet(() => loading = true);
                      final r = await SchoolApiService.instance.fetchStudents(query: q);
                      setSheet(() {
                        results = r;
                        loading = false;
                      });
                    },
                  ),
                ),
                onSubmitted: (q) async {
                  if (q.trim().isEmpty) return;
                  setSheet(() => loading = true);
                  final r = await SchoolApiService.instance.fetchStudents(query: q.trim());
                  setSheet(() {
                    results = r;
                    loading = false;
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final s = results[i];
                          final id = s['id']?.toString() ?? '';
                          if (existingIds.contains(id)) return const SizedBox.shrink();
                          final name = s['fullName']?.toString() ?? '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                          final cls = s['className']?.toString() ?? s['class_name']?.toString() ?? '';

                          return ListTile(
                            title: Text(name.isNotEmpty ? name : 'Şagird #$id', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Sinif: $cls', style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
                            onTap: () {
                              Navigator.pop(
                                sheetCtx,
                                _ParentChildItem(
                                  studentId: id,
                                  name: name,
                                  className: cls,
                                  parentType: 'father',
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD SCREEN
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;

    final canEdit = isSuper || session.can('gopanel.academic.parents.update');
    final canDelete = isSuper || session.can('gopanel.academic.parents.delete');
    final canManageChildren = isSuper || session.can('gopanel.academic.parents.manage_children');
    final canLoginDetails = isSuper || session.canViewPassword('parent');
    final canMerge = isSuper || session.can('gopanel.academic.parents.update');

    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B192C),
        foregroundColor: Colors.white,
        title: const Text('Valideynlər', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Yenilə'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveCenter(
                horizontalPadding: 0,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 140),
                  children: [
                    // Search box
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Valideyn adı, FİN, nömrə, kod və ya övladı ilə axtar...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'Hamısı (${_stats['totalParents'] ?? _parents.length})'),
                          const SizedBox(width: 8),
                          _filterChip('active', 'Aktiv Şagirdli (${_stats['activeParents'] ?? 563})'),
                          const SizedBox(width: 8),
                          _filterChip('admission', 'Qəbul prosesində'),
                          const SizedBox(width: 8),
                          _filterChip('expelled', 'Xaric edilmiş'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stat Cards
                    StatCardRow(
                      children: [
                        StatCard(
                          value: '${_stats['activeParents'] ?? 563}',
                          label: 'Aktiv Valideynlər',
                          icon: Icons.family_restroom_rounded,
                          color: const Color(0xFF1E3E62),
                        ),
                        StatCard(
                          value: '${_stats['totalParents'] ?? _parents.length}',
                          label: 'Ümumi Qeydiyyat',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        StatCard(
                          value: '${_stats['totalChildren'] ?? 562}',
                          label: 'Şagirdlər',
                          icon: Icons.school_rounded,
                          color: AppColors.emerald,
                        ),
                        StatCard(
                          value: '${_stats['maleCount'] ?? 0}',
                          label: 'Oğlanlar',
                          icon: Icons.male_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SectionHeader(
                      title: 'Qeydiyyatdakı Valideynlər',
                      subtitle: '${items.length} valideyn göstərilir',
                    ),
                    const SizedBox(height: 10),

                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text('Valideyn tapılmadı', style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final p in items) ...[
                        _buildParentCard(
                          context,
                          palette: palette,
                          parent: p,
                          canEdit: canEdit,
                          canDelete: canDelete,
                          canManageChildren: canManageChildren,
                          canLoginDetails: canLoginDetails,
                          canMerge: canMerge,
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B192C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0B192C) : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0B192C).withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  void _openParentProfile(Map<String, dynamic> parent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentProfileScreen(
          parent: parent,
          onRefresh: _load,
        ),
      ),
    );
  }

  // ===========================================================================
  // PARENT CARD
  // ===========================================================================
  Widget _buildParentCard(
    BuildContext context, {
    required AppPalette palette,
    required Map<String, dynamic> parent,
    required bool canEdit,
    required bool canDelete,
    required bool canManageChildren,
    required bool canLoginDetails,
    required bool canMerge,
  }) {
    final name = parent['name']?.toString() ?? 'Valideyn';
    final father = parent['fatherName']?.toString() ?? '';
    final code = parent['code']?.toString() ?? '';
    final phone = parent['phone']?.toString() ?? '';
    final email = parent['email']?.toString() ?? '';
    final fin = parent['finCode']?.toString() ?? '';
    final serial = '${parent['serialType'] ?? ''} ${parent['serialNumber'] ?? ''}'.trim();
    final isActive = parent['isActive'] != false;
    final children = List<Map<String, dynamic>>.from(parent['children'] as List? ?? []);

    final displayName = father.isNotEmpty ? '$name $father' : name;

    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => _openParentProfile(parent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar, name, and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1E3E62).withValues(alpha: 0.12),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3E62)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code.isNotEmpty ? code : 'ID: ${parent['id']}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.emerald : AppColors.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Aktiv' : 'Qeyri-aktiv',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppColors.emerald : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Identity chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (phone.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_rounded, size: 13, color: AppColors.emerald),
                      const SizedBox(width: 5),
                      Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              if (fin.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF1E3E62)),
                      const SizedBox(width: 5),
                      Text('FİN: $fin', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              if (serial.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text('Ş.V: $serial', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, fontWeight: FontWeight.w700)),
                ),
              if (email.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email_outlined, size: 13, color: Colors.grey.shade700),
                      const SizedBox(width: 5),
                      Text(email, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
            ],
          ),

          // Children block
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: Color(0xFF1E3E62)),
                      const SizedBox(width: 6),
                      Text(
                        'Övladları (${children.length}):',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E3E62)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final ch in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3E62))),
                          Expanded(
                            child: Text(
                              '${ch['name']} (${ch['className']})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              _formatRelation(ch['relation']?.toString() ?? ''),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action buttons row
          Row(
            children: [
              // 1. Login Details button
              if (canLoginDetails) ...[
                IconButton(
                  tooltip: 'Giriş məlumatları',
                  onPressed: () => _showLoginDetails(parent),
                  icon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFFF59E0B)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(38, 38),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // 2. Merge button
              if (canMerge) ...[
                IconButton(
                  tooltip: 'Valideyni Birləşdir (Merge)',
                  onPressed: () => _showMergeModal(parent),
                  icon: const Icon(Icons.compress_rounded, size: 18, color: Color(0xFF1E3E62)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3E62).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(38, 38),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // 3. Children Management button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3E62),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showChildrenModal(parent, canManage: canManageChildren),
                  icon: const Icon(Icons.people_alt_outlined, size: 16),
                  label: Text(
                    'Övladlar (${children.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 4. Edit button
              if (canEdit) ...[
                IconButton(
                  tooltip: 'Redaktə et',
                  onPressed: () => _showForm(parent: parent),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1E3E62)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(38, 38),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // 5. Delete button
              if (canDelete) ...[
                IconButton(
                  tooltip: 'Sil',
                  onPressed: () => _delete(parent),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(38, 38),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
