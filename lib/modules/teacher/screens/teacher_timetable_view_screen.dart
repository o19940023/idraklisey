import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../data/models/timetable_model.dart';
import 'smart_attendance_screen.dart';

class TeacherTimetableViewScreen extends StatefulWidget {
  const TeacherTimetableViewScreen({super.key});

  @override
  State<TeacherTimetableViewScreen> createState() => _TeacherTimetableViewScreenState();
}

class _TeacherTimetableViewScreenState extends State<TeacherTimetableViewScreen> {
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
    
    // Find Monday of the current week
    final daysFromMonday = now.weekday - 1; // Mon=1 -> 0, etc.
    _selectedWeekMonday = today.subtract(Duration(days: daysFromMonday < 5 ? daysFromMonday : 0));

    // Default select today if weekday is Monday-Friday (1..5), else Monday (0)
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
    final currentUser = appState.currentUser!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedDate = _selectedWeekMonday.add(Duration(days: _selectedDayIndex));
    final weekFriday = _selectedWeekMonday.add(const Duration(days: 4));

    final isCurrentWeek = _selectedWeekMonday.isAtSameMomentAs(
      today.subtract(Duration(days: now.weekday - 1 < 5 ? now.weekday - 1 : 0)),
    );

    final lessons = appState.getTeacherLessonsForDate(currentUser.id, selectedDate);

    final weekRangeTitle = '${_selectedWeekMonday.day} ${_getShortMonthName(_selectedWeekMonday.month)} - ${weekFriday.day} ${_getShortMonthName(weekFriday.month)} ${weekFriday.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1B2E), Color(0xFF2D1B69), Color(0xFF7C3AED)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -10,
                      child: Icon(Icons.calendar_month_rounded, size: 140, color: Colors.white.withAlpha(8)),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 36, 20, 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withAlpha(40), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white.withAlpha(20),
                                    backgroundImage: currentUser.photoUrl != null ? NetworkImage(currentUser.photoUrl!) : null,
                                    child: currentUser.photoUrl == null
                                        ? const Icon(Icons.person_rounded, size: 22, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dərs Cədvəlim',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            currentUser.fullName,
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(200),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold.withAlpha(25),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              currentUser.subject ?? 'Müəllim',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.goldLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isCurrentWeek)
                                  GestureDetector(
                                    onTap: _goToToday,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryAccent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryAccent.withAlpha(60),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.today_rounded, color: Colors.white, size: 13),
                                          SizedBox(width: 4),
                                          Text('Bu Gün', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                        ],
                                      ),
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
          ),

          // ── Week Switcher Bar ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          ),

          // ── Day Selector Cards (5 Days Mon-Fri) ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: List.generate(5, (index) {
                  final dayDate = _selectedWeekMonday.add(Duration(days: index));
                  final isToday = dayDate.isAtSameMomentAs(today);
                  final isSelected = _selectedDayIndex == index;
                  final dayLessons = appState.getTeacherLessonsForDate(currentUser.id, dayDate);

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
          ),

          // ── Selected Day Info Banner ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selectedDate.isAtSameMomentAs(today) ? AppColors.success.withAlpha(10) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate.isAtSameMomentAs(today) ? AppColors.success.withAlpha(40) : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedDate.isAtSameMomentAs(today) ? Icons.today_rounded : Icons.calendar_today_rounded,
                    size: 14,
                    color: selectedDate.isAtSameMomentAs(today) ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_dayNames[_selectedDayIndex]}, ${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}${selectedDate.isAtSameMomentAs(today) ? " (Bugün)" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selectedDate.isAtSameMomentAs(today) ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${lessons.length} dərs',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // ── Empty State ──
          if (lessons.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withAlpha(8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${selectedDate.day} ${_getMonthName(selectedDate.month)} üçün\ndərs təyin edilməyib.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bu tarix üçün dərsiniz yoxdur və ya tətil günüdür.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Lessons List ──
          if (lessons.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final slot = lessons[index];
                    return _buildLessonSlotCard(context, appState, slot, selectedDate, index);
                  },
                  childCount: lessons.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonSlotCard(BuildContext context, AppState appState, LessonSlot slot, DateTime selectedDate, int index) {
    final color = slot.subjectColor;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.isAtSameMomentAs(today);
    final isFuture = selectedDate.isAfter(today);

    // Dərsin sinfini tap
    String targetClass = '9B';
    for (final cls in appState.allDistinctClasses) {
      final timetable = appState.getClassTimetable(cls);
      for (final day in timetable) {
        if (day.lessons.any((l) => l.time == slot.time && l.subject == slot.subject)) {
          targetClass = cls;
          break;
        }
      }
    }

    final isLocked = appState.isAttendanceLocked(targetClass, slot.subject);

    // Dərs başlama vaxtı
    DateTime? lessonStartTime;
    DateTime? tenMinBefore;
    bool canAccess = true;

    if (slot.time.contains(' - ')) {
      final timeParts = slot.time.split(' - ');
      final startParts = timeParts[0].trim().split(':');
      if (startParts.length == 2) {
        final startH = int.tryParse(startParts[0]) ?? 8;
        final startM = int.tryParse(startParts[1]) ?? 30;
        lessonStartTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startH, startM);
        tenMinBefore = lessonStartTime.subtract(const Duration(minutes: 10));

        if (isToday) {
          canAccess = now.isAfter(tenMinBefore) || now.isAtSameMomentAs(tenMinBefore);
        } else if (isFuture) {
          canAccess = false;
        } else {
          canAccess = true;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.background : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isLocked ? AppColors.cardBorder : color.withAlpha(60)),
        boxShadow: isLocked ? [] : AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isLocked) {
              _showLockedDialog(context, slot);
              return;
            }

            if (!canAccess) {
              _showEarlyAccessDialog(context, slot, selectedDate, tenMinBefore ?? DateTime.now(), isFuture);
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SmartAttendanceScreen(
                  targetClass: targetClass,
                  targetClasses: slot.isMerged ? slot.mergedClassNames : [targetClass],
                  targetSubject: slot.subject,
                  targetTime: slot.time,
                  isMerged: slot.isMerged,
                  coTeacherName: slot.coTeacherName,
                  targetDate: selectedDate,
                ),
              ),
            );
          },
          child: Column(
            children: [
              // Top Color Accent Strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLocked
                        ? [AppColors.textMuted.withAlpha(60), AppColors.textMuted.withAlpha(30)]
                        : [color, color.withAlpha(100)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period, Time & Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                slot.period,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              slot.time,
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, color: AppColors.danger, size: 11),
                                SizedBox(width: 4),
                                Text('Kilidli', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        else if (!slot.isRecurring)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Xüsusi Tarix', style: TextStyle(color: AppColors.goldDark, fontSize: 9.5, fontWeight: FontWeight.w800)),
                          )
                        else if (isToday && canAccess)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 11),
                                SizedBox(width: 4),
                                Text('Davamiyyət Açıq', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Subject Name & Room
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(slot.subjectIcon, color: color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.subject,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.meeting_room_outlined, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    slot.room.isNotEmpty ? slot.room : 'Otaq təyin edilməyib',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tags row (Class names & Co-teacher)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            slot.isMerged && slot.mergedClassNames.isNotEmpty
                                ? 'Birləşdirilmiş: ${slot.mergedClassNames.join(" & ")}'
                                : '$targetClass Sinfi',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                        if (slot.coTeacherName != null && slot.coTeacherName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Co-Teacher: ${slot.coTeacherName}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.goldDark),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context, LessonSlot slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_clock_rounded, color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Davamiyyət Kilidlənib', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Bu dərsin (${slot.subject}) davamiyyəti artıq təsdiqlənib və kilidlənib.\n\nDəyişiklik yalnız Admin tərəfindən edilə bilər.',
          style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEarlyAccessDialog(BuildContext context, LessonSlot slot, DateTime selectedDate, DateTime tenMinBefore, bool isFuture) {
    final dateStr = '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}';
    final timeStr = '${tenMinBefore.hour.toString().padLeft(2, '0')}:${tenMinBefore.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timer_rounded, color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 10),
            Text(isFuture ? 'Gələcək Dərs' : 'Dərs Saatı Hələ Çatmayıb', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          isFuture
              ? 'Bu dərs $dateStr, saat ${slot.time} üçün planlaşdırılıb.\n\nDavamiyyət qeydiyyatı yalnız həmin gün dərsdən 10 dəqiqə əvvəl açılacaq.'
              : 'Davamiyyət qeydiyyatına dərs saatından 10 dəqiqə əvvəl ($timeStr) daxil ola bilərsiniz.\n\nDərs: ${slot.subject}\nSaat: ${slot.time}',
          style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
