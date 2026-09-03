import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';

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
    
    // Find Monday of current week
    final daysFromMonday = now.weekday - 1;
    _selectedWeekMonday = today.subtract(Duration(days: daysFromMonday < 5 ? daysFromMonday : 0));

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
      _selectedWeekMonday = today.subtract(Duration(days: daysFromMonday < 5 ? daysFromMonday : 0));
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentStudent = appState.student;
    final className = currentStudent.className.isNotEmpty ? currentStudent.className : '9B';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedDate = _selectedWeekMonday.add(Duration(days: _selectedDayIndex));
    final weekFriday = _selectedWeekMonday.add(const Duration(days: 4));

    final isCurrentWeek = _selectedWeekMonday.isAtSameMomentAs(
      today.subtract(Duration(days: now.weekday - 1 < 5 ? now.weekday - 1 : 0)),
    );

    final lessons = appState.getClassLessonsForDate(className, selectedDate);
    final weekRangeTitle = '${_selectedWeekMonday.day} ${_getShortMonthName(_selectedWeekMonday.month)} - ${weekFriday.day} ${_getShortMonthName(weekFriday.month)} ${weekFriday.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dərs Cədvəli ($className)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
          ),
          onPressed: () => handleBackNavigation(context),
        ),
        actions: [
          if (!isCurrentWeek)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                backgroundColor: AppColors.primaryAccent,
                label: const Text('Bu Gün', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                avatar: const Icon(Icons.today_rounded, color: Colors.white, size: 14),
                onPressed: _goToToday,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Week Switcher Bar ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _goToPreviousWeek,
                  icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.primaryAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCurrentWeek ? Icons.verified_rounded : Icons.date_range_rounded,
                          size: 14,
                          color: isCurrentWeek ? AppColors.primaryAccent : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCurrentWeek ? 'Bu Həftə' : 'Həftəlik Cədvəl',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isCurrentWeek ? AppColors.primaryAccent : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekRangeTitle,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _goToNextWeek,
                  icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.primaryAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // ── Day Selector Cards ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent
                              : (isToday ? AppColors.primaryAccent.withAlpha(12) : AppColors.surface),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : (isToday ? AppColors.primaryAccent.withAlpha(50) : AppColors.cardBorder),
                            width: isSelected || isToday ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryAccent.withAlpha(40),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _shortDays[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white.withAlpha(220)
                                    : (isToday ? AppColors.primaryAccent : AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dayDate.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? Colors.white
                                    : (isToday ? AppColors.primaryAccent : AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withAlpha(30)
                                    : (dayLessons.isNotEmpty
                                        ? AppColors.primaryAccent.withAlpha(15)
                                        : AppColors.cardBorder.withAlpha(50)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${dayLessons.length}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (dayLessons.isNotEmpty ? AppColors.primaryAccent : AppColors.textMuted),
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
          ),

          // ── Day Summary Header ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selectedDate.isAtSameMomentAs(today) ? AppColors.success.withAlpha(10) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedDate.isAtSameMomentAs(today) ? AppColors.success.withAlpha(40) : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      selectedDate.isAtSameMomentAs(today) ? Icons.today_rounded : Icons.calendar_today_rounded,
                      size: 14,
                      color: selectedDate.isAtSameMomentAs(today) ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_dayNames[_selectedDayIndex]}, ${selectedDate.day} ${_getMonthName(selectedDate.month)}${selectedDate.isAtSameMomentAs(today) ? " (Bugün)" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selectedDate.isAtSameMomentAs(today) ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${lessons.length} Dərs Saatı',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // ── Lessons List / Empty State ──
          Expanded(
            child: lessons.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            '${selectedDate.day} ${_getMonthName(selectedDate.month)} üçün dərs cədvəli yoxdur',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bu gün tətil və ya dərslərin olmadığı gündür.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final color = lesson.subjectColor;
                      final icon = lesson.subjectIcon;

                      // Check if currently ongoing (if today)
                      bool isCurrent = false;
                      if (selectedDate.isAtSameMomentAs(today) && lesson.time.contains(' - ')) {
                        final parts = lesson.time.split(' - ');
                        final startParts = parts[0].trim().split(':');
                        final endParts = parts[1].trim().split(':');
                        if (startParts.length == 2 && endParts.length == 2) {
                          final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
                          final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
                          isCurrent = now.isAfter(start) && now.isBefore(end);
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent ? AppColors.primaryAccent : AppColors.cardBorder,
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryAccent.withAlpha(25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : AppShadows.sm,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Accent Strip
                                Container(
                                  width: 5,
                                  color: color,
                                ),

                                // Lesson Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: color.withAlpha(20),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    lesson.period,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: color,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.schedule_outlined, size: 12, color: AppColors.textSecondary),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      lesson.time,
                                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (isCurrent)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.danger,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 11),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'İNDİ KEÇİRİLİR',
                                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.cardBorder),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.meeting_room_outlined, size: 11, color: AppColors.textSecondary),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      lesson.room.isNotEmpty ? lesson.room : 'Otaq -',
                                                      style: TextStyle(fontSize: 10.5, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: color.withAlpha(20),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(icon, color: color, size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    lesson.subject,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary),
                                                      const SizedBox(width: 3),
                                                      Expanded(
                                                        child: Text(
                                                          lesson.displayTeachers,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            color: AppColors.textSecondary,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (lesson.isMerged) ...[
                                                    const SizedBox(height: 5),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.gold.withAlpha(25),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: AppColors.gold.withAlpha(80)),
                                                      ),
                                                      child: Text(
                                                        '🔗 ${lesson.displayClasses(className)} Birgə Dərs',
                                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

