import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';

/// Mövcud dərsə başqa sinif(lər)i birləşdirmək üçün interaktiv modal vərəq
Future<void> showMergeClassesSheet({
  required BuildContext context,
  required String currentClass,
  required String day,
  required LessonSlot lesson,
  DateTime? selectedDate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MergeClassesForm(
      currentClass: currentClass,
      day: day,
      lesson: lesson,
      selectedDate: selectedDate,
    ),
  );
}

class _MergeClassesForm extends StatefulWidget {
  final String currentClass;
  final String day;
  final LessonSlot lesson;
  final DateTime? selectedDate;

  const _MergeClassesForm({
    required this.currentClass,
    required this.day,
    required this.lesson,
    this.selectedDate,
  });

  @override
  State<_MergeClassesForm> createState() => _MergeClassesFormState();
}

class _MergeClassesFormState extends State<_MergeClassesForm> {
  final Set<String> _selectedClasses = {};
  bool _isCoTeaching = false;
  AppUser? _coTeacher;
  bool _applyToAllWeeks = true;
  late TextEditingController _roomCtrl;

  @override
  void initState() {
    super.initState();
    _selectedClasses.add(widget.currentClass);
    if (widget.lesson.mergedClassNames.isNotEmpty) {
      _selectedClasses.addAll(widget.lesson.mergedClassNames);
    }
    _roomCtrl = TextEditingController(text: widget.lesson.room);
    _isCoTeaching = widget.lesson.coTeacherName != null && widget.lesson.coTeacherName!.isNotEmpty;
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allClasses = appState.allDistinctClasses;
    final teachers = appState.users.where((u) => u.role == UserRole.teacher).toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded, color: AppColors.goldDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sinif Birləşdirmə (Joint Class)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${widget.day} • ${widget.lesson.period} (${widget.lesson.time})',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cari Dərs Məlumatı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(widget.lesson.subjectIcon, color: widget.lesson.subjectColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.subject,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        Text(
                          'Müəllim: ${widget.lesson.teacher} • Otaq: ${widget.lesson.room}',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Birləşdiriləcək Siniflər
            const Text(
              'Birləşdiriləcək Sinifləri Seçin:',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allClasses.map((cls) {
                final isCurrent = cls == widget.currentClass;
                final isSelected = _selectedClasses.contains(cls);
                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    isCurrent ? '$cls (Əsas)' : cls,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selectedColor: AppColors.goldDark,
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? Colors.transparent : AppColors.cardBorder),
                  ),
                  onSelected: isCurrent
                      ? null
                      : (val) {
                          setState(() {
                            if (val) {
                              _selectedClasses.add(cls);
                            } else {
                              _selectedClasses.remove(cls);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Müəllim Rejimi
            const Text(
              'Müəllim Rejimi:',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.goldDark,
              title: Text(
                'Tək Müəllim (${widget.lesson.teacher} hər iki sinfi tədris edir)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              value: false,
              groupValue: _isCoTeaching,
              onChanged: (v) => setState(() => _isCoTeaching = v!),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.goldDark,
              title: const Text(
                'Hər İki Müəllim (Co-Teacher ilə Birgə Tədris)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              value: true,
              groupValue: _isCoTeaching,
              onChanged: (v) => setState(() => _isCoTeaching = v!),
            ),

            if (_isCoTeaching) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppUser>(
                    value: _coTeacher,
                    hint: Text('İkinci müəllimi seçin...', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    isExpanded: true,
                    items: teachers.where((t) => t.id != widget.lesson.teacherId).map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          '${t.fullName} (${t.subject ?? 'Fənn'})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _coTeacher = val),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Otaq Seçimi
            TextField(
              controller: _roomCtrl,
              decoration: InputDecoration(
                labelText: 'Birləşdirilmiş Dərs Otağı',
                hintText: 'məs: 301 və ya Böyük Akt Zalı',
                prefixIcon: const Icon(Icons.meeting_room_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Təkrarlanma Seçimi
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.goldDark,
              title: Text(
                'Bütün həftələrin ${widget.day} günlərinə tətbiq et',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _applyToAllWeeks ? 'Daimi cədvələ yazılacaq (hər həftə birləşdirilmiş olacaq)' : 'Yalnız bu gün üçün birləşdiriləcək',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              value: _applyToAllWeeks,
              onChanged: (v) => setState(() => _applyToAllWeeks = v),
            ),
            const SizedBox(height: 16),

            // Əməliyyat düymələri
            Row(
              children: [
                if (widget.lesson.isMerged)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final dateStr = widget.selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(widget.selectedDate!)
                            : widget.lesson.dateStr;

                        appState.unmergeClassesInTimetable(
                          day: widget.day,
                          period: widget.lesson.period,
                          classNames: widget.lesson.mergedClassNames,
                          dateStr: (!widget.lesson.isRecurring) ? dateStr : null,
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text('Birləşməni Ləğv Et', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                if (widget.lesson.isMerged) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (_selectedClasses.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Birləşdirmək üçün ən azı 2 sinif seçməlisiniz!')),
                        );
                        return;
                      }

                      final dateStr = widget.selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(widget.selectedDate!)
                          : null;

                      appState.mergeExistingClassesInTimetable(
                        day: widget.day,
                        period: widget.lesson.period,
                        classNames: _selectedClasses.toList(),
                        primarySubject: widget.lesson.subject,
                        primaryTeacher: widget.lesson.teacher,
                        primaryTeacherId: widget.lesson.teacherId ?? '',
                        primaryTeacherPhotoUrl: widget.lesson.teacherPhotoUrl,
                        primaryRoom: _roomCtrl.text.trim().isNotEmpty ? _roomCtrl.text.trim() : widget.lesson.room,
                        coTeacherName: _isCoTeaching ? _coTeacher?.fullName : null,
                        coTeacherId: _isCoTeaching ? _coTeacher?.id : null,
                        coTeacherPhotoUrl: _isCoTeaching ? _coTeacher?.photoUrl : null,
                        time: widget.lesson.time,
                        isRecurring: _applyToAllWeeks,
                        dateStr: dateStr,
                      );

                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    label: Text(
                      '${_selectedClasses.length} Sinfi Birləşdir',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
