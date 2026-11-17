import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/stat_card.dart';
import '../../journal/screens/api_journal_screen.dart';
import 'admin_timetable_management_screen.dart';

const List<String> _gradeSuffixOptions = [
  'a',
  'a1',
  'a2',
  'a3',
  'r',
  'r1',
  'r2',
  'r3',
  'e',
  'e1',
  'e2',
  'e3',
];

const List<Map<String, String>> _streamOptions = [
  {'value': 'general', 'label': 'Ümumi təhsil'},
  {'value': 'RIYAZIYYAT_IQTISADIYYAT_HUMANITAR', 'label': 'Riyaziyyat-İqtisadiyyat / Humanitar'},
  {'value': 'TEXNIKI_TEBIET', 'label': 'Texniki-Təbiət'},
];

const List<Color> _classColorPresets = [
  Color(0xFF1E3E62),
  Color(0xFF0284C7),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFF475569),
];

const List<Map<String, String>> _groupStreamOptions = [
  {'value': '', 'label': 'Ümumi / Standart qrup'},
  {'value': '1-4', 'label': '1-4 Qrupu (Riyaziyyat, Fizika, Kimya)'},
  {'value': '2-3', 'label': '2-3 Qrupu (Ədəbiyyat, Tarix, Coğrafiya)'},
];

String _groupStreamLabel(String value) {
  return _groupStreamOptions.firstWhere((o) => o['value'] == value, orElse: () => _groupStreamOptions.first)['label']!;
}

String _dateToYmd(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _displayDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final parts = raw.split('-');
  if (parts.length != 3) return raw;
  return '${parts[2]}.${parts[1]}.${parts[0]}';
}

String _teacherName(Map<String, dynamic> teacher) {
  return (teacher['fullName'] ?? teacher['name'] ?? teacher['get_name'] ?? 'Müəllim').toString();
}

String _roomLabel(Map<String, dynamic> room) {
  final number = room['number'] ?? room['room_number'];
  if (number != null && number.toString().isNotEmpty) return 'Otaq $number';
  return (room['name'] ?? 'Otaq').toString();
}

String _groupTitle(Map<String, dynamic> group) {
  final titles = group['titles'];
  if (titles is Map) {
    final az = (titles['az'] ?? '').toString();
    if (az.isNotEmpty) return az;
  }
  return (group['name'] ?? 'Qrup').toString();
}

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'maleCount': 0,
    'femaleCount': 0,
  };
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _teachers = [];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedAcademicYearId;
  String _selectedGradeLevel = 'all';
  String _selectedLanguage = 'all';

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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        SchoolApiService.instance.fetchClassesPayload(
          academicYearId: _selectedAcademicYearId,
          gradeLevel: _selectedGradeLevel == 'all' ? null : _selectedGradeLevel,
          gradeLanguage: _selectedLanguage == 'all' ? null : _selectedLanguage,
          studentSearch: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        ),
        SchoolApiService.instance.fetchRooms(),
        SchoolApiService.instance.fetchEmployees(),
      ]);

      final payload = results[0] as Map<String, dynamic>?;
      final rooms = results[1] as List<Map<String, dynamic>>;
      final teachers = results[2] as List<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        if (payload != null) {
          _classes = List<Map<String, dynamic>>.from(payload['data'] as List? ?? []);
          if (payload['stats'] is Map) {
            _stats = Map<String, dynamic>.from(payload['stats']);
          }
          if (payload['academicYears'] is List) {
            _academicYears = List<Map<String, dynamic>>.from(payload['academicYears']);
            if (_selectedAcademicYearId == null && _academicYears.isNotEmpty) {
              final current = _academicYears.firstWhere(
                (y) => y['is_current'] == true,
                orElse: () => _academicYears.first,
              );
              _selectedAcademicYearId = current['id']?.toString();
            }
          }
        }
        _rooms = rooms;
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
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

  List<Map<String, dynamic>> get _filteredClasses {
    final q = _searchController.text.trim().toLowerCase();
    return _classes.where((c) {
      if (_selectedAcademicYearId != null &&
          _selectedAcademicYearId!.isNotEmpty &&
          c['academicYearId'] != null &&
          c['academicYearId'].toString() != _selectedAcademicYearId) {
        return false;
      }
      if (_selectedGradeLevel != 'all' && c['gradeLevel']?.toString() != _selectedGradeLevel) {
        return false;
      }
      if (_selectedLanguage != 'all') {
        final lang = (c['gradeLanguage'] ?? '').toString().toLowerCase();
        if (_selectedLanguage == 'azerbaijan' && !lang.contains('azerbaijan') && !lang.contains('az')) return false;
        if (_selectedLanguage == 'russian' && !lang.contains('russian') && !lang.contains('ru')) return false;
        if (_selectedLanguage == 'english' && !lang.contains('english') && !lang.contains('en')) return false;
      }
      if (q.isEmpty) return true;
      final name = (c['className'] ?? '').toString().toLowerCase();
      final teacher = (c['classTeacher'] ?? '').toString().toLowerCase();
      final room = (c['roomName'] ?? '').toString().toLowerCase();
      return name.contains(q) || teacher.contains(q) || room.contains(q);
    }).toList();
  }

  Future<DateTime?> _pickDate(BuildContext ctx, {DateTime? initial}) async {
    return showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  // ===========================================================================
  // 1. SINİF YARAT / REDAKTƏ ET
  // ===========================================================================
  Future<void> _showClassForm([Map<String, dynamic>? item]) async {
    final isEdit = item != null;
    final palette = AppPalette.of(context);

    int gradeLevel = isEdit ? (item['gradeLevel'] as num?)?.toInt() ?? 1 : 1;
    final existingSuffix = (isEdit ? (item['gradeSuffix'] ?? 'a').toString() : 'a').toLowerCase();
    String suffix = _gradeSuffixOptions.contains(existingSuffix) ? existingSuffix : 'a';
    final nameCtrl = TextEditingController(text: isEdit ? (item['rawName'] ?? item['className'] ?? '').toString() : '');
    String language = isEdit ? (item['gradeLanguage'] ?? 'azerbaijan').toString() : 'azerbaijan';
    String streamType = isEdit ? (item['streamType'] ?? 'general').toString() : 'general';
    if (!_streamOptions.any((o) => o['value'] == streamType)) streamType = 'general';
    String queue = isEdit ? (item['queue'] ?? 'first_queue').toString() : 'first_queue';
    String? selectedYearId = isEdit ? item['academicYearId']?.toString() : _selectedAcademicYearId;
    String? selectedRoomId = isEdit ? item['roomId']?.toString() : null;
    final capacityCtrl = TextEditingController(text: isEdit ? (item['maxCapacity'] ?? 20).toString() : '20');
    String colorCode = isEdit ? (item['colorCode'] ?? '#1E3E62').toString() : '#1E3E62';
    bool finalGradingLocked = isEdit ? (item['finalGradingLocked'] ?? false) : false;
    bool isActive = isEdit ? (item['isActive'] ?? true) : true;

    final initialTeachers = isEdit && item['teacherIds'] is List
        ? (item['teacherIds'] as List).map((e) => e.toString()).toSet()
        : <String>{};
    final selectedTeacherIds = <String>{...initialTeachers};

    Set<String> conflictingRooms = {};
    Map<String, dynamic> roomHints = {};

    Future<void> refreshRoomHints(String? yearId) async {
      final payload = await SchoolApiService.instance.fetchRoomAssignments(
        academicYearId: yearId,
        classId: isEdit ? item['id'].toString() : null,
      );
      conflictingRooms = (payload['assigned'] as Map?)?.keys.map((e) => e.toString()).toSet() ?? {};
      roomHints = Map<String, dynamic>.from(payload['assigned'] as Map? ?? {});
    }

    await refreshRoomHints(selectedYearId);

    if (!mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setM) {
          void regenerateName() {
            final base = '$gradeLevel${suffix.toUpperCase()}';
            nameCtrl.text = base;
          }

          Future<void> pickTeachers() async {
            final result = await showDialog<Set<String>>(
              context: sheetCtx,
              builder: (dlgCtx) => _MultiSelectDialog(
                title: 'Sinif rəhbərlərini seçin',
                options: _teachers
                    .map((t) => _MultiOption(
                          value: t['id'].toString(),
                          label: _teacherName(t),
                        ))
                    .toList(),
                initialSelected: selectedTeacherIds,
              ),
            );
            if (result != null) {
              setM(() {
                selectedTeacherIds
                  ..clear()
                  ..addAll(result);
              });
            }
          }

          return Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.92,
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(sheetCtx).bottom + 20),
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
                    _iconBadge(Icons.school_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Sinif Redaktəsi' : 'Yeni Sinif Yarat',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: gradeLevel,
                              decoration: _inputDeco('Sinif dərəcəsi *'),
                              items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text('$i-ci sinif'))),
                              onChanged: (v) {
                                if (v == null) return;
                                setM(() {
                                  gradeLevel = v;
                                  regenerateName();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: suffix,
                              decoration: _inputDeco('Şəkilçi *'),
                              items: _gradeSuffixOptions
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setM(() {
                                  suffix = v;
                                  regenerateName();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: _inputDeco('Sinif adı *').copyWith(
                          helperText: 'Məsələn: 1A, 4R1, 10E',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedYearId,
                        decoration: _inputDeco('Tədris ili *'),
                        items: _academicYears.map((y) {
                          return DropdownMenuItem(value: y['id'].toString(), child: Text(y['title'] ?? 'Tədris ili'));
                        }).toList(),
                        onChanged: (v) async {
                          setM(() => selectedYearId = v);
                          await refreshRoomHints(v);
                          if (sheetCtx.mounted) setM(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: language,
                        decoration: _inputDeco('Bölmə / Dil *'),
                        items: const [
                          DropdownMenuItem(value: 'azerbaijan', child: Text('Azərbaycan bölməsi')),
                          DropdownMenuItem(value: 'russian', child: Text('Rus bölməsi')),
                          DropdownMenuItem(value: 'english', child: Text('İngilis bölməsi')),
                        ],
                        onChanged: (v) => setM(() => language = v ?? 'azerbaijan'),
                      ),
                      const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: streamType,
                      decoration: _inputDeco('Təmayül'),
                      items: _groupStreamOptions
                          .map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!)))
                          .toList(),
                        onChanged: (v) => setM(() => streamType = v ?? 'general'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: selectedRoomId,
                        decoration: _inputDeco('Təyin olunacaq otaq'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Otaq təyin edilməyib')),
                          ..._rooms.map((r) {
                            final id = r['id'].toString();
                            final conflict = conflictingRooms.contains(id);
                            return DropdownMenuItem(
                              value: id,
                              child: Text(
                                conflict ? '${_roomLabel(r)} • tutulub' : _roomLabel(r),
                                style: conflict
                                    ? const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)
                                    : null,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setM(() => selectedRoomId = v),
                      ),
                      if (selectedRoomId != null && conflictingRooms.contains(selectedRoomId))
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            'Bu otaq "${roomHints[selectedRoomId]?['class_name'] ?? 'başqa sinif'}" sinfinə təyin edilib. Zəhmət olmasa konflikti nəzərə alın.',
                            style: const TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: capacityCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDeco('Maks. tutum'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: queue,
                              decoration: _inputDeco('Növbə'),
                              items: const [
                                DropdownMenuItem(value: 'first_queue', child: Text('1-ci növbə')),
                                DropdownMenuItem(value: 'second_queue', child: Text('2-ci növbə')),
                              ],
                              onChanged: (v) => setM(() => queue = v ?? 'first_queue'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Sinif rəngi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _classColorPresets.map((color) {
                          final hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                          final selected = colorCode.toUpperCase() == hex;
                          return InkWell(
                            onTap: () => setM(() => colorCode = hex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? Colors.black87 : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedTeacherIds.isEmpty
                                    ? 'Sinif rəhbəri seçilməyib'
                                    : 'Sinif rəhbərləri: ${selectedTeacherIds.length}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: pickTeachers,
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                              label: const Text('Seç'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: finalGradingLocked,
                        title: const Text('Yekun qiymətləndirmə kilidli', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        subtitle: const Text('Kilid aktiv olduqda yekun qiymətlər dəyişdirilə bilməz', style: TextStyle(fontSize: 11.5)),
                        onChanged: (v) => setM(() => finalGradingLocked = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        title: const Text('Sinif aktivdir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        subtitle: const Text('Deaktiv edildikdə jurnallarda və cədvəldə gizlədilir', style: TextStyle(fontSize: 11.5)),
                        onChanged: (v) => setM(() => isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3E62),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    isEdit ? 'Dəyişiklikləri Yadda Saxla' : 'Sinif Yarat',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => Navigator.pop(sheetCtx, true),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (saved != true) return;
    if (nameCtrl.text.trim().isEmpty) {
      _snack('Sinif adı tələb olunur', ok: false);
      return;
    }

    final data = <String, dynamic>{
      'className': nameCtrl.text.trim(),
      'gradeLevel': gradeLevel,
      'gradeSuffix': suffix,
      'gradeLanguage': language,
      'streamType': streamType,
      'queue': queue,
      'academicYearId': selectedYearId,
      'roomId': selectedRoomId,
      'maxCapacity': int.tryParse(capacityCtrl.text.trim()) ?? 20,
      'colorCode': colorCode,
      'finalGradingLocked': finalGradingLocked,
      'isActive': isActive,
      'teacherIds': selectedTeacherIds.toList(),
    };

    final ok = await SchoolApiService.instance.saveClass(data, id: isEdit ? item['id'].toString() : null);
    _snack(ok ? (isEdit ? 'Sinif yeniləndi' : 'Sinif yaradıldı') : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  // ===========================================================================
  // 2. SİNFİN İDARƏETMƏ PANELİ
  // ===========================================================================
  Future<void> _openClassManageSheet(Map<String, dynamic> classItem) async {
    final session = context.read<SessionController>();
    final isSuper = session.profile?.isSuper == true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ClassManageSheet(
        classItem: classItem,
        classes: _classes,
        teachers: _teachers,
        isSuper: isSuper,
        canManage: isSuper || session.can('gopanel.academic.teachers.classes.manage'),
        canAssignHomeroom: isSuper || session.can('gopanel.academic.classes.assign_homeroom'),
        canAssignSubjects: isSuper || session.can('gopanel.academic.teachers.assign_subjects'),
        canManageStudents: isSuper || session.can('gopanel.academic.teachers.classes.manage'),
        canManageGroups: isSuper || session.can('gopanel.academic.teachers.classes.manage'),
        canManageCurriculum: isSuper ||
            session.can('gopanel.academic.ejournal.curriculums.manage') ||
            session.can('gopanel.academic.ejournal.curriculums.view'),
        onSnack: _snack,
        onChanged: _load,
      ),
    );
  }

  // ===========================================================================
  // 3. FORS-MAJOR ƏMƏLİYYATLARI
  // ===========================================================================
  Future<void> _deleteClass(Map<String, dynamic> classItem) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sinifi sil'),
        content: Text('${classItem['className']} adlı sinif silinsin?'),
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
    final ok = await SchoolApiService.instance.deleteClass(classItem['id'].toString());
    _snack(ok ? 'Sinif silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _cancelClassSubject(Map<String, dynamic> classItem) async {
    final classId = classItem['id'].toString();
    final data = await SchoolApiService.instance.fetchClassManageDetails(classId);
    if (!mounted) return;
    if (data == null) {
      _snack('Sinif məlumatı yüklənmədi', ok: false);
      return;
    }
    final curriculums = List<Map<String, dynamic>>.from(data['curriculums'] as List? ?? []);
    if (curriculums.isEmpty) {
      _snack('Bu sinifdə kurikulum fənni yoxdur', ok: false);
      return;
    }

    String? subjectId = curriculums.first['subjectId']?.toString();
    DateTime cancelDate = DateTime.now();

    final done = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          return AlertDialog(
            title: const Text('Fənni ləğv et'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: subjectId,
                  decoration: _inputDeco('Fənn seçin *'),
                  items: curriculums
                      .map((c) => DropdownMenuItem(
                            value: c['subjectId'].toString(),
                            child: Text((c['subjectName'] ?? 'Fənn').toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setD(() => subjectId = v),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await _pickDate(dlgCtx, initial: cancelDate);
                    if (picked != null) setD(() => cancelDate = picked);
                  },
                  child: InputDecorator(
                    decoration: _inputDeco('Ləğv tarixi *'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_displayDate(_dateToYmd(cancelDate))),
                        const Icon(Icons.calendar_month_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu tarixdən sonrakı dərslər silinəcək və fənn təyinatı ləğv olunacaq.',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Geri')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: subjectId == null ? null : () => Navigator.pop(dlgCtx, true),
                child: const Text('Ləğv et'),
              ),
            ],
          );
        },
      ),
    );

    if (done == true && subjectId != null) {
      final ok = await SchoolApiService.instance.cancelClassSubject(
        classId,
        subjectId: subjectId!,
        cancelDate: _dateToYmd(cancelDate),
      );
      _snack(ok ? 'Fənn ləğv edildi' : 'Əməliyyat alınmadı', ok: ok);
      if (ok) _load();
    }
  }

  Future<void> _dissolveClass(Map<String, dynamic> classItem) async {
    final classId = classItem['id'].toString();
    final data = await SchoolApiService.instance.fetchClassManageDetails(classId);
    if (!mounted) return;
    if (data == null) {
      _snack('Sinif məlumatı yüklənmədi', ok: false);
      return;
    }
    final students = List<Map<String, dynamic>>.from(data['students'] as List? ?? []);
    final targetClasses = _classes
        .where((c) => c['id'].toString() != classId && (c['academicYearId']?.toString() ?? '') == (classItem['academicYearId']?.toString() ?? ''))
        .toList();
    DateTime dissolveDate = DateTime.now();
    final transferEnabled = <String>{};
    final transferTargets = <String, String?>{};

    final done = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          return AlertDialog(
            title: const Text('Sinfi ləğv et (Fors-Major)'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDate(dlgCtx, initial: dissolveDate);
                      if (picked != null) setD(() => dissolveDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _inputDeco('Ləğv tarixi *'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_displayDate(_dateToYmd(dissolveDate))),
                          const Icon(Icons.calendar_month_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Şagird transferi (istəyə bağlı)', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  if (students.isEmpty)
                    const Text('Sinifdə şagird yoxdur', style: TextStyle(fontSize: 12, color: Colors.black54))
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (ctx, i) {
                          final st = students[i];
                          final studentId = st['studentId'].toString();
                          final enabled = transferEnabled.contains(studentId);
                          return Column(
                            children: [
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: enabled,
                                title: Text(
                                  (st['name'] ?? 'Şagird').toString(),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                                onChanged: (v) => setD(() {
                                  if (v == true) {
                                    transferEnabled.add(studentId);
                                  } else {
                                    transferEnabled.remove(studentId);
                                  }
                                }),
                              ),
                              if (enabled)
                                Padding(
                                  padding: const EdgeInsets.only(left: 28, bottom: 6),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: transferTargets[studentId],
                                    decoration: _inputDeco('Köçürüləcək sinif'),
                                    items: targetClasses
                                        .map((c) => DropdownMenuItem(
                                              value: c['id'].toString(),
                                              child: Text((c['className'] ?? 'Sinif').toString()),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setD(() => transferTargets[studentId] = v),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Geri')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(dlgCtx, true),
                child: const Text('Ləğv et'),
              ),
            ],
          );
        },
      ),
    );

    if (done != true) return;
    final transfers = <String, dynamic>{};
    for (final studentId in transferEnabled) {
      final target = transferTargets[studentId];
      if (target != null && target.isNotEmpty) transfers[studentId] = target;
    }
    final ok = await SchoolApiService.instance.dissolveClass(
      classId,
      dissolveDate: _dateToYmd(dissolveDate),
      transfers: transfers,
    );
    _snack(ok ? 'Sinif ləğv edildi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Future<void> _splitClass(Map<String, dynamic> classItem) async {
    final classId = classItem['id'].toString();
    final data = await SchoolApiService.instance.fetchClassManageDetails(classId);
    if (!mounted) return;
    if (data == null) {
      _snack('Sinif məlumatı yüklənmədi', ok: false);
      return;
    }
    final students = List<Map<String, dynamic>>.from(data['students'] as List? ?? []);
    final nameCtrl = TextEditingController(text: '${classItem['className'] ?? ''} - Yeni');
    DateTime splitDate = DateTime.now();
    final moved = <String>{};
    bool copySchedules = false;

    final done = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          return AlertDialog(
            title: const Text('Sinfi böl (Split)'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputDeco('Yeni sinif adı *'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDate(dlgCtx, initial: splitDate);
                      if (picked != null) setD(() => splitDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _inputDeco('Bölünmə tarixi *'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_displayDate(_dateToYmd(splitDate))),
                          const Icon(Icons.calendar_month_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Yeni sinfə keçiriləcək şagirdlər', style: TextStyle(fontWeight: FontWeight.w800)),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (ctx, i) {
                        final st = students[i];
                        final id = st['studentId'].toString();
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: moved.contains(id),
                          title: Text(
                            (st['name'] ?? 'Şagird').toString(),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          onChanged: (v) => setD(() {
                            if (v == true) {
                              moved.add(id);
                            } else {
                              moved.remove(id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: copySchedules,
                    title: const Text('Cədvəli kopyala', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onChanged: (v) => setD(() => copySchedules = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Geri')),
              FilledButton(
                onPressed: () => Navigator.pop(dlgCtx, true),
                child: const Text('Böl'),
              ),
            ],
          );
        },
      ),
    );

    if (done != true) return;
    if (nameCtrl.text.trim().isEmpty || moved.isEmpty) {
      _snack('Yeni sinif adı və şagird seçimi tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.splitClass(
      classId,
      newClassName: nameCtrl.text.trim(),
      splitDate: _dateToYmd(splitDate),
      movedStudents: moved.toList(),
      copySchedules: copySchedules,
    );
    _snack(ok ? 'Sinif bölündü' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3E62).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF1E3E62), size: 22),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ===========================================================================
  // BUILD MAIN SCREEN
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;

    final canCreate = isSuper || session.can('gopanel.academic.classes.create') || session.can('gopanel.academic.classes.store');
    final canManage = isSuper || session.can('gopanel.academic.teachers.classes.manage');
    final canJournal = isSuper || session.can('gopanel.academic.teachers.classes.journal');
    final canSchedule = isSuper || session.can('gopanel.academic.teachers.classes.schedule');
    final canEdit = isSuper || session.can('gopanel.academic.classes.update');
    final canDelete = isSuper || session.can('gopanel.academic.classes.delete');
    final canForsMajor = isSuper || session.can('gopanel.academic.teachers.classes.forsmajor');

    final items = _filteredClasses;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3E62),
              foregroundColor: Colors.white,
              onPressed: () => _showClassForm(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Yeni sinif', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B192C),
        foregroundColor: Colors.white,
        title: const Text('Siniflər', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Yenilə'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError && _classes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Məlumatları yükləmək mümkün olmadı',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'İnternet bağlantısını yoxlayıb yenidən cəhd edin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Yenidən yoxla'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 140),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Sinif, otaq və ya sinif rəhbəri ilə axtar...',
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', 'Bütün bölmələr', _selectedLanguage, (v) => setState(() => _selectedLanguage = v)),
                        const SizedBox(width: 8),
                        _filterChip('azerbaijan', 'Azərbaycan', _selectedLanguage, (v) => setState(() => _selectedLanguage = v)),
                        const SizedBox(width: 8),
                        _filterChip('russian', 'Rus bölməsi', _selectedLanguage, (v) => setState(() => _selectedLanguage = v)),
                        const SizedBox(width: 8),
                        _filterChip('english', 'İngilis bölməsi', _selectedLanguage, (v) => setState(() => _selectedLanguage = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', 'Bütün siniflər', _selectedGradeLevel, (v) => setState(() => _selectedGradeLevel = v)),
                        const SizedBox(width: 8),
                        ...List.generate(12, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _filterChip('$i', '$i-ci sinif', _selectedGradeLevel, (v) => setState(() => _selectedGradeLevel = v)),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  StatCardRow(
                    children: [
                      StatCard(
                        value: '${_stats['totalStudents'] ?? 0}',
                        label: 'Cəmi Şagirdlər',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF1E3E62),
                      ),
                      StatCard(
                        value: '${_stats['maleCount'] ?? 0}',
                        label: 'Oğlanlar',
                        icon: Icons.male_rounded,
                        color: const Color(0xFF0284C7),
                      ),
                      StatCard(
                        value: '${_stats['femaleCount'] ?? 0}',
                        label: 'Qızlar',
                        icon: Icons.female_rounded,
                        color: const Color(0xFFE11D48),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mövcud Siniflər', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: palette.textPrimary)),
                      Text('${items.length} sinif göstərilir', style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w700)),
                    ],
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
                            Text('Axtarışa uyğun sinif tapılmadı', style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...items.map((c) {
                      return _buildClassCard(
                        context,
                        palette: palette,
                        classItem: c,
                        canManage: canManage,
                        canJournal: canJournal,
                        canSchedule: canSchedule,
                        canEdit: canEdit,
                        canDelete: canDelete,
                        canForsMajor: canForsMajor,
                      );
                    }),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Şagirdlər (${students.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (students.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: palette.borderHairline,
                    ),
                  ),
                  child: Text(
                    'Bu sinifə hələ şagird təyin edilməyib.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...students.map((student) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ModernAvatar(
                          imageUrl: student.photoUrl,
                          name: student.fullName,
                          size: 38,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'ID: ${student.studentNumber} • Valideyn: ${student.parentName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: student.gpa > 0
                                ? palette.brandRoyal.withValues(alpha: 0.09)
                                : palette.surface3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            student.gpa > 0
                                ? 'GPA ${student.gpa.toStringAsFixed(2)}'
                                : 'Yeni',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: student.gpa > 0
                                  ? palette.brandRoyal
                                  : palette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String text,
    bool visible = true,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _filterChip(String key, String label, String currentVal, ValueChanged<String> onSelected) {
    final isSelected = currentVal == key;
    return InkWell(
      onTap: () => onSelected(key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3E62) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3E62) : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF1E3E62).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context, {
    required AppPalette palette,
    required Map<String, dynamic> classItem,
    required bool canManage,
    required bool canJournal,
    required bool canSchedule,
    required bool canEdit,
    required bool canDelete,
    required bool canForsMajor,
  }) {
    final className = classItem['className'] ?? 'Sinif';
    final academicYear = classItem['academicYearTitle'] ?? '2026-2027';
    final roomName = classItem['roomName']?.toString().isNotEmpty == true ? classItem['roomName'] : null;
    final teacher = classItem['classTeacher']?.toString().isNotEmpty == true ? classItem['classTeacher'] : null;
    final studentCount = classItem['studentCount'] ?? 0;
    final maxCapacity = classItem['maxCapacity'] ?? 20;
    final lang = (classItem['gradeLanguage'] ?? '').toString().toLowerCase();

    String langLabel = 'Azərbaycan';
    Color langColor = const Color(0xFF0284C7);
    if (lang.contains('russian') || lang.contains('ru')) {
      langLabel = 'Rus';
      langColor = const Color(0xFF8B5CF6);
    } else if (lang.contains('english') || lang.contains('en')) {
      langLabel = 'İngilis';
      langColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3E62),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    className,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: langColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$langLabel bölməsi',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: langColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              academicYear,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.door_front_door_outlined, size: 15, color: palette.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              roomName != null ? 'Otaq: $roomName' : 'Otaq təyin edilməyib',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: roomName != null ? palette.textPrimary : palette.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$studentCount',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.emerald),
                      ),
                      Text(
                        '/$maxCapacity tutum',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: teacher != null ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 16,
                    color: teacher != null ? const Color(0xFF1E3E62) : AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teacher != null ? 'Sinif rəhbəri: $teacher' : 'Sinif rəhbəri təyin edilməyib',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: teacher != null ? const Color(0xFF0F172A) : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (canManage)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 15),
                    label: const Text('İdarə et', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    onPressed: () => _openClassManageSheet(classItem),
                  ),
                if (canJournal)
                  IconButton(
                    icon: const Icon(Icons.fact_check_outlined, size: 19, color: Color(0xFF2563EB)),
                    tooltip: 'Jurnal',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApiJournalScreen()),
                    ),
                  ),
                if (canSchedule)
                  IconButton(
                    icon: const Icon(Icons.calendar_view_week_rounded, size: 19, color: Color(0xFF059669)),
                    tooltip: 'Cədvəl',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminTimetableManagementScreen()),
                    ),
                  ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF1E3E62)),
                    tooltip: 'Redaktə et',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showClassForm(classItem),
                  ),
                if (canForsMajor)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF59E0B)),
                    tooltip: 'Fors-Major',
                    onSelected: (val) {
                      switch (val) {
                        case 'dissolve':
                          _dissolveClass(classItem);
                        case 'cancel_subject':
                          _cancelClassSubject(classItem);
                        case 'split':
                          _splitClass(classItem);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'dissolve',
                        child: Row(children: [
                          Icon(Icons.cancel_outlined, color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Text('Sinfi Ləğv Et (Dissolve)', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'cancel_subject',
                        child: Row(children: [
                          Icon(Icons.block_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Text('Fənni ləğv et'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'split',
                        child: Row(children: [
                          Icon(Icons.call_split_rounded, color: Color(0xFF0284C7), size: 18),
                          SizedBox(width: 8),
                          Text('Sinfi böl (Split)'),
                        ]),
                      ),
                    ],
                  ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.danger),
                    tooltip: 'Sil',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _deleteClass(classItem),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SINİF İDARƏETMƏ PANELİ (4 TAB)
// =============================================================================
class _ClassManageSheet extends StatefulWidget {
  const _ClassManageSheet({
    required this.classItem,
    required this.classes,
    required this.teachers,
    required this.isSuper,
    required this.canManage,
    required this.canAssignHomeroom,
    required this.canAssignSubjects,
    required this.canManageStudents,
    required this.canManageGroups,
    required this.canManageCurriculum,
    required this.onSnack,
    required this.onChanged,
  });

  final Map<String, dynamic> classItem;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> teachers;
  final bool isSuper;
  final bool canManage;
  final bool canAssignHomeroom;
  final bool canAssignSubjects;
  final bool canManageStudents;
  final bool canManageGroups;
  final bool canManageCurriculum;
  final void Function(String text, {bool ok}) onSnack;
  final Future<void> Function() onChanged;

  @override
  State<_ClassManageSheet> createState() => _ClassManageSheetState();
}

class _ClassManageSheetState extends State<_ClassManageSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _error = false;
  String get _classId => widget.classItem['id'].toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final data = await SchoolApiService.instance.fetchClassManageDetails(_classId);
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
        _error = data == null;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _load();
    await widget.onChanged();
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final data = _data;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3E62).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded, color: Color(0xFF1E3E62), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.classItem['className']} Sinfinin İdarəsi',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${widget.classItem['academicYearTitle'] ?? '2026-2027'} • ${widget.classItem['roomName'] ?? 'Otaq yoxdur'}',
                              style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF1E3E62),
              unselectedLabelColor: palette.textSecondary,
              indicatorColor: const Color(0xFF1E3E62),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.person_pin_rounded, size: 18), text: 'Müəllimlər'),
                Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'Şagirdlər'),
                Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'Qruplar'),
                Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Kurikulum'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error || data == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text('Məlumat yüklənmədi', style: TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Yenidən yoxla'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                      children: [
                        _buildTeachersTab(context, palette, data),
                        _buildStudentsTab(context, palette, data),
                        _buildGroupsTab(context, palette, data),
                        _buildCurriculumTab(context, palette, data),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: MÜƏLLİMLƏR
  // ---------------------------------------------------------------------------
  Widget _buildTeachersTab(BuildContext ctx, AppPalette palette, Map<String, dynamic> data) {
    final classTeachers = List<Map<String, dynamic>>.from(data['classTeachers'] as List? ?? []);
    final subjectTeachers = List<Map<String, dynamic>>.from(data['subjectTeachers'] as List? ?? []);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sinif Rəhbərləri', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  if (widget.canAssignHomeroom)
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Dəyiş'),
                      onPressed: () => _showHomeroomDialog(ctx, classTeachers),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (classTeachers.isEmpty)
                const Text('Təyin edilməyib', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: classTeachers.map((t) {
                    return Chip(
                      avatar: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF1E3E62)),
                      label: Text((t['name'] ?? 'Müəllim').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      backgroundColor: const Color(0xFF1E3E62).withValues(alpha: 0.08),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fənn Müəllimləri (${subjectTeachers.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            if (widget.canAssignSubjects)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3E62),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Fənn təyin et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                onPressed: () => _showSubjectTeacherDialog(ctx),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (subjectTeachers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text('Fənn müəllimi təyin edilməyib', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          )
        else
          ...subjectTeachers.map((st) {
            final parallel = (st['parallelSubjectIds'] as List? ?? []);
            final separated = st['separated'] == true;
            final preferred = st['preferredLessonNumber'];
            final groupName = st['groupName'];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E3E62).withValues(alpha: 0.1),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3E62), size: 18),
                ),
                title: Text((st['subjectName'] ?? 'Fənn').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Müəllim: ${st['teacherName'] ?? 'Təyin edilməyib'} • Həftəlik: ${st['weeklyHours'] ?? 0} saat'
                        '${st['hoursPerDay'] != null ? ' • Gündəlik: ${st['hoursPerDay']}' : ''}',
                        style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (groupName != null)
                            _miniBadge('Qrup: $groupName', const Color(0xFF7C3AED)),
                          if (preferred != null)
                            _miniBadge('$preferred-ci dərs', const Color(0xFF0284C7)),
                          if (parallel.isNotEmpty)
                            _miniBadge('Paralel: ${parallel.length}', const Color(0xFFD97706)),
                          if (separated)
                            _miniBadge('Ayrılmış', const Color(0xFF059669)),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: widget.canAssignSubjects
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                        onPressed: () async {
                          final ok = await SchoolApiService.instance.deleteClassSubjectTeacher(_classId, st['id'].toString());
                          widget.onSnack(ok ? 'Fənn təyinatı silindi' : 'Xəta baş verdi', ok: ok);
                          if (ok) _refreshAll();
                        },
                      )
                    : null,
              ),
            );
          }),
      ],
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Future<void> _showHomeroomDialog(BuildContext ctx, List<Map<String, dynamic>> current) async {
    final result = await showDialog<Set<String>>(
      context: ctx,
      builder: (_) => _MultiSelectDialog(
        title: 'Sinif rəhbərlərini seçin',
        options: widget.teachers
            .map((t) => _MultiOption(value: t['id'].toString(), label: _teacherName(t)))
            .toList(),
        initialSelected: current.map((t) => t['id'].toString()).toSet(),
      ),
    );
    if (result == null) return;
    final ok = await SchoolApiService.instance.assignClassHomeroomTeacher(_classId, result.toList());
    widget.onSnack(ok ? 'Sinif rəhbəri təyin edildi' : 'Xəta baş verdi', ok: ok);
    if (ok) await _refreshAll();
  }

  Future<void> _showSubjectTeacherDialog(BuildContext ctx) async {
    final subjects = await SchoolApiService.instance.fetchSubjects();
    if (!mounted || !ctx.mounted) return;
    if (subjects.isEmpty) {
      widget.onSnack('Fənn siyahısı boşdur', ok: false);
      return;
    }
    String? selectedSubId;
    String? selectedTeacherId;
    final hoursCtrl = TextEditingController(text: '2');
    int hoursPerDay = 1;
    int? preferredLesson;
    final parallelIds = <String>{};
    bool separated = false;

    final done = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          Future<void> pickParallel() async {
            final result = await showDialog<Set<String>>(
              context: dlgCtx,
              builder: (_) => _MultiSelectDialog(
                title: 'Paralel fənlər',
                options: subjects
                    .where((s) => s['id'].toString() != selectedSubId)
                    .map((s) => _MultiOption(value: s['id'].toString(), label: (s['name'] ?? 'Fənn').toString()))
                    .toList(),
                initialSelected: parallelIds,
              ),
            );
            if (result != null) {
              setD(() {
                parallelIds
                  ..clear()
                  ..addAll(result);
              });
            }
          }

          return AlertDialog(
            title: const Text('Fənn Müəllimi Təyin Et'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedSubId,
                    decoration: _inputDeco('Fənn seçin *'),
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text((s['name'] ?? 'Fənn').toString())))
                        .toList(),
                    onChanged: (v) => setD(() => selectedSubId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedTeacherId,
                    decoration: _inputDeco('Müəllim seçin *'),
                    items: widget.teachers
                        .map((t) => DropdownMenuItem(value: t['id'].toString(), child: Text(_teacherName(t))))
                        .toList(),
                    onChanged: (v) => setD(() => selectedTeacherId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hoursCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('Həftəlik saat *'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: hoursPerDay,
                          decoration: _inputDeco('Gündəlik saat'),
                          items: List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                          onChanged: (v) => setD(() => hoursPerDay = v ?? 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: preferredLesson,
                    decoration: _inputDeco('Arzu olunan dərs nömrəsi'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Fərq etməz')),
                      ...List.generate(8, (i) => DropdownMenuItem<int?>(value: i + 1, child: Text('${i + 1}-ci dərs'))),
                    ],
                    onChanged: (v) => setD(() => preferredLesson = v),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: pickParallel,
                    child: InputDecorator(
                      decoration: _inputDeco('Paralel fənlər'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(parallelIds.isEmpty ? 'Seçilməyib' : '${parallelIds.length} fənn seçildi'),
                          const Icon(Icons.link_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: separated,
                    title: const Text('Ayrı qrup kimi təyin et', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onChanged: (v) => setD(() => separated = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Ləğv et')),
              FilledButton(
                onPressed: (selectedSubId != null && selectedTeacherId != null)
                    ? () => Navigator.pop(dlgCtx, true)
                    : null,
                child: const Text('Əlavə et'),
              ),
            ],
          );
        },
      ),
    );

    if (done == true && selectedSubId != null && selectedTeacherId != null) {
      final ok = await SchoolApiService.instance.saveClassSubjectTeacher(_classId, {
        'subjectId': selectedSubId,
        'teacherId': selectedTeacherId,
        'weeklyHours': int.tryParse(hoursCtrl.text.trim()) ?? 2,
        'hoursPerDay': hoursPerDay,
        'preferredLessonNumber': preferredLesson,
        'parallelSubjectIds': parallelIds.toList(),
        'separated': separated,
      });
      widget.onSnack(ok ? 'Fənn müəllimi təyin edildi' : 'Xəta baş verdi', ok: ok);
      if (ok) await _refreshAll();
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 2: ŞAGİRDLƏR
  // ---------------------------------------------------------------------------
  Widget _buildStudentsTab(BuildContext ctx, AppPalette palette, Map<String, dynamic> data) {
    final students = List<Map<String, dynamic>>.from(data['students'] as List? ?? []);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sinifdəki Şagirdlər (${students.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              if (widget.canManageStudents)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3E62),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Şagird təyini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => _showAssignStudentsSheet(ctx),
                ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('Sinifdə hələ şagird yoxdur'))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final st = students[i];
                    final name = (st['name'] ?? 'Şagird').toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3E62).withValues(alpha: 0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'Ş',
                            style: const TextStyle(color: Color(0xFF1E3E62), fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          'Kod: ${st['code'] ?? '—'} • FİN: ${st['finCode'] ?? '—'}'
                          '\nBaşlama: ${_displayDate(st['startDate']?.toString())}',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onSelected: (val) async {
                            if (val == 'date' && widget.isSuper) {
                              await _showChangeStartDateDialog(ctx, st);
                            } else if (val == 'remove') {
                              final ok = await SchoolApiService.instance.removeStudentFromClass(_classId, st['studentId'].toString());
                              widget.onSnack(ok ? 'Şagird sinifdən çıxarıldı' : 'Xəta baş verdi', ok: ok);
                              if (ok) await _refreshAll();
                            }
                          },
                          itemBuilder: (_) => [
                            if (widget.isSuper)
                              const PopupMenuItem(
                                value: 'date',
                                child: Row(children: [
                                  Icon(Icons.calendar_month_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Başlama tarixini dəyiş'),
                                ]),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(children: [
                                Icon(Icons.person_remove_rounded, color: AppColors.danger, size: 18),
                                SizedBox(width: 8),
                                Text('Sinifdən çıxar', style: TextStyle(color: AppColors.danger)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showAssignStudentsSheet(BuildContext ctx) async {
    final options = await SchoolApiService.instance.fetchStudentsForAssignment(_classId);
    if (!mounted || !ctx.mounted) return;
    final selected = options.where((o) => o['selected'] == true).map((o) => o['id'].toString()).toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _MultiSelectSheet(
        title: 'Sinifə şagird təyini',
        options: options
            .map((o) => _MultiOption(value: o['id'].toString(), label: (o['text'] ?? 'Şagird').toString()))
            .toList(),
        initialSelected: selected,
        confirmLabel: 'Yadda saxla',
      ),
    );

    if (result == null) return;
    final ok = await SchoolApiService.instance.assignStudentsToClass(_classId, result.toList());
    widget.onSnack(ok ? 'Şagird təyinatı yeniləndi' : 'Xəta baş verdi', ok: ok);
    if (ok) await _refreshAll();
  }

  Future<void> _showChangeStartDateDialog(BuildContext ctx, Map<String, dynamic> st) async {
    DateTime initial = DateTime.tryParse(st['startDate'] ?? '') ?? DateTime(2026, 9, 1);
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    final ok = await SchoolApiService.instance.updateClassStudentStartDate(
      _classId,
      st['classStudentId'].toString(),
      _dateToYmd(picked),
    );
    widget.onSnack(ok ? 'Başlama tarixi yeniləndi' : 'Xəta baş verdi', ok: ok);
    if (ok) await _load();
  }

  // ---------------------------------------------------------------------------
  // TAB 3: QRUPLLAR
  // ---------------------------------------------------------------------------
  Widget _buildGroupsTab(BuildContext ctx, AppPalette palette, Map<String, dynamic> data) {
    final groups = List<Map<String, dynamic>>.from(data['groups'] as List? ?? []);
    final activeGroups = groups.where((g) => g['cancelledAt'] == null).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sinif Qrupları (${activeGroups.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Row(
              children: [
                if (widget.canManageGroups && activeGroups.length >= 2)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.merge_rounded, size: 16),
                    label: const Text('Birləşdir'),
                    onPressed: () => _showMergeGroupsDialog(ctx, activeGroups),
                  ),
                if (widget.canManageGroups)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3E62),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Qrup yarat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    onPressed: () => _showGroupFormDialog(ctx, activeGroups),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'Bu sinif üçün xüsusi alt qrup (məs: xarici dil qrupu) yaradılmayıb',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ...groups.map((g) {
            final cancelled = g['cancelledAt'] != null;
            final isMerged = g['isMerged'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                enabled: !cancelled,
                leading: CircleAvatar(
                  backgroundColor: (cancelled ? Colors.grey : const Color(0xFF1E3E62)).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.groups_rounded,
                    color: cancelled ? Colors.grey : const Color(0xFF1E3E62),
                    size: 18,
                  ),
                ),
                title: Text(
                  _groupTitle(g),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: cancelled ? Colors.grey : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Şagird: ${g['studentCount'] ?? 0}',
                        style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                      ),
                      if ((g['teacherNames'] as List? ?? []).isNotEmpty)
                        _miniBadge(
                          'Müəllim: ${(g['teacherNames'] as List).join(', ')}',
                          const Color(0xFF0284C7),
                        ),
                      if ((g['streamType'] ?? '').toString().isNotEmpty)
                        _miniBadge(_groupStreamLabel(g['streamType'].toString()), const Color(0xFF7C3AED)),
                      if (isMerged) _miniBadge('Birləşdirilib', const Color(0xFFD97706)),
                      if (cancelled) _miniBadge('Ləğv: ${_displayDate(g['cancelledAt'].toString())}', AppColors.danger),
                    ],
                  ),
                ),
                trailing: cancelled
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (val) async {
                          switch (val) {
                            case 'students':
                              await _showGroupStudentsDialog(ctx, g);
                            case 'edit':
                              await _showGroupFormDialog(ctx, activeGroups, editing: g);
                            case 'delete':
                              final ok = await SchoolApiService.instance.deleteClassGroup(g['id'].toString());
                              widget.onSnack(ok ? 'Qrup silindi' : 'Xəta baş verdi', ok: ok);
                              if (ok) await _refreshAll();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'students',
                            child: Row(children: [
                              Icon(Icons.people_alt_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Şagirdləri təyin et'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Redaktə et'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: AppColors.danger)),
                            ]),
                          ),
                        ],
                      ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showGroupFormDialog(
    BuildContext ctx,
    List<Map<String, dynamic>> activeGroups, {
    Map<String, dynamic>? editing,
  }) async {
    final subjects = await SchoolApiService.instance.fetchSubjects();
    if (!ctx.mounted) return;
    final titles = editing?['titles'] as Map? ?? {};
    final azCtrl = TextEditingController(text: editing != null ? _groupTitle(editing) : '');
    final ruCtrl = TextEditingController(text: (titles['ru'] ?? '').toString());
    final enCtrl = TextEditingController(text: (titles['en'] ?? '').toString());
    String streamType = (editing?['streamType'] ?? '').toString();
    if (!_groupStreamOptions.any((o) => o['value'] == streamType)) streamType = '';
    String? subjectId = editing?['subjectId']?.toString();
    final teacherIds = (editing?['teacherIds'] as List? ?? []).map((e) => e.toString()).toSet();

    final done = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          Future<void> pickTeachers() async {
            final result = await showDialog<Set<String>>(
              context: dlgCtx,
              builder: (_) => _MultiSelectDialog(
                title: 'Qrup müəllimləri',
                options: widget.teachers
                    .map((t) => _MultiOption(value: t['id'].toString(), label: _teacherName(t)))
                    .toList(),
                initialSelected: teacherIds,
              ),
            );
            if (result != null) {
              setD(() {
                teacherIds
                  ..clear()
                  ..addAll(result);
              });
            }
          }

          return AlertDialog(
            title: Text(editing == null ? 'Yeni Sinif Qrupu' : 'Qrupu Redaktə Et'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: azCtrl, decoration: _inputDeco('Qrup adı (AZ) *')),
                  const SizedBox(height: 10),
                  TextField(controller: ruCtrl, decoration: _inputDeco('Qrup adı (RU)')),
                  const SizedBox(height: 10),
                  TextField(controller: enCtrl, decoration: _inputDeco('Qrup adı (EN)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: streamType,
                    decoration: _inputDeco('Təmayül'),
                    items: _groupStreamOptions
                        .map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!)))
                        .toList(),
                    onChanged: (v) => setD(() => streamType = v ?? 'general'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: subjectId,
                    decoration: _inputDeco('Fənn (istəyə bağlı)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Seçilməyib')),
                      ...subjects.map((s) => DropdownMenuItem<String?>(
                            value: s['id'].toString(),
                            child: Text((s['name'] ?? 'Fənn').toString()),
                          )),
                    ],
                    onChanged: (v) => setD(() => subjectId = v),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: pickTeachers,
                    child: InputDecorator(
                      decoration: _inputDeco('Müəllimlər'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(teacherIds.isEmpty ? 'Seçilməyib' : '${teacherIds.length} müəllim'),
                          const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Ləğv et')),
              FilledButton(
                onPressed: azCtrl.text.trim().isEmpty ? null : () => Navigator.pop(dlgCtx, true),
                child: Text(editing == null ? 'Yarat' : 'Yadda saxla'),
              ),
            ],
          );
        },
      ),
    );

    if (done != true) return;
    final payload = <String, dynamic>{
      'title': {
        'az': azCtrl.text.trim(),
        'ru': ruCtrl.text.trim(),
        'en': enCtrl.text.trim(),
      },
      'streamType': streamType,
      'subjectId': subjectId,
      'teachers': teacherIds.toList(),
      'teachers_submitted': true,
    };
    final result = await SchoolApiService.instance.saveClassGroupForClass(
      _classId,
      payload,
      groupId: editing?['id']?.toString(),
    );
    widget.onSnack(result != null ? (editing == null ? 'Qrup yaradıldı' : 'Qrup yeniləndi') : 'Xəta baş verdi', ok: result != null);
    if (result != null) await _refreshAll();
  }

  Future<void> _showGroupStudentsDialog(BuildContext ctx, Map<String, dynamic> group) async {
    final options = await SchoolApiService.instance.fetchGroupStudentsForAssignment(_classId, group['id'].toString());
    if (!mounted || !ctx.mounted) return;
    final selected = options.where((o) => o['selected'] == true).map((o) => o['id'].toString()).toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _MultiSelectSheet(
        title: '${_groupTitle(group)} — şagirdlər',
        options: options
            .map((o) => _MultiOption(value: o['id'].toString(), label: (o['text'] ?? 'Şagird').toString()))
            .toList(),
        initialSelected: selected,
        confirmLabel: 'Yadda saxla',
      ),
    );

    if (result == null) return;
    final ok = await SchoolApiService.instance.assignGroupStudentsToGroup(
      _classId,
      group['id'].toString(),
      result.toList(),
    );
    widget.onSnack(ok ? 'Qrup şagirdləri yeniləndi' : 'Xəta baş verdi', ok: ok);
    if (ok) await _refreshAll();
  }

  Future<void> _showMergeGroupsDialog(BuildContext ctx, List<Map<String, dynamic>> activeGroups) async {
    final selectedGroupIds = <String>{};
    String? teacherId;
    DateTime mergeDate = DateTime.now();
    String streamType = '';
    final azCtrl = TextEditingController();

    final done = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setD) {
          return AlertDialog(
            title: const Text('Qrupları Birləşdir'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Birləşdiriləcək qruplar (min. 2)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ...activeGroups.map((g) {
                      final id = g['id'].toString();
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selectedGroupIds.contains(id),
                        title: Text(_groupTitle(g), style: const TextStyle(fontSize: 12.5)),
                        onChanged: (v) => setD(() {
                          if (v == true) {
                            selectedGroupIds.add(id);
                          } else {
                            selectedGroupIds.remove(id);
                          }
                        }),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextField(controller: azCtrl, decoration: _inputDeco('Yeni qrup adı (AZ) *')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: teacherId,
                      decoration: _inputDeco('Müəllim *'),
                      items: widget.teachers
                          .map((t) => DropdownMenuItem(value: t['id'].toString(), child: Text(_teacherName(t))))
                          .toList(),
                      onChanged: (v) => setD(() => teacherId = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: streamType,
                      decoration: _inputDeco('Təmayül'),
                      items: _streamOptions
                          .map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!)))
                          .toList(),
                      onChanged: (v) => setD(() => streamType = v ?? 'general'),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dlgCtx,
                          initialDate: mergeDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setD(() => mergeDate = picked);
                      },
                      child: InputDecorator(
                        decoration: _inputDeco('Birləşmə tarixi *'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_displayDate(_dateToYmd(mergeDate))),
                            const Icon(Icons.calendar_month_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Ləğv et')),
              FilledButton(
                onPressed: (selectedGroupIds.length >= 2 && teacherId != null && azCtrl.text.trim().isNotEmpty)
                    ? () => Navigator.pop(dlgCtx, true)
                    : null,
                child: const Text('Birləşdir'),
              ),
            ],
          );
        },
      ),
    );

    if (done != true) return;
    final result = await SchoolApiService.instance.mergeClassGroups(_classId, {
      'group_ids': selectedGroupIds.toList(),
      'teacher_id': teacherId,
      'merge_date': _dateToYmd(mergeDate),
      'title': {'az': azCtrl.text.trim()},
      'stream_type': streamType,
    });
    widget.onSnack(result != null ? 'Qruplar birləşdirildi' : 'Xəta baş verdi', ok: result != null);
    if (result != null) await _refreshAll();
  }

  // ---------------------------------------------------------------------------
  // TAB 4: KURİKULUM
  // ---------------------------------------------------------------------------
  Widget _buildCurriculumTab(BuildContext ctx, AppPalette palette, Map<String, dynamic> data) {
    final curriculums = List<Map<String, dynamic>>.from(data['curriculums'] as List? ?? []);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kurikulum (${curriculums.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              if (widget.canManageCurriculum)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3E62),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Redaktə et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => _showCurriculumDialog(ctx, curriculums),
                ),
            ],
          ),
        ),
        Expanded(
          child: curriculums.isEmpty
              ? const Center(child: Text('Kurikulum məlumatı tapılmadı'))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: curriculums.length,
                  itemBuilder: (ctx, i) {
                    final c = curriculums[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3E62).withValues(alpha: 0.1),
                          child: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF1E3E62), size: 18),
                        ),
                        title: Text((c['subjectName'] ?? 'Fənn').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                        subtitle: Text(
                          'Mövzu sayı: ${c['topicsCount'] ?? 0}',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3E62).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${c['weeklyHours'] ?? 0} saat/həftə',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3E62)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showCurriculumDialog(BuildContext ctx, List<Map<String, dynamic>> current) async {
    final subjects = await SchoolApiService.instance.fetchSubjects();
    if (!mounted || !ctx.mounted) return;
    final existing = <String, int>{};
    for (final c in current) {
      existing[c['subjectId'].toString()] = (c['weeklyHours'] as num?)?.toInt() ?? 0;
    }
    final controllers = <String, TextEditingController>{};
    for (final s in subjects) {
      final id = s['id'].toString();
      controllers[id] = TextEditingController(text: (existing[id] ?? 0).toString());
    }

    final done = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Kurikulumu Redaktə Et'),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (ctx, i) {
              final s = subjects[i];
              final id = s['id'].toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (s['name'] ?? 'Fənn').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 76,
                      child: TextField(
                        controller: controllers[id],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Saat',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Ləğv et')),
          FilledButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Yadda saxla'),
          ),
        ],
      ),
    );

    if (done != true) return;
    final items = <Map<String, dynamic>>[];
    for (final s in subjects) {
      final id = s['id'].toString();
      final hours = int.tryParse(controllers[id]?.text.trim() ?? '') ?? 0;
      if (hours > 0) {
        items.add({'subjectId': id, 'weeklyHours': hours});
      }
    }
    final ok = await SchoolApiService.instance.saveClassCurriculum(_classId, items);
    widget.onSnack(ok ? 'Kurikulum yeniləndi' : 'Xəta baş verdi', ok: ok);
    if (ok) await _refreshAll();
  }
}

// =============================================================================
// ORTAQ MULTI-SELECT WIDGET-LƏR
// =============================================================================
class _MultiOption {
  const _MultiOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _MultiSelectDialog extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.options,
    required this.initialSelected,
  });

  final String title;
  final List<_MultiOption> options;
  final Set<String> initialSelected;

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => _query.isEmpty || o.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Axtar...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final option = filtered[i];
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(option.value),
                    title: Text(option.label, style: const TextStyle(fontSize: 13)),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(option.value);
                      } else {
                        _selected.remove(option.value);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ləğv et')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Təsdiqlə'),
        ),
      ],
    );
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initialSelected,
    required this.confirmLabel,
  });

  final String title;
  final List<_MultiOption> options;
  final Set<String> initialSelected;
  final String confirmLabel;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final filtered = widget.options
        .where((o) => _query.isEmpty || o.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.viewInsetsOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Ad və ya kod ilə axtar...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final option = filtered[i];
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(option.value),
                  title: Text(option.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(option.value);
                    } else {
                      _selected.remove(option.value);
                    }
                  }),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3E62),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text('${widget.confirmLabel} (${_selected.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ),
        ],
      ),
    );
  }
}
