import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/responsive.dart';
import '../../../providers/app_state.dart';

class AcademicNotesScreen extends StatefulWidget {
  final String? studentId;
  final String? studentName;

  const AcademicNotesScreen({
    super.key,
    this.studentId,
    this.studentName,
  });

  @override
  State<AcademicNotesScreen> createState() => _AcademicNotesScreenState();
}

class _AcademicNotesScreenState extends State<AcademicNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _selectedType = 'all';
  List<Map<String, dynamic>> _allNotes = [];
  String? _copiedNoteId;

  // Type definitions matching Web 1:1
  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'label': 'Hamısı',
      'icon': Icons.layers_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'id': 'student_note',
      'label': 'Şagird qeydləri',
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'id': 'grade',
      'label': 'Qiymətləndirmə',
      'icon': Icons.school_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'attendance',
      'label': 'Davamiyyət',
      'icon': Icons.access_time_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'assignment',
      'label': 'Tapşırıqlar',
      'icon': Icons.assignment_rounded,
      'color': Color(0xFF06B6D4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _resolveTargetStudentId(AppState appState) {
    if (widget.studentId != null && widget.studentId!.isNotEmpty) {
      return widget.studentId!;
    }
    final user = appState.currentUser;
    if (user != null && user.role == UserRole.student) {
      return user.id;
    }
    if (appState.student.id.isNotEmpty) {
      return appState.student.id;
    }
    return '';
  }

  String _resolveTargetStudentName(AppState appState) {
    if (widget.studentName != null && widget.studentName!.isNotEmpty) {
      return widget.studentName!;
    }
    final user = appState.currentUser;
    if (user != null && user.role == UserRole.student) {
      return user.fullName;
    }
    if (appState.student.fullName.isNotEmpty) {
      return appState.student.fullName;
    }
    return 'Şagird';
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    final studentId = _resolveTargetStudentId(appState);

    try {
      final notes = await SchoolApiService.instance.fetchAcademicNotes(
        studentId: studentId.isNotEmpty ? studentId : null,
        perPage: 250,
      );
      if (!mounted) return;
      setState(() {
        _allNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Qeydlər yüklənərkən xəta baş verdi: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredNotes {
    final query = _searchController.text.trim().toLowerCase();
    return _allNotes.where((item) {
      // 1. Type filter
      final type = (item['type'] ?? 'student_note').toString();
      if (_selectedType != 'all' && type != _selectedType) {
        return false;
      }
      // 2. Search query filter
      if (query.isNotEmpty) {
        final body = (item['body'] ?? '').toString().toLowerCase();
        final title = (item['title'] ?? '').toString().toLowerCase();
        final subject = (item['subject'] ?? '').toString().toLowerCase();
        final teacher = (item['teacher'] ?? item['authorName'] ?? '').toString().toLowerCase();
        final studentName = (item['studentName'] ?? '').toString().toLowerCase();
        final refCode = (item['refCode'] ?? '').toString().toLowerCase();

        final match = body.contains(query) ||
            title.contains(query) ||
            subject.contains(query) ||
            teacher.contains(query) ||
            studentName.contains(query) ||
            refCode.contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  int _countForType(String typeId) {
    if (typeId == 'all') return _allNotes.length;
    return _allNotes.where((n) => (n['type'] ?? '') == typeId).length;
  }

  void _copyToClipboard(Map<String, dynamic> note) {
    final text = (note['body'] ?? note['title'] ?? '').toString().trim();
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    final noteId = note['id']?.toString() ?? '';
    setState(() => _copiedNoteId = noteId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Qeyd mətni buferə kopyalandı', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _copiedNoteId == noteId) {
        setState(() => _copiedNoteId = null);
      }
    });
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('0xFF$clean'));
    } else if (clean.length == 8) {
      return Color(int.parse('0x$clean'));
    }
    return fallback;
  }

  void _showNoteDetails(Map<String, dynamic> note) {
    final palette = AppPalette.of(context);
    final borderColor = _parseHex(note['borderColor']?.toString(), const Color(0xFF6366F1));
    final typeLabel = note['typeLabel']?.toString() ?? 'Akademik qeyd';
    final subject = note['subject']?.toString() ?? '–';
    final teacher = note['teacher']?.toString() ?? note['authorName']?.toString() ?? 'Müəllim';
    final date = note['formattedDate']?.toString() ?? note['date']?.toString() ?? '–';
    final body = note['body']?.toString() ?? '';
    final title = note['title']?.toString() ?? '';
    final refCode = note['refCode']?.toString() ?? '#${note['id'] ?? ''}';
    final grade = note['grade'];
    final status = note['status']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type & Ref code row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    refCode,
                    style: TextStyle(
                      color: palette.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title if available
              if (title.isNotEmpty && title != 'Akademik qeyd') ...[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Meta details (Subject, Date, Teacher, Score)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Column(
                  children: [
                    if (subject != '–')
                      _detailRow(Icons.book_outlined, 'Fənn:', subject, palette),
                    _detailRow(Icons.person_outline_rounded, 'Müəllim:', teacher, palette),
                    _detailRow(Icons.calendar_today_outlined, 'Tarix:', date, palette),
                    if (grade != null)
                      _detailRow(Icons.star_rounded, 'Qiymət / Bal:', '$grade', palette, valueColor: AppColors.success),
                    if (status != null && status.isNotEmpty)
                      _detailRow(Icons.info_outline_rounded, 'Status:', status, palette, valueColor: AppColors.warning),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Full Note Body
              const Text(
                'Qeyd mətni:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    body.isNotEmpty ? body : 'Qeyd mətni daxil edilməyib.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions: Copy & Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _copyToClipboard(note);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Qeydi kopyala', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      child: const Text('Bağla', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _detailRow(IconData icon, String label, String value, AppPalette palette, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: palette.textTertiary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final palette = AppPalette.of(context);
    final studentName = _resolveTargetStudentName(appState);
    final filtered = _filteredNotes;

    return Scaffold(
      backgroundColor: palette.bgBase,
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: palette.brandNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Yenilə',
                    onPressed: _loadNotes,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                  title: Text(
                    'Akademik Qeydlər',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              palette.brandNavy,
                              const Color(0xFF1E293B),
                              const Color(0xFF0F172A),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          Icons.sticky_note_2_rounded,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        top: 75,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.white54,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_allNotes.length} qeyd',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Müəllimlərin şagird və dərslər haqqında qeydləri',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  child: ResponsiveCenter(
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        // Search & Filter header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Search Input
                                TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Fənn, müəllim və ya qeyd axtar...',
                                    hintStyle: TextStyle(color: palette.textTertiary, fontSize: 13.5),
                                    prefixIcon: Icon(Icons.search_rounded, color: palette.textTertiary, size: 20),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: palette.surface1,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: palette.borderHairline),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: palette.borderHairline),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: palette.brandRoyal, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Quick Category Filter Pills (Horizontal Scroll)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: _categories.map((cat) {
                                      final id = cat['id'] as String;
                                      final label = cat['label'] as String;
                                      final icon = cat['icon'] as IconData;
                                      final color = cat['color'] as Color;
                                      final count = _countForType(id);
                                      final isSelected = _selectedType == id;

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: InkWell(
                                          onTap: () => setState(() => _selectedType = id),
                                          borderRadius: BorderRadius.circular(20),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? color
                                                  : palette.surface1,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSelected
                                                    ? color
                                                    : palette.borderHairline,
                                                width: 1,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: color.withValues(alpha: 0.25),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  icon,
                                                  size: 15,
                                                  color: isSelected ? Colors.white : color,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                    color: isSelected ? Colors.white : palette.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.white.withValues(alpha: 0.25)
                                                        : palette.surface2,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '$count',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: isSelected ? Colors.white : palette.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Empty State or List
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notes_rounded,
                                      size: 36,
                                      color: palette.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Heç bir akademik qeyd tapılmadı',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Seçilmiş filtrlərə uyğun heç bir qeyd mövcud deyil.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                  if (_selectedType != 'all' || _searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedType = 'all';
                                          _searchController.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.undo_rounded, size: 16),
                                      label: const Text('Filtrləri sıfırla', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final note = filtered[index];
                                  return _buildNoteCard(context, note, palette);
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> note, AppPalette palette) {
    final borderColor = _parseHex(note['borderColor']?.toString(), const Color(0xFF6366F1));
    final type = note['type']?.toString() ?? 'student_note';
    final typeLabel = note['typeLabel']?.toString() ?? 'Qeyd';
    final subject = note['subject']?.toString() ?? '–';
    final teacher = note['teacher']?.toString() ?? note['authorName']?.toString() ?? 'Müəllim';
    final teacherRole = note['teacherRole']?.toString() ?? 'Müəllim';
    final date = note['formattedDate']?.toString() ?? note['date']?.toString() ?? '–';
    final body = (note['body'] ?? '').toString().trim();
    final title = (note['title'] ?? '').toString().trim();
    final refCode = note['refCode']?.toString() ?? '#${note['id'] ?? ''}';
    final grade = note['grade'];
    final status = note['status']?.toString();
    final isCopied = _copiedNoteId == (note['id']?.toString() ?? '');

    // Icon per type
    IconData typeIcon = Icons.sticky_note_2_rounded;
    if (type == 'grade') {
      typeIcon = Icons.school_rounded;
    } else if (type == 'attendance') {
      typeIcon = Icons.access_time_rounded;
    } else if (type == 'assignment') {
      typeIcon = Icons.assignment_rounded;
    } else if (type == 'student_note') {
      typeIcon = Icons.edit_note_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Color Strip
              Container(
                width: 5,
                color: borderColor,
              ),

              // Main Card Content
              Expanded(
                child: InkWell(
                  onTap: () => _showNoteDetails(note),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Type Badge, Subject Chip, Score / Status Pill & Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: borderColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(typeIcon, size: 13, color: borderColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    typeLabel,
                                    style: TextStyle(
                                      color: borderColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Subject Chip (if available)
                            if (subject != '–') ...[
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: palette.surface2,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    subject,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            const Spacer(),

                            // Grade Score or Attendance Status Badge
                            if (type == 'grade' && grade != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Bal: $grade',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),

                            if (type == 'attendance' && status != null && status.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                            const SizedBox(width: 6),

                            // Date
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Title (if meaningful)
                        if (title.isNotEmpty &&
                            title != 'Şagird qeydi' &&
                            title != 'Akademik qeyd' &&
                            !title.startsWith('Qiymət:') &&
                            !title.startsWith('Davamiyyət:')) ...[
                          const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Note Content Bubble
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.surface2.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.borderHairline.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            body.isNotEmpty ? body : (title.isNotEmpty ? title : 'Qeyd mətni yoxdur'),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Card Footer: Teacher Info + Ref Code + Copy Button
                        Row(
                          children: [
                            // Teacher avatar icon
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: palette.brandNavy.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: palette.brandNavy,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Teacher name & role
                            Expanded(
                              child: RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$teacher ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '($teacherRole)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Ref code chip
                            Text(
                              refCode,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: palette.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // One-tap Copy Note Button
                            InkWell(
                              onTap: () => _copyToClipboard(note),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isCopied
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : palette.surface2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: isCopied
                                      ? const Icon(
                                          Icons.check_rounded,
                                          key: ValueKey('copied'),
                                          size: 15,
                                          color: AppColors.success,
                                        )
                                      : Icon(
                                          Icons.copy_rounded,
                                          key: const ValueKey('copy'),
                                          size: 15,
                                          color: palette.textSecondary,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
