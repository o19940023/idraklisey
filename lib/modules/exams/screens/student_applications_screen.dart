import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/status_badge.dart';
import '../../admin/screens/student_registration_screen.dart';
import '../../academic_ops/screens/create_contract_screen.dart';

class StudentApplicationsScreen extends StatefulWidget {
  const StudentApplicationsScreen({super.key});

  @override
  State<StudentApplicationsScreen> createState() => _StudentApplicationsScreenState();
}

class _StudentApplicationsScreenState extends State<StudentApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _activeTab = 'pending';
  List<Map<String, dynamic>> _applications = [];
  Map<String, dynamic> _counts = {};

  static const List<(String, String, Color)> _tabs = [
    ('pending', 'Gözləyən', Color(0xFF2563EB)),
    ('contracted', 'Müqaviləli', Color(0xFF059669)),
    ('rejected_psychology', 'Psixoloq imtina', Color(0xFFD97706)),
    ('rejected_exam', 'İmtahan imtina', Color(0xFFDC2626)),
    ('expired', 'Vaxtı bitmiş', Color(0xFF64748B)),
    ('refused', 'İmtina edilən', Color(0xFF991B1B)),
    ('all', 'Bütün müraciətlər', Color(0xFF334155)),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final payload = await SchoolApiService.instance.fetchAdmissionsData(tab: _activeTab);
    if (!mounted) return;
    setState(() {
      _applications = payload != null && payload['data'] is List
          ? List<Map<String, dynamic>>.from(payload['data'])
          : [];
      _counts = payload != null && payload['counts'] is Map
          ? Map<String, dynamic>.from(payload['counts'])
          : {};
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _applications;
    return _applications.where((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final fin = (a['fin'] ?? '').toString().toLowerCase();
      final phone = (a['phone'] ?? '').toString().toLowerCase();
      final cls = (a['className'] ?? '').toString().toLowerCase();
      final code = (a['code'] ?? '').toString().toLowerCase();
      return name.contains(q) || fin.contains(q) || phone.contains(q) || cls.contains(q) || code.contains(q);
    }).toList();
  }

  int _count(String key) => (_counts[key] as num?)?.toInt() ?? 0;

  String _stageLabel(String kind, dynamic status) {
    final s = status?.toString().toLowerCase() ?? 'pending';
    return switch (s) {
      'passed' || 'valid' => 'Keçib',
      'failed' || 'invalid' => 'Uyğunsuz',
      'exempt' => 'Azad',
      _ => 'Gözləyir',
    };
  }

  Color _stageColor(dynamic status) {
    final s = status?.toString().toLowerCase();
    return switch (s) {
      'passed' || 'valid' => AppColors.emerald,
      'failed' || 'invalid' => AppColors.danger,
      'exempt' => const Color(0xFF0284C7),
      _ => const Color(0xFFD97706),
    };
  }

  void _snack(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> a) async {
    final form = await SchoolApiService.instance.fetchStudentForm(a['id'].toString());
    final detail = form ?? await SchoolApiService.instance.fetchAdmissionDetail(a['id'].toString()) ?? a;
    if (!mounted) return;
    final palette = AppPalette.of(context);
    final profile = (detail['profile'] as Map?) ?? {};
    final oldSchool = (detail['oldSchool'] as Map?) ?? {};
    final family = (detail['familyMembers'] as List?) ?? (detail['parents'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: palette.brandRoyal.withOpacity(0.12),
                    child: Text(
                      (detail['name']?.toString() ?? 'Ş').isNotEmpty ? detail['name'].toString()[0] : 'Ş',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${detail['name'] ?? detail['firstName'] ?? ''} ${detail['surname'] ?? detail['lastName'] ?? ''}'.trim(),
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${detail['code'] ?? ''} • FİN: ${profile['finCode'] ?? detail['fin'] ?? '—'}',
                          style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: detail['status']?.toString() ?? 'Gözləmədə',
                    color: palette.brandRoyal,
                    fontSize: 10,
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(palette, 'Şəxsi Məlumatlar'),
                      _infoTile(palette, 'Ata adı', detail['fatherName']?.toString() ?? '—'),
                      _infoTile(palette, 'Telefon', detail['phone']?.toString().isNotEmpty == true ? detail['phone'].toString() : '—'),
                      _infoTile(palette, 'Cins', profile['gender']?.toString() == 'female' ? 'Qadın' : 'Kişi'),
                      _infoTile(palette, 'Doğum tarixi', profile['birthDate']?.toString() ?? '—'),
                      _infoTile(palette, 'Ş.V. Seriya / Nömrə', '${profile['serialType'] ?? '—'} ${profile['serialNumber'] ?? ''}'),
                      _infoTile(palette, 'Qeydiyyat ünvanı', profile['registrationAddress']?.toString() ?? '—'),
                      _infoTile(palette, 'Faktiki ünvan', (profile['actualAddress']?.toString().isNotEmpty == true ? profile['actualAddress'] : profile['address'])?.toString() ?? '—'),
                      if (profile['note']?.toString().isNotEmpty == true)
                        _infoTile(palette, 'Qeyd', profile['note'].toString()),
                      const SizedBox(height: 12),
                      _sectionTitle(palette, 'Sinif və Yoxlanış Nəticələri'),
                      _infoTile(palette, 'Hədəf Sinif', '${detail['className'] ?? '—'} • ${profile['targetGradeLanguage'] ?? ''}'),
                      _infoTile(palette, 'İmtahan nəticəsi', _stageLabel('exam', detail['examStatus'])),
                      _infoTile(palette, 'Psixoloq rəyi', _stageLabel('psychology', detail['psychologyStatus'])),
                      _infoTile(palette, 'Tibbi baxış', _stageLabel('medical', detail['medicalStatus'])),
                      if (oldSchool['schoolName']?.toString().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _sectionTitle(palette, 'Köhnə Məktəb'),
                        _infoTile(palette, 'Məktəb adı', oldSchool['schoolName']?.toString() ?? '—'),
                        _infoTile(palette, 'Sinif səviyyəsi', oldSchool['gradeLevel']?.toString() ?? '—'),
                      ],
                      const SizedBox(height: 12),
                      _sectionTitle(palette, 'Ailə Üzvləri (${family.length})'),
                      if (family.isEmpty)
                        Text('Ailə üzvü qeyd edilməyib', style: TextStyle(fontSize: 12, color: palette.textSecondary))
                      else
                        for (final f in family)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.borderHairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 16, color: AppColors.info),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${f['name'] ?? ''} ${f['surname'] ?? ''}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                    const Spacer(),
                                    StatusBadge(
                                      label: f['relationType'] ?? f['relation'] ?? 'Valideyn',
                                      color: palette.brandRoyal,
                                      fontSize: 9.5,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Əlaqə: ${f['phone'] ?? '—'} • FİN: ${f['finCode'] ?? '—'}', style: TextStyle(fontSize: 11.5, color: palette.textSecondary)),
                                if (f['companyName']?.toString().isNotEmpty == true)
                                  Text('İş: ${f['companyName']} (${f['positionName'] ?? ''})', style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editStudent(detail);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: const Text('Düzəliş et', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandNavy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Bağla', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(AppPalette palette, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(title, style: TextStyle(fontSize: 13, color: palette.brandRoyal, fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoTile(AppPalette palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(Map<String, dynamic> a) async {
    final palette = AppPalette.of(context);
    final hasContract = a['hasContract'] == true;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4)),
          ],
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
                    color: palette.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: palette.brandRoyal.withOpacity(0.12),
                    child: Text(
                      (a['name']?.toString() ?? 'Ş').isNotEmpty ? a['name'].toString()[0] : 'Ş',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['name'] ?? 'Şagird', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        Text('${a['className'] ?? '—'} • FİN: ${a['fin'] ?? '—'}',
                            style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _actionTile(ctx, 'Haqqında', Icons.person_search_rounded, palette.brandRoyal, () {
                    Navigator.pop(ctx);
                    _showDetail(a);
                  }),
                  _actionTile(ctx, 'İmtahan: ${_stageLabel('exam', a['examStatus'])}', Icons.school_rounded, _stageColor(a['examStatus']), () {
                    Navigator.pop(ctx);
                    _updateStage(a, 'exam');
                  }),
                  _actionTile(ctx, 'Psixoloq: ${_stageLabel('psychology', a['psychologyStatus'])}', Icons.psychology_rounded, _stageColor(a['psychologyStatus']), () {
                    Navigator.pop(ctx);
                    _updateStage(a, 'psychology');
                  }),
                  _actionTile(ctx, 'Tibb: ${_stageLabel('medical', a['medicalStatus'])}', Icons.medical_services_rounded, _stageColor(a['medicalStatus']), () {
                    Navigator.pop(ctx);
                    _updateStage(a, 'medical');
                  }),
                  _actionTile(ctx, hasContract ? 'Müqaviləyə bax' : 'Müqavilə yarat', Icons.receipt_long_rounded, AppColors.emerald, () {
                    Navigator.pop(ctx);
                    _createContract(a);
                  }),
                  _actionTile(ctx, 'İmtina et', Icons.block_rounded, AppColors.danger, () {
                    Navigator.pop(ctx);
                    _reject(a);
                  }),
                  _actionTile(ctx, 'Düzəliş et', Icons.edit_rounded, palette.brandAzure, () {
                    Navigator.pop(ctx);
                    _editStudent(a);
                  }),
                  _actionTile(ctx, 'Sil', Icons.delete_rounded, AppColors.danger, () {
                    Navigator.pop(ctx);
                    _deleteStudent(a);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext ctx, String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: (MediaQuery.of(ctx).size.width - 52) / 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStage(Map<String, dynamic> a, String stage) async {
    final palette = AppPalette.of(context);
    String status = 'passed';
    final scoreCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(ctx).bottom + 22),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                stage == 'exam' ? 'İmtahan nəticəsi' : stage == 'medical' ? 'Tibbi baxış' : 'Psixoloq rəyi',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(a['name'] ?? '', style: TextStyle(fontSize: 12.5, color: palette.textSecondary)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Nəticə', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Gözləyir')),
                  DropdownMenuItem(value: 'passed', child: Text('Keçdi (Müsbət)')),
                  DropdownMenuItem(value: 'failed', child: Text('Keçmədi (Uyğunsuz)')),
                  DropdownMenuItem(value: 'exempt', child: Text('Azad')),
                ],
                onChanged: (v) => setSheet(() => status = v ?? 'passed'),
              ),
              if (stage == 'exam') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: scoreCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'İmtahan balı', border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Qeyd / Rəy', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.brandNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx, {
                  'stage': stage,
                  'status': status,
                  '${stage}_status': status,
                  'exam_score': stage == 'exam' ? double.tryParse(scoreCtrl.text.replaceAll(',', '.')) : null,
                  'score': scoreCtrl.text.trim().isEmpty ? null : double.tryParse(scoreCtrl.text.replaceAll(',', '.')),
                  '${stage}_date': DateTime.now().toIso8601String().substring(0, 10),
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  '${stage}_note': noteCtrl.text.trim(),
                  'note': noteCtrl.text.trim(),
                }),
                child: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;
    result.removeWhere((k, v) => v == null);
    final ok = await SchoolApiService.instance.updateAdmissionStage(a['id'].toString(), result);
    _snack(ok ? 'Nəticə yeniləndi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _loadData();
  }

  Future<void> _reject(Map<String, dynamic> a) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Qəbuldan imtina', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'İmtina səbəbini qeyd edin...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ləğv et')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('İmtina et', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await SchoolApiService.instance.rejectAdmission(a['id'].toString(), reason);
    _snack(ok ? 'Qəbuldan imtina edildi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _loadData();
  }

  Future<void> _deleteStudent(Map<String, dynamic> a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Şagirdi sil', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('${a['name']} adlı şagird silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SchoolApiService.instance.deleteAdmission(a['id'].toString());
    _snack(ok ? 'Şagird silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _loadData();
  }

  Future<void> _createContract(Map<String, dynamic> a) async {
    final result = await Navigator.push(
      context,
      appRoute(builder: (_) => CreateContractScreen(studentId: a['id'].toString())),
    );
    if (result == true) _loadData();
  }

  Future<void> _editStudent(Map<String, dynamic> a) async {
    await Navigator.push(
      context,
      appRoute(builder: (_) => StudentRegistrationScreen(studentId: a['id'].toString())),
    );
    _loadData();
  }

  Future<void> _openAddForm() async {
    await Navigator.push(
      context,
      appRoute(builder: (_) => const StudentRegistrationScreen()),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final items = _filtered;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Şagird qəbulu', style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData, tooltip: 'Yenilə'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.brandRoyal,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _openAddForm,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          // Header Tab Filters Bar (Clean solid styling with NO invisible white bugs)
          Container(
            color: palette.brandNavy,
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (key, label, tabColor) = _tabs[i];
                  final isSelected = _activeTab == key;
                  final count = _count(key);
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (_activeTab != key) {
                        setState(() => _activeTab = key);
                        _loadData();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? tabColor : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white.withOpacity(0.3) : const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Search & Summary Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Şagird adı, FİN və ya telefon ilə axtar...',
                    hintStyle: TextStyle(fontSize: 13, color: palette.textTertiary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: palette.surface1,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.borderHairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.borderHairline),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: palette.brandRoyal,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Müraciətlər Siyahısı',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} şagird müraciəti göstərilir',
                      style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Student Applications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.folder_open_rounded, size: 54, color: palette.textTertiary),
                                    const SizedBox(height: 12),
                                    Text('Bu kateqoriyada müraciət tapılmadı',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 80),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final a = items[i];
                              return _buildStudentCard(a, palette);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> a, AppPalette palette) {
    final hasContract = a['hasContract'] == true;
    final parent = (a['parents'] as List?)?.firstOrNull as Map?;
    final studentName = a['name']?.toString() ?? 'Şagird';
    final statusText = hasContract ? 'Müqaviləli' : (a['status']?.toString() ?? 'Gözləyir');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, FIN, and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: palette.brandRoyal.withOpacity(0.12),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'Ş',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          a['code'] ?? '',
                          style: TextStyle(fontSize: 11.5, color: palette.textTertiary, fontWeight: FontWeight.w600),
                        ),
                        if ((a['code'] ?? '').toString().isNotEmpty && (a['fin'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: palette.textTertiary)),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'FİN: ${a['fin'] ?? '—'}',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: statusText,
                color: hasContract ? AppColors.emerald : palette.brandRoyal,
                fontSize: 10,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Academic Info & Parent details container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, size: 14, color: palette.brandAzure),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${a['className'] ?? 'Sinif təyin edilməyib'} (${a['sector'] ?? 'Azərbaycan'})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.calendar_month_rounded, size: 13, color: palette.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      a['registrationDate'] ?? '—',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (parent != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.family_restroom_rounded, size: 14, color: palette.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${parent['name'] ?? ''} • ${parent['phone'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3 Stages Badges: Exam, Psychology, Medical
          Row(
            children: [
              _stageCard('İmtahan', a['examStatus'], Icons.school_rounded),
              const SizedBox(width: 6),
              _stageCard('Psixoloq', a['psychologyStatus'], Icons.psychology_rounded),
              const SizedBox(width: 6),
              _stageCard('Tibb', a['medicalStatus'], Icons.medical_services_rounded),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons: Contract + Details
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: hasContract ? palette.brandNavy : palette.brandRoyal,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _createContract(a),
                  icon: Icon(
                    hasContract ? Icons.receipt_long_rounded : Icons.post_add_rounded,
                    size: 17,
                  ),
                  label: Text(
                    hasContract ? 'Müqaviləyə bax' : 'Müqavilə yarat',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.brandNavy,
                    side: BorderSide(color: palette.borderHairline),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showActions(a),
                  icon: const Icon(Icons.more_horiz_rounded, size: 17),
                  label: const Text('Ətraflı', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageCard(String title, dynamic status, IconData icon) {
    final color = _stageColor(status);
    final label = _stageLabel('', status);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
