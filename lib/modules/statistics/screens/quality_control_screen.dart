import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/statistics_model.dart';

class QualityControlScreen extends StatefulWidget {
  const QualityControlScreen({super.key});

  @override
  State<QualityControlScreen> createState() => _QualityControlScreenState();
}

class _QualityControlScreenState extends State<QualityControlScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<QualityControlAudit> _audits = [
    QualityControlAudit(
      id: 'qc-1',
      teacherName: 'Sevinc Məmmədova',
      subject: 'Azərbaycan Dili və Ədəbiyyat',
      className: '9-A',
      observerName: 'Akademik Direktor (Dr. İsmayılov)',
      observationDate: DateTime(2026, 10, 24),
      overallScore: 4.8,
      criteriaScores: {
        'Dərs planlaşdırılması': 5.0,
        'İnteraktiv tədris metodları': 4.8,
        'Şagirdlərin fəallığı və motivasiyası': 4.9,
        'Formativ qiymətləndirmə': 4.6,
        'Sinif idarəetməsi': 4.8,
      },
      strengths: 'Mövzu üzrə debat formatının uğurlu tətbiqi, tənqidi təfəkkür sualları əla təşkil olunub.',
      recommendations: 'Dərsin son 5 dəqiqəsində refleksiya üçün şagirdlərin fərdi qeydlərinə daha çox vaxt ayrılması tövsiyə edilir.',
    ),
    QualityControlAudit(
      id: 'qc-2',
      teacherName: 'Fatma Zalova',
      subject: 'Riyaziyyat və Həndəsə',
      className: '10-B',
      observerName: 'Fənn Metodbirləşmə Rəhbəri',
      observationDate: DateTime(2026, 10, 18),
      overallScore: 4.9,
      criteriaScores: {
        'Dərs planlaşdırılması': 5.0,
        'İnteraktiv tədris metodları': 5.0,
        'Şagirdlərin fəallığı və motivasiyası': 4.8,
        'Formativ qiymətləndirmə': 5.0,
        'Sinif idarəetməsi': 4.8,
      },
      strengths: 'GeoGebra proqramı vasitəsilə fəza fiqurlarının vizual izahı yüksək səviyyədə təqdim edildi.',
      recommendations: 'Diferensial tapşırıqların çətinlik səviyyəsinə görə qruplaşdırılması davam etdirilsin.',
    ),
    QualityControlAudit(
      id: 'qc-3',
      teacherName: 'Rəşad Quliyev',
      subject: 'Fizika',
      className: '11-A',
      observerName: 'Təlim-Tərbiyə İşləri üzrə Direktor Müavini',
      observationDate: DateTime(2026, 10, 12),
      overallScore: 4.5,
      criteriaScores: {
        'Dərs planlaşdırılması': 4.5,
        'İnteraktiv tədris metodları': 4.2,
        'Şagirdlərin fəallığı və motivasiyası': 4.6,
        'Formativ qiymətləndirmə': 4.4,
        'Sinif idarəetməsi': 4.8,
      },
      strengths: 'Laboratoriya təcrübələri zamanı təhlükəsizlik qaydalarına ciddi riayət olunması və praktiki nümayiş.',
      recommendations: 'Müasir rəqəmsal sensorlardan istifadə dərəcəsi artırıla bilər.',
    ),
  ];

  List<QualityControlAudit> get _filteredAudits {
    final query = _searchController.text.trim().toLowerCase();
    return _audits.where((audit) {
      return query.isEmpty ||
          audit.teacherName.toLowerCase().contains(query) ||
          audit.subject.toLowerCase().contains(query) ||
          audit.className.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAuditDetail(QualityControlAudit audit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      audit.teacherName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppPalette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          audit.overallScore.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppPalette.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${audit.subject} • Sinif: ${audit.className}',
                style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Müşahidəçi: ${audit.observerName}',
                style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12),
              ),
              const Divider(height: 32),
              const Text(
                'Meyarlar üzrə Qiymətləndirmə',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...audit.criteriaScores.entries.map((entry) {
                final ratio = entry.value / 5.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${entry.value} / 5.0', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: AppColors.getBorder(context),
                          color: ratio >= 0.9 ? AppColors.success : AppColors.warning,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (audit.strengths.isNotEmpty) ...[
                const Text('Müsbət Tərəflər:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(audit.strengths, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13)),
                const SizedBox(height: 12),
              ],
              if (audit.recommendations.isNotEmpty) ...[
                const Text('Tövsiyələr:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(audit.recommendations, style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Bağla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgScore = _audits.fold<double>(0.0, (acc, a) => acc + a.overallScore) / (_audits.isEmpty ? 1 : _audits.length);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Pedaqoji Keyfiyyətə Nəzarət', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tədris Keyfiyyəti İndeksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Orta Bal: ${avgScore.toStringAsFixed(2)} / 5.0 (${_audits.length} dərs auditi)',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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
              hintText: 'Müəllim, fənn və ya sinif axtarışı...',
              onChanged: (_) => setState(() {}),
              controller: _searchController,
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Dərs Dinləmə və Audit Hesabatları',
              trailing: '${_filteredAudits.length} audit',
            ),
            const SizedBox(height: 8),
            if (_filteredAudits.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun dərs auditi tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredAudits.map((audit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ModernCard(
                    onTap: () => _showAuditDetail(audit),
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
                                  color: AppPalette.primary.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: const Icon(Icons.co_present_rounded, color: AppPalette.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      audit.teacherName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${audit.subject} • Sinif: ${audit.className}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: '${audit.overallScore.toStringAsFixed(1)} ★',
                                color: audit.overallScore >= 4.5 ? AppColors.success : AppColors.warning,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Müşahidə: ${audit.observationDate.day.toString().padLeft(2, '0')}.${audit.observationDate.month.toString().padLeft(2, '0')}.${audit.observationDate.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Ətraflı',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppPalette.primary,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16, color: AppPalette.primary),
                                ],
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
