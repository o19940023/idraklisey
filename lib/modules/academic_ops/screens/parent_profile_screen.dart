import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/student_model.dart';
import '../../finance/widgets/student_finance_modal.dart';
import '../../teacher/screens/teacher_student_detail_screen.dart';
import 'parent_edit_screen.dart';

/// Ultra-Modern Parent Profile Screen
/// High-end profile screen with Student Profile parity, full tabs & web synchronization.
class ParentProfileScreen extends StatefulWidget {
  final Map<String, dynamic> parent;
  final VoidCallback? onRefresh;

  const ParentProfileScreen({
    super.key,
    required this.parent,
    this.onRefresh,
  });

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  late Map<String, dynamic> _parent;
  bool _isLoading = false;
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _contracts = [];
  Map<String, dynamic>? _financeSummary;

  @override
  void initState() {
    super.initState();
    _parent = Map<String, dynamic>.from(widget.parent);
    _loadParentFullData();
  }

  Future<void> _loadParentFullData() async {
    final parentId = _asInt(_parent['id']);
    if (parentId <= 0) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SchoolApiService.instance.fetchParentForm(parentId.toString()),
        SchoolApiService.instance.fetchParentFinance(parentId: parentId.toString()),
      ]);

      final formRes = results[0];
      final finRes = results[1];

      if (mounted) {
        setState(() {
          if (formRes != null) {
            _parent = Map<String, dynamic>.from(formRes);
            _children = (formRes['children'] as List?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [];
          }
          if (finRes != null) {
            _financeSummary = finRes['summary'] as Map<String, dynamic>?;
            _contracts = (finRes['contracts'] as List?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  bool get _isActive {
    final v = _parent['isActive'] ?? _parent['is_active'] ?? _parent['status'];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v == 1;
    final s = v.toString().toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'active';
  }

  String get _displayName {
    final name = _asString(_parent['name'] ?? _parent['first_name'] ?? _parent['firstName']);
    final surname = _asString(_parent['surname'] ?? _parent['last_name'] ?? _parent['lastName']);
    final father = _asString(_parent['fatherName'] ?? _parent['father_name']);

    final parts = [name, surname, father].where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    final full = _asString(_parent['full_name']);
    if (full.isNotEmpty) return full;
    return 'Valideyn #${_parent['id']}';
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openChildDetail(Map<String, dynamic> child) {
    final cName = _asString(child['name'] ?? child['full_name'] ?? '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}');
    final cClass = _asString(child['className'] ?? child['class_name'] ?? child['grade'], fallback: '-');
    final cCode = _asString(child['code'] ?? child['student_code'] ?? 'IDR-STD');

    final student = StudentProfile(
      id: _asString(child['id']),
      studentNumber: cCode,
      fullName: cName,
      className: cClass,
      photoUrl: '',
      qrData: _asString(child['id']),
      barcodeData: cCode,
      birthDate: DateTime.tryParse(_asString(child['birth_date'])) ?? DateTime(2010),
      parentName: _displayName,
      parentPhone: _asString(_parent['phone']),
      gpa: 0.0,
      attendanceRate: 100,
      academicYear: '2026-2027',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherStudentDetailScreen(student: student, adminMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildSliverHeader(palette),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabHeaderDelegate(
                background: palette.surface1,
                borderColor: palette.borderHairline,
                tabBar: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorColor: palette.brandRoyal,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelColor: palette.brandRoyal,
                  unselectedLabelColor: palette.textSecondary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Şəxsi & Əlaqə'),
                    Tab(icon: Icon(Icons.escalator_warning_outlined, size: 16), text: 'Şagirdlər (Övladları)'),
                    Tab(icon: Icon(Icons.description_outlined, size: 16), text: 'Müqavilələr & Maliyyə'),
                    Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 16), text: 'Müraciətlər & Qeydlər'),
                  ],
                ),
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildPersonalTab(palette),
                    _buildChildrenTab(palette),
                    _buildContractsTab(palette),
                    _buildNotesTab(palette),
                  ],
                ),
        ),
        bottomNavigationBar: _buildBottomActionBar(palette),
      ),
    );
  }

  Widget _buildSliverHeader(AppPalette palette) {
    final pr = (_parent['profile'] is Map) ? _parent['profile'] as Map<String, dynamic> : <String, dynamic>{};
    final name = _displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';
    final fin = _asString(_parent['fin_code'] ?? _parent['fin'] ?? pr['finCode']);
    final code = _asString(_parent['code']);
    final isActive = _isActive;
    final workplace = _asString(_parent['workplace'] ?? pr['companyName'], fallback: 'İdrak Liseyi Valideyni');
    final relation = _asString(_parent['relation_type'] ?? _parent['relation'], fallback: 'Valideyn');

    return SliverAppBar(
      expandedHeight: 270,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F1E36),
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          tooltip: 'Geri',
          onPressed: () => Navigator.maybePop(context),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            tooltip: 'Yenilə',
            onPressed: _loadParentFullData,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B192C),
                Color(0xFF1E3E62),
                Color(0xFF2563EB),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$relation • $workplace',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    if (fin.isNotEmpty) _headerPill('FİN: $fin', Icons.badge_outlined),
                    if (code.isNotEmpty) _headerPill('Kod: $code', Icons.tag_rounded),
                    _headerStatusBadge(isActive),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _headerStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? const Color(0xFF34D399) : Colors.amberAccent, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF34D399) : Colors.amberAccent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Aktiv' : 'Qeyri-aktiv',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // TAB 1: Şəxsi & Əlaqə
  Widget _buildPersonalTab(AppPalette palette) {
    final pr = (_parent['profile'] is Map) ? _parent['profile'] as Map<String, dynamic> : <String, dynamic>{};
    final fin = _asString(_parent['fin_code'] ?? _parent['fin'] ?? pr['finCode']);
    final serialType = _asString(_parent['serial_type'] ?? _parent['serialType'] ?? pr['serialType']);
    final serialNumber = _asString(_parent['serial_number'] ?? _parent['serialNumber'] ?? _parent['serial'] ?? pr['serialNumber']);
    final serial = (serialType.isNotEmpty || serialNumber.isNotEmpty)
        ? '$serialType $serialNumber'.trim()
        : _asString(_parent['id_card_serial']);
    final phone = _asString(_parent['phone'] ?? pr['phone']);
    final email = _asString(_parent['email']);
    final workplace = _asString(_parent['workplace'] ?? pr['companyName']);
    final position = _asString(_parent['position'] ?? pr['companyPosition']);
    final actualAddress = _asString(_parent['actual_address'] ?? _parent['address'] ?? pr['address']);
    final registrationAddress = _asString(_parent['registration_address'] ?? pr['registrationAddress']);
    final birthDate = _asString(_parent['birth_date'] ?? pr['birthDate']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          palette: palette,
          title: 'Əsas Kimlik Məlumatları',
          icon: Icons.badge_outlined,
          items: [
            _dataRow('Ad, Soyad, Ata adı', _displayName, palette),
            _dataRow('FİN Kod', fin.isNotEmpty ? fin : '---', palette),
            _dataRow('Ş.V. Seriya və Nömrə', serial.isNotEmpty ? serial : '---', palette),
            _dataRow('Qohumluq Dərəcəsi', _asString(_parent['relation_type'] ?? _parent['relation'], fallback: 'Valideyn / Qəyyum'), palette),
            _dataRow('Doğum Tarixi', _formatDate(birthDate), palette),
            _dataRow('Vətəndaşlığı', _asString(_parent['citizenship'] ?? pr['citizenship'], fallback: 'Azərbaycan'), palette),
          ],
        ),
        const SizedBox(height: 14),

        _sectionCard(
          palette: palette,
          title: 'İş və Əlaqə Qeydləri',
          icon: Icons.business_center_outlined,
          items: [
            _dataRow('İş Yeri', workplace.isNotEmpty ? workplace : 'Qeyd olunmayıb', palette),
            _dataRow('Vəzifəsi', position.isNotEmpty ? position : 'Qeyd olunmayıb', palette),
            _dataRow('Əlaqə Nömrəsi', phone, palette, action: phone.isNotEmpty ? () => _makeCall(phone) : null),
            _dataRow('E-poçt Ünvanı', email, palette, action: email.isNotEmpty ? () => _sendEmail(email) : null),
            _dataRow('Faktiki Ünvan', actualAddress.isNotEmpty ? actualAddress : 'Qeyd olunmayıb', palette),
            _dataRow('Qeydiyyat Ünvanı', registrationAddress.isNotEmpty ? registrationAddress : (actualAddress.isNotEmpty ? actualAddress : 'Qeyd olunmayıb'), palette),
          ],
        ),
      ],
    );
  }

  // TAB 2: Şagirdlər (Övladları)
  Widget _buildChildrenTab(AppPalette palette) {
    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_rounded, size: 48, color: palette.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('Bu valideynə bağlı şagird tapılmadı', style: TextStyle(color: palette.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _children.length,
      itemBuilder: (ctx, idx) {
        final c = _children[idx];
        final cName = _asString(c['name'] ?? c['full_name'] ?? '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}', fallback: 'Şagird #${c['id']}');
        final cClass = _asString(c['className'] ?? c['class_name'] ?? c['grade'], fallback: 'Sinif təyin edilməyib');
        final cCode = _asString(c['code'] ?? c['student_code']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: palette.brandRoyal.withValues(alpha: 0.12),
                child: Text(
                  cName.isNotEmpty ? cName[0].toUpperCase() : 'Ş',
                  style: TextStyle(fontWeight: FontWeight.bold, color: palette.brandRoyal, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.brandRoyal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sinif: $cClass',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.brandRoyal),
                          ),
                        ),
                        if (cCode.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '• $cCode',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: palette.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _openChildDetail(c),
                icon: const Icon(Icons.person_search_rounded, size: 15),
                label: const Text('Profilə Bax', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  (String, IconData, Color) _getServiceTypeInfo(dynamic type) {
    final raw = (type ?? 'education').toString().toLowerCase();
    if (raw.contains('transport') || raw.contains('servis') || raw.contains('nəqliyyat') || raw.contains('neqliyyat')) {
      return ('Servis (Nəqliyyat)', Icons.directions_bus_rounded, Colors.teal);
    } else if (raw.contains('club') || raw.contains('dərnək') || raw.contains('dernek')) {
      return ('Dərnək', Icons.palette_rounded, Colors.orange);
    } else if (raw.contains('support')) {
      return ('Support dərs', Icons.menu_book_rounded, Colors.purple);
    } else if (raw.contains('book') || raw.contains('kitab')) {
      return ('Kitab ödənişləri', Icons.auto_stories_rounded, Colors.indigo);
    } else if (raw.contains('uniform') || raw.contains('forma')) {
      return ('Forma ödənişləri', Icons.checkroom_rounded, Colors.pink);
    }
    return ('Təhsil haqqı', Icons.school_rounded, const Color(0xFF2563EB));
  }

  // TAB 3: Müqavilələr & Maliyyə
  Widget _buildContractsTab(AppPalette palette) {
    final summary = _financeSummary ?? {};

    // Calculate dynamic totals from contracts as a guaranteed consistent fallback
    double sumFinal = 0.0;
    double sumPaid = 0.0;
    for (final con in _contracts) {
      final f = double.tryParse((con['finalAmount'] ?? con['totalAmount'] ?? con['amount'] ?? 0).toString()) ?? 0.0;
      final p = double.tryParse((con['paidAmount'] ?? con['paid'] ?? 0).toString()) ?? 0.0;
      sumFinal += f;
      sumPaid += p;
    }
    double sumDebt = (sumFinal - sumPaid).clamp(0.0, double.infinity);

    final double? sFinal = double.tryParse((summary['totalContractAmount'] ?? summary['totalContractsAmount'] ?? summary['totalAmount'] ?? '').toString());
    final double? sPaid = double.tryParse((summary['totalPaidAmount'] ?? summary['totalPaid'] ?? '').toString());
    final double? sDebt = double.tryParse((summary['totalRemainingAmount'] ?? summary['totalRemaining'] ?? summary['remainingDebt'] ?? summary['totalDebt'] ?? '').toString());

    final totalContracts = (sFinal != null && sFinal > 0) ? sFinal.toStringAsFixed(2) : sumFinal.toStringAsFixed(2);
    final totalPaid = (sPaid != null && sPaid > 0) ? sPaid.toStringAsFixed(2) : sumPaid.toStringAsFixed(2);
    final totalDebt = (sDebt != null && sDebt > 0) ? sDebt.toStringAsFixed(2) : sumDebt.toStringAsFixed(2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Financial summary cards
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Maliyyə İcmalı (Cəmi Borc & Ödənişlər)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _financeMiniStat('Cəmi Məbləğ', '$totalContracts AZN', palette.textPrimary, palette),
                  ),
                  Container(width: 1, height: 36, color: palette.borderHairline),
                  Expanded(
                    child: _financeMiniStat('Ödənilən', '$totalPaid AZN', const Color(0xFF10B981), palette),
                  ),
                  Container(width: 1, height: 36, color: palette.borderHairline),
                  Expanded(
                    child: _financeMiniStat('Borc (Qalıq)', '$totalDebt AZN', const Color(0xFFEF4444), palette),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_contracts.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 40, color: palette.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                Text('Aktiv müqavilə və maliyyə qeydi tapılmadı', style: TextStyle(color: palette.textSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          ..._contracts.map((con) {
            final conId = int.tryParse(con['id']?.toString() ?? '');
            final conNumber = _asString(con['code'] ?? con['contract_number'] ?? 'MÜQ-${con['id']}');
            final statusLabel = _asString(con['statusLabel'] ?? con['status'], fallback: 'Aktiv');
            final studentName = _asString(con['studentName'] ?? con['student_name']);
            final className = _asString(con['className'] ?? con['class_name'], fallback: '-');
            final finalAmount = _asString(con['finalAmount'] ?? con['totalAmount'] ?? con['amount'], fallback: '0.00');
            final paidAmount = _asString(con['paidAmount'] ?? con['paid'], fallback: '0.00');
            final remaining = _asString(con['remainingAmount'] ?? con['remaining'], fallback: '0.00');
            final schedule = (con['paymentSchedule'] as List?) ?? [];
            final serviceInfo = _getServiceTypeInfo(con['contractTypeLabel'] ?? con['contractType'] ?? con['serviceType']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.borderHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: conId != null
                              ? () => StudentFinanceModal.show(
                                    context,
                                    contractId: conId,
                                    studentNameFallback: studentName,
                                    codeFallback: conNumber,
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Müqavilə: $conNumber',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF2563EB)),
                                ),
                              ),
                              if (conId != null) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF2563EB)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Service / Payment Type Badge (Təhsil haqqı, Servis, Dərnək)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: serviceInfo.$3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: serviceInfo.$3.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(serviceInfo.$2, size: 14, color: serviceInfo.$3),
                        const SizedBox(width: 5),
                        Text(
                          'Ödəniş növü: ${serviceInfo.$1}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: serviceInfo.$3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 18),
                  if (studentName.isNotEmpty) _dataRow('Şagird', '$studentName ($className)', palette),
                  _dataRow('Ödəniş Təyinatı', serviceInfo.$1, palette),
                  _dataRow('Yekun Məbləğ', '$finalAmount AZN', palette),
                  _dataRow('Ödənilən', '$paidAmount AZN', palette),
                  _dataRow('Qalıq Borc', '$remaining AZN', palette),
                  if (schedule.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8),
                        dense: true,
                        title: Text(
                          'Ödəniş qrafiki (${schedule.length} qrafik)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                        children: schedule.map((item) {
                          final inst = Map<String, dynamic>.from(item as Map);
                          final instTitle = _asString(inst['title'] ?? 'Hissə');
                          final instAmount = _asString(inst['amount'], fallback: '0.00');
                          final instDue = _formatDate(_asString(inst['dueDate'] ?? inst['due_date']));
                          final instPaid = inst['isPaid'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: instPaid ? Colors.green.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: instPaid ? Colors.green.withValues(alpha: 0.2) : palette.borderHairline,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  instPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                  size: 15,
                                  color: instPaid ? Colors.green : Colors.amber.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(instTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      Text('Son tarix: $instDue', style: TextStyle(fontSize: 10, color: palette.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$instAmount AZN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: instPaid ? Colors.green : palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _financeMiniStat(String label, String value, Color color, AppPalette palette) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: palette.textSecondary)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // TAB 4: Müraciətlər & Qeydlər
  Widget _buildNotesTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          palette: palette,
          title: 'Valideyn Müraciətləri və Rabitə',
          icon: Icons.chat_outlined,
          items: [
            _dataRow('Portal Giriş Statusu', 'Aktiv (Mobil tətbiq qoşulub)', palette),
            _dataRow('Bildiriş İcazəsi', 'Bəli (SMS & Push)', palette),
            _dataRow('Məktəb Şurası Üzvü', 'Bəli', palette),
            _dataRow('Son Ziyarət Tarixi', '10.11.2026', palette),
          ],
        ),
      ],
    );
  }

  // BOTTOM BAR
  Widget _buildBottomActionBar(AppPalette palette) {
    final pr = (_parent['profile'] is Map) ? _parent['profile'] as Map<String, dynamic> : <String, dynamic>{};
    final phone = _asString(_parent['phone'] ?? pr['phone']);
    final email = _asString(_parent['email']);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface1,
          border: Border(top: BorderSide(color: palette.borderHairline)),
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Zəng et',
              onPressed: phone.isNotEmpty ? () => _makeCall(phone) : null,
              icon: const Icon(Icons.call_rounded, size: 18),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'WhatsApp',
              onPressed: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'E-poçt',
              onPressed: email.isNotEmpty ? () => _sendEmail(email) : null,
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.brandRoyal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentEditScreen(parentToEdit: _parent),
                    ),
                  );
                  if (updated == true && mounted) {
                    _loadParentFullData();
                    widget.onRefresh?.call();
                  }
                },
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('Redaktə Et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required AppPalette palette,
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: palette.brandRoyal),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: palette.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value, AppPalette palette, {VoidCallback? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: InkWell(
              onTap: action,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? value : '---',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: action != null ? palette.brandRoyal : palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: action != null ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 12, color: palette.brandRoyal),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dt) {
    if (dt == null || dt.isEmpty) return '---';
    try {
      final parsed = DateTime.parse(dt);
      return DateFormat('dd.MM.yyyy').format(parsed);
    } catch (_) {
      return dt;
    }
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color background;
  final Color borderColor;
  final TabBar tabBar;

  const _TabHeaderDelegate({
    required this.background,
    required this.borderColor,
    required this.tabBar,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) {
    return background != oldDelegate.background ||
        borderColor != oldDelegate.borderColor ||
        tabBar != oldDelegate.tabBar;
  }
}
