// Kullanıcı Tercihleri Modeli
// Modül sıralama ve navigation bar özelleştirmesi için (GoPanel Web 1:1 adlandırma ilə)

import '../../l10n/app_localizations.dart';

class ModuleItem {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String accentColor;
  final String routeName;
  final bool isVisible;
  final int orderIndex;

  const ModuleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.routeName,
    this.isVisible = true,
    this.orderIndex = 0,
  });

  String getLocalizedTitle(AppLocalizations loc) {
    switch (id) {
      case 'dashboard': return loc.dashboard;
      // Şagird və Valideyn
      case 'student_360': return 'Şagird və Valideyn';
      // E-məktəb (Web ilə 1:1 eyni adlar)
      case 'parents': return 'Valideynlər';
      case 'student_applications': return 'Şagird qəbulu';
      case 'view_students': return 'Şagirdlər';
      case 'graduations': return 'Məzunlar';
      case 'view_classes': return 'Siniflər';
      case 'view_timetable': return 'Cədvəl';
      case 'excused_absences': return 'Üzürlü qayıb sorğuları';
      case 'curriculums': return 'Kurikulum';
      case 'clubs': return 'Dərnəklər';
      case 'academic_years': return 'Akademik illər';
      case 'rooms': return 'Otaqlar';
      case 'time_slots': return 'Zəng cədvəli';

      // İnsan resursları (Web ilə 1:1 eyni adlar)
      case 'organizational_structure': return 'Təşkilati struktur';
      case 'view_employees': return 'Əməkdaşlar';
      case 'view_contracts': return 'Müqavilələr';
      case 'employee_documents': return 'İşçi sənədləri';
      case 'employee_attendance': return 'Davamiyyət';
      case 'salary_calculator': return 'Maaş kalkulyatoru';

      // Maliyyə və mühasibatlıq
      case 'student_invoices': return 'Şagird müqavilələri';
      case 'payroll': return 'Əmək haqqı hesablanması';
      case 'general_ledger': return 'Gəlir/xərc';
      case 'finance_dictionary': return 'Maliyyə tənzimləmələri';

      // Təsərrüfat və inventar
      case 'warehouse_inventory': return 'Anbar inventarı';
      case 'canteen_supply': return 'Yeməkxana';
      case 'view_cafeteria': return 'Həftəlik Menyu';
      case 'view_inventory': return 'QR İnventar';

      // Tibbi əməliyyatlar & Psixologiya
      case 'medical_journal': return 'Tibbi müayinə nəticələri';
      case 'psychology_evaluation': return 'Psixologiya nəticələri';

      // İmtahan
      case 'exam_categories': return 'İmtahan kateqoriyaları';
      case 'view_exams': return 'İmtahanlar';
      case 'exam_results': return 'İmtahan nəticələri';

      // Dəstək biletləri
      case 'view_tickets': case 'tickets': return 'Dəstək biletləri';

      // Kitabxana
      case 'view_library': return 'Kitablar';
      case 'book_loans': return 'Kitab icarələri';
      case 'book_reservations': return 'Kitab reservasiyaları';

      // Statistika və hesabatlar
      case 'quality_control': return 'Keyfiyyətə nəzarət';
      case 'school_attendance_stats': return 'Davamiyyət statistikası';
      case 'view_reports': case 'analytics': return 'Şagird performans statistikası';
      case 'workload_report': return 'İş yükü hesabatı';

      // Sistem və loqlar
      case 'view_settings': return 'Bildirişlər';
      case 'view_users': case 'users': return 'Adminlər';
      case 'view_roles': return 'Vəzifələr (Rollar)';
      case 'activity_logs': return 'Sistem loqları';

      // Müəllim, Şagird, Valideyn panelləri
      case 'student_notes': case 'academic_notes': case 'parent_notes': return 'Akademik Qeydlər';
      case 'student_clubs': case 'parent_clubs': return 'Dərnəklər';
      case 'student_excuses': case 'parent_excuses': return 'Üzürlü Qayıb';
      case 'students': case 'teacher_students': return 'Şagirdlər';
      case 'classes': return 'Siniflər';
      case 'timetable': case 'teacher_timetable': case 'student_timetable': case 'parent_timetable': return 'Dərs Cədvəli';
      case 'grades': case 'student_grades': case 'parent_grades': return 'Qiymətlər';
      case 'cafeteria': case 'student_cafeteria': case 'parent_cafeteria': return 'Həftəlik Menyu';
      case 'inventory': case 'teacher_inventory': return 'Dəstək biletləri';
      case 'library': case 'teacher_library': case 'student_library': case 'parent_library': return 'Kitabxana';
      case 'student_id': case 'digital_id': return loc.digitalIdCard;
      case 'student_assignments': case 'parent_assignments': case 'assignments': case 'teacher_assignments': return 'Ev Tapşırıqları';
      case 'student_meet': case 'meet': case 'teacher_meet': return loc.meetIdrak;
      case 'parent_attendance': case 'student_attendance': case 'attendance': case 'teacher_attendance': return 'Davamiyyət';
      case 'parent_medical': case 'medical': case 'teacher_medical': return 'Tibbi Məlumatlar';
      case 'parent_invoices': return 'Müqavilə və Ödənişlər';
      case 'teacher_grading': case 'grading': return 'E-Jurnal & Qiymət';
      case 'teacher_notifications': return 'Bildirişlər';
      default: return title;
    }
  }

  String getLocalizedSubtitle(AppLocalizations loc) {
    return subtitle;
  }

  ModuleItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? icon,
    String? accentColor,
    String? routeName,
    bool? isVisible,
    int? orderIndex,
  }) {
    return ModuleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      routeName: routeName ?? this.routeName,
      isVisible: isVisible ?? this.isVisible,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  NavigationItem toNavigationItem({int orderIndex = 0, bool isPinned = true}) {
    String outlineIcon = icon.replaceAll('_rounded', '_outlined');
    if (!outlineIcon.endsWith('_outlined')) {
      outlineIcon = '${icon}_outlined';
    }
    return NavigationItem(
      id: id,
      label: title.length > 12 ? title.substring(0, 12) : title,
      icon: outlineIcon,
      activeIcon: icon,
      orderIndex: orderIndex,
      isPinned: isPinned,
      isVisible: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'icon': icon,
    'accentColor': accentColor,
    'routeName': routeName,
    'isVisible': isVisible,
    'orderIndex': orderIndex,
  };

  factory ModuleItem.fromJson(Map<String, dynamic> json) => ModuleItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    icon: json['icon'] ?? 'school_rounded',
    accentColor: json['accentColor'] ?? '#0EA5E9',
    routeName: json['routeName'] ?? '',
    isVisible: json['isVisible'] ?? true,
    orderIndex: json['orderIndex'] ?? 0,
  );
}

class NavigationItem {
  final String id;
  final String label;
  final String icon;
  final String activeIcon;
  final bool isVisible;
  final int orderIndex;
  final bool isPinned;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isVisible = true,
    this.orderIndex = 0,
    this.isPinned = false,
  });

  String getLocalizedLabel(AppLocalizations loc) {
    switch (id) {
      case 'dashboard': return loc.dashboard;
      case 'view_students': case 'students': case 'teacher_students': return 'Şagirdlər';
      case 'view_classes': return 'Siniflər';
      case 'view_timetable': case 'timetable': case 'teacher_timetable': case 'student_timetable': case 'parent_timetable': return 'Cədvəl';
      case 'view_users': case 'users': return 'Adminlər';
      case 'view_roles': return 'Rollar';
      case 'view_tickets': case 'tickets': return 'Biletlər';
      case 'view_reports': case 'analytics': return 'Statistika';
      case 'grades': case 'student_grades': case 'parent_grades': return 'Qiymətlər';
      case 'view_cafeteria': case 'cafeteria': case 'student_cafeteria': case 'parent_cafeteria': return 'Menyu';
      case 'view_settings': return 'Bildirişlər';
      case 'view_inventory': case 'inventory': case 'teacher_inventory': return 'İnventar';
      case 'view_library': case 'library': case 'teacher_library': case 'student_library': case 'parent_library': return 'Kitablar';
      case 'student_id': case 'digital_id': return loc.digitalId;
      case 'student_assignments': case 'parent_assignments': case 'assignments': case 'teacher_assignments': return 'Tapşırıqlar';
      case 'student_meet': case 'meet': case 'teacher_meet': return loc.meetIdrak;
      case 'parent_attendance': case 'student_attendance': case 'attendance': case 'teacher_attendance': return 'Davamiyyət';
      case 'parent_medical': case 'medical': case 'teacher_medical': return 'Tibb';
      case 'excused_absences': return 'Üzürlü qayıb';
      case 'clubs': return 'Dərnəklər';
      case 'parent_invoices': case 'student_invoices': return 'Müqavilələr';
      case 'teacher_grading': case 'grading': return 'Qiymətlər';
      default: return label;
    }
  }

  NavigationItem copyWith({
    String? id,
    String? label,
    String? icon,
    String? activeIcon,
    bool? isVisible,
    int? orderIndex,
    bool? isPinned,
  }) {
    return NavigationItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      activeIcon: activeIcon ?? this.activeIcon,
      isVisible: isVisible ?? this.isVisible,
      orderIndex: orderIndex ?? this.orderIndex,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'icon': icon,
    'activeIcon': activeIcon,
    'isVisible': isVisible,
    'orderIndex': orderIndex,
    'isPinned': isPinned,
  };

  factory NavigationItem.fromJson(Map<String, dynamic> json) => NavigationItem(
    id: json['id'] ?? '',
    label: json['label'] ?? '',
    icon: json['icon'] ?? 'dashboard_outlined',
    activeIcon: json['activeIcon'] ?? 'dashboard_rounded',
    isVisible: json['isVisible'] ?? true,
    orderIndex: json['orderIndex'] ?? 0,
    isPinned: json['isPinned'] ?? false,
  );
}

class UserPreferences {
  final String userId;
  final String userRole;
  final List<ModuleItem> dashboardModules;
  final List<NavigationItem> navigationItems;
  final DateTime lastModified;

  const UserPreferences({
    required this.userId,
    required this.userRole,
    this.dashboardModules = const [],
    this.navigationItems = const [],
    required this.lastModified,
  });

  UserPreferences copyWith({
    String? userId,
    String? userRole,
    List<ModuleItem>? dashboardModules,
    List<NavigationItem>? navigationItems,
    DateTime? lastModified,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      dashboardModules: dashboardModules ?? this.dashboardModules,
      navigationItems: navigationItems ?? this.navigationItems,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userRole': userRole,
    'dashboardModules': dashboardModules.map((m) => m.toJson()).toList(),
    'navigationItems': navigationItems.map((n) => n.toJson()).toList(),
    'lastModified': lastModified.toIso8601String(),
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
    userId: json['userId'] ?? '',
    userRole: json['userRole'] ?? 'admin',
    dashboardModules: (json['dashboardModules'] as List<dynamic>?)
        ?.map((m) => ModuleItem.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    navigationItems: (json['navigationItems'] as List<dynamic>?)
        ?.map((n) => NavigationItem.fromJson(n as Map<String, dynamic>))
        .toList() ?? [],
    lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toIso8601String()),
  );

  UserPreferences withMergedDefaultModules() {
    final defaults = _getDefaultModulesForRole(userRole);
    final defaultsById = {for (final d in defaults) d.id: d};
    final allowedIds = defaultsById.keys.toSet();
    final cleanedExisting = dashboardModules
        .where((m) => allowedIds.contains(m.id))
        .map((m) {
          final def = defaultsById[m.id]!;
          return m.copyWith(title: def.title, subtitle: def.subtitle);
        })
        .toList();
    final existingIds = cleanedExisting.map((m) => m.id).toSet();
    final missing = defaults.where((m) => !existingIds.contains(m.id)).toList();
    final cleanedNav = navigationItems
        .where((n) => n.id != 'view_users' && (n.id == 'dashboard' || allowedIds.contains(n.id)))
        .toList();
    return copyWith(
      dashboardModules: [...cleanedExisting, ...missing],
      navigationItems: cleanedNav,
      lastModified: DateTime.now(),
    );
  }

  static UserPreferences createDefault({
    required String userId,
    required String userRole,
  }) {
    return UserPreferences(
      userId: userId,
      userRole: userRole,
      dashboardModules: _getDefaultModulesForRole(userRole),
      navigationItems: _getDefaultNavigationForRole(userRole),
      lastModified: DateTime.now(),
    );
  }

  static List<ModuleItem> _getDefaultModulesForRole(String role) {
    switch (role) {
      case 'admin':
        // Əsas 8 Dashboard Modulu (Qalan bütün 23 modul Side Bar Drawer-dədir)
        return [
          const ModuleItem(id: 'student_360', title: 'Şagird və Valideyn', subtitle: 'Vahid şagird mərkəzi', icon: 'person_search_rounded', accentColor: '#0284C7', routeName: 'StudentManagementScreen', orderIndex: 0),
          const ModuleItem(id: 'parents', title: 'Valideynlər', subtitle: 'Şagird və Valideyn • Valideynlər', icon: 'people_alt_rounded', accentColor: '#6366F1', routeName: 'ParentsManagementScreen', orderIndex: 1),
          const ModuleItem(id: 'view_classes', title: 'Siniflər', subtitle: 'E-məktəb • Siniflər', icon: 'class_rounded', accentColor: '#0284C7', routeName: 'ClassManagementScreen', orderIndex: 2),
          const ModuleItem(id: 'view_journal', title: 'Jurnal', subtitle: 'E-məktəb • Elektron jurnal', icon: 'fact_check_rounded', accentColor: '#2563EB', routeName: 'ApiJournalScreen', orderIndex: 3),
          const ModuleItem(id: 'view_timetable', title: 'Cədvəl', subtitle: 'E-məktəb • Dərs cədvəli', icon: 'calendar_month_rounded', accentColor: '#7C3AED', routeName: 'AdminTimetableManagementScreen', orderIndex: 4),
          const ModuleItem(id: 'view_employees', title: 'Əməkdaşlar', subtitle: 'İnsan resursları • Heyət', icon: 'badge_rounded', accentColor: '#2563EB', routeName: 'EmployeesScreen', orderIndex: 5),
          const ModuleItem(id: 'payroll', title: 'Əmək haqqı', subtitle: 'Maliyyə • Əmək haqqı', icon: 'payments_rounded', accentColor: '#16A34A', routeName: 'PayrollScreen', orderIndex: 6),
          const ModuleItem(id: 'view_roles', title: 'Rollar və icazələr', subtitle: 'Tənzimləmələr • Rollar', icon: 'admin_panel_settings_rounded', accentColor: '#6366F1', routeName: 'RoleManagementScreen', orderIndex: 7),
        ];
      case 'teacher':
        // Əsas 8 Dashboard Modulu (İdrak Meet & Digital ID yalnız Müəllim və Şagirdə məxsusdur)
        return [
          const ModuleItem(id: 'teacher_journal', title: 'Jurnal', subtitle: 'E-jurnal • Dərs qeydi', icon: 'fact_check_rounded', accentColor: '#2563EB', routeName: 'ApiJournalScreen', orderIndex: 0),
          const ModuleItem(id: 'teacher_timetable', title: 'Dərs Cədvəli', subtitle: 'Həftəlik cədvəl', icon: 'calendar_month_rounded', accentColor: '#0284C7', routeName: 'TeacherTimetableViewScreen', orderIndex: 1),
          const ModuleItem(id: 'teacher_students', title: 'Şagirdlər', subtitle: 'Sinif şagirdləri', icon: 'school_rounded', accentColor: '#0EA5E9', routeName: 'TeacherStudentsScreen', orderIndex: 2),
          const ModuleItem(id: 'teacher_grading', title: 'Qiymətləndirmə', subtitle: 'Sürətli qiymətləndirmə', icon: 'grading_rounded', accentColor: '#10B981', routeName: 'QuickGradingScreen', orderIndex: 3),
          const ModuleItem(id: 'teacher_submissions', title: 'Tapşırıqlar', subtitle: 'Təhvil yoxlanışı', icon: 'assignment_turned_in_rounded', accentColor: '#7C3AED', routeName: 'ReviewSubmissionsScreen', orderIndex: 4),
          const ModuleItem(id: 'teacher_id_card', title: 'Digital ID Card', subtitle: 'Rəqəmsal kimlik passı', icon: 'badge_rounded', accentColor: '#059669', routeName: 'TeacherIdCardScreen', orderIndex: 5),
          const ModuleItem(id: 'teacher_meet', title: 'Meet İdrak', subtitle: 'Video dərslər və otaqlar', icon: 'video_camera_front_rounded', accentColor: '#0D9488', routeName: 'MeetIdrakScreen', orderIndex: 6),
          const ModuleItem(id: 'clubs', title: 'Dərnəklər', subtitle: 'Məktəb dərnəkləri', icon: 'sports_soccer_rounded', accentColor: '#F97316', routeName: 'ClubsScreen', orderIndex: 7),
        ];
case 'student':
        // Web student_sidebar.php ilə 1:1 (+ Mobil xüsusi Digital ID & Meet İdrak)
        return [
          const ModuleItem(id: 'student_timetable', title: 'Dərs Cədvəli', subtitle: 'Həftəlik dərslər', icon: 'calendar_month_rounded', accentColor: '#0284C7', routeName: 'TimetableMatrixScreen', orderIndex: 0),
          const ModuleItem(id: 'student_grades', title: 'Qiymətlər', subtitle: 'Akademik dinamika', icon: 'insights_rounded', accentColor: '#10B981', routeName: 'GradesAnalyticsScreen', orderIndex: 1),
          const ModuleItem(id: 'student_attendance', title: 'Davamiyyət', subtitle: 'Dərslərə davamiyyət', icon: 'event_available_rounded', accentColor: '#059669', routeName: 'AttendanceCalendarScreen', orderIndex: 2),
          const ModuleItem(id: 'student_assignments', title: 'Ev Tapşırıqları', subtitle: 'Gündəlik tapşırıqlar', icon: 'assignment_rounded', accentColor: '#7C3AED', routeName: 'AssignmentsTimelineScreen', orderIndex: 3),
          const ModuleItem(id: 'student_notes', title: 'Akademik Qeydlər', subtitle: 'Müəllim və dərs şərhləri', icon: 'sticky_note_2_rounded', accentColor: '#6366F1', routeName: 'AcademicNotesScreen', orderIndex: 4),
          const ModuleItem(id: 'student_clubs', title: 'Dərnəklər', subtitle: 'Məktəb dərnəkləri', icon: 'sports_soccer_rounded', accentColor: '#F97316', routeName: 'ClubsScreen', orderIndex: 5),
          const ModuleItem(id: 'student_library', title: 'Kitabxana', subtitle: 'Dərslik və ədəbiyyat', icon: 'local_library_rounded', accentColor: '#9333EA', routeName: 'LibraryScreen', orderIndex: 6),
          const ModuleItem(id: 'student_cafeteria', title: 'Həftəlik Menyu', subtitle: 'Yeməkxana menyusu', icon: 'restaurant_menu_rounded', accentColor: '#D97706', routeName: 'CafeteriaMenuScreen', orderIndex: 7),
          const ModuleItem(id: 'student_id', title: 'Digital ID', subtitle: 'Turniket & Kimlik Passı', icon: 'badge_rounded', accentColor: '#0EA5E9', routeName: 'DigitalIdCardScreen', orderIndex: 8),
          const ModuleItem(id: 'student_meet', title: 'Meet İdrak', subtitle: 'Səsli & Video otaqlar', icon: 'video_camera_front_rounded', accentColor: '#0D9488', routeName: 'MeetIdrakScreen', orderIndex: 9),
        ];
      case 'parent':
        // Web parent_sidebar.php ilə 1:1
        return [
          const ModuleItem(id: 'parent_timetable', title: 'Dərs Cədvəli', subtitle: 'Həftəlik dərslər', icon: 'grid_view_rounded', accentColor: '#0284C7', routeName: 'TimetableMatrixScreen', orderIndex: 0),
          const ModuleItem(id: 'parent_grades', title: 'Qiymətlər', subtitle: 'KSQ / BSQ dinamika', icon: 'insights_rounded', accentColor: '#0EA5E9', routeName: 'GradesAnalyticsScreen', orderIndex: 1),
          const ModuleItem(id: 'parent_attendance', title: 'Davamiyyət', subtitle: 'Rəqəmsal təqvim', icon: 'calendar_month_rounded', accentColor: '#10B981', routeName: 'AttendanceCalendarScreen', orderIndex: 2),
          const ModuleItem(id: 'parent_assignments', title: 'Ev Tapşırıqları', subtitle: 'Gündəlik tapşırıqlar', icon: 'assignment_rounded', accentColor: '#7C3AED', routeName: 'AssignmentsTimelineScreen', orderIndex: 3),
          const ModuleItem(id: 'parent_notes', title: 'Akademik Qeydlər', subtitle: 'Müəllim və dərs şərhləri', icon: 'sticky_note_2_rounded', accentColor: '#6366F1', routeName: 'AcademicNotesScreen', orderIndex: 4),
          const ModuleItem(id: 'parent_clubs', title: 'Dərnəklər', subtitle: 'Dərsdənkənar dərnəklər', icon: 'sports_soccer_rounded', accentColor: '#F97316', routeName: 'ClubsScreen', orderIndex: 5),
          const ModuleItem(id: 'parent_medical', title: 'Tibbi Məlumatlar', subtitle: 'Peyvənd & Sağlamlıq', icon: 'favorite_rounded', accentColor: '#EF4444', routeName: 'MedicalCardScreen', orderIndex: 6),
          const ModuleItem(id: 'parent_cafeteria', title: 'Həftəlik Menyu', subtitle: 'Gündəlik qidalanma', icon: 'restaurant_menu_rounded', accentColor: '#D97706', routeName: 'CafeteriaMenuScreen', orderIndex: 7),
          const ModuleItem(id: 'parent_library', title: 'Kitabxana', subtitle: 'Dərslik və kitablar', icon: 'local_library_rounded', accentColor: '#9333EA', routeName: 'LibraryScreen', orderIndex: 8),
          const ModuleItem(id: 'parent_invoices', title: 'Müqavilə və Ödənişlər', subtitle: 'Təhsil haqqı & Ödəniş', icon: 'receipt_long_rounded', accentColor: '#0D9488', routeName: 'StudentInvoicesScreen', orderIndex: 9),
        ];
      default:
        return [];
    }
  }

  static List<NavigationItem> _getDefaultNavigationForRole(String role) {
    switch (role) {
      case 'admin':
        return [
          const NavigationItem(id: 'dashboard', label: 'İnzibatçı', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'view_tickets', label: 'Biletlər', icon: 'support_agent_outlined', activeIcon: 'support_agent_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'view_reports', label: 'Statistika', icon: 'analytics_outlined', activeIcon: 'analytics_rounded', orderIndex: 2, isPinned: false),
        ];
      case 'teacher':
        return [
          const NavigationItem(id: 'dashboard', label: 'Müəllim', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'teacher_students', label: 'Şagirdlər', icon: 'groups_outlined', activeIcon: 'groups_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'teacher_timetable', label: 'Cədvəl', icon: 'calendar_month_outlined', activeIcon: 'calendar_month_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'teacher_grading', label: 'Qiymətlər', icon: 'edit_note_outlined', activeIcon: 'edit_note_rounded', orderIndex: 3, isPinned: true),
          const NavigationItem(id: 'teacher_inventory', label: 'Biletlər', icon: 'qr_code_scanner_outlined', activeIcon: 'qr_code_scanner_rounded', orderIndex: 4, isPinned: false),
        ];
      case 'student':
        return [
          const NavigationItem(id: 'dashboard', label: 'Şagird', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'student_timetable', label: 'Cədvəl', icon: 'calendar_month_outlined', activeIcon: 'calendar_month_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'student_assignments', label: 'Tapşırıqlar', icon: 'assignment_outlined', activeIcon: 'assignment_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'student_grades', label: 'Qiymətlər', icon: 'insights_outlined', activeIcon: 'insights_rounded', orderIndex: 3, isPinned: true),
          const NavigationItem(id: 'student_id', label: 'Digital ID', icon: 'badge_outlined', activeIcon: 'badge_rounded', orderIndex: 4, isPinned: false),
        ];
      case 'parent':
        return [
          const NavigationItem(id: 'dashboard', label: 'Panel', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'parent_timetable', label: 'Cədvəl', icon: 'grid_view_outlined', activeIcon: 'grid_view_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'parent_grades', label: 'Qiymətlər', icon: 'insights_outlined', activeIcon: 'insights_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'parent_attendance', label: 'Davamiyyət', icon: 'calendar_month_outlined', activeIcon: 'calendar_month_rounded', orderIndex: 3, isPinned: true),
          const NavigationItem(id: 'parent_assignments', label: 'Tapşırıqlar', icon: 'assignment_outlined', activeIcon: 'assignment_rounded', orderIndex: 4, isPinned: false),
        ];
      default:
        return [];
    }
  }
}
