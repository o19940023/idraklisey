import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/app_state.dart';

class ExcusedAbsencesScreen extends StatefulWidget {
  final String? initialStudentId;

  const ExcusedAbsencesScreen({super.key, this.initialStudentId});

  @override
  State<ExcusedAbsencesScreen> createState() => _ExcusedAbsencesScreenState();
}

class _ExcusedAbsencesScreenState extends State<ExcusedAbsencesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allExcuses = [];
  String _selectedStatus = 'Hamısı';
  String _selectedChildId = 'all';

  final List<String> _statuses = ['Hamısı', 'Gözləmədə', 'Təsdiqləndi', 'Rədd edildi'];

  @override
  void initState() {
    super.initState();
    if (widget.initialStudentId != null) {
      _selectedChildId = widget.initialStudentId!;
    }
    _loadExcuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExcuses() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    final isParent = user?.role == UserRole.parent;

    String? parentId;
    String? studentId;

    if (isParent) {
      parentId = (user != null && user.id.isNotEmpty) ? user.id : '1474';
      if (_selectedChildId != 'all') {
        studentId = _selectedChildId;
      }
    }

    final data = await SchoolApiService.instance.fetchExcuses(
      parentId: parentId,
      studentId: studentId,
    );

    if (!mounted) return;
    setState(() {
      _allExcuses = data;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredExcuses {
    final query = _searchController.text.trim().toLowerCase();
    return _allExcuses.where((a) {
      final st = a['status']?.toString() ?? 'Gözləmədə';
      final matchesStatus = _selectedStatus == 'Hamısı' || st.toLowerCase() == _selectedStatus.toLowerCase();

      final sName = (a['studentName']?.toString() ?? '').toLowerCase();
      final cName = (a['className']?.toString() ?? '').toLowerCase();
      final docNo = (a['documentNo']?.toString() ?? '').toLowerCase();
      final reason = (a['reason']?.toString() ?? '').toLowerCase();

      final matchesSearch = query.isEmpty ||
          sName.contains(query) ||
          cName.contains(query) ||
          docNo.contains(query) ||
          reason.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _showNewExcuseModal(BuildContext context, {String? preselectedStudentId, String? defaultReason}) {
    final palette = AppPalette.of(context);
    final appState = Provider.of<AppState>(context, listen: false);
    final children = appState.children;

    String selectedChild = preselectedStudentId ?? (children.isNotEmpty ? children.first.id : '851');
    String selectedCategory = 'health';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final noteController = TextEditingController(text: defaultReason ?? '');

    final categories = [
      {'key': 'health', 'title': 'Tibbi Arayış (Səhhət)', 'icon': Icons.medical_services_rounded, 'color': AppColors.danger},
      {'key': 'early_leave', 'title': 'Dərsdən Tez Getmə', 'icon': Icons.access_time_filled_rounded, 'color': AppColors.warning},
      {'key': 'pickup_person', 'title': 'Şəxs Tərəfindən Götürülmə', 'icon': Icons.person_pin_circle_rounded, 'color': palette.brandAzure},
      {'key': 'leave_alone', 'title': 'Tək Getmə (Məsuliyyət)', 'icon': Icons.directions_walk_rounded, 'color': palette.brandRoyal},
      {'key': 'travel', 'title': 'Səyahət Ərizəsi', 'icon': Icons.flight_takeoff_rounded, 'color': AppColors.emerald},
      {'key': 'general', 'title': 'Ümumi / Digər Ərizə', 'icon': Icons.edit_note_rounded, 'color': palette.textSecondary},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final selStudent = children.cast<StudentProfile?>().firstWhere(
                (c) => c?.id == selectedChild,
                orElse: () => children.isNotEmpty ? children.first : null,
              );

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: palette.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Üzürlü Qayıb / Ərizə Sorğusu',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Rəsmi sənəd qeydiyyatı və məktəbə göndəriş',
                                style: TextStyle(fontSize: 12, color: palette.textSecondary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: palette.borderHairline, height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (children.isNotEmpty) ...[
                            const Text('Övladınızı seçin *',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: children.map((ch) {
                                final isSel = selectedChild == ch.id;
                                return ChoiceChip(
                                  label: Text('${ch.fullName} (${ch.className})'),
                                  selected: isSel,
                                  onSelected: (val) {
                                    if (val) setModalState(() => selectedChild = ch.id);
                                  },
                                  selectedColor: palette.brandRoyal,
                                  labelStyle: TextStyle(
                                    color: isSel ? Colors.white : palette.textPrimary,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  backgroundColor: palette.surface2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const Text('Müraciət / Ərizə Forması *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final cat in categories)
                            InkWell(
                              onTap: () => setModalState(() => selectedCategory = cat['key'] as String),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedCategory == cat['key']
                                      ? (cat['color'] as Color).withValues(alpha: 0.12)
                                      : palette.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedCategory == cat['key']
                                        ? (cat['color'] as Color)
                                        : palette.borderHairline,
                                    width: selectedCategory == cat['key'] ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(cat['icon'] as IconData, size: 20, color: cat['color'] as Color),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        cat['title'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selectedCategory == cat['key']
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (selectedCategory == cat['key'])
                                      Icon(Icons.check_circle_rounded, size: 18, color: cat['color'] as Color),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 14),

                          // Date range picker
                          const Text('Tarix Aralığı *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: startDate,
                                      firstDate: DateTime(2025),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) {
                                      setModalState(() {
                                        startDate = d;
                                        if (endDate.isBefore(startDate)) endDate = startDate;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: palette.borderHairline),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 15, color: palette.brandAzure),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('dd.MM.yyyy').format(startDate),
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('—', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: endDate,
                                      firstDate: startDate,
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) setModalState(() => endDate = d);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: palette.borderHairline),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.event_available_rounded, size: 15, color: AppColors.emerald),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('dd.MM.yyyy').format(endDate),
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text('Səbəbin təsviri / Qeyd *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Xahişinizi və ya səbəbi ətraflı qeyd edin...',
                              filled: true,
                              fillColor: palette.surface2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: palette.borderHairline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: palette.borderHairline),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.brandRoyal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'Sorğunu Təsdiqlə və Göndər',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            onPressed: () async {
                              final reasonText = noteController.text.trim();
                              if (reasonText.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Zəhmət olmasa səbəb və ya müraciət mətnini daxil edin.'),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(ctx);
                              setState(() => _isLoading = true);

                              final postData = {
                                'studentId': selectedChild,
                                'studentName': selStudent?.fullName ?? 'Şagird',
                                'startDate': DateFormat('yyyy-MM-dd').format(startDate),
                                'endDate': DateFormat('yyyy-MM-dd').format(endDate),
                                'reason': '[$selectedCategory] $reasonText',
                                'category': selectedCategory,
                                'documentNo': 'ƏRİZƏ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              };

                              final ok = await SchoolApiService.instance.saveExcuse(postData);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Üzürlü qayıb sorğusu rəsmi olaraq göndərildi və qeydiyyata alındı!'
                                        : 'Xəta baş verdi, yenidən cəhd edin.'),
                                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                                  ),
                                );
                                _loadExcuses();
                              }
                            },
                          ),
                        ],
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

  Future<void> _handleStatusUpdate(String id, String status) async {
    final ok = await SchoolApiService.instance.updateExcuseStatus(id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Müraciət statusu uğurla yeniləndi!' : 'Xəta baş verdi.'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
    if (ok) _loadExcuses();
  }

  Future<void> _handleRejectWithReason(String id) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müraciəti İmtina Et', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('İmtina səbəbini qeyd edin:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Məsələn: Sənəd natamamdır və ya tarix uyğun deyil',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bağla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İmtina Et'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SchoolApiService.instance.updateExcuseStatus(
      id,
      'rejected',
      reason: reasonController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Müraciət imtina edildi.' : 'Xəta baş verdi.'),
        backgroundColor: ok ? AppColors.warning : AppColors.danger,
      ),
    );
    if (ok) _loadExcuses();
  }

  Future<void> _handleEdit(Map<String, dynamic> a) async {
    final palette = AppPalette.of(context);
    DateTime startDate = DateTime.tryParse(a['startDate']?.toString() ?? '') ?? DateTime.now();
    DateTime endDate = DateTime.tryParse(a['endDate']?.toString() ?? '') ?? startDate;
    final noteController = TextEditingController(text: a['note']?.toString() ?? (a['reason']?.toString() ?? ''));

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Müraciəti Redaktə Et',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx, false)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (d != null) {
                                setModalState(() {
                                  startDate = d;
                                  if (endDate.isBefore(startDate)) endDate = startDate;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: palette.borderHairline)),
                              child: Text('Başlanğıc: ${DateFormat('yyyy-MM-dd').format(startDate)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime(2030));
                              if (d != null) setModalState(() => endDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: palette.borderHairline)),
                              child: Text('Bitmə: ${DateFormat('yyyy-MM-dd').format(endDate)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Qeyd / Səbəb',
                        filled: true,
                        fillColor: palette.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: palette.brandRoyal, padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Yadda saxla', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () async {
                        final ok = await SchoolApiService.instance.updateExcuseStatus(
                          a['id'].toString(),
                          '',
                          extra: {
                            'action': 'edit',
                            'startDate': DateFormat('yyyy-MM-dd').format(startDate),
                            'endDate': DateFormat('yyyy-MM-dd').format(endDate),
                            'note': noteController.text.trim(),
                          },
                        );
                        if (ctx.mounted) Navigator.pop(ctx, ok);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Məlumatlar uğurla yeniləndi'), backgroundColor: AppColors.success),
      );
      _loadExcuses();
    }
  }

  void _showApplicationDialog(String studentName, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text('$studentName - Ərizə Mətni', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bağla')),
        ],
      ),
    );
  }

  void _showDocumentDialog(String? docUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_present_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Tibbi Arayış Sənədi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
        content: docUrl != null && docUrl.isNotEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      docUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Sənəd təsviri açıla bilmədi və ya PDF formatındadır.'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(docUrl, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )
            : const Text('Bu müraciət üçün heç bir sənəd faylı yüklənməyib.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bağla')),
        ],
      ),
    );
  }

  Future<void> _handleDelete(Map<String, dynamic> a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qeydi sil'),
        content: Text('${a['studentName']} üzürlü qayıb qeydi silinsin?'),
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
    final ok = await SchoolApiService.instance.deleteExcuse(a['id'].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Qeyd silindi' : 'Əməliyyat alınmadı'), backgroundColor: ok ? AppColors.success : AppColors.danger),
    );
    if (ok) _loadExcuses();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isParent = user?.role == UserRole.parent;
    final canApprove = user?.role == UserRole.admin || user?.role == UserRole.teacher;
    final children = appState.children;
    final excuses = _filteredExcuses;

    final pendingCount = _allExcuses.where((e) => (e['status'] ?? '').toString().toLowerCase().contains('gözlə')).length;
    final approvedCount = _allExcuses.where((e) => (e['status'] ?? '').toString().toLowerCase().contains('təsdiq')).length;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: palette.brandNavy,
        foregroundColor: Colors.white,
        title: Text(
          isParent ? 'Üzrlü Qayıblar və Arayışlarım' : 'Üzrlü Qayıblar və Arayışlar',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadExcuses,
            tooltip: 'Yenilə',
          ),
        ],
      ),
      floatingActionButton: isParent
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              foregroundColor: Colors.white,
              onPressed: () => _showNewExcuseModal(context),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                'Sorğu Göndər',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExcuses,
              child: ResponsiveCenter(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: [
                    // Child Filter for Parent
                    if (isParent && children.isNotEmpty) ...[
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('Bütün Övladlar'),
                                selected: _selectedChildId == 'all',
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedChildId = 'all');
                                    _loadExcuses();
                                  }
                                },
                                selectedColor: palette.brandRoyal,
                                labelStyle: TextStyle(
                                  color: _selectedChildId == 'all' ? Colors.white : palette.textPrimary,
                                  fontWeight: _selectedChildId == 'all' ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                backgroundColor: palette.surface1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  side: BorderSide(
                                    color: _selectedChildId == 'all' ? palette.brandRoyal : palette.borderHairline,
                                  ),
                                ),
                              ),
                            ),
                            for (final ch in children)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${ch.fullName} (${ch.className})'),
                                  selected: _selectedChildId == ch.id,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _selectedChildId = ch.id);
                                      _loadExcuses();
                                    }
                                  },
                                  selectedColor: palette.brandRoyal,
                                  labelStyle: TextStyle(
                                    color: _selectedChildId == ch.id ? Colors.white : palette.textPrimary,
                                    fontWeight: _selectedChildId == ch.id ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  backgroundColor: palette.surface1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    side: BorderSide(
                                      color: _selectedChildId == ch.id ? palette.brandRoyal : palette.borderHairline,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Top Stat Cards
                    StatCardRow(
                      columns: 3,
                      spacing: 8,
                      children: [
                        StatCard(
                          compact: true,
                          value: '${_allExcuses.length}',
                          label: 'Cəmi Qeyd',
                          icon: Icons.event_note_rounded,
                          color: palette.brandRoyal,
                        ),
                        StatCard(
                          compact: true,
                          value: '$pendingCount',
                          label: 'Gözləyir',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                        ),
                        StatCard(
                          compact: true,
                          value: '$approvedCount',
                          label: 'Təsdiqləndi',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.emerald,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Search Bar
                    AppSearchBar(
                      controller: _searchController,
                      hintText: 'Şagird adı, sinif və ya sənəd kodu ilə axtar...',
                      onChanged: (_) => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 10),

                    // Status Filters
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statuses.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final st = _statuses[index];
                          final isSelected = st == _selectedStatus;
                          return ChoiceChip(
                            label: Text(st),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedStatus = st);
                            },
                            selectedColor: palette.brandRoyal,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : palette.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 11.5,
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

                    const SizedBox(height: 14),

                    SectionHeader(
                      title: isParent ? 'Qayıb və Arayış Qeydləri' : 'Qeydə Alınmış İcazələr',
                      subtitle: '${excuses.length} qeyd göstərilir',
                    ),

                    const SizedBox(height: 6),

                    if (excuses.isEmpty)
                      AppEmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Heç bir qayıb və ya arayış tapılmadı',
                        message: isParent
                            ? 'Övladınızın heç bir arayış tələb olunan qayıbı yoxdur. İstədiyiniz halda aşağıdakı düymə ilə qabaqcadan üzürlü qayıb sorğusu göndərə bilərsiniz.'
                            : 'Meyarlara uyğun müraciət tapılmadı.',
                      )
                    else
                      for (final a in excuses)
                        _buildExcuseCard(context, palette, a, canApprove, isParent),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExcuseCard(
    BuildContext context,
    AppPalette palette,
    Map<String, dynamic> a,
    bool canApprove,
    bool isParent,
  ) {
    final statusStr = a['status']?.toString() ?? 'Gözləmədə';
    final isApproved = statusStr.toLowerCase().contains('təsdiq');
    final isRejected = statusStr.toLowerCase().contains('rədd');
    final statusColor = isApproved ? AppColors.emerald : (isRejected ? AppColors.danger : AppColors.gold);

    final rawReason = a['reason']?.toString() ?? 'Qayıb';
    final isJournalAbsence = (a['source']?.toString() ?? '') == 'attendance_journal';
    final isMedicalRef = (a['source']?.toString() ?? '') == 'medical_reference';

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isMedicalRef
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : (isJournalAbsence
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : palette.brandRoyal.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMedicalRef
                          ? Icons.medical_services_rounded
                          : (isJournalAbsence ? Icons.event_busy_rounded : Icons.edit_note_rounded),
                      size: 13,
                      color: isMedicalRef
                          ? AppColors.danger
                          : (isJournalAbsence ? AppColors.warning : palette.brandRoyal),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isMedicalRef ? 'Tibbi Arayış' : (isJournalAbsence ? 'Sistem Qayıbı' : 'Ərizə Sorğusu'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isMedicalRef
                            ? AppColors.danger
                            : (isJournalAbsence ? AppColors.warning : palette.brandRoyal),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: statusStr,
                color: statusColor,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['studentName']?.toString() ?? 'Şagird',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sinif: ${a['className'] ?? '-'}  •  Sənəd: ${a['documentNo'] ?? '-'}',
                      style: TextStyle(
                        color: palette.brandAzure,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.notes_rounded, size: 14, color: palette.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rawReason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 14, color: palette.brandRoyal),
                    const SizedBox(width: 6),
                    Text(
                      '${a['startDate']} - ${a['endDate']}',
                      style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '${a['days']} gün',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
          ),

          // Medical status badge & Category
          if (a['medicalStatus'] != null || a['category'] == 'health') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (a['medicalStatus'] == 'approved') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.emerald),
                        const SizedBox(width: 4),
                        Text('Həkim Təsdiqləyib${a['medicalVerifier'] != null && a['medicalVerifier'].toString().isNotEmpty ? ' (${a['medicalVerifier']})' : ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                      ],
                    ),
                  ),
                ] else if (a['category'] == 'health') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text('Həkim Təsdiqi Gözlənilir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Document / Application View Buttons
          if (a['documentUrl'] != null || a['applicationText'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (a['documentUrl'] != null && a['documentUrl'].toString().isNotEmpty) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.file_present_rounded, size: 15),
                    label: const Text('Arayışa Bax', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    onPressed: () => _showDocumentDialog(a['documentUrl']?.toString()),
                  ),
                  const SizedBox(width: 8),
                ],
                if (a['applicationText'] != null && a['applicationText'].toString().isNotEmpty) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.brandRoyal,
                      side: BorderSide(color: palette.brandRoyal),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.description_rounded, size: 15),
                    label: const Text('Ərizəyə Bax', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    onPressed: () => _showApplicationDialog(a['studentName']?.toString() ?? 'Şagird', a['applicationText'].toString()),
                  ),
                ],
              ],
            ),
          ],

          // Absent Lessons Chips
          if (a['absentLessons'] is List && (a['absentLessons'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Qayıb dərsləri:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final l in (a['absentLessons'] as List))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(6), border: Border.all(color: palette.borderHairline)),
                    child: Text(
                      '${l['date']}: ${l['title']}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],

          // Action buttons: If Parent and unexcused journal absence -> "Arayış Yüklə / Sorğu Göndər"
          if (isParent && isJournalAbsence && !isApproved) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.brandRoyal,
                  side: BorderSide(color: palette.brandRoyal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Bu Qayıb üçün Arayış Yüklə / Ərizə Yaz',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                onPressed: () => _showNewExcuseModal(
                  context,
                  preselectedStudentId: a['studentId']?.toString(),
                  defaultReason: 'Tarix: ${a['startDate']} dərslər üzrə üzürlü qayıb arayışı',
                ),
              ),
            ),
          ],

          // Action buttons for Admin/Teacher to approve/reject/edit
          if (canApprove && !isApproved && !isRejected && a['source'] == 'excuse_request') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Təsdiqlə', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    onPressed: () => _handleStatusUpdate(a['id'].toString(), 'approved'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('İmtina', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    onPressed: () => _handleRejectWithReason(a['id'].toString()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  tooltip: 'Redaktə et',
                  onPressed: () => _handleEdit(a),
                ),
              ],
            ),
          ],
          if (canApprove) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isApproved || isRejected)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: palette.brandRoyal),
                    onPressed: () => _handleEdit(a),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Tarixləri / Qeydi Dəyiş', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  )
                else
                  const SizedBox.shrink(),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: () => _handleDelete(a),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
