import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../data/models/timetable_model.dart';
import '../../../providers/app_state.dart';

class TimetableMatrixScreen extends StatefulWidget {
  const TimetableMatrixScreen({super.key});

  @override
  State<TimetableMatrixScreen> createState() => _TimetableMatrixScreenState();
}

class _TimetableMatrixScreenState extends State<TimetableMatrixScreen> {
  late DateTime _selectedWeekMonday;
  int _selectedDayIndex = 0;

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
    _selectedWeekMonday = today.subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday
            ? now.weekday - 1
            : 0;
  }

  void _goToPreviousWeek() {
    setState(() {
      _selectedWeekMonday =
          _selectedWeekMonday.subtract(const Duration(days: 7));
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
    setState(() {
      _selectedWeekMonday = today.subtract(Duration(days: now.weekday - 1));
      _selectedDayIndex =
          now.weekday >= DateTime.monday && now.weekday <= DateTime.friday
              ? now.weekday - 1
              : 0;
    });
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = [
      'Yan',
      'Fev',
      'Mar',
      'Apr',
      'May',
      'İyun',
      'İyul',
      'Avq',
      'Sen',
      'Okt',
      'Noy',
      'Dek',
    ];
    return months[month - 1];
  }

  int? _calculateBreakMinutes(String prevEndTimeStr, String nextStartTimeStr) {
    try {
      final prevParts = prevEndTimeStr.trim().split(':');
      final nextParts = nextStartTimeStr.trim().split(':');
      if (prevParts.length == 2 && nextParts.length == 2) {
        final prevMinutes =
            int.parse(prevParts[0]) * 60 + int.parse(prevParts[1]);
        final nextMinutes =
            int.parse(nextParts[0]) * 60 + int.parse(nextParts[1]);
        final diff = nextMinutes - prevMinutes;
        return (diff > 0 && diff <= 120) ? diff : null;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = Provider.of<AppState>(context);
    final className = appState.student.className;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate =
        _selectedWeekMonday.add(Duration(days: _selectedDayIndex));
    final weekFriday = _selectedWeekMonday.add(const Duration(days: 4));
    final thisWeeksMonday = today.subtract(Duration(days: now.weekday - 1));
    final isCurrentWeek = _selectedWeekMonday.isAtSameMomentAs(thisWeeksMonday);
    final isViewingToday = selectedDate.isAtSameMomentAs(today);
    final lessons = appState.getClassLessonsForDate(className, selectedDate);

    LessonSlot? activeLesson;
    LessonSlot? nextLesson;
    if (isViewingToday) {
      for (final lesson in lessons) {
        if (!lesson.time.contains(' - ')) continue;
        final parts = lesson.time.split(' - ');
        final startParts = parts[0].trim().split(':');
        final endParts = parts[1].trim().split(':');
        if (startParts.length != 2 || endParts.length != 2) continue;
        final start = DateTime(now.year, now.month, now.day,
            int.parse(startParts[0]), int.parse(startParts[1]));
        final end = DateTime(now.year, now.month, now.day,
            int.parse(endParts[0]), int.parse(endParts[1]));
        if (now.isAfter(start) && now.isBefore(end)) {
          activeLesson = lesson;
          break;
        }
        if (now.isBefore(start) && nextLesson == null) {
          nextLesson = lesson;
        }
      }
    }

    final weekRangeTitle =
        '${_selectedWeekMonday.day} ${_getShortMonthName(_selectedWeekMonday.month)}'
        ' – ${weekFriday.day} ${_getShortMonthName(weekFriday.month)} ${weekFriday.year}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: Column(
          children: [
            _buildHero(
              className: className,
              weekRangeTitle: weekRangeTitle,
              isCurrentWeek: isCurrentWeek,
              isViewingToday: isViewingToday,
              today: today,
              appState: appState,
            ),
            if (isViewingToday && (activeLesson != null || nextLesson != null))
              _buildLiveBanner(
                activeLesson ?? nextLesson!,
                isActive: activeLesson != null,
              ),
            _buildDaySummary(
              palette: palette,
              selectedDate: selectedDate,
              isViewingToday: isViewingToday,
              lessonCount: lessons.length,
            ),
            Expanded(
              child: className.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.school_outlined,
                      title: 'Sinif təyin edilməyib',
                      message:
                          'Şagirdin sinfi administrator tərəfindən təyin olunmadığı üçün dərs cədvəli göstərilə bilmir.',
                    )
                  : lessons.isEmpty
                      ? AppEmptyState(
                          icon: Icons.weekend_rounded,
                          title:
                              '${selectedDate.day} ${_getMonthName(selectedDate.month)} üçün dərs yoxdur',
                          message:
                              'Bu gün tətil və ya istirahət günüdür. Sabahkı dərslərə hazırlaşa bilərsiniz.',
                          accent: palette.brandAzure,
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.03, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: ListView.builder(
                            key: ValueKey(
                                '${_selectedWeekMonday.toIso8601String()}-$_selectedDayIndex'),
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              MediaQuery.paddingOf(context).bottom + 28,
                            ),
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              final isLast = index == lessons.length - 1;
                              int? breakMins;
                              if (!isLast &&
                                  lesson.time.contains(' - ') &&
                                  lessons[index + 1].time.contains(' - ')) {
                                breakMins = _calculateBreakMinutes(
                                  lesson.time.split(' - ')[1],
                                  lessons[index + 1].time.split(' - ')[0],
                                );
                              }
                              final isCurrent = _isLessonNow(lesson, now,
                                  isViewingToday: isViewingToday);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLessonCard(
                                    context,
                                    palette,
                                    lesson,
                                    className,
                                    isCurrent,
                                  ),
                                  if (breakMins != null && breakMins > 0)
                                    _buildBreakIndicator(palette, breakMins),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLessonNow(LessonSlot lesson, DateTime now,
      {required bool isViewingToday}) {
    if (!isViewingToday || !lesson.time.contains(' - ')) return false;
    final parts = lesson.time.split(' - ');
    final startParts = parts[0].trim().split(':');
    final endParts = parts[1].trim().split(':');
    if (startParts.length != 2 || endParts.length != 2) return false;
    final start = DateTime(now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final end = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
    return now.isAfter(start) && now.isBefore(end);
  }

  Widget _buildHero({
    required String className,
    required String weekRangeTitle,
    required bool isCurrentWeek,
    required bool isViewingToday,
    required DateTime today,
    required AppState appState,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF080F1F), Color(0xFF111D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => handleBackNavigation(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dərs Cədvəli',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              className.isNotEmpty
                                  ? '$className sinfi • İdrak Liseyi'
                                  : 'İdrak Liseyi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isViewingToday)
                        GestureDetector(
                          onTap: _goToToday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.32),
                              ),
                            ),
                            child: const Text(
                              'Bu gün',
                              style: TextStyle(
                                color: Color(0xFF7DD3FC),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        _weekArrow(Icons.chevron_left_rounded, _goToPreviousWeek),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                isCurrentWeek ? 'BU HƏFTƏ' : 'HƏFTƏ',
                                style: TextStyle(
                                  color: isCurrentWeek
                                      ? const Color(0xFF7DD3FC)
                                      : Colors.white.withValues(alpha: 0.45),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                weekRangeTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _weekArrow(Icons.chevron_right_rounded, _goToNextWeek),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final dayDate =
                          _selectedWeekMonday.add(Duration(days: index));
                      final isToday = dayDate.isAtSameMomentAs(today);
                      final isSelected = _selectedDayIndex == index;
                      final count = appState.getClassLessonsForDate(
                          className, dayDate).length;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index < 4 ? 6 : 0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDayIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF1D4ED8),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : Colors.white.withValues(
                                        alpha: isToday ? 0.10 : 0.04),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF60A5FA)
                                          .withValues(alpha: 0.7)
                                      : isToday
                                          ? const Color(0xFF38BDF8)
                                              .withValues(alpha: 0.45)
                                          : Colors.white
                                              .withValues(alpha: 0.07),
                                  width: isSelected ? 1.4 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withValues(alpha: 0.38),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _shortDays[index],
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? const Color(0xFF7DD3FC)
                                              : Colors.white
                                                  .withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${dayDate.day}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected || isToday
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.88),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                              .withValues(alpha: 0.18)
                                          : Colors.white
                                              .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$count dərs',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.5),
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
          ],
        ),
      ),
    );
  }

  Widget _weekArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 22, color: Colors.white70),
      ),
    );
  }

  Widget _buildLiveBanner(LessonSlot lesson, {required bool isActive}) {
    final colors = isActive
        ? const [Color(0xFF047857), Color(0xFF065F46)]
        : const [Color(0xFF1D4ED8), Color(0xFF1E3A8A)];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(lesson.subjectIcon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'İNDİ' : 'NÖVBƏTİ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        lesson.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${lesson.displayTeachers}${lesson.room.isNotEmpty ? " • ${lesson.room}" : ""}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummary({
    required AppPalette palette,
    required DateTime selectedDate,
    required bool isViewingToday,
    required int lessonCount,
  }) {
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isViewingToday ? const Color(0xFF10B981) : palette.brandRoyal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_dayNames[_selectedDayIndex]}, ${selectedDate.day} ${_getMonthName(selectedDate.month)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (isViewingToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BUGÜN',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Text(
              '$lessonCount dərs',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakIndicator(AppPalette palette, int minutes) {
    final isLunch = minutes >= 35;
    final accent = isLunch ? palette.brandGold : palette.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(height: 1, color: palette.borderHairline),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isLunch
                    ? palette.warningContainer
                    : palette.surface2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isLunch
                      ? palette.brandGold.withValues(alpha: 0.35)
                      : palette.borderHairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLunch
                        ? Icons.restaurant_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 11,
                    color: accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLunch
                        ? 'Nahar tənəffüsü • $minutes dəq'
                        : '$minutes dəqiqə tənəffüs',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: palette.borderHairline),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    AppPalette palette,
    LessonSlot lesson,
    String currentClassName,
    bool isCurrent,
  ) {
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final accent = lesson.subjectColor;
    final tintAlpha = Theme.of(context).brightness == Brightness.dark
        ? 0.18
        : 0.10;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? accent : palette.borderHairline,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.035,
            ),
            blurRadius: isCurrent ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isCurrent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CANLI',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: tintAlpha),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          lesson.period,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                lesson.time,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (lesson.room.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface2,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: palette.borderHairline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 11,
                                color: palette.textMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                lesson.room,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: tintAlpha),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(lesson.subjectIcon, color: accent, size: 21),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_pin_rounded,
                                  size: 13,
                                  color: palette.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    lesson.displayTeachers,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textMuted,
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
                  if (lesson.isMerged) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.warningContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 12,
                            color: palette.brandGold,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Birgə dərs • ${lesson.displayClasses(currentClassName)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: palette.brandGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
