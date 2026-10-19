import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/timetable_model.dart';

class TimetableMatrixScreen extends StatefulWidget {
  const TimetableMatrixScreen({super.key});

  @override
  State<TimetableMatrixScreen> createState() => _TimetableMatrixScreenState();
}

class _TimetableMatrixScreenState extends State<TimetableMatrixScreen> {
  late DateTime _selectedWeekMonday;
  int _selectedDayIndex = 0; // 0: Mon, 1: Tue, 2: Wed, 3: Thu, 4: Fri

  final List<String> _dayNames = [
    'Bazar ertəsi',
    'Çərşənbə axşamı',
    'Çərşənbə',
    'Cümə axşamı',
    'Cümə',
  ];

  final List<String> _shortDays = ['B.E', 'Ç.A', 'Ç.', 'C.A', 'C.'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysFromMonday = now.weekday - 1;
    _selectedWeekMonday = today.subtract(Duration(days: daysFromMonday));

    if (now.weekday >= 1 && now.weekday <= 5) {
      _selectedDayIndex = now.weekday - 1;
    } else {
      _selectedDayIndex = 0;
    }
  }

  void _goToPreviousWeek() {
    setState(() {
      _selectedWeekMonday = _selectedWeekMonday.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _selectedWeekMonday = _selectedWeekMonday.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysFromMonday = now.weekday - 1;
    setState(() {
      _selectedWeekMonday = today.subtract(Duration(days: daysFromMonday));
      if (now.weekday >= 1 && now.weekday <= 5) {
        _selectedDayIndex = now.weekday - 1;
      } else {
        _selectedDayIndex = 0;
      }
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
      'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr'
    ];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = [
      'Yan', 'Fev', 'Mar', 'Apr', 'May', 'İyun',
      'İyul', 'Avq', 'Sen', 'Okt', 'Noy', 'Dek'
    ];
    return months[month - 1];
  }

  /// Calculates break duration in minutes between two consecutive lesson times
  int? _calculateBreakMinutes(String prevEndTimeStr, String nextStartTimeStr) {
    try {
      final prevParts = prevEndTimeStr.trim().split(':');
      final nextParts = nextStartTimeStr.trim().split(':');
      if (prevParts.length == 2 && nextParts.length == 2) {
        final prevMinutes = int.parse(prevParts[0]) * 60 + int.parse(prevParts[1]);
        final nextMinutes = int.parse(nextParts[0]) * 60 + int.parse(nextParts[1]);
        final diff = nextMinutes - prevMinutes;
        return (diff > 0 && diff <= 120) ? diff : null;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;
    final className = currentStudent.className;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedDate = _selectedWeekMonday.add(Duration(days: _selectedDayIndex));
    final weekFriday = _selectedWeekMonday.add(const Duration(days: 4));

    final thisWeeksMonday = today.subtract(Duration(days: now.weekday - 1));
    final isCurrentWeek = _selectedWeekMonday.isAtSameMomentAs(thisWeeksMonday);
    final isViewingToday = selectedDate.isAtSameMomentAs(today);

    final lessons = appState.getClassLessonsForDate(className, selectedDate);
    final weekRangeTitle = '${_selectedWeekMonday.day} ${_getShortMonthName(_selectedWeekMonday.month)} - ${weekFriday.day} ${_getShortMonthName(weekFriday.month)} ${weekFriday.year}';

    // Check if there is an active lesson right now
    LessonSlot? activeLesson;
    LessonSlot? nextLesson;
    if (isViewingToday) {
      for (final l in lessons) {
        if (l.time.contains(' - ')) {
          final parts = l.time.split(' - ');
          final startParts = parts[0].trim().split(':');
          final endParts = parts[1].trim().split(':');
          if (startParts.length == 2 && endParts.length == 2) {
            final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
            final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
            if (now.isAfter(start) && now.isBefore(end)) {
              activeLesson = l;
              break;
            } else if (now.isBefore(start) && nextLesson == null) {
              nextLesson = l;
            }
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dərs Cədvəli',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.3),
            ),
            Text(
              className.isNotEmpty ? '$className Sinifi • İdrak Liseyi' : 'İdrak Liseyi',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5, color: Colors.white.withAlpha(200)),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
          ),
          onPressed: () => handleBackNavigation(context),
        ),
        actions: [
          if (!isViewingToday)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _goToToday,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent.withAlpha(40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryAccent.withAlpha(100)),
                  ),
                ),
                icon: const Icon(Icons.today_rounded, size: 14, color: AppColors.primaryAccent),
                label: const Text('Bu Günə Qayıt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Week Controller & Navigation ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Week Switcher Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _goToPreviousWeek,
                        icon: const Icon(Icons.chevron_left_rounded, size: 22, color: Colors.white),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCurrentWeek ? Icons.check_circle_rounded : Icons.date_range_rounded,
                            size: 14,
                            color: isCurrentWeek ? const Color(0xFF38BDF8) : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            weekRangeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _goToNextWeek,
                        icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Modern Day Pills ──
                Row(
                  children: List.generate(5, (index) {
                    final dayDate = _selectedWeekMonday.add(Duration(days: index));
                    final isToday = dayDate.isAtSameMomentAs(today);
                    final isSelected = _selectedDayIndex == index;
                    final dayLessons = appState.getClassLessonsForDate(className, dayDate);

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 4 ? 6 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDayIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isToday ? Colors.white.withAlpha(25) : Colors.white.withAlpha(10)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF60A5FA)
                                    : (isToday ? const Color(0xFF38BDF8).withAlpha(120) : Colors.white.withAlpha(20)),
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withAlpha(100),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _shortDays[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : (isToday ? const Color(0xFF38BDF8) : Colors.white70),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dayDate.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : (isToday ? const Color(0xFF38BDF8) : Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withAlpha(35)
                                        : Colors.white.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${dayLessons.length} d',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Active / Next Lesson Hero Card (If today has ongoing lesson) ──
          if (isViewingToday && (activeLesson != null || nextLesson != null))
            _buildLiveHeroBanner(activeLesson ?? nextLesson!, isActive: activeLesson != null),

          // ── Day Summary Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isViewingToday ? const Color(0xFF10B981) : AppColors.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_dayNames[_selectedDayIndex]}, ${selectedDate.day} ${_getMonthName(selectedDate.month)}${isViewingToday ? " (Bugün)" : ""}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${lessons.length} Dərs Saatı',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),

          // ── Lessons Timeline List ──
          Expanded(
            child: className.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.school_outlined,
                    title: 'Sinif təyin edilməyib',
                    message: 'Şagirdin sinfi administrator tərəfindən təyin olunmadığı üçün dərs cədvəli göstərilə bilmir.',
                  )
                : lessons.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.weekend_rounded, size: 48, color: Color(0xFF4F46E5)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${selectedDate.day} ${_getMonthName(selectedDate.month)} üçün dərs yoxdur',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Bu gün tətil və ya istirahət günüdür. Sabahkı dərslərə hazırlaşa bilərsiniz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                        itemCount: lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          final isLast = index == lessons.length - 1;

                          // Check break time before next lesson
                          int? breakMins;
                          if (!isLast && lesson.time.contains(' - ') && lessons[index + 1].time.contains(' - ')) {
                            final prevEnd = lesson.time.split(' - ')[1];
                            final nextStart = lessons[index + 1].time.split(' - ')[0];
                            breakMins = _calculateBreakMinutes(prevEnd, nextStart);
                          }

                          // Check if currently ongoing (if today)
                          bool isCurrent = false;
                          if (isViewingToday && lesson.time.contains(' - ')) {
                            final parts = lesson.time.split(' - ');
                            final startParts = parts[0].trim().split(':');
                            final endParts = parts[1].trim().split(':');
                            if (startParts.length == 2 && endParts.length == 2) {
                              final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
                              final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
                              isCurrent = now.isAfter(start) && now.isBefore(end);
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildModernLessonCard(lesson, className, isCurrent, index),
                              if (breakMins != null && breakMins > 0)
                                _buildBreakIndicator(breakMins),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Live Hero Card for Ongoing/Next Lesson
  Widget _buildLiveHeroBanner(LessonSlot lesson, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF047857), const Color(0xFF065F46)]
              : [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isActive ? const Color(0xFF059669) : const Color(0xFF2563EB)).withAlpha(60),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(lesson.subjectIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? '🔴 İNDİ KEÇİRİLİR' : '⏳ NÖVBƏTİ DƏRS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lesson.time,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lesson.displayTeachers} • ${lesson.room.isNotEmpty ? lesson.room : "Otaq Təyin Edilməyib"}',
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Break indicator between periods
  Widget _buildBreakIndicator(int minutes) {
    final isLunch = minutes >= 35;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isLunch ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLunch ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLunch ? Icons.restaurant_rounded : Icons.pause_circle_outline_rounded,
                    size: 13,
                    color: isLunch ? const Color(0xFFD97706) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLunch ? 'Nahar Tənəffüsü ($minutes dəq)' : '$minutes dəqiqə tənəffüs',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isLunch ? const Color(0xFFB45309) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }

  /// Beautiful Lesson Card
  Widget _buildModernLessonCard(LessonSlot lesson, String currentClassName, bool isCurrent, int index) {
    final color = lesson.subjectColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.8 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Vibrant Strip
              Container(
                width: 6,
                color: color,
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Period, Time, Room Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lesson.period,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 3),
                                  Text(
                                    lesson.time,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room_outlined, size: 12, color: Color(0xFF475569)),
                                const SizedBox(width: 3),
                                Text(
                                  lesson.room.isNotEmpty ? lesson.room : 'Otaq -',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Subject Title & Teacher Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(lesson.subjectIcon, color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.subject,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        lesson.displayTeachers,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Merged / Co-teaching banner if applicable
                      if (lesson.isMerged) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 13, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              Text(
                                'Birgə Dərs (${lesson.displayClasses(currentClassName)})',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
