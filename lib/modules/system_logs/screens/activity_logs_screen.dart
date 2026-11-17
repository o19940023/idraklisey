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

class ActivityLogItem {
  final String id;
  final String userName;
  final String userRole;
  final String action;
  final String module;
  final String ipAddress;
  final DateTime timestamp;
  final String severity; // 'Məlumat', 'Xəbərdarlıq', 'Təhlükəsizlik'

  const ActivityLogItem({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.module,
    required this.ipAddress,
    required this.timestamp,
    this.severity = 'Məlumat',
  });
}

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSeverity = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealLogs();
  }

  Future<void> _loadRealLogs() async {
    final rows = await SchoolApiService.instance.fetchActivityLogs();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _logs
          ..clear()
          ..addAll(rows.map((r) => ActivityLogItem(
            id: r['id']?.toString() ?? 'log-1',
            userName: r['userName']?.toString() ?? 'Sistem',
            userRole: r['userRole']?.toString() ?? 'GoPanel',
            action: r['action']?.toString() ?? 'Əməliyyat',
            module: r['module']?.toString() ?? 'Sistem',
            ipAddress: r['ipAddress']?.toString() ?? '127.0.0.1',
            timestamp: DateTime.tryParse(r['timestamp']?.toString() ?? '') ?? DateTime.now(),
            severity: r['severity']?.toString() ?? 'Məlumat',
          )));
      });
    }
  }

  final List<ActivityLogItem> _logs = [
    ActivityLogItem(
      id: 'log-1',
      userName: 'Tural Əliyev',
      userRole: 'Baş İnzibatçı',
      action: 'Yeni əməkdaş profili yaradıldı (Sevinc Məmmədova)',
      module: 'İnsan Resursları',
      ipAddress: '192.168.1.45',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      severity: 'Məlumat',
    ),
    ActivityLogItem(
      id: 'log-2',
      userName: 'Afaq Qasımova',
      userRole: 'Baş Mühasib',
      action: '2026 Oktyabr ayı əməkhaqqı cədvəli təsdiqləndi',
      module: 'Maliyyə',
      ipAddress: '192.168.1.18',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      severity: 'Məlumat',
    ),
    ActivityLogItem(
      id: 'log-3',
      userName: 'Sistem Təhlükəsizliyi',
      userRole: 'Avtomatlaşdırma',
      action: 'Uğursuz giriş cəhdi (3 dəfə yanlış şifrə yoxlanışı)',
      module: 'Autentifikasiya',
      ipAddress: '185.120.45.12',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      severity: 'Təhlükəsizlik',
    ),
    ActivityLogItem(
      id: 'log-4',
      userName: 'Fatma Zalova',
      userRole: 'Müəllim',
      action: '10-B sinfi üzrə KSQ-1 nəticələri daxil edildi',
      module: 'İmtahanlar',
      ipAddress: '192.168.1.92',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      severity: 'Məlumat',
    ),
    ActivityLogItem(
      id: 'log-5',
      userName: 'Rauf Əliyev',
      userRole: 'IT Menecer',
      action: 'İstifadəçi hüquqlarında dəyişiklik edildi (Yeni rol təyini)',
      module: 'Rol İdarəetməsi',
      ipAddress: '192.168.1.10',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      severity: 'Xəbərdarlıq',
    ),
  ];

  final List<String> _severities = ['Hamısı', 'Məlumat', 'Xəbərdarlıq', 'Təhlükəsizlik'];

  List<ActivityLogItem> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    return _logs.where((log) {
      final matchesSeverity = _selectedSeverity == 'Hamısı' || log.severity == _selectedSeverity;
      final matchesSearch = query.isEmpty ||
          log.userName.toLowerCase().contains(query) ||
          log.action.toLowerCase().contains(query) ||
          log.module.toLowerCase().contains(query) ||
          log.ipAddress.contains(query);
      return matchesSeverity && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Sistem Loqları və Audit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      child: const Icon(Icons.security_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sistem Hərəkət Tarixçəsi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Bütün inzibati əməliyyatlar şifrələnmiş qeydə alınır',
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
              hintText: 'İstifadəçi, əməliyyat və ya IP ünvanı...',
              onChanged: (_) => setState(() {}),
              controller: _searchController,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _severities.map((sev) {
                  final isSelected = _selectedSeverity == sev;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sev),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedSeverity = sev);
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
              title: 'Son İnzibati Hərəkətlər',
              trailing: '${_filteredLogs.length} hadisə',
            ),
            const SizedBox(height: 8),
            if (_filteredLogs.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun sistem loqu tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredLogs.map((log) {
                final statusColor = switch (log.severity) {
                  'Təhlükəsizlik' => AppColors.error,
                  'Xəbərdarlıq' => AppColors.warning,
                  _ => AppColors.success,
                };

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
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Icon(Icons.history_rounded, color: statusColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.userName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${log.userRole} • ${log.module}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: log.severity,
                                color: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            log.action,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'IP: ${log.ipAddress}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                              Text(
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')} • ${log.timestamp.day.toString().padLeft(2, '0')}.${log.timestamp.month.toString().padLeft(2, '0')}.${log.timestamp.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTextSecondary(context),
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
