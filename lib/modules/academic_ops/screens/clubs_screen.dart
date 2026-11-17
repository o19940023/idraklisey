import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/app_state.dart';
import 'club_journal_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _kBrandRoyal = Color(0xFF2563EB);

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedGradeCategory = 'all_filter';
  String _selectedSubjectCategory = 'Hamısı';

  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic> _studentLimits = {
    'activeCount': 0,
    'maxActive': 2,
    'freeCount': 0,
    'maxFree': 1,
    'paidCount': 0,
    'maxPaid': 2,
    'totalCount': 0,
    'maxTotal': 3,
  };
  Map<String, dynamic> _meta = {};

  String? _selectedStudentId;
  int _staffTabIndex = 0; // 0 = Dərnəklər, 1 = Gözləyən Müraciətlər, 2 = Kataloq Görünüşü

  final TextEditingController _searchCtrl = TextEditingController();

  static const List<Map<String, String>> _gradeCategoryFilters = [
    {'key': 'all_filter', 'label': 'Bütün siniflər'},
    {'key': '1-4', 'label': '1-4 siniflər'},
    {'key': '5-11', 'label': '5-11 siniflər'},
    {'key': 'all', 'label': '1-11 siniflər'},
  ];

  static const List<String> _subjectCategories = [
    'Hamısı',
    'İdman',
    'Texnologiya',
    'İncəsənət',
    'Akademik',
  ];

  static const Map<int, String> _dayNames = {
    1: 'Bazar ertəsi',
    2: 'Çərşənbə axşamı',
    3: 'Çərşənbə',
    4: 'Cümə axşamı',
    5: 'Cümə',
    6: 'Şənbə',
    7: 'Bazar',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isStudent {
    final session = context.read<SessionController>();
    final appState = context.read<AppState>();
    if (session.profile?.isStudent == true) return true;
    return appState.currentUser?.role == UserRole.student;
  }

  bool get _isParent {
    final session = context.read<SessionController>();
    final appState = context.read<AppState>();
    if (session.profile?.isParent == true) return true;
    return appState.currentUser?.role == UserRole.parent;
  }

  bool get _isStaff => !_isStudent && !_isParent;

  bool get _canCreateClub {
    final session = context.read<SessionController>();
    if (session.profile?.isSuper == true) return true;
    return session.can('gopanel.academic.clubs.create');
  }

  bool get _canEditClub {
    final session = context.read<SessionController>();
    if (session.profile?.isSuper == true) return true;
    return session.can('gopanel.academic.clubs.update');
  }

  bool get _canDeleteClub {
    final session = context.read<SessionController>();
    if (session.profile?.isSuper == true) return true;
    return session.can('gopanel.academic.clubs.delete');
  }

  bool get _canEnrollClub {
    final session = context.read<SessionController>();
    if (session.profile?.isSuper == true) return true;
    return session.can('gopanel.academic.clubs.enroll');
  }

  Future<void> _load({String? overrideStudentId}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final session = context.read<SessionController>();
    final appState = context.read<AppState>();
    final profileId = session.profile?.id.toString() ??
        appState.currentUser?.id;

    String? studentIdParam = overrideStudentId ?? _selectedStudentId;
    String? parentIdParam;

    if (_isParent) {
      parentIdParam = profileId;
      if (studentIdParam == null && appState.student.id.isNotEmpty) {
        studentIdParam = appState.student.id.replaceAll(RegExp(r'[^0-9]'), '');
      }
    } else if (_isStudent) {
      studentIdParam = profileId;
    }

    final payload = await SchoolApiService.instance.fetchClubsPayload(
      studentId: studentIdParam,
      parentId: parentIdParam,
      onlyActive: !_isStaff,
    );

    if (!mounted) return;

    if (payload != null) {
      final rawClubs = (payload['data'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final rawPending = (payload['pendingRequests'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final rawChildren = (payload['children'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final selSt = payload['selectedStudent'] is Map
          ? Map<String, dynamic>.from(payload['selectedStudent'] as Map)
          : null;
      final limits = payload['studentLimits'] is Map
          ? Map<String, dynamic>.from(payload['studentLimits'] as Map)
          : _studentLimits;
      final metaMap = payload['meta'] is Map
          ? Map<String, dynamic>.from(payload['meta'] as Map)
          : <String, dynamic>{};

      setState(() {
        _clubs = rawClubs;
        _pendingRequests = rawPending;
        _children = rawChildren;
        _selectedStudent = selSt;
        if (selSt != null && selSt['id'] != null) {
          _selectedStudentId = selSt['id'].toString();
        }
        _studentLimits = limits;
        _meta = metaMap;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredClubs {
    return _clubs.where((c) {
      if (!_isStaff && c['isActive'] == false) return false;

      if (_selectedGradeCategory != 'all_filter') {
        final gc = (c['gradeCategory'] ?? 'all').toString();
        if (gc != _selectedGradeCategory) return false;
      }

      if (_selectedSubjectCategory != 'Hamısı') {
        final cat = (c['category'] ?? '').toString();
        if (cat != _selectedSubjectCategory) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final name = (c['name'] ?? '').toString().toLowerCase();
        final teacher = (c['instructor'] ?? '').toString().toLowerCase();
        final subj = (c['subjectTitle'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !teacher.contains(q) && !subj.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _double(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  void _snack(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================================================================
  // PARENT ACTIONS: JOIN & CANCEL REQUEST (1:1 WITH catalog.blade.php)
  // ===========================================================================

  Future<void> _handleParentJoin(Map<String, dynamic> club) async {
    final studentId = _selectedStudentId ?? _selectedStudent?['id']?.toString();
    final studentName = _selectedStudent?['name']?.toString() ?? 'Övladınız';
    if (studentId == null || studentId.isEmpty) {
      _snack('Zəhmət olmasa əvvəlcə övladınızı seçin.', ok: false);
      return;
    }

    final clubName = club['name']?.toString() ?? 'Dərnək';
    final priceLabel = club['priceLabel']?.toString() ?? 'Ödənişsiz';
    final isFull = club['isFull'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kBrandRoyal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.how_to_reg_rounded, color: _kBrandRoyal),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Dərnəyə qoşulma müraciəti',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Övladınız "$studentName" üçün "$clubName" dərnəyinə qoşulma müraciəti göndərilsin?',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: _kBrandRoyal),
                      const SizedBox(width: 6),
                      Text(
                        'Ödəniş: $priceLabel',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Müraciətiniz dərnək rəhbəri tərəfindən təsdiqləndikdən sonra üzvlük aktivləşəcək.',
                    style: TextStyle(fontSize: 11.5, color: Colors.black54),
                  ),
                  if (isFull) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Qeyd: Dərnəkdə yer dolduğu üçün müraciətiniz növbə (gözləmə) siyahısına əlavə olunacaq.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Xeyr'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _kBrandRoyal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Bəli, müraciət et', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await SchoolApiService.instance.joinClubRequest(
      club['id'].toString(),
      studentId,
      asParent: true,
    );

    _snack(res['message']?.toString() ?? 'Müraciət göndərildi', ok: res['success'] == true);
    if (res['success'] == true) {
      _load(overrideStudentId: studentId);
    }
  }

  Future<void> _handleParentCancelRequest(Map<String, dynamic> club) async {
    final studentId = _selectedStudentId ?? _selectedStudent?['id']?.toString();
    if (studentId == null || studentId.isEmpty) return;

    final clubName = club['name']?.toString() ?? 'Dərnək';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Müraciəti ləğv et', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('"$clubName" dərnəyinə göndərilmiş qoşulma müraciətini ləğv etmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xeyr')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bəli, ləğv et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await SchoolApiService.instance.cancelClubJoinRequest(
      club['id'].toString(),
      studentId,
    );
    _snack(res['message']?.toString() ?? 'Müraciət ləğv edildi', ok: res['success'] == true);
    if (res['success'] == true) {
      _load(overrideStudentId: studentId);
    }
  }

  // ===========================================================================
  // STAFF / ROLE 34 / ADMIN ACTIONS: APPROVE / REJECT / CRUD / SCHEDULE / ENROLL
  // ===========================================================================

  Future<void> _handleApproveRequest(Map<String, dynamic> req) async {
    final csId = _int(req['clubStudentId'] ?? req['id']);
    if (csId <= 0) return;

    final res = await SchoolApiService.instance.approveClubJoinRequest(csId);
    _snack(res['message']?.toString() ?? 'Təsdiqləndi', ok: res['success'] == true);
    if (res['success'] == true) {
      _load();
    }
  }

  Future<void> _handleRejectRequest(Map<String, dynamic> req) async {
    final csId = _int(req['clubStudentId'] ?? req['id']);
    if (csId <= 0) return;

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Müraciətə imtina ver', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${req['studentName']} (${req['className']}) üçün "${req['clubName']}" müraciətini imtina edirsiniz.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'İmtina səbəbi (ixtiyari)',
                hintText: 'Valideynə göndəriləcək qeyd...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bağla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İmtina et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await SchoolApiService.instance.rejectClubJoinRequest(
      csId,
      reason: reasonCtrl.text.trim(),
    );
    _snack(res['message']?.toString() ?? 'İmtina edildi', ok: res['success'] == true);
    if (res['success'] == true) {
      _load();
    }
  }

  Future<void> _openEditClubModal(Map<String, dynamic>? club) async {
    final palette = AppPalette.of(context);
    final nameCtrl = TextEditingController(text: club?['name']?.toString() ?? '');
    final capacityCtrl = TextEditingController(text: (club?['maxCapacity'] ?? 20).toString());
    final priceCtrl = TextEditingController(text: _double(club?['price']).toStringAsFixed(0));

    String? selectedSubjectId = club?['subjectId']?.toString();
    String? selectedTeacherId = club?['teacherId']?.toString();
    String selectedGradeCat = (club?['gradeCategory'] ?? '1-4').toString();
    if (!['1-4', '5-11', 'all'].contains(selectedGradeCat)) {
      selectedGradeCat = 'all';
    }
    bool isActive = club == null ? true : (club['isActive'] != false);

    final subjects = (_meta['subjects'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final teachers = (_meta['teachers'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (selectedSubjectId != null && !subjects.any((s) => s['id'].toString() == selectedSubjectId)) {
      selectedSubjectId = null;
    }
    if (selectedTeacherId != null && !teachers.any((t) => t['id'].toString() == selectedTeacherId)) {
      selectedTeacherId = null;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.brandRoyal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          club == null ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded,
                          color: palette.brandRoyal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          club == null ? 'Yeni Dərnək Yarat' : 'Dərnəyə Düzəliş Et',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Dərnək adı *',
                      hintText: 'Məs: Şahmat, Robototexnika, Rəsm...',
                      prefixIcon: const Icon(Icons.stars_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedSubjectId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Fənn (İxtiyari)',
                      prefixIcon: const Icon(Icons.menu_book_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— Fənn seçilməyib (Müstəqil dərnək) —'),
                      ),
                      ...subjects.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s['id'].toString(),
                          child: Text(s['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => selectedSubjectId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedTeacherId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Dərnək rəhbəri (Müəllim)',
                      prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— Müəllim seçin —'),
                      ),
                      ...teachers.map(
                        (t) => DropdownMenuItem<String?>(
                          value: t['id'].toString(),
                          child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => selectedTeacherId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGradeCat,
                    decoration: InputDecoration(
                      labelText: 'Sinif kateqoriyası',
                      prefixIcon: const Icon(Icons.groups_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: '1-4', child: Text('1 - 4-cü siniflər')),
                      DropdownMenuItem(value: '5-11', child: Text('5 - 11-ci siniflər')),
                      DropdownMenuItem(value: 'all', child: Text('1 - 11-ci siniflər (Bütün siniflər)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedGradeCat = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Aylıq ödəniş (AZN)',
                            helperText: '0 = Ödənişsiz (Pulsuz)',
                            prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Maksimum şagird',
                            helperText: 'Kontingent limiti',
                            prefixIcon: const Icon(Icons.people_outline_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (v) => setModalState(() => isActive = v),
                    title: const Text('Dərnək aktivdir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Kataloqda valideyn və şagirdlərə göstərilsin', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandNavy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (nameCtrl.text.trim().isEmpty && selectedSubjectId == null) {
      _snack('Dərnək adı və ya fənn seçilməlidir', ok: false);
      return;
    }

    final res = await SchoolApiService.instance.saveClubWithResult(
      {
        'name': nameCtrl.text.trim(),
        'subjectId': selectedSubjectId ?? '',
        'teacherId': selectedTeacherId ?? '',
        'gradeCategory': selectedGradeCat,
        'maxCapacity': int.tryParse(capacityCtrl.text.trim()) ?? 20,
        'price': double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
        'isActive': isActive,
      },
      id: club?['id']?.toString(),
    );

    _snack(res['message']?.toString() ?? 'Yadda saxlanıldı', ok: res['success'] == true);
    if (res['success'] == true) _load();
  }

  Future<void> _openScheduleModal(Map<String, dynamic> club) async {
    final palette = AppPalette.of(context);
    final rooms = (_meta['rooms'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final timeSlots = (_meta['timeSlots'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final existingSchedules = (club['schedules'] as List? ?? [])
        .whereType<Map>()
        .map((s) => <String, String>{
              'day_of_week': (s['dayOfWeek'] ?? 1).toString(),
              'time_slot_id': (s['timeSlotId'] ?? '').toString(),
              'room_id': (s['roomId'] ?? '').toString(),
            })
        .toList();

    final rows = existingSchedules.isNotEmpty
        ? existingSchedules
        : <Map<String, String>>[
            {
              'day_of_week': '1',
              'time_slot_id': timeSlots.isNotEmpty ? timeSlots.first['id'].toString() : '',
              'room_id': rooms.isNotEmpty ? rooms.first['id'].toString() : '',
            }
          ];

    bool generateLessons = false;
    final startDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.86),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kBrandRoyal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: _kBrandRoyal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dərnək Cədvəli',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            club['name']?.toString() ?? '',
                            style: TextStyle(fontSize: 12.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          rows.add({
                            'day_of_week': '1',
                            'time_slot_id': timeSlots.isNotEmpty ? timeSlots.first['id'].toString() : '',
                            'room_id': rooms.isNotEmpty ? rooms.first['id'].toString() : '',
                          });
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Gün əlavə et'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (rows.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Cədvəl günü əlavə edilməyib.',
                              style: TextStyle(color: palette.textSecondary),
                            ),
                          ),
                        for (int i = 0; i < rows.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.bgBase,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.borderHairline),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: rows[i]['day_of_week'],
                                        decoration: const InputDecoration(
                                          labelText: 'Həftənin günü',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _dayNames.entries
                                            .map((e) => DropdownMenuItem(
                                                  value: e.key.toString(),
                                                  child: Text(e.value),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) setModalState(() => rows[i]['day_of_week'] = v);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                      onPressed: () => setModalState(() => rows.removeAt(i)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: timeSlots.any((t) => t['id'].toString() == rows[i]['time_slot_id'])
                                            ? rows[i]['time_slot_id']
                                            : (timeSlots.isNotEmpty ? timeSlots.first['id'].toString() : null),
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Saat (Zəng)',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        items: timeSlots
                                            .map((t) => DropdownMenuItem(
                                                  value: t['id'].toString(),
                                                  child: Text(
                                                    t['label']?.toString() ?? '',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12.5),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) setModalState(() => rows[i]['time_slot_id'] = v);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: rooms.any((r) => r['id'].toString() == rows[i]['room_id'])
                                            ? rows[i]['room_id']
                                            : (rooms.isNotEmpty ? rooms.first['id'].toString() : null),
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Otaq',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        items: rooms
                                            .map((r) => DropdownMenuItem(
                                                  value: r['id'].toString(),
                                                  child: Text(
                                                    r['name']?.toString() ?? '',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12.5),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) setModalState(() => rows[i]['room_id'] = v);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 20),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: generateLessons,
                          onChanged: (v) => setModalState(() => generateLessons = v == true),
                          title: const Text(
                            'Tədris ili sonuna qədər dərsləri E-Jurnalda yarat',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Seçilmiş başlanğıc tarixindən etibarən dərs cədvəlinə əlavə olunur',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                        if (generateLessons)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: startDateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Başlanğıc tarixi (YYYY-MM-DD)',
                                prefixIcon: Icon(Icons.event_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.brandNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Cədvəli yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;

    final payloadSchedules = rows
        .map((r) => {
              'day_of_week': int.tryParse(r['day_of_week'] ?? '1') ?? 1,
              'time_slot_id': int.tryParse(r['time_slot_id'] ?? '0') ?? 0,
              'room_id': int.tryParse(r['room_id'] ?? '0') ?? 0,
            })
        .where((r) => r['time_slot_id']! > 0 && r['room_id']! > 0)
        .toList();

    final res = await SchoolApiService.instance.saveClubSchedule(
      club['id'].toString(),
      schedules: payloadSchedules,
      generateLessons: generateLessons,
      startDate: startDateCtrl.text.trim(),
    );

    _snack(res['message']?.toString() ?? 'Cədvəl yeniləndi', ok: res['success'] == true);
    if (res['success'] == true) _load();
  }

  Future<void> _openEnrollStudentModal(Map<String, dynamic> club) async {
    final palette = AppPalette.of(context);
    final allStudents = await SchoolApiService.instance.fetchStudents();
    if (!mounted) return;

    final activeIds = (club['activeStudents'] as List? ?? [])
        .whereType<Map>()
        .map((s) => s['id'].toString())
        .toSet();

    String filterQ = '';
    final selectedIds = <String>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final visible = allStudents.where((s) {
            final sid = (s['numericId'] ?? s['id']).toString().replaceAll(RegExp(r'[^0-9]'), '');
            if (activeIds.contains(sid)) return false;
            if (filterQ.trim().isEmpty) return true;
            final q = filterQ.toLowerCase();
            final name = (s['fullName'] ?? s['name'] ?? '').toString().toLowerCase();
            final cls = (s['className'] ?? s['grade'] ?? '').toString().toLowerCase();
            return name.contains(q) || cls.contains(q);
          }).take(80).toList();

          return Container(
            height: MediaQuery.sizeOf(ctx).height * 0.80,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
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
                  Text(
                    'Şagird Təyin Et — ${club['name']}',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seçilmiş şagirdlər birbaşa aktiv üzv kimi dərnəyə əlavə olunur (limit və cədvəl toqquşması yoxlanılır).',
                    style: TextStyle(fontSize: 12, color: palette.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setModalState(() => filterQ = v),
                    decoration: InputDecoration(
                      hintText: 'Şagird adı və ya sinif axtar...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, idx) {
                        final st = visible[idx];
                        final sid = (st['numericId'] ?? st['id']).toString().replaceAll(RegExp(r'[^0-9]'), '');
                        final name = (st['fullName'] ?? st['name'] ?? 'Şagird').toString();
                        final cls = (st['className'] ?? st['grade'] ?? '').toString();
                        final checked = selectedIds.contains(sid);
                        return CheckboxListTile(
                          dense: true,
                          value: checked,
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true) {
                                selectedIds.add(sid);
                              } else {
                                selectedIds.remove(sid);
                              }
                            });
                          },
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          subtitle: cls.isNotEmpty ? Text('Sinif: $cls', style: const TextStyle(fontSize: 12)) : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: selectedIds.isEmpty ? null : () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      'Seçilmiş şagirdləri əlavə et (${selectedIds.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed != true || selectedIds.isEmpty) return;

    final res = await SchoolApiService.instance.enrollClubStudents(
      club['id'].toString(),
      selectedIds.toList(),
    );
    _snack(res['message']?.toString() ?? 'Əlavə edildi', ok: res['success'] == true);
    if (res['success'] == true) _load();
  }

  Future<void> _deleteClub(Map<String, dynamic> club) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Dərnəyi sil', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('"${club['name']}" dərnəyini və onunla bağlı cədvəlləri silmək istədiyinizə əminsiniz?'),
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
    final ok = await SchoolApiService.instance.deleteClub(club['id'].toString());
    _snack(ok ? 'Dərnək silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) _load();
  }

  void _showClubDetailsSheet(Map<String, dynamic> club) {
    final palette = AppPalette.of(context);
    final activeStudents = (club['activeStudents'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final pendingStudents = (club['pendingStudents'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final schedules = (club['schedules'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.86),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.borderHairline),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                      child: Icon(Icons.stars_rounded, color: palette.brandRoyal, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            club['name']?.toString() ?? 'Dərnək',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dərnək rəhbəri: ${club['instructor'] ?? 'Təyin olunmayıb'}',
                            style: TextStyle(color: palette.brandAzure, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: club['priceLabel']?.toString() ?? 'Ödənişsiz',
                      color: club['isFree'] == true ? AppColors.emerald : _kBrandRoyal,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                _detailRow('Sinif kateqoriyası', club['gradeCategoryLabel']?.toString() ?? '1-11 siniflər', palette),
                _detailRow('Tədris ili', '${club['academicYearTitle'] ?? '2025-2026'} Tədris ili', palette),
                _detailRow(
                  'Kontingent (Aktiv üzv)',
                  '${_int(club['members'])} / ${_int(club['maxCapacity'])} nəfər',
                  palette,
                  isBold: true,
                ),
                if (schedules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Həftəlik Dərs Cədvəli',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  for (final sch in schedules)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: palette.bgBase,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: _kBrandRoyal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${sch['dayName']} • ${sch['timeRange']}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kBrandRoyal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sch['roomName']?.toString() ?? 'Otaq',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kBrandRoyal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (_isStaff && pendingStudents.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Gözləyən Müraciətlər (${pendingStudents.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(height: 8),
                  for (final ps in pendingStudents)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ps['name']}${ps['className']?.toString().isNotEmpty == true ? ' (${ps['className']})' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E)),
                                ),
                                if (ps['parentName']?.toString().isNotEmpty == true)
                                  Text(
                                    'Valideyn: ${ps['parentName']} ${ps['parentPhone'] ?? ''}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Təsdiqlə',
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.emerald),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleApproveRequest(ps);
                            },
                          ),
                          IconButton(
                            tooltip: 'İmtina et',
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleRejectRequest({
                                ...ps,
                                'clubName': club['name'],
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
                if (_isStaff && activeStudents.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Aktiv Üzvlər (${activeStudents.length})',
                    style: TextStyle(fontSize: 13, color: palette.textSecondary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final s in activeStudents)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: palette.bgBase,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: AppColors.emerald),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${s['name']}${s['className']?.toString().isNotEmpty == true ? ' (${s['className']})' : ''}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Dərnəkdən çıxar',
                            icon: const Icon(Icons.person_remove_rounded, size: 17, color: AppColors.danger),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final ok = await SchoolApiService.instance.removeClubStudent(
                                club['id'].toString(),
                                s['id'].toString(),
                              );
                              _snack(ok ? 'Şagird dərnəkdən çıxarıldı' : 'Xəta baş verdi', ok: ok);
                              if (ok) _load();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
                if (_isStaff) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openScheduleModal(club);
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 17),
                        label: const Text('Cədvəl'),
                      ),
                      if (_canEnrollClub)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openEnrollStudentModal(club);
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                          label: const Text('Şagird əlavə et'),
                        ),
                      if (_canEditClub)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openEditClubModal(club);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 17),
                          label: const Text('Düzəliş et'),
                        ),
                      if (_canDeleteClub)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteClub(club);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 17),
                          label: const Text('Sil'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, AppPalette palette, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI BUILDERS: HERO CARD, PARENT CHILD BAR, CATALOG CARDS, STAFF VIEWS
  // ===========================================================================

  Widget _buildCatalogHeroCard(AppPalette palette) {
    final yearTitle = (_meta['academicYear'] is Map ? _meta['academicYear']['title'] : null)?.toString() ?? '2025-2026';
    final activeCount = _int(_studentLimits['activeCount']);
    final maxActive = _int(_studentLimits['maxActive'] ?? 2);
    final selName = _selectedStudent?['name']?.toString() ?? '';
    final selClass = _selectedStudent?['className']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF38BDF8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Məktəb Dərnəkləri Kataloqu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dərsdənkənar dərnəklər, həftəlik cədvəllər və üzvlük müraciətləri',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroBadge(
                icon: Icons.calendar_today_rounded,
                text: '$yearTitle Tədris ili',
                bg: Colors.white.withValues(alpha: 0.10),
                fg: Colors.white,
              ),
              if (selName.isNotEmpty)
                _heroBadge(
                  icon: Icons.person_rounded,
                  text: '${_isParent ? 'Övladınız' : 'Şagird'}: $selName${selClass.isNotEmpty ? ' ($selClass)' : ''}',
                  bg: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                  fg: const Color(0xFFBAE6FD),
                ),
              _heroBadge(
                icon: Icons.check_circle_rounded,
                text: 'Aktiv dərnəklər: $activeCount / $maxActive',
                bg: const Color(0xFF10B981).withValues(alpha: 0.22),
                fg: const Color(0xFF6EE7B7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBadge({
    required IconData icon,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildParentChildAndLimitsBar(AppPalette palette) {
    final freeCount = _int(_studentLimits['freeCount']);
    final maxFree = _int(_studentLimits['maxFree'] ?? 1);
    final paidCount = _int(_studentLimits['paidCount']);
    final maxPaid = _int(_studentLimits['maxPaid'] ?? 2);
    final totalCount = _int(_studentLimits['totalCount']);
    final maxTotal = _int(_studentLimits['maxTotal'] ?? 3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_children.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.child_care_rounded, size: 17, color: _kBrandRoyal),
                const SizedBox(width: 6),
                Text(
                  'Övlad seçin:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _children.map((ch) {
                  final cid = ch['id'].toString();
                  final isSelected = cid == _selectedStudentId;
                  final cName = ch['name']?.toString() ?? 'Şagird';
                  final cClass = ch['className']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        if (!isSelected) {
                          setState(() => _selectedStudentId = cid);
                          _load(overrideStudentId: cid);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _kBrandRoyal : palette.bgBase,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? _kBrandRoyal : palette.borderHairline,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 15,
                              color: isSelected ? Colors.white : palette.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : palette.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            if (cClass.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : _kBrandRoyal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cClass,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : _kBrandRoyal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _limitChip(
                icon: Icons.card_giftcard_rounded,
                label: 'Pulsuz dərnək: $freeCount / $maxFree',
                color: const Color(0xFF0D9488),
              ),
              _limitChip(
                icon: Icons.payments_outlined,
                label: 'Pullu dərnək: $paidCount / $maxPaid',
                color: const Color(0xFF2563EB),
              ),
              _limitChip(
                icon: Icons.layers_rounded,
                label: 'Cəmi müraciət/üzvlük: $totalCount / $maxTotal',
                color: const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _limitChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Dərnək adı və ya müəllim axtar...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: palette.surface1,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final gf in _gradeCategoryFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(gf['label']!),
                      selected: _selectedGradeCategory == gf['key'],
                      onSelected: (_) => setState(() => _selectedGradeCategory = gf['key']!),
                      selectedColor: palette.brandNavy,
                      labelStyle: TextStyle(
                        color: _selectedGradeCategory == gf['key'] ? Colors.white : palette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                      backgroundColor: palette.surface1,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const VerticalDivider(width: 12),
                for (final sc in _subjectCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(sc),
                      selected: _selectedSubjectCategory == sc,
                      onSelected: (_) => setState(() => _selectedSubjectCategory = sc),
                      selectedColor: palette.brandRoyal,
                      labelStyle: TextStyle(
                        color: _selectedSubjectCategory == sc ? Colors.white : palette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                      backgroundColor: palette.surface1,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogClubCard(Map<String, dynamic> club, AppPalette palette, {bool isStaffManagement = false}) {
    final isFree = club['isFree'] == true;
    final priceLabel = club['priceLabel']?.toString() ?? (isFree ? 'Ödənişsiz' : '${club['price']} AZN / ay');
    final gradeCatLabel = club['gradeCategoryLabel']?.toString() ?? '1-11 siniflər';
    final members = _int(club['members']);
    final maxCap = _int(club['maxCapacity']);
    final hasLimit = club['hasLimit'] == true && maxCap > 0;
    final remainingSeats = _int(club['remainingSeats']);
    final isFull = club['isFull'] == true;
    final pendingCnt = _int(club['pendingCount']);
    final myStatus = club['myStatus']?.toString();
    final schedules = (club['schedules'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final freeCount = _int(_studentLimits['freeCount']);
    final maxFree = _int(_studentLimits['maxFree'] ?? 1);
    final paidCount = _int(_studentLimits['paidCount']);
    final maxPaid = _int(_studentLimits['maxPaid'] ?? 2);
    final totalCount = _int(_studentLimits['totalCount']);
    final maxTotal = _int(_studentLimits['maxTotal'] ?? 3);

    bool isLimitReached = false;
    String limitMessage = '';
    if (totalCount >= maxTotal) {
      isLimitReached = true;
      limitMessage = 'Maksimum $maxTotal dərnək limiti dolub (1 pulsuz, 2 pullu)';
    } else if (isFree && freeCount >= maxFree) {
      isLimitReached = true;
      limitMessage = 'Pulsuz dərnək limiti dolub (maks. $maxFree)';
    } else if (!isFree && paidCount >= maxPaid) {
      isLimitReached = true;
      limitMessage = 'Pullu dərnək limiti dolub (maks. $maxPaid)';
    }

    return ModernCard(
      onTap: () => _showClubDetailsSheet(club),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Accent Strip
          Container(
            height: 5,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: isFree
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.bgBase,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.signal_cellular_alt_rounded, size: 13, color: palette.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            gradeCatLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: club['category']?.toString() ?? 'Akademik',
                      color: palette.brandRoyal,
                      fontSize: 10.5,
                    ),
                    if (club['isActive'] == false) ...[
                      const SizedBox(width: 6),
                      const StatusBadge(label: 'Deaktiv', color: AppColors.danger, fontSize: 10.5),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFree
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isFree ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        priceLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isFree ? const Color(0xFF059669) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Club Title
                Text(
                  club['name']?.toString() ?? 'Dərnək',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Teacher & Capacity Row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.bgBase,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.borderHairline),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _kBrandRoyal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_pin_rounded, color: _kBrandRoyal, size: 19),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DƏRNƏK RƏHBƏRİ',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textTertiary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  club['instructor']?.toString() ?? 'Təyin olunmayıb',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Icon(Icons.groups_rounded, size: 16, color: palette.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Kontingent: ',
                            style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            hasLimit ? '$members / $maxCap nəfər' : '$members üzv',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                          ),
                          if (isStaffManagement && pendingCnt > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$pendingCnt gözləyir',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFull
                                  ? 'Dolub (Gözləmədə)'
                                  : (hasLimit ? '$remainingSeats yer qalıb' : 'Açıqdır'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isFull ? const Color(0xFFD97706) : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Weekly Schedule Section
                Text(
                  'HƏFTƏLİK DƏRS CƏDVƏLİ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: palette.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                if (schedules.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.bgBase,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.borderHairline),
                    ),
                    child: Text(
                      'Hələlik cədvəl təyin edilməyib',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: palette.textSecondary),
                    ),
                  )
                else
                  Column(
                    children: schedules.map((sch) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: palette.bgBase,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: _kBrandRoyal),
                            const SizedBox(width: 6),
                            Text(
                              sch['dayName']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sch['timeRange']?.toString() ?? '',
                                style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kBrandRoyal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sch['roomName']?.toString() ?? 'Otaq',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _kBrandRoyal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 12),

                // Footer Action Area
                if (isStaffManagement)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openScheduleModal(club),
                          icon: const Icon(Icons.calendar_month_rounded, size: 15),
                          label: const Text('Cədvəl', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_canEnrollClub) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _openEnrollStudentModal(club),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                            label: const Text('Şagird +', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (_canEditClub) ...[
                        IconButton.outlined(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Düzəliş et',
                          onPressed: () => _openEditClubModal(club),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (_canDeleteClub)
                        IconButton.outlined(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Sil',
                          style: IconButton.styleFrom(foregroundColor: AppColors.danger),
                          onPressed: () => _deleteClub(club),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        ),
                    ],
                  )
                else if (myStatus == 'active')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF047857)),
                        SizedBox(width: 8),
                        Text(
                          'Qoşulub (Fəal üzv)',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (myStatus == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFB45309)),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Təsdiq gözlənilir',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isParent) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleParentCancelRequest(club),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Ləğv et', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        ),
                      ],
                    ],
                  )
                else if (_isParent)
                  if (isLimitReached)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: palette.bgBase,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded, size: 16, color: palette.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              limitMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kBrandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _handleParentJoin(club),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text(
                        isFull ? 'Növbəyə yazıl (Qoşul)' : 'Qoşul',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    )
                else
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _snack(
                      'Dərnəyə yalnız valideyn öz hesabından müraciət edə bilər.',
                      ok: false,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                      decoration: BoxDecoration(
                        color: palette.bgBase,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 16, color: palette.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Valideyn müraciəti tələb olunur',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPendingRequestsView(AppPalette palette) {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done_all_rounded, size: 42, color: AppColors.emerald),
              ),
              const SizedBox(height: 14),
              const Text(
                'Gözləyən müraciət yoxdur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Valideynlər tərəfindən göndərilmiş bütün dərnək müraciətləri cavablandırılıb.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
        itemCount: _pendingRequests.length,
        itemBuilder: (_, idx) {
          final req = _pendingRequests[idx];
          final isFree = req['clubIsFree'] == true;
          return ModernCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_top_rounded, size: 13, color: Color(0xFFB45309)),
                          SizedBox(width: 4),
                          Text(
                            'Təsdiq gözləyir',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (req['createdAt']?.toString().isNotEmpty == true)
                      Text(
                        req['createdAt'].toString(),
                        style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _kBrandRoyal.withValues(alpha: 0.12),
                      child: const Icon(Icons.person_rounded, color: _kBrandRoyal),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  req['studentName']?.toString() ?? 'Şagird',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (req['className']?.toString().isNotEmpty == true) ...[
                                const SizedBox(width: 6),
                                StatusBadge(
                                  label: req['className'].toString(),
                                  color: _kBrandRoyal,
                                  fontSize: 10.5,
                                ),
                              ],
                            ],
                          ),
                          if (req['parentName']?.toString().isNotEmpty == true)
                            Text(
                              'Valideyn: ${req['parentName']}${req['parentPhone']?.toString().isNotEmpty == true ? ' • ${req['parentPhone']}' : ''}',
                              style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.bgBase,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.borderHairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, size: 18, color: _kBrandRoyal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req['clubName']?.toString() ?? 'Dərnək',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                            Text(
                              'Rəhbər: ${req['clubTeacher'] ?? '—'}',
                              style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: req['clubPriceLabel']?.toString() ?? 'Ödənişsiz',
                        color: isFree ? AppColors.emerald : _kBrandRoyal,
                        fontSize: 11,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        onPressed: () => _handleRejectRequest(req),
                        icon: const Icon(Icons.close_rounded, size: 17),
                        label: const Text('İmtina et', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        onPressed: () => _handleApproveRequest(req),
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Təsdiqlə', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffKpiStrip(AppPalette palette) {
    final totalClubs = _clubs.length;
    final activeClubs = _clubs.where((c) => c['isActive'] != false).length;
    final totalEnrolled = _clubs.fold<int>(0, (sum, c) => sum + _int(c['members']));
    final pendingCnt = _pendingRequests.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _kpiCard('Cəmi Dərnək', '$totalClubs ($activeClubs aktiv)', Icons.stars_rounded, _kBrandRoyal, palette),
          const SizedBox(width: 8),
          _kpiCard('Aktiv Üzvlər', '$totalEnrolled şagird', Icons.groups_rounded, AppColors.emerald, palette),
          const SizedBox(width: 8),
          _kpiCard(
            'Müraciətlər',
            '$pendingCnt gözləyir',
            Icons.notifications_active_rounded,
            const Color(0xFFD97706),
            palette,
            onTap: () => setState(() => _staffTabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    AppPalette palette, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: palette.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final clubs = _filteredClubs;

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: _isStaff && _canCreateClub && _staffTabIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _openEditClubModal(null),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Yeni dərnək', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: Text(
          _isStaff ? 'Dərnəklərin İdarəetməsi' : 'Məktəb Dərnəkləri Kataloqu',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        elevation: 0,
        actions: [
          if (_isStaff)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClubJournalScreen()),
                );
              },
              icon: const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF6EE7B7)),
              label: const Text(
                'Jurnal',
                style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          IconButton(
            tooltip: 'Yenilə',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(overrideStudentId: _selectedStudentId),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCenter(
              child: _isStaff
                  ? Column(
                      children: [
                        _buildStaffKpiStrip(palette),
                        // Staff Mode Tabs
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Row(
                            children: [
                              _staffTabPill(
                                index: 0,
                                icon: Icons.list_alt_rounded,
                                label: 'Dərnəklər (${_clubs.length})',
                                palette: palette,
                              ),
                              const SizedBox(width: 8),
                              _staffTabPill(
                                index: 1,
                                icon: Icons.pending_actions_rounded,
                                label: 'Müraciətlər (${_pendingRequests.length})',
                                badgeCount: _pendingRequests.length,
                                palette: palette,
                              ),
                              const SizedBox(width: 8),
                              _staffTabPill(
                                index: 2,
                                icon: Icons.visibility_rounded,
                                label: 'Kataloq',
                                palette: palette,
                              ),
                            ],
                          ),
                        ),
                        if (_staffTabIndex == 1)
                          Expanded(child: _buildStaffPendingRequestsView(palette))
                        else ...[
                          _buildSearchAndFilterBar(palette),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _load,
                              child: clubs.isEmpty
                                  ? ListView(
                                      children: [
                                        const SizedBox(height: 60),
                                        Center(
                                          child: Text(
                                            'Axtarışa uyğun dərnək tapılmadı.',
                                            style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(bottom: 90),
                                      itemCount: clubs.length,
                                      itemBuilder: (_, idx) => _buildCatalogClubCard(
                                        clubs[idx],
                                        palette,
                                        isStaffManagement: _staffTabIndex == 0,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(overrideStudentId: _selectedStudentId),
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildCatalogHeroCard(palette)),
                          if (_isParent)
                            SliverToBoxAdapter(child: _buildParentChildAndLimitsBar(palette)),
                          SliverToBoxAdapter(child: _buildSearchAndFilterBar(palette)),
                          if (clubs.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'Hazırda uyğun aktiv dərnək tapılmadı.',
                                    style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.only(bottom: 40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, idx) => _buildCatalogClubCard(
                                    clubs[idx],
                                    palette,
                                    isStaffManagement: false,
                                  ),
                                  childCount: clubs.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _staffTabPill({
    required int index,
    required IconData icon,
    required String label,
    required AppPalette palette,
    int badgeCount = 0,
  }) {
    final selected = _staffTabIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _staffTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? palette.brandNavy : palette.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? palette.brandNavy : palette.borderHairline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? Colors.white
                    : (badgeCount > 0 ? const Color(0xFFD97706) : palette.textSecondary),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
