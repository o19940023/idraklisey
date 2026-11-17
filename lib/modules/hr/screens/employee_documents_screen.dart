import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/employee_model.dart';

class EmployeeDocumentsScreen extends StatefulWidget {
  final String? employeeId;
  final String? employeeName;

  const EmployeeDocumentsScreen({
    super.key,
    this.employeeId,
    this.employeeName,
  });

  @override
  State<EmployeeDocumentsScreen> createState() => _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState extends State<EmployeeDocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTypeId = 0;
  String _selectedStatus = 'Hamısı';
  bool _isLoading = true;

  List<EmployeeDocument> _documents = [];
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _documentTypes = [];

  final List<String> _statuses = ['Hamısı', 'Aktiv', 'Tamamlanmış', 'Ləğv edilmiş', 'Qaralama'];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final res = await SchoolApiService.instance.fetchEmployeeDocumentsData(
        documentTypeId: _selectedTypeId > 0 ? _selectedTypeId : null,
        employeeId: widget.employeeId,
        status: _selectedStatus != 'Hamısı' ? _selectedStatus : null,
        search: _searchController.text.trim(),
      );

      if (res != null && res['success'] == true) {
        _summary = (res['summary'] as Map?)?.cast<String, dynamic>() ?? {};
        _documentTypes = (res['documentTypes'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        final rawList = (res['data'] as List?) ?? [];
        final parsed = rawList.map((m) => EmployeeDocument.fromJson(Map<String, dynamic>.from(m as Map))).toList();

        if (mounted) {
          setState(() {
            _documents = parsed;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<EmployeeDocument> get _filteredDocuments {
    final query = _searchController.text.trim().toLowerCase();
    return _documents.where((doc) {
      final matchesStatus = switch (_selectedStatus) {
        'Aktiv' => doc.status == 'active',
        'Tamamlanmış' => doc.status == 'completed',
        'Ləğv edilmiş' => doc.status == 'cancelled',
        'Qaralama' => doc.status == 'draft',
        _ => true,
      };
      final matchesType = _selectedTypeId == 0 || doc.documentTypeId == _selectedTypeId;
      final matchesSearch = query.isEmpty ||
          doc.employeeName.toLowerCase().contains(query) ||
          doc.documentNumber.toLowerCase().contains(query) ||
          doc.documentType.toLowerCase().contains(query) ||
          doc.employeeFin.toLowerCase().contains(query) ||
          doc.notes.toLowerCase().contains(query);
      return matchesStatus && matchesType && matchesSearch;
    }).toList();
  }

  (IconData, Color) _getDocTypeVisuals(String code, String name) {
    final c = code.toUpperCase();
    final n = name.toLowerCase();

    if (c.contains('XITAM') || c.contains('AZAD') || n.contains('xitam') || n.contains('azad')) {
      return (Icons.person_remove_rounded, AppColors.danger);
    }
    if (c.contains('MEZUNIYYET') || n.contains('məzuniyyət')) {
      return (Icons.beach_access_rounded, const Color(0xFFF59E0B));
    }
    if (c.contains('MUKAFAT') || n.contains('mükafat') || n.contains('yardım')) {
      return (Icons.military_tech_rounded, const Color(0xFF10B981));
    }
    if (c.contains('EZAMIYYET') || n.contains('ezamiyyət')) {
      return (Icons.flight_takeoff_rounded, const Color(0xFF06B6D4));
    }
    if (c.contains('TOHMET') || c.contains('TENBEH') || n.contains('töhmət')) {
      return (Icons.gavel_rounded, const Color(0xFFEF4444));
    }
    if (c.contains('HAQQI') || n.contains('maaş') || n.contains('haqqı')) {
      return (Icons.payments_rounded, const Color(0xFF8B5CF6));
    }
    if (c.contains('VEZIFE') || n.contains('vəzifə')) {
      return (Icons.badge_rounded, const Color(0xFF3B82F6));
    }
    return (Icons.description_rounded, const Color(0xFF2563EB));
  }

  void _showDocumentDetailSheet(EmployeeDocument doc) {
    final palette = AppPalette.of(context);
    String formatDate(DateTime? dt) =>
        dt == null ? '—' : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

    Widget rowItem(String label, String value, {bool isBold = false, bool isHighlight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isHighlight ? palette.brandAzure : palette.textPrimary,
                  fontSize: isBold ? 14 : 13,
                  fontWeight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final (iconData, iconColor) = _getDocTypeVisuals(doc.documentTypeCode, doc.documentType);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.documentType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(doc.documentNumber, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: doc.statusLabel,
                      color: doc.status == 'active'
                          ? AppColors.emerald
                          : (doc.status == 'cancelled' ? AppColors.danger : AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                rowItem('Əməkdaş', doc.employeeName, isBold: true),
                if (doc.employeePosition.isNotEmpty) rowItem('Vəzifə', doc.employeePosition),
                if (doc.employeeFin.isNotEmpty) rowItem('FİN Kod', doc.employeeFin),
                if (doc.employeeCode.isNotEmpty) rowItem('Əməkdaş Kodu', doc.employeeCode),
                rowItem('Sənədin Başlama Tarixi', formatDate(doc.issueDate)),
                if (doc.expiryDate != null) rowItem('Sənədin Bitmə Tarixi', formatDate(doc.expiryDate)),
                rowItem('Əlavə Edən', doc.creatorName),
                if (doc.notes.trim().isNotEmpty) rowItem('Qeyd / Əsaslandırma', doc.notes),
                const SizedBox(height: 16),

                // Download Template action if available
                if (doc.templates.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...doc.templates.map((t) {
                    final title = t['title']?.toString() ?? 'Word Şablonu';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$title endirilir...'),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text('Endir: $title (.docx)', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDocument(EmployeeDocument doc) async {
    final palette = AppPalette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface1,
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Sənədi Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '${doc.documentNumber} nömrəli sənədi (${doc.documentType}) silmək istədiyinizə əminsiniz?',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İmtina'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bəli, Sil'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await SchoolApiService.instance.deleteEmployeeDocument(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Sənəd uğurla silindi' : 'Xəta baş verdi'),
            backgroundColor: success ? AppColors.emerald : AppColors.danger,
          ),
        );
        if (success) _loadDocuments();
      }
    }
  }

  Future<void> _openCreateDocumentModal() async {
    final palette = AppPalette.of(context);
    int? selectedEmpId = int.tryParse(widget.employeeId ?? '');
    String selectedEmpName = widget.employeeName ?? '';
    int? selectedTypeId;
    final startCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    final endCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    // Fetch employee list for picker
    List<Map<String, dynamic>> employees = [];
    try {
      final rawEmps = await SchoolApiService.instance.fetchEmployees();
      employees = rawEmps.map((e) {
        final f = e['first_name'] ?? e['name'] ?? '';
        final l = e['last_name'] ?? '';
        final fullName = ('$f $l').trim();
        return {
          'id': e['id']?.toString() ?? '',
          'name': fullName.isNotEmpty ? fullName : (e['code'] ?? 'Əməkdaş'),
          'position': e['position'] ?? e['positionTitle'] ?? 'Vəzifə',
          'code': e['code'] ?? '',
        };
      }).toList();
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Yeni İşçi Sənədi Əlavə Et',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Employee Dropdown / Selector
                    if (widget.employeeId == null) ...[
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Əməkdaş *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: employees.map((emp) {
                          final id = int.tryParse(emp['id'].toString()) ?? 0;
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${emp['name']} (${emp['position']})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedEmpId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Əməkdaş: $selectedEmpName', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Document Type Dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Sənəd Tipi *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _documentTypes.map((dt) {
                        final id = int.tryParse(dt['id'].toString()) ?? 0;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            dt['name']?.toString() ?? 'Sənəd',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedTypeId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Start Date
                    TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Başlama Tarixi (YYYY-MM-DD) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // End Date (Optional)
                    TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bitmə Tarixi (Opsional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Əsaslandırma / Qeyd',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Button
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (selectedEmpId == null || selectedEmpId! <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Zəhmət olmasa əməkdaş seçin')),
                          );
                          return;
                        }
                        if (selectedTypeId == null || selectedTypeId! <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Zəhmət olmasa sənəd tipini seçin')),
                          );
                          return;
                        }

                        final res = await SchoolApiService.instance.createEmployeeDocument(
                          employeeId: selectedEmpId!,
                          documentTypeId: selectedTypeId!,
                          startDate: startCtrl.text.trim(),
                          endDate: endCtrl.text.trim().isNotEmpty ? endCtrl.text.trim() : null,
                          notes: noteCtrl.text.trim(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          final ok = res != null && res['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Sənəd uğurla qeydiyyata alındı!' : 'Xəta baş verdi'),
                              backgroundColor: ok ? AppColors.emerald : AppColors.danger,
                            ),
                          );
                          if (ok) _loadDocuments();
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Bazada Qeydiyyata Al', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String title, dynamic value, Color col, AppPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value?.toString() ?? '0',
          style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final documents = _filteredDocuments;
    final isSingleEmployee = widget.employeeId != null && widget.employeeId!.isNotEmpty;
    final titleText = isSingleEmployee ? '${widget.employeeName ?? 'Əməkdaş'} — Sənədlər' : 'Əməkdaş Sənədləri';

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenilə',
            onPressed: _loadDocuments,
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Yeni Sənəd',
            onPressed: _openCreateDocumentModal,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.brandRoyal,
        foregroundColor: Colors.white,
        onPressed: _openCreateDocumentModal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Sənəd', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            if (!isSingleEmployee) ...[
              // Summary Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.surface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniStat('Cəmi', _summary['totalDocuments'] ?? _documents.length, palette.textPrimary, palette),
                    Container(width: 1, height: 26, color: palette.borderHairline),
                    _miniStat('Aktiv', _summary['activeDocuments'] ?? 0, AppColors.emerald, palette),
                    Container(width: 1, height: 26, color: palette.borderHairline),
                    _miniStat('Şablonlar', _summary['templatesCount'] ?? 0, palette.brandRoyal, palette),
                    Container(width: 1, height: 26, color: palette.borderHairline),
                    _miniStat('Bu Ay', _summary['thisMonthCount'] ?? 0, AppColors.gold, palette),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Sənəd nömrəsi, FİN, əməkdaş və ya növ axtar...',
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),

              // Filter Chips: Status
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statuses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = status == _selectedStatus;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedStatus = status);
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
                        side: BorderSide(
                          color: isSelected ? palette.brandRoyal : palette.borderHairline,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Filter Chips: Document Types (Categories)
              if (_documentTypes.isNotEmpty) ...[
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _documentTypes.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSel = _selectedTypeId == 0;
                        return ChoiceChip(
                          label: const Text('Bütün Növlər'),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedTypeId = 0);
                          },
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : palette.textSecondary,
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: palette.surface2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }
                      final dt = _documentTypes[index - 1];
                      final dtId = int.tryParse(dt['id'].toString()) ?? 0;
                      final isSel = _selectedTypeId == dtId;

                      return ChoiceChip(
                        label: Text(dt['name']?.toString() ?? 'Sənəd'),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => _selectedTypeId = dtId);
                        },
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : palette.textSecondary,
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: palette.surface2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],

            SectionHeader(
              title: isSingleEmployee ? 'Əməkdaşın Rəsmi Sənədləri' : 'Sənəd Dövriyyəsi',
              subtitle: _isLoading ? 'Baza ilə sinxronlaşdırılır...' : '${documents.length} sənəd tapıldı',
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : documents.isEmpty
                      ? Center(
                          child: Text(
                            'Uyğun sənəd tapılmadı',
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            final (iconData, iconColor) = _getDocTypeVisuals(doc.documentTypeCode, doc.documentType);

                            return ModernCard(
                              onTap: () => _showDocumentDetailSheet(doc),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Document number + Status badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: palette.surface2,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.tag_rounded, size: 13, color: palette.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              doc.documentNumber,
                                              style: TextStyle(
                                                color: palette.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(
                                        label: doc.statusLabel,
                                        color: doc.status == 'active'
                                            ? AppColors.emerald
                                            : (doc.status == 'cancelled' ? AppColors.danger : AppColors.gold),
                                        fontSize: 10.5,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Document Type Title with Visual Icon
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: iconColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(iconData, color: iconColor, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc.documentType,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${doc.employeeName} ${doc.employeePosition.isNotEmpty ? "• ${doc.employeePosition}" : ""}',
                                              style: TextStyle(
                                                color: palette.textSecondary,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Info Row: Tarix & Əlavə edən
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: palette.surface2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 13, color: palette.textTertiary),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Tarix: ${doc.issueDate.day.toString().padLeft(2, '0')}.${doc.issueDate.month.toString().padLeft(2, '0')}.${doc.issueDate.year}',
                                              style: TextStyle(color: palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline_rounded, size: 13, color: palette.textTertiary),
                                            const SizedBox(width: 4),
                                            Text(
                                              doc.creatorName,
                                              style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Action Buttons: Baxış, Şablon Endir, Sil
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Endir (Word Template if exists)
                                      if (doc.templates.isNotEmpty) ...[
                                        InkWell(
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${doc.templates.first['title']} endirilir...'),
                                                backgroundColor: AppColors.emerald,
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.download_rounded, size: 14, color: Color(0xFF2563EB)),
                                                SizedBox(width: 4),
                                                Text('Şablon (.docx)', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11.5, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],

                                      // Baxış Düyməsi
                                      InkWell(
                                        onTap: () => _showDocumentDetailSheet(doc),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: palette.surface2,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.visibility_outlined, size: 14),
                                              SizedBox(width: 4),
                                              Text('Baxış', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      // Sil Düyməsi
                                      InkWell(
                                        onTap: () => _confirmDeleteDocument(doc),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
                                              SizedBox(width: 4),
                                              Text('Sil', style: TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
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
