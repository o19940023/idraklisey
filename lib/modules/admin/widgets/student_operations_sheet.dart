import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/app_state.dart';
import '../../teacher/screens/teacher_student_detail_screen.dart';
import '../screens/student_registration_screen.dart';
import '../../finance/widgets/student_contracts_section.dart';

class StudentOperationsSheet {
  static void show(
    BuildContext context,
    StudentProfile student, {
    required VoidCallback onRefresh,
  }) {
    final palette = AppPalette.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OperationsMenu(
        student: student,
        palette: palette,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _OperationsMenu extends StatelessWidget {
  final StudentProfile student;
  final AppPalette palette;
  final VoidCallback onRefresh;

  const _OperationsMenu({
    required this.student,
    required this.palette,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.borderHairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ModernAvatar(
                    imageUrl: student.photoUrl,
                    name: student.fullName,
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${student.className.isNotEmpty ? student.className : "Sinifsiz"} • ${student.studentNumber}${(student.finCode ?? "").isNotEmpty ? " • FİN: ${student.finCode}" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: palette.borderHairline),
            Builder(
              builder: (ctx) {
                final appState = ctx.read<AppState>();
                final isSuper = appState.isPrimaryAdmin;
                final canLoginDetails = appState.canViewPassword('student');
                final canManageRelations = isSuper || appState.hasPermission('gopanel.academic.students.manage_relations');
                final canCancellation = isSuper || appState.hasPermission('gopanel.academic.students.delete');
                final canNotes = isSuper || appState.hasPermission('gopanel.academic.students.more_info');
                final canGraduation = isSuper || appState.hasPermission('gopanel.academic.graduations.create') || appState.hasPermission('gopanel.academic.graduations.view');
                final canEdit = isSuper || appState.hasPermission('gopanel.academic.students.update');
                final canContracts = isSuper || appState.hasPermission('gopanel.finance.student_contracts.view') || appState.hasPermission('gopanel.academic.students.more_info');
                final canProfile = isSuper || (appState.currentUser?.roleNames.any((r) => r.contains('Direktor') || r.contains('Valideynlərlə iş')) ?? false);
                final canDelete = isSuper || appState.hasPermission('gopanel.academic.students.delete');

                return Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    children: [
                      if (canLoginDetails)
                        _actionTile(
                          icon: Icons.key_rounded,
                          color: const Color(0xFFF59E0B),
                          title: 'Giriş Məlumatları',
                          subtitle: 'Şifrə, FİN və e-poçt idarəsi',
                          onTap: () {
                            Navigator.pop(context);
                            _showLoginDetailsDialog(context, student);
                          },
                        ),
                      if (canManageRelations)
                        _actionTile(
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF3B82F6),
                          title: 'Qohumluq Əlaqələri',
                          subtitle: 'Valideyn və böyük qohumları təyin et',
                          onTap: () {
                            Navigator.pop(context);
                            _showRelationsDialog(context, student, onRefresh);
                          },
                        ),
                      if (canCancellation)
                        _actionTile(
                          icon: Icons.person_off_rounded,
                          color: const Color(0xFFEF4444),
                          title: 'Məktəbdən Çıxarma (Xitam)',
                          subtitle: 'Borc yoxlanışı və xitam aktı tərtibatı',
                          onTap: () {
                            Navigator.pop(context);
                            _showCancellationDialog(context, student, onRefresh);
                          },
                        ),
                      if (canNotes)
                        _actionTile(
                          icon: Icons.note_alt_rounded,
                          color: const Color(0xFF8B5CF6),
                          title: 'Şagird Qeydləri',
                          subtitle: 'Daxili qeydlər və xarakteristika',
                          onTap: () {
                            Navigator.pop(context);
                            _showNotesSheet(context, student);
                          },
                        ),
                      if (canGraduation)
                        _actionTile(
                          icon: Icons.school_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Məzuniyyət',
                          subtitle: 'Ali məktəb qəbulu, ixtisas və dövlət sifarişi',
                          onTap: () {
                            Navigator.pop(context);
                            _showGraduationDialog(context, student);
                          },
                        ),
                      if (canEdit)
                        _actionTile(
                          icon: Icons.edit_note_rounded,
                          color: const Color(0xFF0284C7),
                          title: 'Redaktə et',
                          subtitle: 'Şagird qeydiyyat anketini tam redaktə et',
                          onTap: () async {
                            Navigator.pop(context);
                            await Navigator.push(
                              context,
                              appRoute(
                                builder: (_) => StudentRegistrationScreen(studentId: student.id),
                              ),
                            );
                            onRefresh();
                          },
                        ),
                      if (canContracts)
                        _actionTile(
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF0D9488),
                          title: 'Müqavilələr və Maliyyə',
                          subtitle: 'Müqavilə bağla, redaktə, ödəniş və qrafik',
                          onTap: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => Container(
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: palette.surface1,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                  border: Border.all(color: palette.borderHairline),
                                ),
                                child: SafeArea(
                                  child: SingleChildScrollView(
                                    child: StudentContractsSection(
                                      studentId: int.tryParse(student.id),
                                      studentNumber: student.studentNumber,
                                      studentName: student.fullName,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      if (canProfile)
                        _actionTile(
                          icon: Icons.account_circle_rounded,
                          color: const Color(0xFF6366F1),
                          title: 'Ətraflı Profil',
                          subtitle: 'Akademik jurnal, davamiyyət və fəaliyyət',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              appRoute(
                                builder: (_) => TeacherStudentDetailScreen(
                                  student: student,
                                  adminMode: true,
                                ),
                              ),
                            );
                          },
                        ),
                      if (canDelete)
                        _actionTile(
                          icon: Icons.delete_forever_rounded,
                          color: const Color(0xFFDC2626),
                          title: 'Sil',
                          subtitle: 'Şagirdi sistemdən xaric et',
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete(context, student, onRefresh);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  static void _showLoginDetailsDialog(BuildContext context, StudentProfile student) {
    showDialog(
      context: context,
      builder: (ctx) => _LoginDetailsDialog(student: student),
    );
  }

  static void _showRelationsDialog(
    BuildContext context,
    StudentProfile student,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _RelationsDialog(student: student, onSaved: onRefresh),
    );
  }

  static void _showCancellationDialog(
    BuildContext context,
    StudentProfile student,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _CancellationDialog(student: student, onSaved: onRefresh),
    );
  }

  static void _showNotesSheet(BuildContext context, StudentProfile student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotesModalSheet(student: student),
    );
  }

  static void _showGraduationDialog(BuildContext context, StudentProfile student) {
    showDialog(
      context: context,
      builder: (ctx) => _GraduationDialog(student: student),
    );
  }

  static void _confirmDelete(
    BuildContext context,
    StudentProfile student,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Şagirdi Sil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text(
          '${student.fullName} adlı şagirdi sistemdən silmək istədiyinizə əminsiniz?\nBu əməliyyat geri qaytarılmır.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İmtina'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await SchoolApiService.instance.deleteStudent(student.id);
              if (ok) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Şagird uğurla silindi!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.read<AppState>().syncStudentsFromApi();
                  onRefresh();
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silinmə zamanı xəta baş verdi.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// 1. LOGIN DETAILS DIALOG
// ====================================================================
class _LoginDetailsDialog extends StatefulWidget {
  final StudentProfile student;
  const _LoginDetailsDialog({required this.student});

  @override
  State<_LoginDetailsDialog> createState() => _LoginDetailsDialogState();
}

class _LoginDetailsDialogState extends State<_LoginDetailsDialog> {
  bool _loading = true;
  bool _saving = false;
  final _emailCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _lastPassword;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SchoolApiService.instance.fetchStudentLoginDetails(widget.student.id);
    if (mounted) {
      if (data != null) {
        _emailCtrl.text = data['email']?.toString() ?? widget.student.email ?? '';
        _finCtrl.text = data['fin_code']?.toString() ?? widget.student.finCode ?? '';
        _lastPassword = data['last_password']?.toString() ?? '123456';
      } else {
        _emailCtrl.text = widget.student.email ?? '';
        _finCtrl.text = widget.student.finCode ?? '';
        _lastPassword = '123456';
      }
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _finCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.key_rounded, color: Color(0xFFF59E0B), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giriş Məlumatları',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              widget.student.fullName,
                              style: TextStyle(fontSize: 12, color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _finCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 7,
                    decoration: _inputDeco('FİN Kod', icon: Icons.badge_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDeco('E-poçt ünvanı', icon: Icons.alternate_email_rounded),
                  ),
                  const SizedBox(height: 14),
                  if (_lastPassword != null && _lastPassword!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_open_rounded, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cari Şifrə (Sistemdəki)',
                                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _lastPassword!,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2563EB)),
                            tooltip: 'Şifrəni kopyala',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _lastPassword!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Şifrə kopyalandı!'), duration: Duration(seconds: 2)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: _inputDeco(
                      'Yeni şifrə təyin et (istəyə bağlı)',
                      icon: Icons.lock_outline_rounded,
                      hint: 'Dəyişmək istəmirsinizsə boş buraxın',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Bağla'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: palette.brandRoyal),
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                final payload = {
                                  'fin_code': _finCtrl.text.trim().toUpperCase(),
                                  'email': _emailCtrl.text.trim(),
                                  if (_passCtrl.text.trim().isNotEmpty) 'password': _passCtrl.text.trim(),
                                };
                                final ok = await SchoolApiService.instance.saveStudentLoginDetails(
                                  widget.student.id,
                                  payload,
                                );
                                if (!context.mounted) return;
                                setState(() => _saving = false);
                                if (ok) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Giriş məlumatları uğurla yeniləndi!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Yadda saxlanarkən xəta baş verdi.'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              },
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Yadda saxla'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ====================================================================
// 2. RELATIONS DIALOG (Valideyn və Qohumlar)
// ====================================================================
class _RelationsDialog extends StatefulWidget {
  final StudentProfile student;
  final VoidCallback onSaved;
  const _RelationsDialog({required this.student, required this.onSaved});

  @override
  State<_RelationsDialog> createState() => _RelationsDialogState();
}

class _RelationsDialogState extends State<_RelationsDialog> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _assigned = [];
  List<Map<String, dynamic>> _allParents = [];

  static const _relationTypes = [
    'Ata',
    'Ana',
    'Baba',
    'Nənə',
    'Əmi',
    'Dayı',
    'Xala',
    'Bibi',
    'Qəyyum',
    'Digər',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await SchoolApiService.instance.fetchStudentRelations(widget.student.id);
    if (mounted) {
      if (res != null) {
        _assigned = List<Map<String, dynamic>>.from(res['assigned'] ?? []);
        final rawParents = List<Map<String, dynamic>>.from(res['all_parents'] ?? []);
        final Set<String> seenIds = {};
        _allParents = [];
        for (final p in rawParents) {
          final pid = p['id']?.toString();
          if (pid != null && seenIds.add(pid)) {
            _allParents.add({
              'id': pid,
              'name': (p['name'] ?? 'Valideyn #18464').toString(),
            });
          }
        }
        for (final a in _assigned) {
          final aid = a['id']?.toString();
          if (aid != null && seenIds.add(aid)) {
            _allParents.insert(0, {
              'id': aid,
              'name': a['name'] != null ? ''.trim() : 'Valideyn #',
            });
          }
        }
      }
      setState(() => _loading = false);
    }
  }

  void _addRelationRow() {
    if (_allParents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sistemdə əlaqələndiriləcək başqa valideyn tapılmadı.')),
      );
      return;
    }
    setState(() {
      _assigned.add({
        'id': _allParents.first['id'],
        'name': _allParents.first['name'],
        'relation_type': 'Ata',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Color(0xFF3B82F6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Qohumluq Əlaqələri',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              widget.student.fullName,
                              style: TextStyle(fontSize: 12, color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Şagirdə bağlı olan valideynləri və qohumluq dərəcəsini seçin:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _assigned.isEmpty
                        ? Center(
                            child: Text(
                              'Hələ heç bir valideyn əlaqələndirilməyib.',
                              style: TextStyle(color: palette.textMuted, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _assigned.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final item = _assigned[idx];
                              final currentParentId = item['id']?.toString();
                              final currentType = item['relation_type']?.toString() ?? 'Digər';

                              final Map<String, String> dropdownItemsMap = {};
                              for (final p in _allParents) {
                                final pid = p['id']?.toString();
                                if (pid != null && pid.isNotEmpty) {
                                  dropdownItemsMap.putIfAbsent(pid, () => (p['name'] ?? pid).toString());
                                }
                              }
                              if (currentParentId != null && !dropdownItemsMap.containsKey(currentParentId)) {
                                dropdownItemsMap[currentParentId] = item['name']?.toString() ?? 'Valideyn #';
                              }

                              final String? selectedParentValue = (currentParentId != null && dropdownItemsMap.containsKey(currentParentId))
                                  ? currentParentId
                                  : null;

                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: palette.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: palette.borderHairline),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: selectedParentValue,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        items: dropdownItemsMap.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12.5),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              item['id'] = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _relationTypes.contains(currentType) ? currentType : 'Digər',
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _relationTypes.map((t) {
                                          return DropdownMenuItem<String>(
                                            value: t,
                                            child: Text(t, style: const TextStyle(fontSize: 12.5)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              item['relation_type'] = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() {
                                          _assigned.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _addRelationRow,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Yeni valideyn / qohum əlavə et'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Bağla'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: palette.brandRoyal),
                        onPressed: _saving
                            ? null
                            : () async {
                                setState(() => _saving = true);
                                final payload = {
                                  'parents': _assigned.map((a) {
                                    return {
                                      'parent_id': a['id'],
                                      'relation_type': a['relation_type'],
                                    };
                                  }).toList(),
                                };
                                final ok = await SchoolApiService.instance.saveStudentRelations(
                                  widget.student.id,
                                  payload,
                                );
                                if (!context.mounted) return;
                                setState(() => _saving = false);
                                if (ok) {
                                  Navigator.pop(context);
                                  widget.onSaved();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Qohumluq əlaqələri uğurla yeniləndi!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Xəta baş verdi.'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              },
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Yadda saxla'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ====================================================================
// 3. CANCELLATION DIALOG (Məktəbdən Çıxarma)
// ====================================================================
class _CancellationDialog extends StatefulWidget {
  final StudentProfile student;
  final VoidCallback onSaved;
  const _CancellationDialog({required this.student, required this.onSaved});

  @override
  State<_CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<_CancellationDialog> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _data;

  final _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _reasonCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await SchoolApiService.instance.fetchStudentCancellation(widget.student.id);
    if (mounted) {
      setState(() {
        _data = res;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _reasonCtrl.dispose();
    _schoolCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final hasBookDebt = _data?['has_book_debt'] == true;
    final bookLoans = List<Map<String, dynamic>>.from(_data?['book_loans'] ?? []);
    final hasFinanceDebt = _data?['has_finance_debt'] == true;
    final totalDebt = _data?['total_finance_debt'] ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_off_rounded, color: AppColors.danger, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Məktəbdən Çıxarma (Xitam)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                widget.student.fullName,
                                style: TextStyle(fontSize: 12, color: palette.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasBookDebt ? AppColors.danger.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasBookDebt ? AppColors.danger.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasBookDebt ? Icons.warning_rounded : Icons.check_circle_rounded,
                                      size: 16,
                                      color: hasBookDebt ? AppColors.danger : AppColors.success,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Kitabxana', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasBookDebt ? 'Borc var (${bookLoans.length} kitab)' : 'Borc yoxdur',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasBookDebt ? AppColors.danger : AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: hasFinanceDebt ? AppColors.danger.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasFinanceDebt ? AppColors.danger.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasFinanceDebt ? Icons.warning_rounded : Icons.check_circle_rounded,
                                      size: 16,
                                      color: hasFinanceDebt ? AppColors.danger : AppColors.success,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Maliyyə', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasFinanceDebt ? 'Borc: $totalDebt AZN' : 'Borc yoxdur',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasFinanceDebt ? AppColors.danger : AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Xitam tarixi *',
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Xitam səbəbi *',
                        hintText: 'Məs: Yaşayış yerinin dəyişdirilməsi ilə əlaqədar...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _schoolCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Getdiyi Məktəb / Qeyd',
                        hintText: 'Məs: 132-134 nömrəli təhsil kompleksi',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Əlavə qeyd',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İmtina'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (_reasonCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Zəhmət olmasa xitam səbəbini qeyd edin!')),
                                    );
                                    return;
                                  }
                                  setState(() => _saving = true);
                                  final payload = {
                                    'cancellation_date': _dateCtrl.text.trim(),
                                    'reason': _reasonCtrl.text.trim(),
                                    'to_school_name': _schoolCtrl.text.trim(),
                                    'note': _noteCtrl.text.trim(),
                                  };
                                  final ok = await SchoolApiService.instance.storeStudentCancellation(
                                    widget.student.id,
                                    payload,
                                  );
                                  if (!context.mounted) return;
                                  setState(() => _saving = false);
                                  if (ok) {
                                    Navigator.pop(context);
                                    widget.onSaved();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Xitam sorğusu uğurla icra olundu!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Xəta baş verdi.'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                },
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Xitamı təsdiq et'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ====================================================================
// 4. NOTES MODAL SHEET (Şagird Qeydləri)
// ====================================================================
class _NotesModalSheet extends StatefulWidget {
  final StudentProfile student;
  const _NotesModalSheet({required this.student});

  @override
  State<_NotesModalSheet> createState() => _NotesModalSheetState();
}

class _NotesModalSheetState extends State<_NotesModalSheet> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _notes = [];
  final _newNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SchoolApiService.instance.fetchStudentNotes(widget.student.id);
    if (mounted) {
      setState(() {
        _notes = list;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _newNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: palette.borderHairline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.note_alt_rounded, color: Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Şagird Qeydləri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(widget.student.fullName, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _newNoteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Yeni daxili qeyd yazın...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        final text = _newNoteCtrl.text.trim();
                        if (text.isEmpty) return;
                        setState(() => _saving = true);
                        final ok = await SchoolApiService.instance.storeStudentNote(
                          widget.student.id,
                          {'note': text},
                        );
                        if (mounted) {
                          setState(() => _saving = false);
                          if (ok) {
                            _newNoteCtrl.clear();
                            _load();
                          }
                        }
                      },
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Əvvəlki Qeydlər:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Text('Hələ heç bir qeyd əlavə edilməyib.', style: TextStyle(color: palette.textMuted)),
                      )
                    : ListView.separated(
                        itemCount: _notes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final n = _notes[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.borderHairline),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['note']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${n['author'] ?? 'Admin'} • ${n['created_at'] ?? ''}',
                                        style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    final noteId = n['id']?.toString();
                                    if (noteId != null) {
                                      await SchoolApiService.instance.deleteStudentNote(noteId);
                                      _load();
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// 5. GRADUATION DIALOG (Məzuniyyət)
// ====================================================================
class _GraduationDialog extends StatefulWidget {
  final StudentProfile student;
  const _GraduationDialog({required this.student});

  @override
  State<_GraduationDialog> createState() => _GraduationDialogState();
}

class _GraduationDialogState extends State<_GraduationDialog> {
  bool _loading = true;
  bool _saving = false;
  String _educationType = 'higher';
  bool _isStateOrder = false;
  final _institutionCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _specialityCtrl = TextEditingController();
  final _admissionScoreCtrl = TextEditingController();
  final _stateExamScoreCtrl = TextEditingController();
  final _admissionExamScoreCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await SchoolApiService.instance.fetchStudentGraduation(widget.student.id);
    if (mounted) {
      if (res != null && res['graduation'] != null) {
        final g = Map<String, dynamic>.from(res['graduation']);
        _educationType = g['education_type']?.toString() ?? 'higher';
        _isStateOrder = g['is_state_order'] == 1 || g['is_state_order'] == true;
        _institutionCtrl.text = g['institution']?.toString() ?? '';
        _facultyCtrl.text = g['faculty']?.toString() ?? '';
        _specialityCtrl.text = g['speciality']?.toString() ?? '';
        _admissionScoreCtrl.text = g['admission_score']?.toString() ?? '';
        _stateExamScoreCtrl.text = g['state_exam_score']?.toString() ?? '';
        _admissionExamScoreCtrl.text = g['admission_exam_score']?.toString() ?? '';
        _notesCtrl.text = g['notes']?.toString() ?? '';
      }
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _facultyCtrl.dispose();
    _specialityCtrl.dispose();
    _admissionScoreCtrl.dispose();
    _stateExamScoreCtrl.dispose();
    _admissionExamScoreCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isNone = _educationType == 'none';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Məzuniyyət Məlumatları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                              Text(widget.student.fullName, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _educationType,
                      decoration: const InputDecoration(labelText: 'Təhsil Tipi *', border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'higher', child: Text('Yerli Ali Məktəb')),
                        DropdownMenuItem(value: 'college', child: Text('Orta İxtisas (Kollec)')),
                        DropdownMenuItem(value: 'abroad', child: Text('Beynəlxalq / Xarici')),
                        DropdownMenuItem(value: 'vocational', child: Text('Peşə Təhsili')),
                        DropdownMenuItem(value: 'none', child: Text('Qəbul Olmayıb / Digər')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _educationType = val);
                      },
                    ),
                    if (!isNone) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _institutionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Təhsil Müəssisəsi *',
                          hintText: 'Məs: BDU, ADA, Oksford və s.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _facultyCtrl,
                              decoration: const InputDecoration(labelText: 'Fakültə', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _specialityCtrl,
                              decoration: const InputDecoration(labelText: 'İxtisas', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _admissionScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qəbul Balı', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Dövlət Sifarişi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              value: _isStateOrder,
                              onChanged: (val) => setState(() => _isStateOrder = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _stateExamScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Dövlət İmtahan Balı', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _admissionExamScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qəbul İmtahan Balı', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Qeydlər', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bağla')),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          onPressed: _saving
                              ? null
                              : () async {
                                  setState(() => _saving = true);
                                  final payload = {
                                    'education_type': _educationType,
                                    'institution': _institutionCtrl.text.trim(),
                                    'faculty': _facultyCtrl.text.trim(),
                                    'speciality': _specialityCtrl.text.trim(),
                                    'admission_score': _admissionScoreCtrl.text.trim(),
                                    'state_exam_score': _stateExamScoreCtrl.text.trim(),
                                    'admission_exam_score': _admissionExamScoreCtrl.text.trim(),
                                    'is_state_order': _isStateOrder ? 1 : 0,
                                    'notes': _notesCtrl.text.trim(),
                                  };
                                  final ok = await SchoolApiService.instance.saveStudentGraduation(
                                    widget.student.id,
                                    payload,
                                  );
                                  if (!context.mounted) return;
                                  setState(() => _saving = false);
                                  if (ok) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Məzuniyyət məlumatları yadda saxlanıldı!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Xəta baş verdi.'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                },
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Yadda saxla'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
