import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/responsive.dart';
import '../../journal/screens/api_journal_screen.dart';

class TeachersManagementScreen extends StatefulWidget {
  const TeachersManagementScreen({super.key});

  @override
  State<TeachersManagementScreen> createState() => _TeachersManagementScreenState();
}

class _TeachersManagementScreenState extends State<TeachersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  List<Map<String, dynamic>> _teachers = [];
  Map<String, dynamic> _kpi = {};
  Map<String, dynamic> _permissions = {};
  List<Map<String, dynamic>> _filials = [];
  List<Map<String, dynamic>> _academicYears = [];

  int? _selectedFilialId;
  int? _selectedAcademicYearId;
  String _selectedStatus = 'all'; // all, with_workload, active, maternity, terminated

  // Header Print/Export section state
  bool _isPrintCardExpanded = false;
  int? _printTeacherId;
  String _printFormat = 'single'; // single, full

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  Color _parseColor(String? hexString, {Color fallback = const Color(0xFF2563EB)}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
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
    try {
      final res = await SchoolApiService.instance.fetchTeachersPage(
        filialId: _selectedFilialId,
        academicYearId: _selectedAcademicYearId,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        query: _searchController.text.trim(),
      );

      final items = res['items'] as List<Map<String, dynamic>>? ?? [];
      final kpi = res['kpi'] as Map<String, dynamic>? ?? {};
      final filters = res['filters'] as Map<String, dynamic>? ?? {};
      final perms = res['permissions'] as Map<String, dynamic>? ?? {};

      final filialsRaw = filters['filials'] as List? ?? [];
      final yearsRaw = filters['academic_years'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        _teachers = items;
        _kpi = kpi;
        _permissions = perms;
        if (filialsRaw.isNotEmpty) {
          _filials = List<Map<String, dynamic>>.from(filialsRaw);
        }
        if (yearsRaw.isNotEmpty) {
          _academicYears = List<Map<String, dynamic>>.from(yearsRaw);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Məlumatlar yüklənərkən xəta baş verdi: $e', ok: false);
    }
  }

  void _snack(String t, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _teachers;
    return _teachers.where((t) {
      final name = _asString(t['name']).toLowerCase();
      final code = _asString(t['code']).toLowerCase();
      final fin = _asString(t['fin_code']).toLowerCase();
      final pos = _asString(t['position']).toLowerCase();
      final email = _asString(t['email']).toLowerCase();
      return name.contains(q) || code.contains(q) || fin.contains(q) || pos.contains(q) || email.contains(q);
    }).toList();
  }

  // =========================================================================
  // TOP PRINT / EXPORT SCHEDULE BAR (Modern Glass & Gradient)
  // =========================================================================
  Widget _buildPrintHeaderCard(AppPalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isPrintCardExpanded = !_isPrintCardExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emerald.withValues(alpha: 0.12),
                      palette.surface1,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.print_rounded, color: AppColors.emerald, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dərs Cədvəli Çapı & İxracı',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.emerald),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Müəllimlərin toplu və fərdi dərs cədvəli PDF',
                            style: TextStyle(fontSize: 11, color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text('Toplu PDF', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isPrintCardExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.emerald,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _selectedFilialId,
                            decoration: InputDecoration(
                              labelText: 'Filial',
                              filled: true,
                              fillColor: palette.surface2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Bütün filiallar', style: TextStyle(fontSize: 12))),
                              ..._filials.map((f) => DropdownMenuItem<int?>(
                                    value: _asInt(f['id']),
                                    child: Text(_asString(f['name']), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedFilialId = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _selectedAcademicYearId,
                            decoration: InputDecoration(
                              labelText: 'Tədris İli',
                              filled: true,
                              fillColor: palette.surface2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Cari il', style: TextStyle(fontSize: 12))),
                              ..._academicYears.map((y) => DropdownMenuItem<int?>(
                                    value: _asInt(y['id']),
                                    child: Text(_asString(y['name']), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedAcademicYearId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      initialValue: _printTeacherId,
                      decoration: InputDecoration(
                        labelText: 'Müəllim Seçimi',
                        filled: true,
                        fillColor: palette.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Bütün Müəllimlər (Toplu)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                        ..._teachers.map((t) => DropdownMenuItem<int?>(
                              value: _asInt(t['id']),
                              child: Text(_asString(t['name']), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setState(() => _printTeacherId = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _printFormat,
                      decoration: InputDecoration(
                        labelText: 'Çap Formatı',
                        filled: true,
                        fillColor: palette.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'single', child: Text('Ayrı-ayrı vərəqlər (A4 Landscape)', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'full', child: Text('Bütöv Cədvəl (Full Matrix)', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => setState(() => _printFormat = v ?? 'single'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _triggerBulkExport(mode: 'pdf'),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                            label: const Text('PDF Yüklə', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _triggerBulkExport(mode: 'print'),
                            icon: const Icon(Icons.print_rounded, size: 17),
                            label: const Text('Çap Et / Bax', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _isPrintCardExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerBulkExport({required String mode}) async {
    final filial = _selectedFilialId != null ? '&filial_id=$_selectedFilialId' : '';
    final year = _selectedAcademicYearId != null ? '&academic_year_id=$_selectedAcademicYearId' : '';
    final teacher = _printTeacherId != null ? '&teacher_id=$_printTeacherId' : '';
    final urlStr = 'http://127.0.0.1:8000/panel/academic/teachers/teachers/export-bulk-schedule-pdf?mode=$mode&print_type=$_printFormat$filial$year$teacher';
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Keçid açıla bilmədi: $urlStr', ok: false);
    }
  }

  Future<void> _exportTeacherSchedulePdf(Map<String, dynamic> teacher) async {
    final teacherId = _asInt(teacher['id']);
    final pdfUrl = _asString(teacher['pdf_url'], fallback: 'http://127.0.0.1:8000/panel/academic/teachers/teachers/exports/$teacherId/export-schedule-pdf');
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('PDF açıla bilmədi', ok: false);
    }
  }

  // =========================================================================
  // 1. TEACHER SCHEDULE SHEET (WEEKLY TIMETABLE - 100% TEMPLATE PARITY)
  // =========================================================================
  Future<void> _openTeacherScheduleSheet(Map<String, dynamic> teacher) async {
    final palette = AppPalette.of(context);
    final teacherId = _asString(teacher['id']);
    final teacherName = _asString(teacher['name']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: SchoolApiService.instance.fetchSchedules(teacherId: teacherId, isTemplate: true),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final schedules = snapshot.data ?? [];

          final Map<int, List<Map<String, dynamic>>> byDay = {1: [], 2: [], 3: [], 4: [], 5: []};
          for (final s in schedules) {
            final dow = _asInt(s['day_of_week'] ?? s['dayOfWeek'], fallback: 1);
            if (byDay.containsKey(dow)) {
              byDay[dow]!.add(s);
            }
          }

          final dayNames = {
            1: 'Bazar ertəsi',
            2: 'Çərşənbə axşamı',
            3: 'Çərşənbə',
            4: 'Cümə axşamı',
            5: 'Cümə',
          };

          return DefaultTabController(
            length: 5,
            child: Container(
              height: MediaQuery.sizeOf(ctx).height * 0.85,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFB45309), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(teacherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Həftəlik Dərs Cədvəli (${schedules.length} saat)', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            foregroundColor: AppColors.danger,
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          tooltip: 'PDF İxrac',
                          onPressed: () => _exportTeacherSchedulePdf(teacher),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.surface2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: palette.textSecondary,
                        indicator: BoxDecoration(
                          color: palette.brandRoyal,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: palette.brandRoyal.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        tabs: const [
                          Tab(text: 'B.E'),
                          Tab(text: 'Ç.A'),
                          Tab(text: 'Çər'),
                          Tab(text: 'C.A'),
                          Tab(text: 'Cüm'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              children: [1, 2, 3, 4, 5].map((d) {
                                final dayList = byDay[d] ?? [];
                                if (dayList.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.event_busy_rounded, size: 48, color: palette.textTertiary.withValues(alpha: 0.4)),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${dayNames[d]} günü üçün dərs yoxdur',
                                          style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  itemCount: dayList.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) {
                                    final s = dayList[idx];
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: palette.surface2,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: palette.borderHairline),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: palette.brandRoyal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primaryAccent),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _asString(s['start_time']),
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                                                ),
                                                Text(
                                                  _asString(s['end_time']),
                                                  style: TextStyle(fontSize: 10, color: palette.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _asString(s['subject_name'] ?? s['subject']),
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: palette.brandAzure.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        _asString(s['class_name'] ?? s['class']),
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0369A1)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Otaq: ${_asString(s['room_name'] ?? s['room'], fallback: '—')}',
                                                      style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 2. TEACHER JOURNAL SHEET
  // =========================================================================
  Future<void> _openTeacherJournalSheet(Map<String, dynamic> teacher) async {
    final palette = AppPalette.of(context);
    final teacherId = _asInt(teacher['id']);
    final teacherName = _asString(teacher['name']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: SchoolApiService.instance.fetchTeacherProfile(teacherId, academicYearId: _selectedAcademicYearId),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data?['data'] as Map<String, dynamic>? ?? snapshot.data;
          final assignments = (data?['assignments'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

          return Container(
            height: MediaQuery.sizeOf(ctx).height * 0.78,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.fact_check_rounded, color: Color(0xFF334155), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Elektron Jurnal & Fənn Dərsləri', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Davamiyyət və qiymətləndirmə üçün fənn seçin:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textSecondary)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : assignments.isEmpty
                            ? Center(
                                child: Text('Bu müəllim üçün aktiv jurnal dərsi tapılmadı.', style: TextStyle(color: palette.textSecondary)),
                              )
                            : ListView.separated(
                                itemCount: assignments.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (ctx, idx) {
                                  final a = assignments[idx];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ApiJournalScreen(initialClassId: _asString(a['class_id']))),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: palette.surface2,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: palette.borderHairline),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: palette.brandRoyal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              _asString(a['class_name']),
                                              style: TextStyle(fontWeight: FontWeight.w900, color: palette.brandRoyal, fontSize: 13),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _asString(a['subject_title']),
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${_asDouble(a['weekly_hours'])} saat/həftə • Jurnala daxil olmaq üçün toxunun',
                                                  style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: palette.surface1,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 3. TEACHER SUBSTITUTION SHEET (MATCHING substitution_modal.blade.php)
  // =========================================================================
  Future<void> _openTeacherSubstitutionSheet(Map<String, dynamic> teacher) async {
    final palette = AppPalette.of(context);
    final teacherId = _asInt(teacher['id']);
    final teacherName = _asString(teacher['name']);

    final data = await SchoolApiService.instance.fetchTeacherSubstitution(teacherId);
    if (data == null) {
      _snack('Əvəzetmə məlumatları yüklənə bilmədi', ok: false);
      return;
    }

    final docTypes = (data['document_types'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final assignments = (data['assignments'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final availableTeachers = (data['available_teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

    int? selectedDocTypeId = docTypes.isNotEmpty ? _asInt(docTypes.first['id']) : null;
    String startDate = DateTime.now().toIso8601String().substring(0, 10);
    String endDate = '';
    final docNumberCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    final Map<String, int> substitutions = {};

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.sizeOf(ctx).height * 0.88,
          padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.viewInsetsOf(ctx).bottom + 20),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF047857), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sənədləşmə və Əvəzetmə', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          Text(teacherName, style: TextStyle(fontSize: 12, color: palette.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      DropdownButtonFormField<int?>(
                        initialValue: selectedDocTypeId,
                        decoration: InputDecoration(
                          labelText: 'Sənəd Növü *',
                          filled: true,
                          fillColor: palette.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                        ),
                        items: docTypes.map((dt) => DropdownMenuItem<int?>(
                              value: _asInt(dt['id']),
                              child: Text(_asString(dt['name']), overflow: TextOverflow.ellipsis),
                            )).toList(),
                        onChanged: (v) => setSheet(() => selectedDocTypeId = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: startDate,
                              decoration: InputDecoration(
                                labelText: 'Başlama Tarixi *',
                                filled: true,
                                fillColor: palette.surface2,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                              ),
                              onChanged: (v) => startDate = v,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: endDate,
                              decoration: InputDecoration(
                                labelText: 'Bitmə Tarixi',
                                filled: true,
                                fillColor: palette.surface2,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                              ),
                              onChanged: (v) => endDate = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: docNumberCtrl,
                        decoration: InputDecoration(
                          labelText: 'Sənəd Nömrəsi',
                          filled: true,
                          fillColor: palette.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Səbəb / Qeyd',
                          filled: true,
                          fillColor: palette.surface2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Dərslərin Köçürülməsi (Əvəzetmə)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: palette.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Əvəz edən müəllimi hər dərs üçün seçin',
                        style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      if (assignments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Bu müəllimin aktiv dərsi yoxdur.', style: TextStyle(color: palette.textSecondary)),
                        )
                      else
                        ...assignments.map((a) {
                          final aId = _asString(a['assignment_id']);
                          final currentSub = substitutions[aId];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
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
                                    Expanded(
                                      child: Text(
                                        '${_asString(a['class_name'])} • ${_asString(a['subject_name'])}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: palette.brandRoyal.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_asDouble(a['weekly_hours'])} saat',
                                        style: TextStyle(color: palette.brandRoyal, fontSize: 10.5, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int?>(
                                  initialValue: currentSub,
                                  decoration: InputDecoration(
                                    labelText: 'Əvəz edən müəllim',
                                    filled: true,
                                    fillColor: palette.surface1,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.borderHairline)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('Seçilməyib (Müəllimsiz qalsın)', style: TextStyle(fontSize: 12))),
                                    ...availableTeachers.map((t) => DropdownMenuItem<int?>(
                                          value: _asInt(t['id']),
                                          child: Text(_asString(t['name']), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setSheet(() => substitutions[aId] = v);
                                    } else {
                                      setSheet(() => substitutions.remove(aId));
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: selectedDocTypeId == null
                      ? null
                      : () async {
                          final ok = await SchoolApiService.instance.saveTeacherSubstitution(
                            teacherId: teacherId,
                            documentTypeId: selectedDocTypeId!,
                            startDate: startDate,
                            endDate: endDate.isNotEmpty ? endDate : null,
                            documentNumber: docNumberCtrl.text.trim().isNotEmpty ? docNumberCtrl.text.trim() : null,
                            reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                            substitutions: substitutions,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (ok) {
                            _snack('Əvəzetmə və sənədləşmə uğurla qeyd edildi!');
                            _load();
                          } else {
                            _snack('Əvəzetmə saxlanılarkən xəta baş verdi', ok: false);
                          }
                        },
                  child: const Text('Yadda saxla və Tətbiq et', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. TEACHER PROFILE & WORKLOAD SHEET
  // =========================================================================
  Future<void> _openTeacherProfileSheet(Map<String, dynamic> teacher) async {
    final palette = AppPalette.of(context);
    final teacherId = _asInt(teacher['id']);
    final refreshNotifier = ValueNotifier<int>(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ValueListenableBuilder<int>(
          valueListenable: refreshNotifier,
          builder: (context, val, child) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: SchoolApiService.instance.fetchTeacherProfile(teacherId, academicYearId: _selectedAcademicYearId),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final data = snapshot.data?['data'] as Map<String, dynamic>? ?? snapshot.data;
                final assignments = (data?['assignments'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
                final homeroomClasses = (data?['homeroom_classes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
                final availableHomeroom = (data?['available_homeroom_classes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
                final teacherSubjects = (data?['teacher_subjects'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
                final allSubjects = (data?['all_subjects'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
                final timeSlots = (data?['time_slots'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
                final unavailabilities = (data?['unavailabilities'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

                final weeklyHoursTotal = _asDouble(data?['weekly_hours_total'] ?? teacher['weekly_hours']);
                final subjectsCount = _asInt(data?['subjects_count'] ?? teacher['subjects_count']);
                final classesCount = _asInt(data?['classes_count'] ?? assignments.map((a) => a['class_id']).toSet().length);
                final colorCode = _asString(data?['color_code'] ?? teacher['color_code'], fallback: '#2563EB');
                final teacherColor = _parseColor(colorCode);

                return DefaultTabController(
                  length: 4,
                  child: Container(
                    height: MediaQuery.sizeOf(ctx).height * 0.88,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    decoration: BoxDecoration(
                      color: palette.surface1,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _openColorPicker(teacherId, colorCode, () {
                                  refreshNotifier.value++;
                                  _load();
                                }),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: teacherColor, width: 2.8),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    backgroundColor: teacherColor.withValues(alpha: 0.15),
                                    child: Text(
                                      (_asString(teacher['name']).isNotEmpty ? _asString(teacher['name'])[0] : 'M').toUpperCase(),
                                      style: TextStyle(color: teacherColor, fontWeight: FontWeight.w900, fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _asString(teacher['name']),
                                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (_asString(teacher['code']).isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: palette.brandRoyal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _asString(teacher['code']),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: palette.brandRoyal),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          'FİN: ${_asString(teacher['fin_code'])}',
                                          style: TextStyle(fontSize: 11, color: palette.textSecondary, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          _asString(teacher['position'], fallback: 'Müəllim'),
                                          style: TextStyle(fontSize: 11.5, color: palette.brandAzure, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () => _openColorPicker(teacherId, colorCode, () {
                                            refreshNotifier.value++;
                                            _load();
                                          }),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(color: teacherColor, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 4),
                                              Text('Rəng təyin et', style: TextStyle(fontSize: 11, color: palette.brandRoyal, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Summary KPI cards
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: palette.surface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: palette.borderHairline),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${weeklyHoursTotal.toStringAsFixed(weeklyHoursTotal.truncateToDouble() == weeklyHoursTotal ? 0 : 1)} saat',
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: palette.brandRoyal),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Həftəlik Yük', style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: palette.surface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: palette.borderHairline),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$subjectsCount fənn',
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.emerald),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Fənlər', style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: palette.surface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: palette.borderHairline),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$classesCount sinif',
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: palette.brandAzure),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Siniflər', style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: palette.surface2,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: palette.textSecondary,
                              indicator: BoxDecoration(
                                color: palette.brandRoyal,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.brandRoyal.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              tabs: const [
                                Tab(text: 'Dərs Yükü'),
                                Tab(text: 'Rəhbərlik'),
                                Tab(text: 'Fənlər'),
                                Tab(text: 'Qadağan Saatları ⛔'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : TabBarView(
                                    children: [
                                      // Tab 1: Assignments / Workload
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Cari Təyinatlar (${assignments.length})',
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.textPrimary),
                                              ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: palette.brandRoyal,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  visualDensity: VisualDensity.compact,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                onPressed: () => _openAddAssignmentDialog(
                                                  teacherId,
                                                  availableHomeroom,
                                                  teacherSubjects.isNotEmpty ? teacherSubjects : allSubjects,
                                                  () {
                                                    refreshNotifier.value++;
                                                    _load();
                                                  },
                                                ),
                                                icon: const Icon(Icons.add_rounded, size: 16),
                                                label: const Text('Yeni Təyinat', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: assignments.isEmpty
                                                ? Center(
                                                    child: Text('Cari tədris ilində dərs yükü təyin edilməyib.', style: TextStyle(color: palette.textSecondary)),
                                                  )
                                                : ListView.separated(
                                                    itemCount: assignments.length,
                                                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                                                    itemBuilder: (ctx, idx) {
                                                      final a = assignments[idx];
                                                      final aId = _asInt(a['id']);
                                                      final isGroup = a['group_id'] != null;
                                                      final hours = _asDouble(a['weekly_hours']);
                                                      final hoursStr = hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1);

                                                      return Container(
                                                        padding: const EdgeInsets.all(14),
                                                        decoration: BoxDecoration(
                                                          color: palette.surface2,
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: Border.all(color: palette.borderHairline),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                  decoration: BoxDecoration(
                                                                    color: palette.brandRoyal.withValues(alpha: 0.12),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                  child: Text(
                                                                    _asString(a['class_name']),
                                                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: palette.brandRoyal),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 10),
                                                                Expanded(
                                                                  child: Text(
                                                                    _asString(a['subject_title']),
                                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFFECFDF5),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                  child: Text(
                                                                    '$hoursStr saat',
                                                                    style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w800, fontSize: 11),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            if (isGroup) ...[
                                                              const SizedBox(height: 6),
                                                              Text(
                                                                'Qrup: ${_asString(a['group_name'])}',
                                                                style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontStyle: FontStyle.italic),
                                                              ),
                                                            ],
                                                            const SizedBox(height: 10),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                              children: [
                                                                OutlinedButton.icon(
                                                                  style: OutlinedButton.styleFrom(
                                                                    foregroundColor: palette.brandRoyal,
                                                                    side: BorderSide(color: palette.brandRoyal.withValues(alpha: 0.4)),
                                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                    visualDensity: VisualDensity.compact,
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                  ),
                                                                  onPressed: () => _openSplitTransferDialog(teacherId, aId, hours, () {
                                                                    refreshNotifier.value++;
                                                                    _load();
                                                                  }),
                                                                  icon: const Icon(Icons.call_split_rounded, size: 14),
                                                                  label: const Text('Böl / Ötür', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                OutlinedButton.icon(
                                                                  style: OutlinedButton.styleFrom(
                                                                    foregroundColor: AppColors.danger,
                                                                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                    visualDensity: VisualDensity.compact,
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                  ),
                                                                  onPressed: () => _confirmDeleteAssignment(teacherId, aId, () {
                                                                    refreshNotifier.value++;
                                                                    _load();
                                                                  }),
                                                                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                                                  label: const Text('Ləğv et', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
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

                                      // Tab 2: Homeroom Classes
                                      _buildHomeroomTab(teacherId, homeroomClasses, availableHomeroom, palette, () {
                                        refreshNotifier.value++;
                                        _load();
                                      }),

                                      // Tab 3: Subjects
                                      _buildSubjectsTab(teacherId, teacherSubjects, allSubjects, palette, () {
                                        refreshNotifier.value++;
                                        _load();
                                      }),

                                      // Tab 4: Unavailability Grid
                                      _buildUnavailabilityTab(teacherId, timeSlots, unavailabilities, palette, () {
                                        refreshNotifier.value++;
                                        _load();
                                      }),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // SUB-TABS IN TEACHER PROFILE
  // =========================================================================
  Widget _buildHomeroomTab(int teacherId, List<Map<String, dynamic>> current, List<Map<String, dynamic>> available, AppPalette palette, VoidCallback onSaved) {
    final selectedIds = current.map((c) => _asInt(c['id'])).toSet();

    return StatefulBuilder(
      builder: (ctx, setTab) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rəhbər olduğu sinifləri seçin:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textSecondary)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: available.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final c = available[idx];
                  final cId = _asInt(c['id']);
                  final isChecked = selectedIds.contains(cId);

                  return CheckboxListTile(
                    title: Text(_asString(c['class_name']), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    value: isChecked,
                    dense: true,
                    activeColor: palette.brandRoyal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: palette.surface2,
                    onChanged: (val) {
                      setTab(() {
                        if (val == true) {
                          selectedIds.add(cId);
                        } else {
                          selectedIds.remove(cId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.brandRoyal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final ok = await SchoolApiService.instance.saveTeacherHomeroom(teacherId, selectedIds.toList());
                if (ok) {
                  _snack('Sinif rəhbərliyi saxlanıldı');
                  onSaved();
                } else {
                  _snack('Xəta baş verdi', ok: false);
                }
              },
              child: const Text('Rəhbərliyi Yadda Saxla', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectsTab(int teacherId, List<Map<String, dynamic>> current, List<Map<String, dynamic>> all, AppPalette palette, VoidCallback onSaved) {
    final selectedIds = current.map((s) => _asInt(s['id'])).toSet();

    return StatefulBuilder(
      builder: (ctx, setTab) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Müəllimin tədris etdiyi fənlər:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textSecondary)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: all.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final s = all[idx];
                  final sId = _asInt(s['id']);
                  final isChecked = selectedIds.contains(sId);

                  return CheckboxListTile(
                    title: Text(_asString(s['title']), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    value: isChecked,
                    dense: true,
                    activeColor: palette.brandRoyal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: palette.surface2,
                    onChanged: (val) {
                      setTab(() {
                        if (val == true) {
                          selectedIds.add(sId);
                        } else {
                          selectedIds.remove(sId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.brandRoyal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final ok = await SchoolApiService.instance.saveTeacherSubjects(teacherId, selectedIds.toList());
                if (ok) {
                  _snack('Fənlər uğurla saxlanıldı');
                  onSaved();
                } else {
                  _snack('Xəta baş verdi', ok: false);
                }
              },
              child: const Text('Fənləri Yadda Saxla', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnavailabilityTab(int teacherId, List<Map<String, dynamic>> timeSlots, List<Map<String, dynamic>> currentUnav, AppPalette palette, VoidCallback onSaved) {
    final unavKeys = currentUnav.map((u) => _asString(u['key'])).toSet();
    final dayNames = ['B.E', 'Ç.A', 'Çər', 'C.A', 'Cüm'];

    return StatefulBuilder(
      builder: (ctx, setTab) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.danger),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Qırmızı (⛔) qeyri-iş vaxtıdır. Bu saatlara dərs qoyulmur.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    headingRowHeight: 38,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 48,
                    columns: [
                      const DataColumn(label: Text('Saat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5))),
                      ...dayNames.map((d) => DataColumn(label: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)))),
                    ],
                    rows: timeSlots.map((ts) {
                      final slotId = _asInt(ts['id']);
                      final num = _asInt(ts['lesson_number']);
                      final sTime = _asString(ts['start_time']);
                      final eTime = _asString(ts['end_time']);
                      final label = sTime.isNotEmpty && eTime.isNotEmpty ? '$num ($sTime)' : '$num';

                      return DataRow(
                        cells: [
                          DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                          ...[1, 2, 3, 4, 5].map((day) {
                            final key = '${day}_$slotId';
                            final isUnav = unavKeys.contains(key);
                            return DataCell(
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setTab(() {
                                    if (isUnav) {
                                      unavKeys.remove(key);
                                    } else {
                                      unavKeys.add(key);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isUnav ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isUnav ? AppColors.danger : AppColors.emerald, width: 1.2),
                                  ),
                                  child: Text(
                                    isUnav ? '⛔' : '✓',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isUnav ? AppColors.danger : AppColors.emerald,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final ok = await SchoolApiService.instance.saveTeacherUnavailability(teacherId, unavKeys.toList());
                if (ok) {
                  _snack('Qeyri-iş vaxtları uğurla saxlanıldı');
                  onSaved();
                } else {
                  _snack('Xəta baş verdi', ok: false);
                }
              },
              child: const Text('Qadağan Saatlarını Saxla', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  // Color picker dialog
  Future<void> _openColorPicker(int teacherId, String currentColor, VoidCallback onSaved) async {
    final colors = [
      '#008040', // Green
      '#2563EB', // Blue
      '#E91E8C', // Pink
      '#7C3AED', // Purple
      '#D97706', // Amber
      '#DC2626', // Red
      '#0D9488', // Teal
      '#0284C7', // Sky
    ];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Müəllim Rəngi Seçin', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((c) {
            final col = _parseColor(c);
            final isSelected = currentColor.toLowerCase() == c.toLowerCase();
            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await SchoolApiService.instance.saveTeacherColor(teacherId, c);
                if (ok) {
                  _snack('Rəng uğurla yeniləndi!');
                  onSaved();
                } else {
                  _snack('Xəta baş verdi', ok: false);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: [
                    BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Add Assignment Dialog (Web "Tədris tapşırıqları - Təyinatı əlavə et" parity)
  Future<void> _openAddAssignmentDialog(
    int teacherId,
    List<Map<String, dynamic>> availableClasses,
    List<Map<String, dynamic>> subjects,
    VoidCallback onSaved,
  ) async {
    int? selectedSubjectId = subjects.isNotEmpty ? _asInt(subjects.first['id']) : null;
    int? selectedClassId = availableClasses.isNotEmpty ? _asInt(availableClasses.first['id']) : null;
    double weeklyHours = 1.0;
    int hoursPerDay = 1;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Dərs Təyinatı Əlavə Et', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                initialValue: selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Fənn *', border: OutlineInputBorder()),
                items: subjects.map((s) => DropdownMenuItem<int?>(
                      value: _asInt(s['id']),
                      child: Text(_asString(s['title']), overflow: TextOverflow.ellipsis),
                    )).toList(),
                onChanged: (v) => setD(() => selectedSubjectId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: selectedClassId,
                decoration: const InputDecoration(labelText: 'Sinif *', border: OutlineInputBorder()),
                items: availableClasses.map((c) => DropdownMenuItem<int?>(
                      value: _asInt(c['id']),
                      child: Text(_asString(c['class_name']), overflow: TextOverflow.ellipsis),
                    )).toList(),
                onChanged: (v) => setD(() => selectedClassId = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: weeklyHours.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Həftəlik saat', border: OutlineInputBorder()),
                      onChanged: (v) => weeklyHours = double.tryParse(v) ?? weeklyHours,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: hoursPerDay.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Gündəlik saat', border: OutlineInputBorder()),
                      onChanged: (v) => hoursPerDay = int.tryParse(v) ?? hoursPerDay,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İmtina')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAccent),
              onPressed: (selectedSubjectId == null || selectedClassId == null)
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await SchoolApiService.instance.createTeacherClassSubject(
                        teacherId,
                        subjectId: selectedSubjectId!,
                        weeklyHours: weeklyHours,
                        hoursPerDay: hoursPerDay,
                        assignmentType: 'class',
                        classes: [selectedClassId!],
                      );
                      if (ok) {
                        _snack('Dərs təyinatı uğurla əlavə edildi!');
                        onSaved();
                      } else {
                        _snack('Təyinat əlavə edilərkən xəta baş verdi', ok: false);
                      }
                    },
              child: const Text('Əlavə et', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSplitTransferDialog(int teacherId, int assignmentId, double currentHours, VoidCallback onTransferred) async {
    final subData = await SchoolApiService.instance.fetchTeacherSubstitution(teacherId);
    final available = (subData?['available_teachers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

    int? targetTeacherId = available.isNotEmpty ? _asInt(available.first['id']) : null;
    double transferHours = currentHours > 1 ? 1.0 : currentHours;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Saatları Böl və Ötür', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cari dərs saatı: $currentHours saat/həftə', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              DropdownButtonFormField<int?>(
                initialValue: targetTeacherId,
                decoration: InputDecoration(
                  labelText: 'Ötürüləcək Müəllim',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: available.map((t) => DropdownMenuItem<int?>(
                      value: _asInt(t['id']),
                      child: Text(_asString(t['name']), overflow: TextOverflow.ellipsis),
                    )).toList(),
                onChanged: (v) => setD(() => targetTeacherId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: transferHours.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Ötürüləcək saat miqdarı',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => transferHours = double.tryParse(v) ?? transferHours,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İmtina')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAccent),
              onPressed: targetTeacherId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await SchoolApiService.instance.splitTransferTeacherClassSubject(
                        teacherId,
                        assignmentId,
                        targetTeacherId!,
                        transferHours,
                      );
                      if (ok) {
                        _snack('Saatlar uğurla bölündü və ötürüldü!');
                        onTransferred();
                      } else {
                        _snack('Xəta baş verdi', ok: false);
                      }
                    },
              child: const Text('Təsdiq et', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAssignment(int teacherId, int assignmentId, VoidCallback onDeleted) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Təyinatı Ləğv Et', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Bu dərs təyinatını ləğv etmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xeyr')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bəli, Ləğv et'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await SchoolApiService.instance.deleteTeacherClassSubject(teacherId, assignmentId);
      if (ok) {
        _snack('Təyinat ləğv edildi');
        onDeleted();
      } else {
        _snack('Xəta baş verdi', ok: false);
      }
    }
  }

  void _showFilterModal() {
    final palette = AppPalette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                const Text('Filtrlər', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                if (_academicYears.isNotEmpty) ...[
                  Text('Tədris İli', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedAcademicYearId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Cari tədris ili')),
                      ..._academicYears.map((y) => DropdownMenuItem<int?>(
                            value: _asInt(y['id']),
                            child: Text(_asString(y['name']), overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setSheet(() => _selectedAcademicYearId = v),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_filials.isNotEmpty) ...[
                  Text('Filial', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedFilialId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: palette.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.borderHairline)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Bütün Filiallar')),
                      ..._filials.map((f) => DropdownMenuItem<int?>(
                            value: _asInt(f['id']),
                            child: Text(_asString(f['name'])),
                          )),
                    ],
                    onChanged: (v) => setSheet(() => _selectedFilialId = v),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedAcademicYearId = null;
                            _selectedFilialId = null;
                          });
                          Navigator.pop(ctx);
                          _load();
                        },
                        child: const Text('Sıfırla', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.brandNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _load();
                        },
                        child: const Text('Tətbiq et', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // CUSTOM ACTION PILL BUTTON (MODERN PASTEL TINT)
  // =========================================================================
  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 1.1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.5, color: textColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MODERN TEACHER CARD
  // =========================================================================
  Widget _buildTeacherCard({
    required Map<String, dynamic> t,
    required AppPalette palette,
    required bool canViewProfile,
    required bool canViewJournal,
    required bool canViewSchedule,
    required bool canExportPdf,
    required bool canSubstitution,
  }) {
    final teacherColor = _parseColor(_asString(t['color_code']));
    final statusColor = _asString(t['status_color']);
    final isTerminated = statusColor == 'danger';
    final isMaternity = statusColor == 'warning';

    final Color badgeDotColor = isTerminated
        ? AppColors.danger
        : isMaternity
            ? const Color(0xFFE91E8C)
            : AppColors.emerald;

    final double weeklyHours = _asDouble(t['weekly_hours']);
    final String hoursStr = weeklyHours.toStringAsFixed(weeklyHours.truncateToDouble() == weeklyHours ? 0 : 1);
    final int subCount = _asInt(t['subjects_count']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderHairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar + Name + Code (Clickable to open profile)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openTeacherProfileSheet(t),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: teacherColor, width: 2.4),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          backgroundColor: teacherColor.withValues(alpha: 0.14),
                          child: Text(
                            (_asString(t['name']).isNotEmpty ? _asString(t['name'])[0] : 'M').toUpperCase(),
                            style: TextStyle(
                              color: teacherColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: badgeDotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.surface1, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _asString(t['name']),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                              ),
                            ),
                            if (_asString(t['code']).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: palette.brandRoyal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: palette.brandRoyal.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  _asString(t['code']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: palette.brandRoyal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.school_outlined, size: 13, color: palette.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_asString(t['position'], fallback: 'Müəllim')} • ${_asString(t['filial_name'], fallback: 'Baş Filial')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (_asString(t['fin_code']).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.fingerprint_rounded, size: 13, color: palette.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                'FİN: ${_asString(t['fin_code'])}',
                                style: TextStyle(fontSize: 10.5, color: palette.textTertiary, fontFamily: 'monospace', fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Metrics row: Status + Subjects + Weekly Hours
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTerminated
                        ? const Color(0xFFFEE2E2)
                        : isMaternity
                            ? const Color(0xFFFCE7F3)
                            : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTerminated
                          ? const Color(0xFFFECACA)
                          : isMaternity
                              ? const Color(0xFFFBCFE8)
                              : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: badgeDotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _asString(t['status_label'], fallback: 'Aktiv'),
                        style: TextStyle(
                          color: isTerminated
                              ? const Color(0xFF991B1B)
                              : isMaternity
                                  ? const Color(0xFF9D174D)
                                  : const Color(0xFF047857),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.borderHairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 12, color: palette.brandRoyal),
                      const SizedBox(width: 4),
                      Text(
                        '$subCount fənn',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, color: palette.brandNavy),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: weeklyHours > 0 ? palette.brandAzure.withValues(alpha: 0.12) : palette.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: weeklyHours > 0 ? palette.brandAzure.withValues(alpha: 0.3) : palette.borderHairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: weeklyHours > 0 ? const Color(0xFF0284C7) : palette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$hoursStr saat/həftə',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          color: weeklyHours > 0 ? const Color(0xFF0369A1) : palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: palette.borderHairline.withValues(alpha: 0.6)),
            const SizedBox(height: 10),

            // =======================================================
            // 5 OPERATION BUTTONS (100% WEB PARITY & ROBUST PERMISSIONS)
            // =======================================================
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // 1. Profil & Yük
                if (canViewProfile)
                  _buildActionPill(
                    label: 'Profil & Yük',
                    icon: Icons.manage_accounts_rounded,
                    bg: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
                    textColor: const Color(0xFF1D4ED8),
                    onTap: () => _openTeacherProfileSheet(t),
                  ),

                // 2. Jurnal
                if (canViewJournal)
                  _buildActionPill(
                    label: 'Jurnal',
                    icon: Icons.fact_check_rounded,
                    bg: const Color(0xFFF1F5F9),
                    border: const Color(0xFFCBD5E1),
                    textColor: const Color(0xFF334155),
                    onTap: () => _openTeacherJournalSheet(t),
                  ),

                // 3. Dərs Cədvəli
                if (canViewSchedule)
                  _buildActionPill(
                    label: 'Cədvəl',
                    icon: Icons.calendar_month_rounded,
                    bg: const Color(0xFFFEF3C7),
                    border: const Color(0xFFFDE68A),
                    textColor: const Color(0xFFB45309),
                    onTap: () => _openTeacherScheduleSheet(t),
                  ),

                // 4. PDF Cədvəl
                if (canExportPdf)
                  _buildActionPill(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    bg: const Color(0xFFFEE2E2),
                    border: const Color(0xFFFECACA),
                    textColor: const Color(0xFFDC2626),
                    onTap: () => _exportTeacherSchedulePdf(t),
                  ),

                // 5. Əvəzetmə / Sənədləşmə
                if (canSubstitution)
                  _buildActionPill(
                    label: 'Əvəzetmə',
                    icon: Icons.swap_horiz_rounded,
                    bg: const Color(0xFFECFDF5),
                    border: const Color(0xFFA7F3D0),
                    textColor: const Color(0xFF047857),
                    onTap: () => _openTeacherSubstitutionSheet(t),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final session = context.watch<SessionController>();
    final isSuper = session.profile?.isSuper == true;

    final canViewProfile = isSuper || session.can('gopanel.academic.teachers.teachers.profile') || (_permissions['can_view_profile'] == true);
    final canViewJournal = isSuper || session.can('gopanel.academic.teachers.teachers.journal') || (_permissions['can_view_journal'] == true);
    final canViewSchedule = isSuper || session.can('gopanel.academic.teachers.teachers.schedule') || (_permissions['can_view_schedule'] == true);
    final canExportPdf = isSuper || session.can('gopanel.academic.teachers.export_pdf') || (_permissions['can_export_pdf'] == true);
    final canSubstitution = isSuper || session.can('gopanel.academic.teachers.teachers.substitution') || (_permissions['can_substitution'] == true);

    final items = _filtered;

    final totalTeachers = _asInt(_kpi['total_teachers'] ?? _teachers.length);
    final activeTeaching = _asInt(_kpi['active_teaching'] ?? _teachers.where((t) => _asDouble(t['weekly_hours']) > 0).length);
    final maternity = _asInt(_kpi['maternity_leave'] ?? 0);
    final terminated = _asInt(_kpi['terminated'] ?? 0);

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Müəllimlər', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(
              'Pedaqoji heyət və dərs bölgüsü',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filtrlər',
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenilə',
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ResponsiveCenter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    // Top Print/Export Schedule Bar (Web Parity)
                    _buildPrintHeaderCard(palette),

                    // Modern Search Box
                    Container(
                      decoration: BoxDecoration(
                        color: palette.surface1,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Müəllim adı, FİN, İdrak kodu və ya vəzifə...',
                          hintStyle: TextStyle(fontSize: 13, color: palette.textTertiary),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryAccent),
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
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: palette.borderHairline)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: palette.borderHairline)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: palette.brandRoyal, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Bütün',
                            count: totalTeachers,
                            isSelected: _selectedStatus == 'all',
                            palette: palette,
                            onTap: () {
                              setState(() => _selectedStatus = 'all');
                              _load();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Tədris Yükü Olan',
                            count: activeTeaching,
                            isSelected: _selectedStatus == 'with_workload',
                            palette: palette,
                            onTap: () {
                              setState(() => _selectedStatus = 'with_workload');
                              _load();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Analıq Məz.',
                            count: maternity,
                            isSelected: _selectedStatus == 'maternity',
                            palette: palette,
                            onTap: () {
                              setState(() => _selectedStatus = 'maternity');
                              _load();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'İşdən Ayrılan',
                            count: terminated,
                            isSelected: _selectedStatus == 'terminated',
                            palette: palette,
                            onTap: () {
                              setState(() => _selectedStatus = 'terminated');
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4 Modern KPI Stat Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernKpiCard(
                            label: 'Cəmi Müəllim',
                            value: '$totalTeachers',
                            icon: Icons.people_alt_rounded,
                            color: palette.brandRoyal,
                            bgTint: const Color(0xFFEFF6FF),
                            palette: palette,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModernKpiCard(
                            label: 'Tədris Yükü Olan',
                            value: '$activeTeaching',
                            icon: Icons.menu_book_rounded,
                            color: AppColors.emerald,
                            bgTint: const Color(0xFFECFDF5),
                            palette: palette,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernKpiCard(
                            label: 'Analıq Məzuniyyəti',
                            value: '$maternity',
                            icon: Icons.pregnant_woman_rounded,
                            color: const Color(0xFFE91E8C),
                            bgTint: const Color(0xFFFCE7F3),
                            palette: palette,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModernKpiCard(
                            label: 'İşdən Ayrılanlar (İ.A)',
                            value: '$terminated',
                            icon: Icons.person_off_rounded,
                            color: AppColors.danger,
                            bgTint: const Color(0xFFFEE2E2),
                            palette: palette,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pedaqoji Heyət Siyahısı',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.borderHairline),
                          ),
                          child: Text(
                            '${items.length} müəllim',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: palette.textTertiary.withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(
                                'Axtarışa uyğun müəllim tapılmadı',
                                style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final t in items)
                        _buildTeacherCard(
                          t: t,
                          palette: palette,
                          canViewProfile: canViewProfile,
                          canViewJournal: canViewJournal,
                          canViewSchedule: canViewSchedule,
                          canExportPdf: canExportPdf,
                          canSubstitution: canSubstitution,
                        ),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================================
  // MODERN FILTER CHIP
  // =========================================================================
  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required AppPalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.brandNavy : palette.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? palette.brandNavy : palette.borderHairline,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.brandNavy.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : palette.brandNavy,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : palette.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MODERN KPI STAT CARD
  // =========================================================================
  Widget _buildModernKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgTint,
    required AppPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderHairline, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: palette.brandNavy),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
