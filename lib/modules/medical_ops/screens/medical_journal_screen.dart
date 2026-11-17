import '../../../core/services/school_api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';

class MedicalJournalItem {
  final String id;
  final String studentName;
  final String className;
  final String recordType; // 'Ambulator', 'Peyvənd', 'Mantu', 'Allergiya', 'Sanitar Yoxlama'
  final String description;
  final String doctorName;
  final DateTime date;
  final String status; // 'Sağlam', 'Müşahidədə', 'Təxirə salındı'

  const MedicalJournalItem({
    required this.id,
    required this.studentName,
    required this.className,
    required this.recordType,
    required this.description,
    required this.doctorName,
    required this.date,
    this.status = 'Sağlam',
  });
}

class MedicalJournalScreen extends StatefulWidget {
  const MedicalJournalScreen({super.key});

  @override
  State<MedicalJournalScreen> createState() => _MedicalJournalScreenState();
}

class _MedicalJournalScreenState extends State<MedicalJournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealMedical();
  }

  Future<void> _loadRealMedical() async {
    final rows = await SchoolApiService.instance.fetchMedicalRecords();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _records
          ..clear()
          ..addAll(rows.map((r) => MedicalJournalItem(
            id: r['id']?.toString() ?? 'med-1',
            studentName: r['studentName']?.toString() ?? 'Şagird',
            className: r['className']?.toString() ?? 'Məktəb üzrə',
            recordType: r['recordType']?.toString() ?? 'Ambulator',
            description: r['description']?.toString() ?? '',
            doctorName: r['doctorName']?.toString() ?? 'Həkim',
            date: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
            status: r['status']?.toString() ?? 'Sağlam',
          )));
      });
    }
  }

  final List<MedicalJournalItem> _records = [
    MedicalJournalItem(
      id: 'med-1',
      studentName: 'Murad Əliyev',
      className: '10-A',
      recordType: 'Peyvənd',
      description: 'Mövsümi Qrip (İnfluenza) profilaktik peyvəndi vuruldu. Reaksiya normaldır.',
      doctorName: 'Dr. Nərmin Qasımova',
      date: DateTime(2026, 10, 20),
      status: 'Sağlam',
    ),
    MedicalJournalItem(
      id: 'med-2',
      studentName: 'Aytən Məmmədova',
      className: '8-B',
      recordType: 'Allergiya',
      description: 'Qoz və fındıq məhsullarına qarşı kəskin qida allergiyası qeydə alınıb. Yeməkxana məlumatlandırıldı.',
      doctorName: 'Dr. Nərmin Qasımova',
      date: DateTime(2026, 10, 15),
      status: 'Müşahidədə',
    ),
    MedicalJournalItem(
      id: 'med-3',
      studentName: 'Kənan Rəhimov',
      className: '11-C',
      recordType: 'Ambulator',
      description: 'Bədən tərbiyəsi dərsində yüngül bilək zədələnməsi. İlkin tibbi yardım və elastik sarğı tətbiq olundu.',
      doctorName: 'Tibb bacısı Sevda Əliyeva',
      date: DateTime(2026, 10, 28),
      status: 'Sağlam',
    ),
    MedicalJournalItem(
      id: 'med-4',
      studentName: 'Leyla Əlizadə',
      className: '9-A',
      recordType: 'Mantu',
      description: 'İllik Mantu sınağı aparıldı. 72 saat sonra yoxlama təyin edildi (norma: 3mm papula).',
      doctorName: 'Dr. Nərmin Qasımova',
      date: DateTime(2026, 10, 25),
      status: 'Sağlam',
    ),
    MedicalJournalItem(
      id: 'med-5',
      studentName: 'Məktəb Yeməkxanası',
      className: 'Ümumi',
      recordType: 'Sanitar Yoxlama',
      description: 'Mətbəx və yeməkxana avadanlıqlarının gündəlik gigiyenik və mikrobioloji baxışı aparıldı. Nəticə qənaətbəxşdir.',
      doctorName: 'Sanitar Həkim R. İsmayılov',
      date: DateTime(2026, 11, 01),
      status: 'Sağlam',
    ),
  ];

  final List<String> _categories = [
    'Hamısı',
    'Ambulator',
    'Peyvənd',
    'Mantu',
    'Allergiya',
    'Sanitar Yoxlama',
  ];

  List<MedicalJournalItem> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((rec) {
      final matchesCat = _selectedCategory == 'Hamısı' || rec.recordType == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          rec.studentName.toLowerCase().contains(query) ||
          rec.className.toLowerCase().contains(query) ||
          rec.description.toLowerCase().contains(query);
      return matchesCat && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final observedCount = _records.where((r) => r.status == 'Müşahidədə').length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Tibbi Əməliyyatlar və Jurnallar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            ModernCard(
              gradient: LinearGradient(
                colors: [
                  AppPalette.primary.withValues(alpha: 0.85),
                  AppPalette.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Məktəb Həkim Məntəqəsi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_records.length} tibbi qeyd • $observedCount şagird xüsusi nəzarətdə',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppSearchBar(
              hintText: 'Şagird adı, sinif və ya diaqnoz axtarın...',
              onChanged: (_) => setState(() {}),
              controller: _searchController,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppPalette.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppPalette.primary : AppColors.getTextSecondary(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Tibbi Qeydlər Reyestri',
              trailing: '${_filteredRecords.length} qeyd',
            ),
            const SizedBox(height: 8),
            if (_filteredRecords.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.health_and_safety_outlined, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun tibbi qeyd tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredRecords.map((rec) {
                final isWarning = rec.status == 'Müşahidədə';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isWarning ? AppColors.warning : AppColors.success).withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Icon(
                                  Icons.vaccines_rounded,
                                  color: isWarning ? AppColors.warning : AppColors.success,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec.studentName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${rec.className} • ${rec.recordType}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: rec.status,
                                color: isWarning ? AppColors.warning : AppColors.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rec.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.getTextPrimary(context),
                              height: 1.4,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Həkim: ${rec.doctorName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                              Text(
                                '${rec.date.day.toString().padLeft(2, '0')}.${rec.date.month.toString().padLeft(2, '0')}.${rec.date.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
