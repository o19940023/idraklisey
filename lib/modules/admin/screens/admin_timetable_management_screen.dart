import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/timetable_model.dart';
import '../../../providers/app_state.dart';
import '../widgets/merge_classes_sheet.dart';
import 'create_timetable_entry_screen.dart';

class AdminTimetableManagementScreen extends StatefulWidget {
  const AdminTimetableManagementScreen({super.key});

  @override
  State<AdminTimetableManagementScreen> createState() => _AdminTimetableManagementScreenState();
}

class _AdminTimetableManagementScreenState extends State<AdminTimetableManagementScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassFilter; // null = Bütün Siniflər

  final List<String> _weekDayHeaders = ['B.E', 'Ç.A', 'Ç.', 'C.A', 'C.', 'Ş.', 'B.'];

  String _getDayNameFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Bazar ertəsi';
      case DateTime.tuesday:
        return 'Çərşənbə axşamı';
      case DateTime.wednesday:
        return 'Çərşənbə';
      case DateTime.thursday:
        return 'Cümə axşamı';
      case DateTime.friday:
        return 'Cümə';
      case DateTime.saturday:
        return 'Şənbə';
      case DateTime.sunday:
        return 'Bazar';
      default:
        return 'Bazar ertəsi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final classes = appState.allDistinctClasses;
    final selectedDayName = _getDayNameFromDate(_selectedDate);

    // Seçilmiş gün üçün dərsləri topla
    final List<MapEntry<String, LessonSlot>> lessonsForDay = [];
    final targetClasses = _selectedClassFilter != null ? [_selectedClassFilter!] : classes;
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final Set<String> seenMergedKeys = {};

    for (final cls in targetClasses) {
      final days = appState.getClassTimetable(cls);
      final matchDay = days.where((d) => d.dayName == selectedDayName).firstOrNull;
      if (matchDay != null) {
        for (final lesson in matchDay.lessons) {
          // Əgər bu tarix üçün istisna (ləğv) edilibsə, göstərmə
          if (lesson.excludedDates.contains(dateFormatted)) continue;

          // Əgər tarixə görə xüsusi dərsdirsə və təkrarlanmırsa, yoxla
          if (!lesson.isRecurring && lesson.dateStr != null) {
            if (lesson.dateStr != dateFormatted) continue;
          }

          // Birləşdirilmiş dərsləri "Bütün Siniflər" rejimində dublikat göstərmə
          if (_selectedClassFilter == null && lesson.isMerged && lesson.mergedClassNames.isNotEmpty) {
            final sortedClasses = List<String>.from(lesson.mergedClassNames)..sort();
            final mergeKey = '${lesson.time}_${lesson.subject}_${sortedClasses.join("-")}';
            if (seenMergedKeys.contains(mergeKey)) continue;
            seenMergedKeys.add(mergeKey);
          }

          lessonsForDay.add(MapEntry(cls, lesson));
        }
      }
    }

    // Sort by time
    lessonsForDay.sort((a, b) => a.value.time.compareTo(b.value.time));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dərs Cədvəli & Təqvim',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Class Filter dropdown
          if (classes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedClassFilter,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 18),
                      hint: const Text('Bütün Siniflər', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Bütün Siniflər', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        ...classes.map((c) => DropdownMenuItem<String?>(
                              value: c,
                              child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedClassFilter = val);
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTimetableEntryScreen(
                  initialDate: _selectedDate,
                  initialDay: selectedDayName,
                  initialClass: _selectedClassFilter,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          label: Text(
            '${DateFormat('dd MMM').format(_selectedDate)} Tarixinə Dərs Əlavə Et',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── FULL-PAGE STUNNING CALENDAR WIDGET ──
            _buildFullPageCalendar(appState, classes),

            // ── SEÇİLMİŞ GÜNÜN DƏRSLƏRİ (TIMELINE LIST) ──
            _buildSelectedDayLessonsSection(appState, selectedDayName, lessonsForDay),
          ],
        ),
      ),
    );
  }

  // ── FULL-PAGE AYLIQ TƏQVİM ──
  Widget _buildFullPageCalendar(AppState appState, List<String> classes) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Monday = 1, Sunday = 7
    final int leadingEmptyDays = firstDayOfMonth.weekday - 1;
    final int totalDaysInMonth = lastDayOfMonth.day;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          // ── Ay Başlığı & Naviqasiya ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                      });
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primaryAccent.withAlpha(15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(now.year, now.month, 1);
                        _selectedDate = now;
                      });
                    },
                    child: const Text(
                      'Bu gün',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primaryAccent),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Həftə Günləri Başlığı (B.E, Ç.A ...) ──
          Row(
            children: _weekDayHeaders.map((h) {
              final isWeekend = h == 'Ş.' || h == 'B.';
              return Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isWeekend ? AppColors.danger.withAlpha(180) : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // ── Aylıq Günlər Qridi (Calendar Grid) ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
            ),
            itemCount: leadingEmptyDays + totalDaysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }

              final int dayNumber = index - leadingEmptyDays + 1;
              final DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final bool isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final bool isSelected = cellDate.year == _selectedDate.year && cellDate.month == _selectedDate.month && cellDate.day == _selectedDate.day;

              // Bu günün dərslərini say
              final dayName = _getDayNameFromDate(cellDate);
              final cellDateFormatted = DateFormat('yyyy-MM-dd').format(cellDate);
              int lessonCount = 0;
              bool hasMergedLesson = false;

              final targetClasses = _selectedClassFilter != null ? [_selectedClassFilter!] : classes;
              for (final cls in targetClasses) {
                final days = appState.getClassTimetable(cls);
                final d = days.where((item) => item.dayName == dayName).firstOrNull;
                if (d != null) {
                  for (final l in d.lessons) {
                    if (l.excludedDates.contains(cellDateFormatted)) continue;
                    if (!l.isRecurring && l.dateStr != null && l.dateStr != cellDateFormatted) continue;
                    lessonCount++;
                    if (l.isMerged) {
                      hasMergedLesson = true;
                    }
                  }
                }
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryAccent
                        : (isToday ? AppColors.gold.withAlpha(20) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.gold, width: 1.5)
                        : (isSelected ? null : Border.all(color: Colors.transparent)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (cellDate.weekday >= 6 ? AppColors.textMuted : AppColors.textPrimary),
                        ),
                      ),
                      if (lessonCount > 0) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : (hasMergedLesson ? AppColors.goldDark : AppColors.primaryAccent),
                              ),
                            ),
                            if (hasMergedLesson) ...[
                              const SizedBox(width: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white70 : AppColors.gold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  // ── SEÇİLMİŞ GÜNÜN DƏRSLƏRİ ──
  Widget _buildSelectedDayLessonsSection(
    AppState appState,
    String dayName,
    List<MapEntry<String, LessonSlot>> lessons,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlıq: Seçilmiş Tarix & Dərs Sayı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('dd MMMM yyyy').format(_selectedDate)}, $dayName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lessons.length} Dərs Saatı Planlaşdırılıb',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (lessons.any((l) => l.value.isMerged)) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, size: 13, color: AppColors.goldDark),
                      SizedBox(width: 4),
                      Text('Birgə Dərslər Var', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.goldDark)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (lessons.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text(
                    'Bu gün üçün heç bir dərs təyin edilməyib',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dərs əlavə etmək üçün aşağıdakı düymədən istifadə edin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...lessons.map((entry) {
              final className = entry.key;
              final lesson = entry.value;
              return _buildLessonCard(appState, dayName, className, lesson);
            }),
        ],
      ),
    );
  }

  Widget _buildLessonCard(
    AppState appState,
    String day,
    String className,
    LessonSlot lesson,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: lesson.isMerged ? AppColors.gold.withAlpha(120) : AppColors.cardBorder,
          width: lesson.isMerged ? 1.5 : 1,
        ),
        boxShadow: lesson.isMerged
            ? [BoxShadow(color: AppColors.gold.withAlpha(20), blurRadius: 10, offset: const Offset(0, 2))]
            : AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Zolaq: Saat, Sinif, Birləşmə
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${lesson.period} (${lesson.time})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.goldDark.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lesson.displayClasses(className),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.goldDark),
                      ),
                    ),
                  ],
                ),
                if (lesson.isMerged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded, size: 12, color: AppColors.goldDark),
                        SizedBox(width: 4),
                        Text(
                          'Birgə Dərs',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.goldDark),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Orta Zolaq: Fənn və Müəllim
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lesson.subjectColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(lesson.subjectIcon, color: lesson.subjectColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.subject,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lesson.displayTeachers,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.door_front_door_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        lesson.room,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Divider(color: AppColors.cardBorder.withAlpha(50), height: 1),
            const SizedBox(height: 6),

            // Alt Əməliyyatlar: Sinif Birləşdirmə & Silmə
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    showMergeClassesSheet(
                      context: context,
                      currentClass: className,
                      day: day,
                      lesson: lesson,
                      selectedDate: _selectedDate,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 14, color: lesson.isMerged ? AppColors.goldDark : AppColors.primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          lesson.isMerged ? 'Birləşməni Tənzimlə' : 'Başqa Siniflə Birləşdir',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: lesson.isMerged ? AppColors.goldDark : AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                  onPressed: () {
                    _showDeleteConfirm(context, appState, className, day, lesson);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    AppState appState,
    String className,
    String day,
    LessonSlot lesson,
  ) {
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dateDisplay = DateFormat('dd MMMM yyyy').format(_selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Dərsi Ləğv Et / Sil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lesson.period} • ${lesson.subject} (${lesson.displayClasses(className)})',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu dərsi necə silmək istəyirsiniz?',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Option 1: Yalnız bu gün üçün
            InkWell(
              onTap: () {
                appState.excludeLessonFromDate(
                  className: className,
                  day: day,
                  period: lesson.period,
                  dateFormatted: dateFormatted,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$dateDisplay tarixi üçün dərs ləğv edildi.')),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryAccent.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded, color: AppColors.primaryAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Yalnız Bu Gün Üçün Sil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                          Text('Yalnız $dateDisplay tarixində dərs olmayacaq', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Option 2: Bütün həftələr üçün (Daimi)
            InkWell(
              onTap: () {
                appState.deleteLessonFromTimetable(
                  className: className,
                  day: day,
                  period: lesson.period,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dərs bütün $day günləri üçün cədvəldən silindi.')),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bütün Həftələr Üçün Sil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.danger)),
                          Text('Daimi cədvəldən tamamilə silinəcək', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İmtina', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
