import 'package:flutter/material.dart';
import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class AmbulatoryRequestsScreen extends StatefulWidget {
  const AmbulatoryRequestsScreen({super.key});

  @override
  State<AmbulatoryRequestsScreen> createState() => _AmbulatoryRequestsScreenState();
}

class _AmbulatoryRequestsScreenState extends State<AmbulatoryRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _activeTab = 'all';
  String? _selectedFinalStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic> _counts = {
    'all': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  static const List<(String, String)> _tabs = [
    ('all', 'Bütün'),
    ('pending', 'Gözləyən'),
    ('approved', 'Təsdiq edilmiş'),
    ('rejected', 'İnkar edilmiş'),
  ];

  static const List<(String?, String)> _recommendationFilters = [
    (null, 'Bütün tövsiyələr'),
    ('sent_home', 'Evə göndərilməsi'),
    ('returned_to_class', 'Sinfinə / İşinə qayıtması'),
    ('under_observation', 'Nəzarətdə saxlanılması'),
    ('referred_to_hospital', 'Xəstəxanaya yönləndirilməsi'),
    ('other', 'Digər'),
  ];

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
    final fromStr = _dateFrom != null
        ? '${_dateFrom!.year}-${_dateFrom!.month.toString().padLeft(2, '0')}-${_dateFrom!.day.toString().padLeft(2, '0')}'
        : null;
    final toStr = _dateTo != null
        ? '${_dateTo!.year}-${_dateTo!.month.toString().padLeft(2, '0')}-${_dateTo!.day.toString().padLeft(2, '0')}'
        : null;

    final payload = await SchoolApiService.instance.fetchAmbulatoryData(
      tab: _activeTab,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      finalStatus: _selectedFinalStatus,
      dateFrom: fromStr,
      dateTo: toStr,
    );

    if (!mounted) return;
    setState(() {
      _records = payload != null && payload['data'] is List
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
    if (q.isEmpty && _selectedFinalStatus == null) return _records;
    return _records.where((r) {
      final name = (r['studentName'] ?? '').toString().toLowerCase();
      final cls = (r['className'] ?? '').toString().toLowerCase();
      final cmp = (r['complaints'] ?? '').toString().toLowerCase();
      final meas = (r['measuresTaken'] ?? '').toString().toLowerCase();
      final fin = (r['finalStatus'] ?? '').toString();

      final matchesQuery = q.isEmpty || name.contains(q) || cls.contains(q) || cmp.contains(q) || meas.contains(q);
      final matchesFinal = _selectedFinalStatus == null || fin == _selectedFinalStatus;

      return matchesQuery && matchesFinal;
    }).toList();
  }

  int _count(String key) => (_counts[key] as num?)?.toInt() ?? 0;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.emerald;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Təsdiqlənib';
      case 'rejected':
        return 'İmtina edilib';
      default:
        return 'Gözləyir';
    }
  }

  (Color, IconData, String) _recommendationStyle(String? finalStatus, String? label) {
    final text = (label != null && label.isNotEmpty) ? label : 'Sinfinə / İşinə qayıtması tövsiyə olunur';
    switch (finalStatus) {
      case 'sent_home':
        return (const Color(0xFFD97706), Icons.home_outlined, text);
      case 'under_observation':
        return (const Color(0xFF0284C7), Icons.remove_red_eye_outlined, text);
      case 'referred_to_hospital':
        return (const Color(0xFFDC2626), Icons.local_hospital_outlined, text);
      case 'returned_to_class':
      default:
        return (const Color(0xFF059669), Icons.school_outlined, text);
    }
  }

  Future<void> _approve(Map<String, dynamic> r) async {
    final noteCtrl = TextEditingController();
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sorğunu Təsdiqlə',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              r['studentName'] ?? 'Şagird',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Tövsiyə: ${r['finalStatusLabel'] ?? r['finalStatus'] ?? 'Məktəbdə qaldı'}',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Qərar qeydi (İstəyə bağlı)',
                hintText: 'Məsələn: Valideyn məlumatlandırıldı, şagird evə buraxıldı...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ləğv et', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Təsdiqlə', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    final note = noteCtrl.text.trim();
    final ok = await SchoolApiService.instance.approveAmbulatory(r['id'].toString(), note: note.isNotEmpty ? note : null);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Ambulator sorğusu uğurla təsdiqləndi!' : 'Əməliyyat zamanı xəta baş verdi'),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
      ),
    );
    if (ok) _load();
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final reasonCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sorğuya İmtina',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                r['studentName'] ?? 'Şagird',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'İmtina səbəbi mütləq qeyd olunmalıdır';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'İmtina səbəbi (Məcburi) *',
                  hintText: 'Səbəbi daxil edin...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Qərar qeydi (İstəyə bağlı)',
                  hintText: 'Əlavə qeyd...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ləğv et', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('İmtina et', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    final reason = reasonCtrl.text.trim();
    final note = noteCtrl.text.trim();
    final ok = await SchoolApiService.instance.rejectAmbulatory(
      r['id'].toString(),
      reason,
      note: note.isNotEmpty ? note : null,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Ambulator sorğusu imtina edildi!' : 'Əməliyyat zamanı xəta baş verdi'),
        backgroundColor: ok ? AppColors.emerald : AppColors.danger,
      ),
    );
    if (ok) _load();
  }

  void _showDetailModal(Map<String, dynamic> r) {
    final palette = AppPalette.of(context);
    final isPending = (r['approvalStatus'] ?? 'pending') == 'pending';
    final (recColor, recIcon, recLabel) = _recommendationStyle(
      r['finalStatus']?.toString(),
      r['finalStatusLabel']?.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [palette.brandNavy, palette.brandRoyal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (r['studentName'] ?? 'Ş')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['studentName'] ?? 'Şagird',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if ((r['className'] ?? '').toString().isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: palette.brandRoyal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r['className'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: palette.brandRoyal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  r['formattedDate'] ?? r['date'] ?? '',
                                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor(r['approvalStatus'] ?? '').withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _statusColor(r['approvalStatus'] ?? '').withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _statusLabel(r['approvalStatus'] ?? ''),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _statusColor(r['approvalStatus'] ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Medical Recommendation Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: recColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: recColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(recIcon, color: recColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: recColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Details Grid
                  _infoTile(
                    palette,
                    icon: Icons.person_outline_rounded,
                    title: 'Tibb İşçisi (Qeyd edən)',
                    value: r['nurseName'] ?? 'Tibb bacısı',
                  ),
                  if ((r['address'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoTile(
                      palette,
                      icon: Icons.location_on_outlined,
                      title: 'Yaşayış Ünvanı',
                      value: r['address'],
                    ),
                  ],

                  const SizedBox(height: 12),
                  _textBox(palette, title: 'Şikayətlər', content: r['complaints'] ?? 'Şikayət qeyd olunmayıb.'),
                  const SizedBox(height: 10),
                  _textBox(palette, title: 'Görülən İlkin Tibbi Tədbirlər', content: r['measuresTaken'] ?? 'Görülən tədbir qeyd olunmayıb.'),

                  // Decision section
                  if (!isPending) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qəbul Şöbəsinin Qərarı',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: palette.brandNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Qərar verən: ',
                                style: TextStyle(fontSize: 12, color: palette.textSecondary),
                              ),
                              Text(
                                r['approverName']?.isNotEmpty == true ? r['approverName'] : 'Mütəxəssis',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if ((r['approvedAt'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Tarix: ',
                                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                                ),
                                Text(
                                  r['approvedAt'],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          if ((r['rejectionReason'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'İmtina səbəbi: ${r['rejectionReason']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          if ((r['decisionNote'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Qeyd: ${r['decisionNote']}',
                              style: TextStyle(fontSize: 12, color: palette.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  if (isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _reject(r);
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('İmtina et', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _approve(r);
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Təsdiqlə', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandNavy,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Bağla', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(AppPalette palette, {required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBox(AppPalette palette, {required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.surface2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.35),
          ),
        ),
      ],
    );
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
        title: const Text(
          'Ambulator Sorğuları',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Yenilə',
          ),
        ],
      ),
      body: Column(
        children: [
          // Navy Tab Bar Container
          Container(
            color: palette.brandNavy,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final (key, label) = tab;
                  final isSelected = _activeTab == key;
                  final count = _count(key);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        if (_activeTab != key) {
                          setState(() => _activeTab = key);
                          _load();
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? palette.brandRoyal : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
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
          ),

          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.borderHairline),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Şagird, sinif və ya şikayət üzrə axtar...',
                            hintStyle: TextStyle(fontSize: 13, color: palette.textSecondary),
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: palette.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Recommendation filter button
                    PopupMenuButton<String?>(
                      tooltip: 'Tibbi tövsiyə filtri',
                      initialValue: _selectedFinalStatus,
                      onSelected: (val) {
                        setState(() => _selectedFinalStatus = val);
                        _load();
                      },
                      itemBuilder: (context) => _recommendationFilters.map((f) {
                        return PopupMenuItem<String?>(
                          value: f.$1,
                          child: Text(
                            f.$2,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedFinalStatus == f.$1 ? FontWeight.w800 : FontWeight.w500,
                              color: _selectedFinalStatus == f.$1 ? palette.brandRoyal : null,
                            ),
                          ),
                        );
                      }).toList(),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _selectedFinalStatus != null ? palette.brandRoyal.withValues(alpha: 0.1) : palette.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFinalStatus != null ? palette.brandRoyal : palette.borderHairline,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 19,
                              color: _selectedFinalStatus != null ? palette.brandRoyal : palette.textSecondary,
                            ),
                            if (_selectedFinalStatus != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                'Aktiv',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.brandRoyal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main List View (Full width, no ResponsiveCenter side gutter)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      children: [
                        // List Header Info
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Müraciətlər Siyahısı',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: palette.brandNavy,
                                ),
                              ),
                              Text(
                                '${items.length} sorğu',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (items.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                            decoration: BoxDecoration(
                              color: palette.surface1,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: palette.borderHairline),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 52, color: palette.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'Heç bir ambulator sorğusu tapılmadı',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...items.map((r) => _buildCard(context, palette, r)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppPalette palette, Map<String, dynamic> r) {
    final status = r['approvalStatus'] ?? 'pending';
    final isPending = status == 'pending';
    final (recColor, recIcon, recLabel) = _recommendationStyle(
      r['finalStatus']?.toString(),
      r['finalStatusLabel']?.toString(),
    );

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetailModal(r),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Avatar + Student Name + Class & Date + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.brandNavy,
                            palette.brandRoyal.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (r['studentName'] ?? 'Ş')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['studentName'] ?? 'Şagird',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if ((r['className'] ?? '').toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: palette.brandRoyal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.school_outlined, size: 12, color: palette.brandRoyal),
                                      const SizedBox(width: 3),
                                      Text(
                                        r['className'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: palette.brandRoyal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 11.5, color: palette.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    r['formattedDate'] ?? r['date'] ?? '',
                                    style: TextStyle(fontSize: 11.5, color: palette.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _statusColor(status).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'approved'
                                ? Icons.check_circle_rounded
                                : status == 'rejected'
                                    ? Icons.cancel_rounded
                                    : Icons.access_time_rounded,
                            size: 12,
                            color: _statusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Medical Recommendation Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: recColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: recColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(recIcon, size: 15, color: recColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: recColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Complaints & Measures preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.surface2.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: palette.textPrimary),
                          children: [
                            const TextSpan(
                              text: 'Şikayət: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: r['complaints'] ?? 'Ümumi narahatlıq'),
                          ],
                        ),
                      ),
                      if ((r['measuresTaken'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                            children: [
                              const TextSpan(
                                text: 'Görülən tədbir: ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: r['measuresTaken']),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Nurse Name & Address
                if ((r['nurseName'] ?? '').toString().isNotEmpty || (r['address'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((r['nurseName'] ?? '').toString().isNotEmpty) ...[
                        Icon(Icons.medical_services_outlined, size: 13, color: palette.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r['nurseName'],
                            style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if ((r['address'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined, size: 13, color: palette.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            r['address'],
                            style: TextStyle(fontSize: 11, color: palette.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // If rejected, show rejection banner
                if (status == 'rejected' && (r['rejectionReason'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'İmtina səbəbi: ${r['rejectionReason']}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Action Buttons matching GoPanel Web
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.brandRoyal,
                            side: BorderSide(color: palette.brandRoyal.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showDetailModal(r),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                          label: const Text(
                            'Ətraflı',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _reject(r),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text(
                              'İmtina',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _approve(r),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text(
                              'Təsdiqlə',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
