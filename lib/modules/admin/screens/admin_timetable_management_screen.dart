import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';

class AdminTimetableManagementScreen extends StatefulWidget {
  const AdminTimetableManagementScreen({super.key});

  @override
  State<AdminTimetableManagementScreen> createState() => _AdminTimetableManagementScreenState();
}

class _AdminTimetableManagementScreenState extends State<AdminTimetableManagementScreen> {
  bool _isLoading = true;
  bool _isLessonsLoading = false;
  bool _isTemplateMode = false;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _timeSlots = [];
  List<Map<String, dynamic>> _lessons = [];

  String? _classId;
  DateTime _selectedDate = DateTime.now();

  static const _weekDayShort = ['B.E', 'Ç.A', 'Ç', 'C.A', 'C', 'Ş', 'B'];
  static const _monthNames = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
    'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _weekStart {
    final d = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  int get _selectedDayOfWeek => _selectedDate.weekday;

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SchoolApiService.instance.fetchClassesFull(),
        SchoolApiService.instance.fetchSubjects(),
        SchoolApiService.instance.fetchTeachers(),
        SchoolApiService.instance.fetchRooms(),
        SchoolApiService.instance.fetchTimeSlots(),
      ]);
      if (!mounted) return;
      _classes = results[0];
      _subjects = results[1];
      _teachers = results[2];
      _rooms = results[3];
      _timeSlots = results[4];
      _classId ??= _classes.isNotEmpty ? _asString(_classes.first['id']) : null;
      await _loadLessons();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Məlumatlar yüklənərkən xəta: $e', ok: false);
    }
  }

  Future<void> _loadLessons() async {
    if (_classId == null) {
      setState(() => _lessons = []);
      return;
    }
    setState(() => _isLessonsLoading = true);
    try {
      final weekStartStr = '${_weekStart.year}-${_weekStart.month.toString().padLeft(2, '0')}-${_weekStart.day.toString().padLeft(2, '0')}';
      final data = await SchoolApiService.instance.fetchSchedules(
        classId: _classId,
        weekStart: _isTemplateMode ? null : weekStartStr,
        isTemplate: _isTemplateMode,
      );
      if (!mounted) return;
      setState(() {
        _lessons = data;
        _isLessonsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLessonsLoading = false);
      _snack('Dərslər yüklənərkən xəta: $e', ok: false);
    }
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), backgroundColor: ok ? AppColors.emerald : AppColors.danger),
    );
  }

  List<Map<String, dynamic>> get _dayLessons {
    final list = _lessons.where((l) => _asInt(l['dayOfWeek'] ?? l['day_of_week']) == _selectedDayOfWeek).toList();
    list.sort((a, b) => _asString(a['startTime'] ?? a['start_time']).compareTo(_asString(b['startTime'] ?? b['start_time'])));
    return list;
  }

  void _shiftWeek(int weeks) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: 7 * weeks)));
    _loadLessons();
  }

  void _jumpToday() {
    setState(() => _selectedDate = DateTime.now());
    _loadLessons();
  }

  Future<void> _showForm({Map<String, dynamic>? lesson}) async {
    final palette = AppPalette.of(context);
    int day = _asInt(lesson?['dayOfWeek'] ?? lesson?['day_of_week'], fallback: _selectedDayOfWeek);
    String? timeSlotId = _asString(lesson?['timeSlotId'] ?? lesson?['time_slot_id']);
    String? subjectId = _asString(lesson?['subjectId'] ?? lesson?['subject_id']);
    String? teacherId = _asString(lesson?['teacherId'] ?? lesson?['teacher_id']);
    String? roomId = _asString(lesson?['roomId'] ?? lesson?['room_id']);
    if (timeSlotId.isEmpty) timeSlotId = null;
    if (subjectId.isEmpty) subjectId = null;
    if (teacherId.isEmpty) teacherId = null;
    if (roomId.isEmpty) roomId = null;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 22),
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
                  Text(
                    lesson == null ? 'Yeni dərs əlavə et' : 'Dərsi düzəliş et',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: day,
                    decoration: _deco('Həftənin günü'),
                    items: List.generate(6, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text(_dayName(d)))).toList(),
                    onChanged: (v) => setSheet(() => day = v ?? 1),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: timeSlotId,
                    decoration: _deco('Zəng saatı *'),
                    isExpanded: true,
                    items: _timeSlots.map((s) {
                      final pName = _asString(s['periodName'] ?? s['lesson_number']);
                      final st = _asString(s['startTime'] ?? s['start_time']);
                      final et = _asString(s['endTime'] ?? s['end_time']);
                      return DropdownMenuItem(
                        value: _asString(s['id']),
                        child: Text('$pName • $st - $et', style: const TextStyle(fontSize: 12.5)),
                      );
                    }).toList(),
                    onChanged: (v) => setSheet(() => timeSlotId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: subjectId,
                    decoration: _deco('Fənn *'),
                    isExpanded: true,
                    items: _subjects.map((s) => DropdownMenuItem(
                      value: _asString(s['id']),
                      child: Text(_asString(s['name'] ?? s['title']), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                    )).toList(),
                    onChanged: (v) => setSheet(() => subjectId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: teacherId,
                    decoration: _deco('Müəllim'),
                    isExpanded: true,
                    items: _teachers.map((t) => DropdownMenuItem(
                      value: _asString(t['id']),
                      child: Text(_asString(t['name']), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                    )).toList(),
                    onChanged: (v) => setSheet(() => teacherId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: roomId,
                    decoration: _deco('Otaq'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Otaq təyin edilməyib')),
                      ..._rooms.map((r) => DropdownMenuItem(
                            value: _asString(r['id']),
                            child: Text('${_asString(r['name'] ?? r['code'])} (${_asString(r['number'] ?? r['room_number'])})',
                                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                          )),
                    ],
                    onChanged: (v) => setSheet(() => roomId = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.brandNavy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
    if (timeSlotId == null || subjectId == null) {
      _snack('Zəng saatı və fənn tələb olunur', ok: false);
      return;
    }
    final ok = await SchoolApiService.instance.saveSchedule({
      'classId': _classId,
      'class_id': _classId,
      'subjectId': subjectId,
      'subject_id': subjectId,
      'teacherId': teacherId,
      'teacher_id': teacherId,
      'roomId': roomId,
      'room_id': roomId,
      'timeSlotId': timeSlotId,
      'time_slot_id': timeSlotId,
      'dayOfWeek': day,
      'day_of_week': day,
    }, id: lesson != null ? _asString(lesson['id']) : null);

    _snack(ok ? 'Dərs cədvələ əlavə edildi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) await _loadLessons();
  }

  Future<void> _delete(Map<String, dynamic> lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dərsi sil'),
        content: Text('${_asString(lesson['subjectName'] ?? lesson['subject'])} dərsi cədvəldən silinsin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SchoolApiService.instance.deleteSchedule(_asString(lesson['id']));
    _snack(ok ? 'Dərs cədvəldən silindi' : 'Əməliyyat alınmadı', ok: ok);
    if (ok) await _loadLessons();
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  String _dayName(int d) => switch (d) {
        1 => 'Bazar ertəsi',
        2 => 'Çərşənbə axşamı',
        3 => 'Çərşənbə',
        4 => 'Cümə axşamı',
        5 => 'Cümə',
        6 => 'Şənbə',
        _ => 'Bazar',
      };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final canManage = session.can('gopanel.academic.schedules.manage');

    final selectedClass = _classes.where((c) => _asString(c['id']) == _classId).toList();
    final className = selectedClass.isNotEmpty ? _asString(selectedClass.first['className'] ?? selectedClass.first['class_name']) : '';

    final dayLessons = _dayLessons;
    final totalWeeklyLessons = _lessons.length;
    final distinctSubjects = _lessons.map((l) => _asString(l['subjectId'] ?? l['subject_id'])).where((s) => s.isNotEmpty).toSet().length;
    final distinctTeachers = _lessons.map((l) => _asString(l['teacherId'] ?? l['teacher_id'])).where((t) => t.isNotEmpty).toSet().length;

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Dərs əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: const Text('Cədvəl', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenilə',
            onPressed: () async {
              await _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mode selector & class picker
                Container(
                  color: palette.surface1,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _classId,
                              decoration: InputDecoration(
                                labelText: 'Sinif seçin',
                                isDense: true,
                                filled: true,
                                fillColor: palette.surface2,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              isExpanded: true,
                              items: _classes.map((c) {
                                final name = _asString(c['className'] ?? c['class_name']);
                                return DropdownMenuItem(value: _asString(c['id']), child: Text(name, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (v) async {
                                setState(() => _classId = v);
                                await _loadLessons();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Template mode toggle
                          FilterChip(
                            label: Text(_isTemplateMode ? 'Şablon Cədvəl' : 'Canlı Cədvəl',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _isTemplateMode ? Colors.white : palette.brandRoyal,
                                )),
                            selected: _isTemplateMode,
                            selectedColor: palette.brandNavy,
                            checkmarkColor: Colors.white,
                            onSelected: (val) {
                              setState(() => _isTemplateMode = val);
                              _loadLessons();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar week selector (when not in template mode)
                if (!_isTemplateMode) _calendarHeader(palette),

                // KPI Stat cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: StatCardRow(
                    columns: 2,
                    children: [
                      StatCard(
                        value: '$totalWeeklyLessons',
                        label: _isTemplateMode ? 'Şablon Dərslər' : 'Həftəlik Dərslər',
                        icon: Icons.calendar_month_rounded,
                        color: palette.brandRoyal,
                      ),
                      StatCard(
                        value: '${dayLessons.length}',
                        label: 'Seçilmiş Gün',
                        icon: Icons.today_rounded,
                        color: AppColors.emerald,
                      ),
                      StatCard(
                        value: '$distinctSubjects',
                        label: 'Fənn Sayı',
                        icon: Icons.auto_stories_rounded,
                        color: palette.brandAzure,
                      ),
                      StatCard(
                        value: '$distinctTeachers',
                        label: 'Müəllim Sayı',
                        icon: Icons.school_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),

                // Day lessons list
                Expanded(
                  child: _isLessonsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadLessons,
                          child: ResponsiveCenter(
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              children: [
                                Row(
                                  children: [
                                    Text(_dayName(_selectedDayOfWeek),
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: palette.textPrimary)),
                                    const SizedBox(width: 6),
                                    Text('• $className', style: TextStyle(fontSize: 12.5, color: palette.textSecondary)),
                                    const Spacer(),
                                    StatusBadge(label: '${dayLessons.length} dərs', color: palette.brandRoyal, fontSize: 10),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (dayLessons.isEmpty)
                                  _emptyDay(palette, canManage)
                                else
                                  for (final l in dayLessons) ...[
                                    _lessonCard(palette, l, canManage),
                                    const SizedBox(height: 10),
                                  ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _calendarHeader(AppPalette palette) {
    final weekStart = _weekStart;
    final today = DateTime.now();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _shiftWeek(-1),
                icon: Icon(Icons.chevron_left_rounded, color: palette.textSecondary),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_monthNames[weekStart.month - 1]} ${weekStart.year}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: palette.textPrimary),
                    ),
                    Text('Həftəlik dərs qrafiki', style: TextStyle(fontSize: 10.5, color: palette.textTertiary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _jumpToday,
                style: TextButton.styleFrom(foregroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Bugün', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _shiftWeek(1),
                icon: Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(6, (i) {
              final date = weekStart.add(Duration(days: i));
              final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
              final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
              final hasLessons = _lessons.any((l) => _asInt(l['dayOfWeek'] ?? l['day_of_week']) == date.weekday);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.brandNavy : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weekDayShort[date.weekday - 1],
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white70 : palette.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : (isToday ? palette.brandRoyal : palette.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasLessons
                                ? (isSelected ? Colors.white : AppColors.emerald)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _emptyDay(AppPalette palette, bool canManage) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 40, color: palette.textTertiary),
          const SizedBox(height: 10),
          Text('Bu gün üçün dərs təyin edilməyib', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.textSecondary)),
          const SizedBox(height: 4),
          Text('Yeni dərs əlavə etmək üçün aşağıdakı düyməni sıxın.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: palette.textTertiary)),
          if (canManage) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showForm(),
              style: FilledButton.styleFrom(
                backgroundColor: palette.brandRoyal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Dərs əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lessonCard(AppPalette palette, Map<String, dynamic> l, bool canManage) {
    final sTime = _asString(l['startTime'] ?? l['start_time']);
    final eTime = _asString(l['endTime'] ?? l['end_time']);
    final subject = _asString(l['subjectName'] ?? l['subject_name'] ?? l['subject'], fallback: 'Fənn');
    final teacher = _asString(l['teacherName'] ?? l['teacher_name'] ?? l['teacher'], fallback: 'Fənn Müəllimi');
    final room = _asString(l['roomName'] ?? l['room_name'] ?? l['room'], fallback: 'Otaq təyin edilməyib');

    return ModernCard(
      padding: const EdgeInsets.all(14),
      onTap: canManage ? () => _showForm(lesson: l) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.brandRoyal.withValues(alpha: 0.16), palette.brandAzure.withValues(alpha: 0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(sTime, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: palette.brandRoyal)),
                Text(eTime, style: TextStyle(fontSize: 10, color: palette.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 13, color: palette.brandRoyal),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(teacher, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 13, color: palette.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(room, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _showForm(lesson: l),
              icon: Icon(Icons.edit_rounded, size: 18, color: palette.brandAzure),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _delete(l),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
