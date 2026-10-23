import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/attendance_model.dart';
import '../../../providers/app_state.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  static const _success = Color(0xFF10B981);
  static const _late = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);

  late int _selectedDay;
  final DateTime _currentDate = DateTime.now();

  final List<String> _monthNames = const [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'İyun',
    'İyul',
    'Avqust',
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _currentDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;
    final attendanceMap = appState.attendance;

    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    int totalPeriods = 0;
    int attendedPeriods = 0;

    attendanceMap.forEach((_, att) {
      if (att.status == AttendanceStatus.present) presentCount++;
      if (att.status == AttendanceStatus.late) lateCount++;
      if (att.status == AttendanceStatus.absent) absentCount++;
      for (final period in att.periodDetails) {
        totalPeriods++;
        if (period.status == AttendanceStatus.present ||
            period.status == AttendanceStatus.late) {
          attendedPeriods++;
        }
      }
    });

    final calculatedRate = totalPeriods > 0
        ? ((attendedPeriods / totalPeriods) * 100).round()
        : (currentStudent.attendanceRate > 0
            ? currentStudent.attendanceRate
            : 100);

    final selectedDayData = attendanceMap[_selectedDay];
    final monthName = '${_monthNames[_currentDate.month - 1]} ${_currentDate.year}';
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentDate.year,
      _currentDate.month,
    );
    final emptyLeadingSlots =
        DateTime(_currentDate.year, _currentDate.month, 1).weekday - 1;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: Text(
          '${currentStudent.fullName} • Davamiyyət',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(
              palette: palette,
              monthName: monthName,
              rate: calculatedRate,
              presentCount: presentCount,
              lateCount: lateCount,
              absentCount: absentCount,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _legend(palette, 'İştirak', _success,
                      Icons.check_circle_outline_rounded),
                  _legend(palette, 'Gecikmə', _late,
                      Icons.schedule_rounded),
                  _legend(palette, 'Qayıb', _danger, Icons.cancel_outlined),
                  _legend(palette, 'Tətil', palette.textMuted,
                      Icons.beach_access_outlined),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCalendarCard(
              palette: palette,
              attendanceMap: attendanceMap,
              daysInMonth: daysInMonth,
              emptyLeadingSlots: emptyLeadingSlots,
            ),
            SectionHeader(
              title:
                  '$_selectedDay ${_monthNames[_currentDate.month - 1]} • Günlük qeydlər',
              subtitle: 'Saatlar üzrə dərs davamiyyəti və qeydlər',
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            ),
            _buildDayDetails(
              palette: palette,
              data: selectedDayData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero({
    required AppPalette palette,
    required String monthName,
    required int rate,
    required int presentCount,
    required int lateCount,
    required int absentCount,
  }) {
    final rateColor = rate >= 90
        ? _success
        : rate >= 75
            ? _late
            : _danger;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1428), Color(0xFF172554)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.brandRoyal.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF7DD3FC),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Aylıq davamiyyət',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: rateColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '$rate%',
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (rate.clamp(0, 100)) / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(rateColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('İştirak', '$presentCount gün', _success),
              _divider(),
              _stat('Gecikmə', '$lateCount dəfə', _late),
              _divider(),
              _stat('Qayıb', '$absentCount gün', _danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _legend(AppPalette palette, String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard({
    required AppPalette palette,
    required Map<int, DayAttendance> attendanceMap,
    required int daysInMonth,
    required int emptyLeadingSlots,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.24
                  : 0.03,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _weekday(palette, 'B.e'),
              _weekday(palette, 'Ç.a'),
              _weekday(palette, 'Çər'),
              _weekday(palette, 'C.a'),
              _weekday(palette, 'Cüm'),
              _weekday(palette, 'Şən', weekend: true),
              _weekday(palette, 'Baz', weekend: true),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: palette.borderHairline, height: 1),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 0.92,
            ),
            itemCount: emptyLeadingSlots + daysInMonth,
            itemBuilder: (context, index) {
              if (index < emptyLeadingSlots) {
                return const SizedBox.shrink();
              }
              final dayNum = index - emptyLeadingSlots + 1;
              final isSelected = dayNum == _selectedDay;
              final isToday = dayNum == _currentDate.day;
              final att = attendanceMap[dayNum];

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = dayNum),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.brandRoyal.withValues(alpha: 0.13)
                        : isToday
                            ? palette.surface3
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isSelected
                          ? palette.brandRoyal
                          : isToday
                              ? palette.brandRoyal.withValues(alpha: 0.35)
                              : palette.borderHairline,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? palette.brandRoyal
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (att != null)
                        _statusIcon(att.status, size: 12)
                      else
                        Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: palette.borderStrong,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _weekday(AppPalette palette, String label,
      {bool weekend = false}) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: weekend ? _danger.withValues(alpha: 0.75) : palette.textMuted,
        ),
      ),
    );
  }

  Widget _buildDayDetails({
    required AppPalette palette,
    required DayAttendance? data,
  }) {
    if (data == null || data.periodDetails.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.borderHairline),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_outlined,
                size: 24,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu gün üçün davamiyyət qeydi yoxdur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Dərslər başladıqda status burada canlı görünəcək.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: palette.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final statusColor = _getStatusColor(data.status);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(data.status),
                  color: statusColor,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getStatusTitle(data.status),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (data.note != null && data.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Qeyd: ${data.note!.trim()}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.35,
                  color: palette.textMuted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(data.periodDetails.length, (index) {
            final period = data.periodDetails[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == data.periodDetails.length - 1 ? 0 : 7,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderHairline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: palette.brandRoyal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        period.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _periodBadge(period.status),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusIcon(AttendanceStatus? status, {double size = 16}) {
    switch (status) {
      case AttendanceStatus.present:
        return Icon(Icons.check_circle_rounded, color: _success, size: size);
      case AttendanceStatus.late:
        return Icon(Icons.schedule_rounded, color: _late, size: size);
      case AttendanceStatus.absent:
        return Icon(Icons.cancel_rounded, color: _danger, size: size);
      case AttendanceStatus.holiday:
        return Icon(Icons.beach_access_rounded, color: const Color(0xFF94A3B8), size: size);
      default:
        return Icon(Icons.remove_circle_outline_rounded, color: const Color(0xFFCBD5E1), size: size);
    }
  }

  Widget _periodBadge(AttendanceStatus status) {
    final color = _getStatusColor(status);
    final label = switch (status) {
      AttendanceStatus.present => 'İştirak',
      AttendanceStatus.late => 'Gecikmə',
      AttendanceStatus.absent => 'Qayıb',
      AttendanceStatus.holiday => 'Tətil',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _getStatusTitle(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Dərslərdə tam iştirak edib';
      case AttendanceStatus.late:
        return 'Dərsə gecikmə qeydə alınıb';
      case AttendanceStatus.absent:
        return 'Qayıb qeydə alınıb';
      case AttendanceStatus.holiday:
        return 'İstirahət / tətil günü';
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.late:
        return Icons.schedule_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.holiday:
        return Icons.beach_access_rounded;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return _success;
      case AttendanceStatus.late:
        return _late;
      case AttendanceStatus.absent:
        return _danger;
      case AttendanceStatus.holiday:
        return const Color(0xFF94A3B8);
    }
  }
}
