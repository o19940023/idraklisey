import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';

class CreateTimetableEntryScreen extends StatefulWidget {
  final String? initialDay;
  final String? initialClass;
  final String? initialPeriod;
  final DateTime? initialDate;

  const CreateTimetableEntryScreen({
    super.key,
    this.initialDay,
    this.initialClass,
    this.initialPeriod,
    this.initialDate,
  });

  @override
  State<CreateTimetableEntryScreen> createState() => _CreateTimetableEntryScreenState();
}

class _CreateTimetableEntryScreenState extends State<CreateTimetableEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  late String _selectedDay;
  String? _selectedPeriod;
  AppUser? _selectedTeacher;
  final Set<String> _selectedClasses = {};
  
  // Co-teaching & Class Merging options
  bool _isCoTeaching = false;
  AppUser? _coTeacher;
  bool _isRecurring = true; // Bütün həftələr üçün tətbiq et
  
  final TextEditingController _roomCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  final Map<String, String> _lessonPeriods = {
    '1-ci dərs': '08:00 - 08:45',
    '2-ci dərs': '08:55 - 09:40',
    '3-cü dərs': '09:50 - 10:35',
    '4-cü dərs': '10:45 - 11:30',
    '5-ci dərs': '11:40 - 12:25',
    '6-cı dərs': '12:35 - 13:20',
    '7-ci dərs': '13:30 - 14:15',
    '8-ci dərs': '14:25 - 15:10',
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDay ?? _getDayNameFromDate(_selectedDate);
    _selectedPeriod = widget.initialPeriod;
    if (widget.initialClass != null) {
      _selectedClasses.add(widget.initialClass!);
      _roomCtrl.text = 'Otaq ${widget.initialClass}';
    }
  }

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
      default:
        return 'Bazar ertəsi';
    }
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teachers = appState.users.where((u) => u.role == UserRole.teacher).toList();
    final classes = appState.allDistinctClasses;

    final isMerged = _selectedClasses.length > 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dərs Cədvəli Yarat',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. TARİX VƏ GÜN SEÇİMİ ──
            _buildSectionCard(
              title: '1. Tarix və Gün',
              icon: Icons.calendar_month_rounded,
              accentColor: AppColors.primaryAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) ? DateTime.now() : _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _selectedDay = _getDayNameFromDate(picked);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.event_available_rounded, color: AppColors.primaryAccent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tarixi dəyişmək üçün toxunun',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _selectedDay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Təkrarlanma toggle
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryAccent,
                    title: Text(
                      'Bütün həftələrin $_selectedDay günlərinə tətbiq et',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      _isRecurring ? 'Hər həftə avtomatik təkrarlanacaq' : 'Yalnız seçilmiş konkret tarix üçün tətbiq ediləcək',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. DƏRS SAATI (PERIOD) ──
            _buildSectionCard(
              title: '2. Dərs Saatı',
              icon: Icons.access_time_filled_rounded,
              accentColor: AppColors.success,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _lessonPeriods.length,
                itemBuilder: (context, idx) {
                  final entry = _lessonPeriods.entries.elementAt(idx);
                  final isSelected = _selectedPeriod == entry.key;
                  return InkWell(
                    onTap: () => setState(() => _selectedPeriod = entry.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.success.withAlpha(20) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.success : AppColors.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isSelected ? AppColors.success : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppColors.success : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.success : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. SİNİF SEÇİMİ VƏ SİNİF BİRLƏŞDİRMƏ ──
            _buildSectionCard(
              title: '3. Sinif(lər) Seçimi & Birləşdirmə',
              icon: Icons.groups_rounded,
              accentColor: isMerged ? AppColors.goldDark : AppColors.primaryAccent,
              badge: isMerged
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link_rounded, size: 12, color: AppColors.goldDark),
                          const SizedBox(width: 4),
                          Text(
                            'Birləşdirilmiş (${_selectedClasses.length} Sinif)',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                          ),
                        ],
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birdən çox sinif seçərək həmin saat üçün dərsi birləşdirə bilərsiniz (məs: 5B + 6B):',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (classes.isEmpty)
                    Text('Sinif tapılmadı', style: TextStyle(color: AppColors.textMuted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: classes.map((cls) {
                        final isSel = _selectedClasses.contains(cls);
                        return FilterChip(
                          selected: isSel,
                          label: Text(
                            cls,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selectedColor: isMerged ? AppColors.goldDark : AppColors.primaryAccent,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSel ? Colors.transparent : AppColors.cardBorder,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedClasses.add(cls);
                                if (_roomCtrl.text.isEmpty) {
                                  _roomCtrl.text = 'Otaq $cls';
                                }
                              } else {
                                _selectedClasses.remove(cls);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 4. MÜƏLLİM VƏ BİRGƏ TƏDRİS SEÇİMİ ──
            _buildSectionCard(
              title: '4. Müəllim və Tədris Rejimi',
              icon: Icons.psychology_rounded,
              accentColor: AppColors.goldDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Əsas Müəllim:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppUser>(
                        value: _selectedTeacher,
                        hint: Text('Müəllim seçin...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        isExpanded: true,
                        items: teachers.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primaryAccent.withAlpha(20),
                                  backgroundImage: t.photoUrl != null ? NetworkImage(t.photoUrl!) : null,
                                  child: t.photoUrl == null ? const Icon(Icons.person, size: 14, color: AppColors.primaryAccent) : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${t.fullName} (${t.subject ?? 'Fənn'})',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedTeacher = val),
                      ),
                    ),
                  ),

                  // Əgər siniflər birləşibsə, müəllim rejimini seçə bilər
                  if (isMerged) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold.withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.co_present_rounded, color: AppColors.goldDark, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Birləşdirilmiş Dərs Müəllim Rejimi',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<bool>(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppColors.goldDark,
                            title: const Text(
                              'Tək Müəllim (Hər iki sinfə tək müəllim keçir)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                              'Hər İki Müəllim / Birgə Tədris (Co-teacher)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            value: true,
                            groupValue: _isCoTeaching,
                            onChanged: (v) => setState(() => _isCoTeaching = v!),
                          ),
                          if (_isCoTeaching) ...[
                            const SizedBox(height: 8),
                            Text(
                              'İkinci Müəllim (Co-Teacher):',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AppUser>(
                                  value: _coTeacher,
                                  hint: Text('İkinci müəllim seçin...', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                                  isExpanded: true,
                                  items: teachers.where((t) => t.id != _selectedTeacher?.id).map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        '${t.fullName} (${t.subject ?? 'Fənn'})',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _coTeacher = val),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 5. OTAQ VƏ QEYD ──
            _buildSectionCard(
              title: '5. Otaq və Qeyd',
              icon: Icons.meeting_room_rounded,
              accentColor: AppColors.info,
              child: Column(
                children: [
                  TextField(
                    controller: _roomCtrl,
                    decoration: InputDecoration(
                      labelText: 'Otaq / Sinif Nömrəsi',
                      hintText: 'məs: 301, Lab-A və ya 5B Otağı',
                      prefixIcon: const Icon(Icons.door_front_door_rounded, color: AppColors.info, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Əlavə Qeyd (İxtiyari)',
                      hintText: 'məs: Açıq dərs, Laboratoriya sınağı və s.',
                      prefixIcon: Icon(Icons.note_alt_rounded, color: AppColors.textSecondary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── YADDA SAXLA DÜYMƏSİ ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMerged ? AppColors.goldDark : AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () => _submitTimetableEntry(context, appState),
                icon: Icon(isMerged ? Icons.link_rounded : Icons.check_circle_rounded, color: Colors.white, size: 22),
                label: Text(
                  isMerged ? 'Birləşdirilmiş Dərsi Təsdiqlə' : 'Dərsi Cədvələ Əlavə Et',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
    Widget? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  void _submitTimetableEntry(BuildContext context, AppState appState) {
    if (_selectedTeacher == null) {
      _showErrorDialog(context, 'Müəllim seçilməyib', 'Zəhmət olmasa dərsi tədris edəcək müəllimi seçin.');
      return;
    }

    if (_selectedClasses.isEmpty) {
      _showErrorDialog(context, 'Sinif seçilməyib', 'Ən azı 1 sinif seçməlisiniz.');
      return;
    }

    if (_selectedPeriod == null) {
      _showErrorDialog(context, 'Dərs saatı seçilməyib', 'Dərsin neçənci saatda olacağını seçin.');
      return;
    }

    if (_roomCtrl.text.trim().isEmpty) {
      _showErrorDialog(context, 'Otaq qeyd olunmayıb', 'Dərsin keçiriləcəyi otaq və ya laboratoriyanı qeyd edin.');
      return;
    }

    final timeRange = _lessonPeriods[_selectedPeriod]!;
    final classList = _selectedClasses.toList();

    // Konflikt yoxlaması
    for (final cls in classList) {
      final conflict = appState.checkTimetableConflict(
        className: cls,
        day: _selectedDay,
        time: timeRange,
        teacherId: _selectedTeacher!.id,
        allowedClassExceptions: classList,
      );
      if (conflict != null) {
        _showErrorDialog(context, 'Cədvəl Konflikti', conflict);
        return;
      }
    }

    final isMerged = classList.length > 1;

    final newLesson = LessonSlot(
      period: _selectedPeriod!,
      time: timeRange,
      subject: _selectedTeacher!.subject ?? 'Fənn',
      teacher: _selectedTeacher!.fullName,
      teacherId: _selectedTeacher!.id,
      teacherPhotoUrl: _selectedTeacher!.photoUrl,
      room: _roomCtrl.text.trim(),
      isMerged: isMerged,
      mergedClassNames: isMerged ? classList : const [],
      coTeacherName: _isCoTeaching ? _coTeacher?.fullName : null,
      coTeacherId: _isCoTeaching ? _coTeacher?.id : null,
      coTeacherPhotoUrl: _isCoTeaching ? _coTeacher?.photoUrl : null,
      dateStr: DateFormat('yyyy-MM-dd').format(_selectedDate),
      isRecurring: _isRecurring,
    );

    appState.addLessonWithMultipleClasses(
      targetClasses: classList,
      day: _selectedDay,
      lesson: newLesson,
    );

    _showSuccessDialog(context, isMerged, classList);
  }

  void _showErrorDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(msg, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bağla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, bool isMerged, List<String> classList) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: 8),
            const Text('Uğurla Əlavə Edildi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          isMerged
              ? '🎉 ${classList.join(" və ")} sinifləri üçün birləşdirilmiş dərs cədvələ yazıldı. Hər iki sinif və müəllim panelində avtomatik görünəcək.'
              : '🎉 Dərs uğurla cədvələ əlavə edildi və dərhal aktivləşdirildi.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Tamamdır', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
