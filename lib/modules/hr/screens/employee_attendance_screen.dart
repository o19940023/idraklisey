import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/employee_model.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Hamısı';

  final List<EmployeeAttendanceRecord> _records = [
    EmployeeAttendanceRecord(
      id: 'att-1',
      employeeId: 'emp-32',
      employeeName: 'Gülnarə Səlimova (İT Rəhbəri)',
      date: DateTime.now(),
      checkInTime: '08:22',
      checkOutTime: '17:35',
      status: 'present',
      notes: 'Turniket keçidi uğurlu',
    ),
    EmployeeAttendanceRecord(
      id: 'att-2',
      employeeId: 'emp-97',
      employeeName: 'Gülnarə İbrahimova (Alman dili)',
      date: DateTime.now(),
      checkInTime: '08:28',
      checkOutTime: '15:10',
      status: 'present',
      notes: '1-ci dərs saatında iştirak edib',
    ),
    EmployeeAttendanceRecord(
      id: 'att-3',
      employeeId: 'emp-180',
      employeeName: 'Gülnarə Fətiyeva (Mühasib)',
      date: DateTime.now(),
      checkInTime: '08:45',
      checkOutTime: '17:30',
      status: 'late',
      notes: '15 dəqiqə gecikmə qeydə alınıb',
    ),
    EmployeeAttendanceRecord(
      id: 'att-4',
      employeeId: 'emp-365',
      employeeName: 'Ramiz Mehdiyev (Baş İT Mütəxəssis)',
      date: DateTime.now(),
      checkInTime: '08:15',
      checkOutTime: '18:00',
      status: 'present',
      notes: 'Şəbəkə server otağı növbətçiliyi',
    ),
    EmployeeAttendanceRecord(
      id: 'att-5',
      employeeId: 'emp-1',
      employeeName: 'Fatma Zalova (İngilis dili Kafedra)',
      date: DateTime.now(),
      checkInTime: null,
      checkOutTime: null,
      status: 'excused',
      notes: 'Rəsmi ezamiyyət (Təhsil Forumu)',
    ),
  ];

  final List<String> _filters = ['Hamısı', 'Gəldi', 'Gecikdi', 'İcazəli', 'Qayıb'];

  List<EmployeeAttendanceRecord> get _filteredRecords {
    return _records.where((rec) {
      return switch (_selectedFilter) {
        'Gəldi' => rec.status == 'present',
        'Gecikdi' => rec.status == 'late',
        'İcazəli' => rec.status == 'excused',
        'Qayıb' => rec.status == 'absent',
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final records = _filteredRecords;

    final presentCount = _records.where((r) => r.status == 'present').length;
    final lateCount = _records.where((r) => r.status == 'late').length;
    final excusedCount = _records.where((r) => r.status == 'excused').length;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Əməkdaş Davamiyyəti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Date Switcher Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface1,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.borderHairline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        'Davamiyyət Günü',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                    },
                  ),
                ],
              ),
            ),

            // Summary Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard('Gəldi', '$presentCount', AppColors.emerald, palette),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard('Gecikdi', '$lateCount', AppColors.gold, palette),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard('İcazəli', '$excusedCount', palette.brandAzure, palette),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status filter chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _filters[index];
                  final isSelected = f == _selectedFilter;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = f);
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

            SectionHeader(
              title: 'İşçi Giriş-Çıxış Jurnalı',
              subtitle: '${records.length} qeyd göstərilir',
            ),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final rec = records[index];
                  final (statusLabel, statusColor) = switch (rec.status) {
                    'present' => ('Vaxtında', AppColors.emerald),
                    'late' => ('Gecikdi', AppColors.gold),
                    'excused' => ('İcazəli', palette.brandAzure),
                    _ => ('Qayıb', AppColors.rose),
                  };

                  return ModernCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          child: Icon(
                            rec.status == 'present'
                                ? Icons.check_circle_rounded
                                : rec.status == 'late'
                                    ? Icons.access_time_rounded
                                    : Icons.assignment_late_rounded,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.employeeName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    rec.checkInTime != null
                                        ? 'Giriş: ${rec.checkInTime}  |  Çıxış: ${rec.checkOutTime ?? '-'}'
                                        : 'Giriş qeydə alınmayıb',
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: statusLabel,
                          color: statusColor,
                          fontSize: 11,
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

  Widget _statCard(String label, String value, Color color, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
