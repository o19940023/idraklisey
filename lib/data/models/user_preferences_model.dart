// Kullanıcı Tercihleri Modeli
// Modül sıralama ve navigation bar özelleştirmesi için

class ModuleItem {
  final String id;            // Benzersiz modül ID (view_students, view_classes vb.)
  final String title;         // Modül başlığı
  final String subtitle;      // Alt açıklama
  final String icon;          // Icon kodu (Icons enum değeri string olarak)
  final String accentColor;   // Hex renk kodu
  final String routeName;     // Navigation route adı
  final bool isVisible;       // Modül görünür mü?
  final int orderIndex;       // Sıralama index'i (0'dan başlar)

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
  final String id;            // Benzersiz nav ID (dashboard, users, tickets vb.)
  final String label;         // Tab etiketi
  final String icon;          // Icon kodu
  final String activeIcon;    // Aktif icon kodu
  final bool isVisible;       // Nav item görünür mü?
  final int orderIndex;       // Sıralama index'i
  final bool isPinned;        // Hızlı erişime sabitlenmiş mi?

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isVisible = true,
    this.orderIndex = 0,
    this.isPinned = false,
  });

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
  final String userId;                        // Kullanıcı ID
  final String userRole;                      // admin, teacher, student, parent
  final List<ModuleItem> dashboardModules;    // Dashboard modül sıralaması
  final List<NavigationItem> navigationItems; // Navigation bar sıralaması
  final DateTime lastModified;                // Son değişiklik tarihi

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

  /// Saxlanılmış preferenslərə sonradan kodda əlavə olunan yeni modulları əlavə edir
  /// (köhnə istifadəçilər reset etmədən yeni modulları görsün)
  UserPreferences withMergedDefaultModules() {
    final defaults = _getDefaultModulesForRole(userRole);
    final existingIds = dashboardModules.map((m) => m.id).toSet();
    final missing = defaults.where((m) => !existingIds.contains(m.id)).toList();
    if (missing.isEmpty) return this;
    return copyWith(
      dashboardModules: [...dashboardModules, ...missing],
      lastModified: DateTime.now(),
    );
  }

  /// Varsayılan sıralamayı oluştur
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

  /// Role göre varsayılan modüller
  static List<ModuleItem> _getDefaultModulesForRole(String role) {
    switch (role) {
      case 'admin':
        return [
          const ModuleItem(id: 'view_students', title: 'Şagird İdarəsi', subtitle: 'Şagird idarəsi', icon: 'school_rounded', accentColor: '#0EA5E9', routeName: 'StudentManagementScreen', orderIndex: 0),
          const ModuleItem(id: 'view_classes', title: 'Sinif İdarəsi', subtitle: 'Sinif yüksəlişi', icon: 'class_rounded', accentColor: '#0284C7', routeName: 'ClassManagementScreen', orderIndex: 1),
          const ModuleItem(id: 'view_timetable', title: 'Dərs Cədvəli', subtitle: 'Cədvəl təyini', icon: 'calendar_month_rounded', accentColor: '#7C3AED', routeName: 'AdminTimetableManagementScreen', orderIndex: 2),
          const ModuleItem(id: 'view_users', title: 'İstifadəçilər', subtitle: 'İşçi hesabı', icon: 'manage_accounts_rounded', accentColor: '#0D9488', routeName: 'AdminUsersScreen', orderIndex: 3),
          const ModuleItem(id: 'view_roles', title: 'Rol İdarəetməsi', subtitle: 'Səlahiyyət təyini', icon: 'admin_panel_settings_rounded', accentColor: '#D97706', routeName: 'RoleManagementScreen', orderIndex: 4),
          const ModuleItem(id: 'view_tickets', title: 'Helpdesk', subtitle: 'Müraciət', icon: 'support_agent_rounded', accentColor: '#9333EA', routeName: 'ParentTicketsScreen', orderIndex: 5),
          const ModuleItem(id: 'view_reports', title: 'Statistika', subtitle: 'KSQ / BSQ / IB', icon: 'analytics_rounded', accentColor: '#0EA5E9', routeName: 'GradesAnalyticsScreen', orderIndex: 6),
          const ModuleItem(id: 'view_cafeteria', title: 'Yeməkxana', subtitle: 'Menyu təyini', icon: 'restaurant_menu_rounded', accentColor: '#D97706', routeName: 'CafeteriaMenuScreen', orderIndex: 7),
          const ModuleItem(id: 'view_settings', title: 'Toplu Elan', subtitle: 'Rəsmi bildirişlər', icon: 'campaign_rounded', accentColor: '#EF4444', routeName: 'NotificationsScreen', orderIndex: 8),
          const ModuleItem(id: 'view_inventory', title: 'QR İnventar', subtitle: 'Texniki xidmət', icon: 'qr_code_rounded', accentColor: '#0D9488', routeName: 'QrInventoryManagementScreen', orderIndex: 9),
          const ModuleItem(id: 'view_library', title: 'E-Kitabxana', subtitle: 'Kitab kolleksiyası', icon: 'local_library_rounded', accentColor: '#7C3AED', routeName: 'LibraryScreen', orderIndex: 10),
        ];
      case 'teacher':
        return [
          const ModuleItem(id: 'teacher_timetable', title: 'Dərs Cədvəlim', subtitle: 'Baxış rejimi', icon: 'calendar_month_rounded', accentColor: '#7C3AED', routeName: 'TeacherTimetableViewScreen', orderIndex: 0),
          const ModuleItem(id: 'teacher_meet', title: 'Meet İdrak', subtitle: 'Canlı səsli dərs', icon: 'mic_external_on_rounded', accentColor: '#0D9488', routeName: 'MeetIdrakScreen', orderIndex: 1),
          const ModuleItem(id: 'teacher_students', title: 'Şagirdlər Kataloqu', subtitle: 'Şagird siyahısı', icon: 'groups_rounded', accentColor: '#0EA5E9', routeName: 'TeacherStudentsScreen', orderIndex: 2),
          const ModuleItem(id: 'teacher_assignments', title: 'Tapşırıq Yoxlanışı', subtitle: 'Ev tapşırıqları', icon: 'assignment_turned_in_rounded', accentColor: '#0D9488', routeName: 'ReviewSubmissionsScreen', orderIndex: 3),
          const ModuleItem(id: 'teacher_grading', title: 'Sürətli Qiymət', subtitle: 'Voice-to-Text rəy', icon: 'mic_rounded', accentColor: '#9333EA', routeName: 'QuickGradingScreen', orderIndex: 4),
          const ModuleItem(id: 'teacher_library', title: 'E-Kitabxana', subtitle: 'Kitab axtarışı', icon: 'local_library_rounded', accentColor: '#D97706', routeName: 'LibraryScreen', orderIndex: 5),
          const ModuleItem(id: 'teacher_notifications', title: 'Bildiriş Göndər', subtitle: 'Sinif & Valideyn', icon: 'notifications_active_rounded', accentColor: '#E11D48', routeName: 'NotificationsScreen', orderIndex: 6),
          const ModuleItem(id: 'teacher_inventory', title: 'Avadanlıq Ticket', subtitle: 'QR inventar şikayəti', icon: 'qr_code_scanner_rounded', accentColor: '#EF4444', routeName: 'QrInventoryTicketScreen', orderIndex: 7),
        ];
      case 'student':
        return [
          const ModuleItem(id: 'student_timetable', title: 'Dərs Cədvəli', subtitle: 'Həftəlik dərslər', icon: 'calendar_month_rounded', accentColor: '#0284C7', routeName: 'TimetableMatrixScreen', orderIndex: 0),
          const ModuleItem(id: 'student_assignments', title: 'Tapşırıqlar', subtitle: 'Gündəlik tapşırıqlar', icon: 'assignment_rounded', accentColor: '#7C3AED', routeName: 'AssignmentsTimelineScreen', orderIndex: 1),
          const ModuleItem(id: 'student_meet', title: 'Meet İdrak', subtitle: 'Səsli & Video otaqlar', icon: 'video_camera_front_rounded', accentColor: '#0D9488', routeName: 'MeetIdrakScreen', orderIndex: 2),
          const ModuleItem(id: 'student_library', title: 'E-Kitabxana', subtitle: 'Dərslik və ədəbiyyat', icon: 'local_library_rounded', accentColor: '#9333EA', routeName: 'LibraryScreen', orderIndex: 3),
          const ModuleItem(id: 'student_cafeteria', title: 'Yeməkxana Menyu', subtitle: 'Həftəlik rasion', icon: 'restaurant_menu_rounded', accentColor: '#D97706', routeName: 'CafeteriaMenuScreen', orderIndex: 4),
          const ModuleItem(id: 'student_id', title: 'Digital ID', subtitle: 'Turniket & Kimlik Passı', icon: 'badge_rounded', accentColor: '#0EA5E9', routeName: 'DigitalIdCardScreen', orderIndex: 5),
          const ModuleItem(id: 'student_grades', title: 'Qiymətlərim', subtitle: 'Akademik dinamika', icon: 'insights_rounded', accentColor: '#10B981', routeName: 'GradesAnalyticsScreen', orderIndex: 6),
        ];
      case 'parent':
        return [
          const ModuleItem(id: 'parent_timetable', title: 'Həftəlik Matris', subtitle: 'Gündəlik dərslər', icon: 'grid_view_rounded', accentColor: '#0284C7', routeName: 'TimetableMatrixScreen', orderIndex: 0),
          const ModuleItem(id: 'parent_grades', title: 'Qiymət Qrafiki', subtitle: 'KSQ / BSQ dinamika', icon: 'insights_rounded', accentColor: '#0EA5E9', routeName: 'GradesAnalyticsScreen', orderIndex: 1),
          const ModuleItem(id: 'parent_attendance', title: 'Davamiyyət', subtitle: 'Rəqəmsal təqvim', icon: 'calendar_month_rounded', accentColor: '#10B981', routeName: 'AttendanceCalendarScreen', orderIndex: 2),
          const ModuleItem(id: 'parent_medical', title: 'Tibbi Kart', subtitle: 'Peyvənd & Sağlamlıq', icon: 'favorite_rounded', accentColor: '#EF4444', routeName: 'MedicalCardScreen', orderIndex: 3),
          const ModuleItem(id: 'parent_tickets', title: 'Müraciət & Əlaqə', subtitle: 'Rəhbərliklə əlaqə', icon: 'support_agent_rounded', accentColor: '#9333EA', routeName: 'ParentTicketsScreen', orderIndex: 4),
          const ModuleItem(id: 'parent_cafeteria', title: 'Yeməkxana Menyusu', subtitle: 'Gündəlik qidalanma', icon: 'restaurant_menu_rounded', accentColor: '#D97706', routeName: 'CafeteriaMenuScreen', orderIndex: 5),
        ];
      default:
        return [];
    }
  }

  /// Role göre varsayılan navigation
  static List<NavigationItem> _getDefaultNavigationForRole(String role) {
    switch (role) {
      case 'admin':
        return [
          const NavigationItem(id: 'dashboard', label: 'İnzibatçı', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'view_users', label: 'Hesablar', icon: 'manage_accounts_outlined', activeIcon: 'manage_accounts_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'view_tickets', label: 'Müraciətlər', icon: 'support_agent_outlined', activeIcon: 'support_agent_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'view_reports', label: 'Analitika', icon: 'analytics_outlined', activeIcon: 'analytics_rounded', orderIndex: 3, isPinned: false),
        ];
      case 'teacher':
        return [
          const NavigationItem(id: 'dashboard', label: 'Müəllim', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'teacher_students', label: 'Şagirdlər', icon: 'groups_outlined', activeIcon: 'groups_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'teacher_timetable', label: 'Davamiyyət', icon: 'calendar_month_outlined', activeIcon: 'calendar_month_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'teacher_grading', label: 'Qiymətlər', icon: 'edit_note_outlined', activeIcon: 'edit_note_rounded', orderIndex: 3, isPinned: true),
          const NavigationItem(id: 'teacher_inventory', label: 'İnventar', icon: 'qr_code_scanner_outlined', activeIcon: 'qr_code_scanner_rounded', orderIndex: 4, isPinned: false),
        ];
      case 'student':
        return [
          const NavigationItem(id: 'dashboard', label: 'Şagird', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'student_id', label: 'Digital ID', icon: 'badge_outlined', activeIcon: 'badge_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'student_assignments', label: 'Tapşırıqlar', icon: 'assignment_outlined', activeIcon: 'assignment_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'student_meet', label: 'Meet İdrak', icon: 'video_camera_front_outlined', activeIcon: 'video_camera_front_rounded', orderIndex: 3, isPinned: false),
          const NavigationItem(id: 'student_library', label: 'Kitabxana', icon: 'local_library_outlined', activeIcon: 'local_library_rounded', orderIndex: 4, isPinned: false),
        ];
      case 'parent':
        return [
          const NavigationItem(id: 'dashboard', label: 'Panel', icon: 'dashboard_outlined', activeIcon: 'dashboard_rounded', orderIndex: 0, isPinned: true),
          const NavigationItem(id: 'parent_timetable', label: 'Gündəlik', icon: 'grid_view_outlined', activeIcon: 'grid_view_rounded', orderIndex: 1, isPinned: true),
          const NavigationItem(id: 'parent_grades', label: 'Qiymətlər', icon: 'insights_outlined', activeIcon: 'insights_rounded', orderIndex: 2, isPinned: true),
          const NavigationItem(id: 'parent_attendance', label: 'Davamiyyət', icon: 'calendar_month_outlined', activeIcon: 'calendar_month_rounded', orderIndex: 3, isPinned: true),
          const NavigationItem(id: 'parent_medical', label: 'Tibbi Kart', icon: 'favorite_outline_rounded', activeIcon: 'favorite_rounded', orderIndex: 4, isPinned: false),
        ];
      default:
        return [];
    }
  }
}

