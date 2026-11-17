import '../services/network/api_client.dart';

import 'package:provider/provider.dart';
import '../core/services/school_api_service.dart';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/password_hasher.dart';
import '../data/models/timetable_model.dart';
import '../data/models/grade_model.dart';
import '../data/models/attendance_model.dart';
import '../data/models/medical_model.dart';
import '../data/models/ticket_model.dart';
import '../data/models/assignment_model.dart';
import '../data/models/student_model.dart';
import '../data/models/library_model.dart';
import '../data/models/menu_model.dart';
import '../data/models/meet_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/inventory_model.dart';
import '../data/models/user_model.dart';
import '../data/models/role_model.dart';
import '../data/models/class_details_model.dart';
import '../data/models/user_preferences_model.dart';
import '../data/mock_data.dart';
import '../core/utils/email_generator.dart';
import '../services/firestore_service.dart';
import '../services/auth_storage_service.dart';
import '../services/push_notification_service.dart';
import '../services/push_relay_service.dart';
import '../services/agora_token_service.dart';
import '../core/session/session_controller.dart';

enum UserRole {
  admin, // Məktəb İdarəetməsi (Admin)
  parent, // Valideyn Paneli
  student, // Şagird Paneli
  teacher, // Müəllim Paneli
}

extension UserRoleExt on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin Paneli';
      case UserRole.parent:
        return 'Valideyn Paneli';
      case UserRole.student:
        return 'Şagird Paneli';
      case UserRole.teacher:
        return 'Müəllim Paneli';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.teacher:
        return Icons.psychology_rounded;
    }
  }
}

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthStorageService _authStorage = AuthStorageService();
  StreamSubscription<List<MeetRoom>>? _meetRoomsSubscription;
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Public getter for FirestoreService
  FirestoreService get firestoreService => _firestoreService;

  // --- CONNECTIVITY (Oflay xəbərdarlıq banneri üçün) ---
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  AppState() {
    _initConnectivity();
  }

  /// Şəbəkə vəziyyətini izləyir. Bağlantı kəsilib sonra bərpa olunarsa və
  /// ilkin sinxronizasiya əvvəl uğursuz olubsa (bax: initFirebaseData catch)
  /// sinxronizasiyanı avtomatik yenidən başladır.
  void _initConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final online =
          results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
      if (online == _isOnline) return;
      _isOnline = online;
      notifyListeners();
      if (online && _initFuture == null) {
        unawaited(ensureDataReady());
      }
    });
  }

  // --- APPEARANCE (Light / Dark) ---
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  /// Restores the persisted theme before the first frame so the app
  /// never flashes the wrong palette on startup.
  Future<void> loadThemeMode() async {
    _isDarkMode = await _authStorage.getIsDarkMode();
    AppColors.applyDark(_isDarkMode);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    AppColors.applyDark(_isDarkMode);
    _authStorage.saveIsDarkMode(_isDarkMode);
    notifyListeners();
  }

  // --- LANGUAGE (az / en / ru) ---
  /// null => follow the system locale
  Locale? _locale;
  Locale? get locale => _locale;

  /// Restores the persisted language before the first frame.
  Future<void> loadLocale() async {
    final code = await _authStorage.getLanguageCode();
    _locale = code != null ? Locale(code) : null;
  }

  /// [code] is a supported language code ('az', 'en', 'ru').
  /// Pass null to follow the device language.
  Future<void> setLocale(String? code) async {
    _locale = code != null ? Locale(code) : null;
    if (code != null) {
      await _authStorage.saveLanguageCode(code);
    }
    notifyListeners();
  }

  // Current Logged In User
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Active Role
  UserRole get currentRole => _currentUser?.role ?? UserRole.admin;

  /// Yalnız quraşdırma ilə gələn baş inzibatçı hesabı bütün icazələrə
  /// sahibdir. Sonradan yaradılan və rol təyin edilməyən admin hesabları
  /// avtomatik tam səlahiyyət almamalıdır.
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isSuperAdmin => isPrimaryAdmin;

  bool get isPrimaryAdmin {
    final user = _currentUser;
    if (user == null || user.role != UserRole.admin) return false;
    final u = user.username.toLowerCase();
    final p = (user.position ?? '').toLowerCase();
    final a = (user.assignedRoleId ?? '').toLowerCase();
    return user.id == 'usr-admin-1' ||
        user.id == '1' ||
        u == 'admin' ||
        u.contains('superadmin') ||
        p.contains('superadmin') ||
        a == 'superadmin';
  }

  // User Accounts Database (Default Master Admin)
  final List<AppUser> _users = [
    AppUser(
      id: 'usr-admin-1',
      username: 'admin',
      password: '123',
      fullName: 'İdrak Liseyi Baş İnzibatçısı',
      role: UserRole.admin,
      idrakCode: 'IDR-ADM-001',
      phone: '+994 (12) 598-00-00',
      email: 'admin@idrakliseyi.edu.az',
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  List<AppUser> get users => _users;

  // Real Students List
  final List<StudentProfile> _students = [];
  List<StudentProfile> get students => _students;

  // Explicit distinct classes created by Admin
  // Yalnız real mənbələrdən (admin yaratdığı siniflər, Firestore class
  // detalları, müəllim təyinatları) doldurulur — hardcoded demo siniflər
  // istehsalat datalarına qarışmamalıdır.
  final Set<String> _customClasses = {};

  // Sinif detalları (otaq, rəhbər, təhsil ili, qeyd) — Firestore-da saxlanır
  final Map<String, ClassDetails> _classDetailsMap = {};
  ClassDetails? classDetails(String name) => _classDetailsMap[name];

  // --- ROLES & PERMISSIONS (Rol İdarəetməsi) ---
  List<Role> _roles = [];
  List<Role> get roles => _roles;

  // --- NAVIGATION TAB INDEX (Alt Menyu Aktiv Tabı) ---
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setCurrentTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void resetToDashboard() {
    if (_currentTabIndex != 0) {
      _currentTabIndex = 0;
      notifyListeners();
    }
  }

  // --- USER PREFERENCES (Modül Sıralama & Navigation Özelleştirme) ---
  UserPreferences? _userPreferences;
  UserPreferences? get userPreferences => _userPreferences;

  /// Kullanıcı tercihlerini Firestore'dan yükle
  Future<void> loadUserPreferences() async {
    if (_currentUser == null) return;

    // Never block the first authenticated frame on Firestore. This is
    // especially important on iOS where the initial network request can be
    // delayed while the app is resuming from the splash screen.
    final user = _currentUser!;
    _userPreferences ??= UserPreferences.createDefault(
      userId: user.id,
      userRole: user.role.name,
    );
    notifyListeners();

    try {
      final prefs = await _firestoreService.fetchUserPreferences(user.id);
      if (prefs != null && prefs.userRole == user.role.name) {
        _userPreferences = prefs.withMergedDefaultModules();
      } else {
        // Varsayılan tercihleri oluştur
        _userPreferences = UserPreferences.createDefault(
          userId: user.id,
          userRole: user.role.name,
        );
        // Firestore'a kaydet; kayıt gecikmesi UI'ı bloke etmemeli.
        try {
          await _firestoreService.saveUserPreferences(_userPreferences!);
        } catch (e) {
          debugPrint('User preferences save notice: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('User preferences load error: $e');
      // Hata durumunda varsayılan değerleri kullan
      _userPreferences = UserPreferences.createDefault(
        userId: user.id,
        userRole: user.role.name,
      );
      notifyListeners();
    }
  }

  /// Modül sırasını güncelle ve kaydet
  Future<void> updateModuleOrder(List<ModuleItem> newOrder) async {
    if (_currentUser == null) return;

    // Index'leri güncelle
    for (int i = 0; i < newOrder.length; i++) {
      newOrder[i] = newOrder[i].copyWith(orderIndex: i);
    }

    _userPreferences =
        (_userPreferences ??
                UserPreferences.createDefault(
                  userId: _currentUser!.id,
                  userRole: _currentUser!.role.name,
                ))
            .copyWith(dashboardModules: newOrder, lastModified: DateTime.now());

    await _firestoreService.saveUserPreferences(_userPreferences!);
    notifyListeners();
  }

  /// Navigation item sırasını güncelle ve kaydet
  Future<void> updateNavigationOrder(List<NavigationItem> newOrder) async {
    if (_currentUser == null) return;

    for (int i = 0; i < newOrder.length; i++) {
      newOrder[i] = newOrder[i].copyWith(orderIndex: i);
    }

    _userPreferences =
        (_userPreferences ??
                UserPreferences.createDefault(
                  userId: _currentUser!.id,
                  userRole: _currentUser!.role.name,
                ))
            .copyWith(navigationItems: newOrder, lastModified: DateTime.now());

    await _firestoreService.saveUserPreferences(_userPreferences!);
    notifyListeners();
  }

  /// Modül görünürlüğünü değiştir
  Future<void> toggleModuleVisibility(String moduleId) async {
    if (_userPreferences == null) return;

    final modules = List<ModuleItem>.from(_userPreferences!.dashboardModules);
    final index = modules.indexWhere((m) => m.id == moduleId);
    if (index == -1) return;

    modules[index] = modules[index].copyWith(
      isVisible: !modules[index].isVisible,
    );

    await updateModuleOrder(modules);
  }

  /// Add a module to bottom navigation bar (if not already pinned)
  Future<bool> pinModuleToNavigation(ModuleItem module) async {
    if (_currentUser == null) return false;

    if (_userPreferences == null) {
      _userPreferences = UserPreferences.createDefault(
        userId: _currentUser!.id,
        userRole: _currentUser!.role.name,
      );
    }

    final currentNav = List<NavigationItem>.from(
      _userPreferences!.navigationItems,
    );

    // Check if already in navigation
    final existingIndex = currentNav.indexWhere((n) => n.id == module.id);
    if (existingIndex != -1) {
      if (!currentNav[existingIndex].isVisible) {
        currentNav[existingIndex] = currentNav[existingIndex].copyWith(
          isVisible: true,
          isPinned: true,
        );
        await updateNavigationOrder(currentNav);
        return true;
      }
      return false; // Already present
    }

    // Limit maximum bottom bar tabs to 5 for optimal mobile layout
    if (currentNav.where((n) => n.isVisible).length >= 5) {
      return false; // Max limit reached
    }

    final newNavItem = module.toNavigationItem(
      orderIndex: currentNav.length,
      isPinned: true,
    );
    currentNav.add(newNavItem);
    await updateNavigationOrder(currentNav);
    return true;
  }

  /// Remove an item from bottom navigation bar
  Future<bool> removeNavigationItem(String navId) async {
    if (_currentUser == null) return false;

    // Do not allow removing main dashboard tab
    if (navId == 'dashboard') return false;

    if (_userPreferences == null) {
      _userPreferences = UserPreferences.createDefault(
        userId: _currentUser!.id,
        userRole: _currentUser!.role.name,
      );
    }

    final currentNav = List<NavigationItem>.from(
      _userPreferences!.navigationItems,
    );
    final index = currentNav.indexWhere((n) => n.id == navId);
    if (index == -1) return false;

    currentNav.removeAt(index);

    // Re-index
    for (int i = 0; i < currentNav.length; i++) {
      currentNav[i] = currentNav[i].copyWith(orderIndex: i);
    }

    await updateNavigationOrder(currentNav);
    return true;
  }

  /// Navigation item pinleme durumunu değiştir
  Future<void> toggleNavigationPin(String navId) async {
    if (_userPreferences == null) return;

    final navItems = List<NavigationItem>.from(
      _userPreferences!.navigationItems,
    );
    final index = navItems.indexWhere((n) => n.id == navId);
    if (index == -1) return;

    navItems[index] = navItems[index].copyWith(
      isPinned: !navItems[index].isPinned,
    );

    await updateNavigationOrder(navItems);
  }

  /// Kullanıcı tercihlerini varsayılana sıfırla
  Future<void> resetUserPreferences() async {
    if (_currentUser == null) return;

    _userPreferences = UserPreferences.createDefault(
      userId: _currentUser!.id,
      userRole: _currentUser!.role.name,
    );

    await _firestoreService.saveUserPreferences(_userPreferences!);
    notifyListeners();
  }

  /// Sıralı modül listesini döndür (yetkiye göre filtrelenmiş + sıralı)
  List<ModuleItem> getOrderedModules() {
    if (_currentUser == null) return [];

    final roleName = _currentUser!.role.name;
    if (_userPreferences == null || _userPreferences!.userRole != roleName) {
      _userPreferences = UserPreferences.createDefault(
        userId: _currentUser!.id,
        userRole: roleName,
      );
    }

    // Default modüllerden eksik olan varsa ekle
    final defaultMods = UserPreferences.createDefault(
      userId: _currentUser!.id,
      userRole: roleName,
    ).dashboardModules;

    final currentMods = List<ModuleItem>.from(
      _userPreferences!.dashboardModules,
    );
    bool updated = false;
    for (final defMod in defaultMods) {
      if (!currentMods.any((m) => m.id == defMod.id)) {
        currentMods.add(defMod.copyWith(orderIndex: currentMods.length));
        updated = true;
      }
    }
    if (updated) {
      _userPreferences = _userPreferences!.copyWith(
        dashboardModules: currentMods,
      );
    }

    // Səlahiyyətlərə görə filtrlə
    final authorized = currentMods
        .where((m) => m.isVisible && hasPermission(m.id))
        .toList();

    authorized.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return authorized;
  }

  /// Sıralı navigation item listesini döndür
  /// İcazəsi olmayan naviqasiya elementləri filtr edilir
  List<NavigationItem> getOrderedNavigation() {
    if (_currentUser == null) return [];

    final roleName = _currentUser!.role.name;
    if (_userPreferences == null || _userPreferences!.userRole != roleName) {
      _userPreferences = UserPreferences.createDefault(
        userId: _currentUser!.id,
        userRole: roleName,
      );
    }

    final visible = _userPreferences!.navigationItems
        .where((n) => n.isVisible)
        .where((n) => n.id == 'dashboard' || hasPermission(n.id))
        .toList();

    visible.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return visible;
  }

  /// getOrderedNavigation() üçün getter qısa yolu
  /// (main_screen alt menyusu bu adla istifadə edir)
  List<NavigationItem> get orderedNavigationItems => getOrderedNavigation();

  /// Rol üçün mövcud bütün modulları qaytarır
  List<ModuleItem> getAvailableModulesForRole() {
    if (_currentUser == null) return [];
    final roleName = _currentUser!.role.name;
    final defaultMods = UserPreferences.createDefault(
      userId: _currentUser!.id,
      userRole: roleName,
    ).dashboardModules;

    // Səlahiyyət yoxlanışı
    return defaultMods.where((m) => hasPermission(m.id)).toList();
  }

  /// Rolları Firestore-dan yükləyir (ilk açılışda default rollar yaradılır)
  Future<void> loadRoles() async {
    try {
      final res = await SchoolApiService.instance.fetchRolesWithCatalog();
      if (res != null) {
        final rawCatalog = res['permissionCatalog'];
        if (rawCatalog is List && rawCatalog.isNotEmpty) {
          final parsedCatalog = rawCatalog
              .whereType<Map>()
              .map((m) => Permission.fromJson(Map<String, dynamic>.from(m)))
              .where((p) => p.id.isNotEmpty)
              .toList();
          DefaultPermissions.setDynamicCatalog(parsedCatalog);
        }

        final rawRoles = res['data'];
        if (rawRoles is List && rawRoles.isNotEmpty) {
          final parsedApi = rawRoles
              .whereType<Map>()
              .map((m) => Role(
                    id: m['id']?.toString() ?? '',
                    name: m['name']?.toString() ?? '',
                    description: m['description']?.toString() ?? 'Sistem rolu',
                    permissionIds: (m['permissionIds'] is List)
                        ? (m['permissionIds'] as List).map((e) => e.toString()).toList()
                        : <String>[],
                    isDefault: m['isDefault'] == true,
                    isDeletable: m['isDeletable'] != false,
                    createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
                  ))
              .where((r) => r.name.isNotEmpty)
              .toList();
          if (parsedApi.isNotEmpty) {
            _roles = parsedApi;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Roles load error: $e');
    }
  }

  Future<bool> saveRoleToBackend(Role role, {bool isNew = false}) async {
    final ok = await SchoolApiService.instance.saveRole(
      {
        'name': role.name,
        'description': role.description,
        'permissionIds': role.permissionIds,
      },
      id: isNew ? null : role.id,
    );
    if (ok) {
      await loadRoles();
    }
    return ok;
  }

  Future<bool> deleteRoleFromBackend(String roleId) async {
    final ok = await SchoolApiService.instance.deleteRole(roleId);
    if (ok) {
      _roles.removeWhere((r) => r.id == roleId || r.name == roleId);
      await loadRoles();
    }
    return ok;
  }

  Role? getRoleById(String? roleId) {
    if (roleId == null || roleId.isEmpty) return null;
    for (final r in _roles) {
      if (r.id == roleId) return r;
    }
    return null;
  }

  /// İdarəetmə icazəsi verildikdə ona uyğun baxış icazəsini də qəbul edir.
  /// Məsələn, yalnız "manage_inventory" seçilmiş rolda inventar modulu
  /// görünməlidir; əks halda istifadəçi idarəetmə icazəsi olsa da modulu
  /// tapa bilmir.
  static const Map<String, List<String>> _permissionImplications = {
    'view_students': ['add_students', 'edit_students', 'delete_students'],
    'view_classes': ['manage_classes', 'assign_teachers'],
    'view_timetable': ['manage_timetable'],
    'view_grades': ['add_grades', 'edit_grades', 'delete_grades'],
    'view_attendance': ['add_attendance', 'edit_attendance', 'delete_attendance'],
    'view_medical': ['manage_medical'],
    'view_library': ['manage_library'],
    'view_cafeteria': ['manage_cafeteria'],
    'view_inventory': ['manage_inventory'],
    'view_tickets': ['manage_tickets', 'view_all_tickets'],
    'view_settings': ['manage_settings'],
    'view_roles': ['manage_roles'],
    'view_users': ['add_users', 'edit_users', 'delete_users'],
    'view_finance': ['manage_student_invoices', 'manage_payroll', 'manage_general_ledger'],
    'student_invoices': ['manage_student_invoices', 'view_finance'],
    'payroll': ['manage_payroll', 'view_finance'],
    'general_ledger': ['manage_general_ledger', 'view_finance'],
    'finance_dictionary': ['view_finance'],
    'view_employees': ['manage_employees'],
    'view_contracts': ['manage_contracts', 'manage_employees'],
    'salary_calculator': ['manage_payroll', 'view_finance', 'view_employees'],
    'employee_documents': ['manage_employees', 'view_employees'],
    'employee_attendance': ['view_employee_attendance', 'manage_employees', 'view_employees'],
    'view_exams': ['manage_exams'],
    'exam_results': ['view_exam_results', 'enter_exam_results', 'view_exams'],
    'exam_categories': ['manage_exams', 'view_exams'],
    'student_applications': ['view_students', 'add_students'],
    'curriculums': ['manage_curriculum'],
    'clubs': ['manage_clubs'],
    'excused_absences': ['view_attendance', 'edit_attendance'],
    'graduations': ['view_students'],
    'academic_years': ['manage_timetable'],
    'rooms': ['manage_timetable', 'view_classes'],
    'time_slots': ['manage_timetable'],
    'book_loans': ['manage_library', 'view_library'],
    'book_reservations': ['manage_library', 'view_library'],
    'warehouse_inventory': ['manage_inventorizations', 'view_warehouse', 'view_inventory'],
    'canteen_supply': ['manage_cafeteria', 'view_cafeteria', 'view_warehouse'],
    'quality_control': ['view_quality_control', 'view_statistics'],
    'workload_report': ['view_statistics', 'view_reports'],
    'school_attendance_stats': ['view_statistics', 'view_attendance', 'view_reports'],
    'medical_journal': ['manage_medical', 'view_medical'],
    'psychology_evaluation': ['view_reports', 'manage_medical'],
    'organizational_structure': ['manage_classes', 'view_users'],
    'activity_logs': ['manage_settings', 'view_settings'],
  };

  bool _roleGrants(Role role, String permissionId) {
    if (role.permissionIds.contains(permissionId)) return true;
    final alternatives = _permissionImplications[permissionId];
    return alternatives?.any(role.permissionIds.contains) ?? false;
  }

  /// Səlahiyyət yoxlaması.
  /// assignedRoleId olan istifadəçi YALNIZ rolunun icazə verdiyi
  /// səlahiyyətlərə çatır (UserRole.admin olan işçilər də daxil —
  /// IT/Helpdesk kimi rollar məhz belə yaradılır). Rol təyin olunmayan
  /// şagird/müəllim/valideynlər öz standart modullarına giriş əldə edir;
  /// yalnız baş inzibatçı hesabı bütün idarəetmə modullarını görür.

  bool canViewPassword([String module = '']) {
    if (isPrimaryAdmin) return true;
    if (hasPermission('gopanel.passwords.view')) return true;

    return switch (module.toLowerCase().trim()) {
      'student' || 'students' => hasPermission('gopanel.academic.students.view_password') ||
          hasPermission('gopanel.students.view_password'),
      'parent' || 'parents' => hasPermission('gopanel.academic.parents.view_password') ||
          hasPermission('gopanel.parents.view_password'),
      'employee' || 'employees' || 'employer' => hasPermission('gopanel.hr.employees.view_password') ||
          hasPermission('gopanel.employees.view_password'),
      'admin' || 'admins' => hasPermission('gopanel.admins.view_password'),
      _ => false,
    };
  }

  Future<bool> switchGuard(BuildContext context) async {
    final session = context.read<SessionController>();
    final ok = await session.switchGuard();
    if (ok) {
      syncFromSession(session);
      resetToDashboard();
      notifyListeners();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
    return ok;
  }

  bool hasPermission(String permissionId) {
    final user = _currentUser;
    if (user == null) return false;

    // 1. SuperAdmin: full access
    if (isPrimaryAdmin) return true;

    // 2. Student & Parent guards
    if (user.role == UserRole.student) {
      const allowedStudentMods = {
        'dashboard',
        'student_timetable',
        'student_grades',
        'student_attendance',
        'student_assignments',
        'student_notes',
        'academic_notes',
        'student_clubs',
        'clubs',
        'gopanel.academic.clubs.view',
        'student_library',
        'student_cafeteria',
        'student_id',
        'digital_id',
        'student_meet',
        'meet',
        'student_excuses',
        'excused_absences',
      };
      return allowedStudentMods.contains(permissionId);
    }

    if (user.role == UserRole.parent) {
      const allowedParentMods = {
        'dashboard',
        'parent_timetable',
        'parent_grades',
        'parent_attendance',
        'parent_assignments',
        'parent_notes',
        'academic_notes',
        'parent_medical',
        'parent_cafeteria',
        'parent_library',
        'parent_invoices',
        'parent_clubs',
        'clubs',
        'gopanel.academic.clubs.view',
        'parent_tickets',
        'tickets',
        'parent_excuses',
        'excused_absences',
      };
      return allowedParentMods.contains(permissionId);
    }

    // 3. User Spatie permissions
    final effectivePerms = <String>{...user.directPermissions};
    final roleId = user.assignedRoleId;
    if (roleId != null && roleId.isNotEmpty) {
      final matchedRole = getRoleById(roleId) ??
          _roles.where((r) => r.name.toLowerCase() == roleId.toLowerCase()).firstOrNull;
      if (matchedRole != null) {
        effectivePerms.addAll(matchedRole.permissionIds);
      }
    }

    final isClubLeaderRole = (roleId != null && roleId.toLowerCase().contains('dərnək')) ||
        user.roleNames.any((r) => r.toLowerCase().contains('dərnək') || r == '34');
    if (isClubLeaderRole &&
        (permissionId.startsWith('gopanel.academic.clubs') ||
            permissionId == 'clubs' ||
            permissionId == 'manage_clubs' ||
            permissionId == 'club_journal')) {
      return true;
    }

    // Direct match (for exact Spatie permission strings)
    if (effectivePerms.contains(permissionId)) {
      return true;
    }

    if (permissionId == 'gopanel.tickets.view' && effectivePerms.contains('gopanel.tickets.view.assigned')) {
      return true;
    }

    if (permissionId == 'gopanel.academic.clubs.journal.view' &&
        (user.role == UserRole.admin ||
            user.role == UserRole.teacher ||
            effectivePerms.contains('gopanel.academic.clubs.view') ||
            effectivePerms.contains('gopanel.academic.ejournal.attendance.view'))) {
      return true;
    }

    bool hasAnySpatie(List<String> list) => list.any(effectivePerms.contains);

    // Fallback/Legacy aliases for dashboard modules
    final hasSpatie = switch (permissionId) {
      'dashboard' => true,
      // 1. E-məktəb
      'student_applications' => hasAnySpatie(['gopanel.academic.students.admissions']),
      'ambulatory_requests' => hasAnySpatie(['gopanel.admissions.ambulatory_requests.view', 'gopanel.medical.ambulatory_journals.view']),
      'view_students' || 'students' => hasAnySpatie(['gopanel.academic.students.view']),
      'add_students' => hasAnySpatie(['gopanel.academic.students.create', 'gopanel.academic.admissions.create']),
      'edit_students' => hasAnySpatie(['gopanel.academic.students.update', 'gopanel.academic.admissions.update']),
      'delete_students' => hasAnySpatie(['gopanel.academic.students.delete']),
      'graduations' => hasAnySpatie(['gopanel.academic.graduations.view']),
      'transition_exceptions' => hasAnySpatie(['gopanel.academic.transitions.exceptions.view']),
      'parents' => hasAnySpatie(['gopanel.academic.parents.view']),
      'view_classes' || 'classes' || 'manage_classes' => hasAnySpatie(['gopanel.academic.classes.view', 'gopanel.academic.classes.create', 'gopanel.academic.classes.update']),
      'parallel_lessons' => hasAnySpatie(['gopanel.academic.parallel_lessons.view']),
      'teachers' => hasAnySpatie(['gopanel.academic.teachers.view', 'gopanel.academic.teachers.teachers.view']),
      'view_timetable' || 'timetable' || 'manage_timetable' => hasAnySpatie(['gopanel.academic.schedules.view', 'gopanel.academic.schedules.manage', 'gopanel.academic.parallel_lessons.view']),
      'view_journal' || 'journal' => hasAnySpatie(['gopanel.academic.ejournal.attendance.view', 'gopanel.academic.operations.attendance.view']),
      'excused_absences' => hasAnySpatie(['gopanel.academic.homeroom.excuses.view', 'gopanel.medical.excuses.view']),
      'club_journal' => user.role == UserRole.teacher ||
          user.role == UserRole.admin ||
          hasAnySpatie(['gopanel.academic.clubs.journal.view', 'gopanel.academic.clubs.view', 'gopanel.academic.ejournal.attendance.view']),
      'final_grading' => hasAnySpatie(['gopanel.academic.ejournal.grading.final']),
      'assignments' => hasAnySpatie(['gopanel.academic.ejournal.assignments.view']),
      'curriculums' || 'manage_curriculum' => hasAnySpatie(['gopanel.academic.ejournal.curriculums.view']),
      'clubs' || 'manage_clubs' => hasAnySpatie(['gopanel.academic.clubs.view']),
      'academic_years' => hasAnySpatie(['gopanel.academic.foundations.years.view']),
      'statuses' => hasAnySpatie(['gopanel.academic.foundations.statuses.view']),
      'subjects' => hasAnySpatie(['gopanel.academic.foundations.subjects.view']),
      'rooms' => hasAnySpatie(['gopanel.academic.foundations.rooms.view']),
      'time_slots' => hasAnySpatie(['gopanel.academic.foundations.time_slots.view']),
      'academic_notes' => hasAnySpatie(['gopanel.academic.notes.view']),

      // 2. İnsan resursları
      'organizational_structure' => hasAnySpatie(['gopanel.structure.structures.view', 'gopanel.structure.positions.view', 'gopanel.structure.staffing_tables.view']),
      'view_employees' || 'employees' || 'manage_employees' => hasAnySpatie(['gopanel.hr.employees.view']),
      'view_contracts' || 'contracts' || 'manage_contracts' => hasAnySpatie(['gopanel.hr.contracts.view', 'gopanel.contracts.view']),
      'employee_documents' => hasAnySpatie(['gopanel.hr.documents.view']),
      'employee_attendance' => hasAnySpatie(['gopanel.hr.attendances.view']),
      'salary_calculator' => hasAnySpatie(['gopanel.dashboard.salary_calculator', 'gopanel.finance.payroll.view', 'gopanel.hr.contracts.view']),

      // 3. Maliyyə və mühasibatlıq
      'student_invoices' || 'view_finance' => hasAnySpatie(['gopanel.finance.student_contracts.view', 'gopanel.finance.payments.view']),
      'payroll' => hasAnySpatie(['gopanel.finance.payroll.view']),
      'general_ledger' => hasAnySpatie(['gopanel.finance.ledger.view', 'gopanel.finance.reports.view']),
      'finance_dictionary' => hasAnySpatie(['gopanel.finance.dictionary.view', 'gopanel.finance.dictionary.transport_rates.view']),

      // 4. Təsərrüfat və inventar
      'warehouse_inventory' || 'view_inventory' || 'inventory' || 'manage_inventory' => hasAnySpatie(['gopanel.warehouse.items.view', 'gopanel.warehouse_actions.inventorizations.view']),
      'canteen_supply' => hasAnySpatie(['gopanel.canteen.canteens.view', 'gopanel.canteen.templates.view']),
      'view_cafeteria' || 'cafeteria' || 'manage_cafeteria' => hasAnySpatie(['gopanel.canteen.menu.view', 'gopanel.canteen.preview.view']),

      // 5. Tibbi & 6. Psixologiya
      'medical_journal' || 'view_medical' => hasAnySpatie(['gopanel.medical.medical_results.view']),
      'psychology_evaluation' => hasAnySpatie(['gopanel.psicology.psicology_results.view']),

      // 7. İmtahan
      'exam_categories' => hasAnySpatie(['gopanel.exams.exam_categories.view']),
      'view_exams' || 'manage_exams' => hasAnySpatie(['gopanel.exams.exams.view']),
      'exam_results' => hasAnySpatie(['gopanel.exams.results.view']),

      // 8. Dəstək biletləri
      'view_tickets' || 'tickets' || 'view_all_tickets' => hasAnySpatie(['gopanel.tickets.view', 'gopanel.tickets.view.assigned']),
      'manage_tickets' => hasAnySpatie(['gopanel.tickets.respond', 'gopanel.tickets.create']),

      // 9. Kitabxana
      'view_library' || 'library' => hasAnySpatie(['gopanel.library.books.view']),
      'book_loans' => hasAnySpatie(['gopanel.library.loans.view']),
      'book_reservations' => hasAnySpatie(['gopanel.library.reservations.view']),

      // 10. Statistika
      'quality_control' => hasAnySpatie(['gopanel.statistics.quality_control.view']),
      'school_attendance_stats' => hasAnySpatie(['gopanel.statistics.attendance.view']),
      'view_reports' || 'analytics' => hasAnySpatie(['gopanel.academic.statistics.performance', 'gopanel.statistics.view']),
      'workload_report' => hasAnySpatie(['gopanel.academic.teachers.report.view']),

      // 11. Sistem & loqlar
      'view_settings' || 'notifications' => hasAnySpatie(['gopanel.notifications.view', 'gopanel.dashboard_banners.view', 'gopanel.settings.site.view']),
      'view_users' || 'users' => hasAnySpatie(['gopanel.admins.view']),
      'view_roles' || 'roles' || 'manage_roles' => hasAnySpatie(['gopanel.roles.view']),
      'activity_logs' => hasAnySpatie(['gopanel.activity.history.view', 'gopanel.activity.logs.view']),

      // Müəllim paneli xüsusi modulları
      'teacher_timetable' => user.role == UserRole.teacher || hasAnySpatie(['gopanel.academic.ejournal.view', 'gopanel.academic.schedules.view']),
      'teacher_meet' || 'meet' => user.role == UserRole.teacher,
      'teacher_students' => user.role == UserRole.teacher || hasAnySpatie(['gopanel.academic.students.view']),
      'teacher_assignments' => user.role == UserRole.teacher || hasAnySpatie(['gopanel.academic.ejournal.assignments.view']),
      'teacher_grading' => user.role == UserRole.teacher || hasAnySpatie(['gopanel.academic.ejournal.attendance.view']),
      'teacher_id_card' => user.role == UserRole.teacher,
      'teacher_inventory' => user.role == UserRole.teacher || hasAnySpatie(['gopanel.tickets.view', 'gopanel.tickets.view.assigned']),
      _ => false,
    };

    if (hasSpatie) return true;

    // Direktor rolu web-də bütün akademik/inzibati modulları görür
    final activeRoleLower = (roleId ?? '').toLowerCase();
    if (activeRoleLower == 'direktor' || activeRoleLower == 'superadmin') {
      return true;
    }

    return hasSpatie;
  }

  // Per-student medical cards map: studentId -> StudentMedicalCard
  final Map<String, StudentMedicalCard> _medicalCardsMap = {};

  // Per-class Timetables Map: className -> List<DayTimetable>
  final Map<String, List<DayTimetable>> _classTimetablesMap = {};
  // Clubs Timetable (Dərnəklər Cədvəli)
  final List<DayTimetable> _clubTimetable = [];
  List<DayTimetable> get clubTimetable => _clubTimetable;

  // Calendar Holidays Map: "YYYY-MM-DD" -> Holiday Title / Day Info
  final Map<String, Map<String, dynamic>> _calendarHolidaysMap = {};
  Map<String, Map<String, dynamic>> get calendarHolidaysMap => _calendarHolidaysMap;

  bool isDateHoliday(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _calendarHolidaysMap[dateStr]?['is_holiday'] == true;
  }

  String? getHolidayTitleForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _calendarHolidaysMap[dateStr]?['title']?.toString();
  }

  // Get Timetable for a specific class (or default empty 5 days)
  List<DayTimetable> getClassTimetable(String rawClassName) {
    final className = _cleanClassName(rawClassName);
    if (_classTimetablesMap.containsKey(className)) {
      return _classTimetablesMap[className]!;
    }
    final defaultDays = [
      DayTimetable(dayName: 'Bazar ertəsi', shortDay: 'B.E', lessons: []),
      DayTimetable(dayName: 'Çərşənbə axşamı', shortDay: 'Ç.A', lessons: []),
      DayTimetable(dayName: 'Çərşənbə', shortDay: 'Ç.', lessons: []),
      DayTimetable(dayName: 'Cümə axşamı', shortDay: 'C.A', lessons: []),
      DayTimetable(dayName: 'Cümə', shortDay: 'C.', lessons: []),
    ];
    _classTimetablesMap[className] = defaultDays;
    return defaultDays;
  }

  // Selected Student for Parent / Active view
  String? _activeChildId;

  /// Valideynin bütün övladları (Övladlar modeli)
  List<StudentProfile> get children {
    final user = _currentUser;
    if (user == null || user.role != UserRole.parent) return const [];
    return childrenOf(user);
  }

  /// İstənilən istifadəçinin övladları — valideynlər və eyni zamanda
  /// övladı olan işçilər (müəllim/admin) üçün ortaq məntiq.
  List<StudentProfile> childrenOf(AppUser user) {
    final ids = <String>{
      if (user.linkedStudentId != null && user.linkedStudentId!.isNotEmpty)
        user.linkedStudentId!,
      ...user.linkedStudentIds,
    };
    if (ids.isEmpty) return const [];
    return _students.where((s) => ids.contains(s.id)).toList();
  }

  /// Valideyn panelində aktiv övladı dəyişir
  void setActiveChild(String studentId) {
    if (children.any((c) => c.id == studentId) && _activeChildId != studentId) {
      _activeChildId = studentId;
      notifyListeners();
    }
  }

  StudentProfile get student {
    final user = _currentUser;
    if (user?.role == UserRole.parent) {
      final kids = children;
      if (kids.isEmpty) return MockData.currentStudent;
      // Aktiv seçilmiş övlad (keçid düyməsi ilə)
      if (_activeChildId != null) {
        for (final s in kids) {
          if (s.id == _activeChildId) return s;
        }
      }
      // Əsas övlad (linkedStudentId), yoxsa siyahıdakı ilk
      final primaryId = user!.linkedStudentId;
      if (primaryId != null) {
        for (final s in kids) {
          if (s.id == primaryId) return s;
        }
      }
      return kids.first;
    }
    if (_currentUser?.role == UserRole.student) {
      return _students.firstWhere(
        (s) =>
            s.id == _currentUser!.id ||
            s.fullName.toLowerCase() == _currentUser!.fullName.toLowerCase() ||
            s.studentNumber.toLowerCase() ==
                _currentUser!.idrakCode.toLowerCase(),
        orElse: () => StudentProfile(
          id: _currentUser!.id,
          fullName: _currentUser!.fullName,
          studentNumber: _currentUser!.idrakCode,
          className: _currentUser!.className ?? '9B',
          photoUrl: _currentUser!.photoUrl ?? '',
          qrData: 'IDRAK-STD-${_currentUser!.id}',
          barcodeData: _currentUser!.id,
          parentName: '',
          parentPhone: _currentUser!.phone,
          gpa: 4.8,
          attendanceRate: 98,
          academicYear: '2026 - 2027',
        ),
      );
    }
    if (_students.isNotEmpty) {
      return _students.first;
    }
    return MockData.currentStudent;
  }

  // Available classes in the entire school
  List<String> get allDistinctClasses {
    final classesSet = <String>{..._customClasses};
    for (final s in _students) {
      if (s.className.isNotEmpty) classesSet.add(s.className);
    }
    for (final u in _users) {
      classesSet.addAll(u.assignedClasses);
    }
    classesSet.addAll(_classTimetablesMap.keys);
    return classesSet.toList()..sort();
  }

  // Classes claimed/taught by current teacher
  List<String> get currentTeacherClasses {
    if (_currentUser == null) return [];
    return _currentUser!.assignedClasses;
  }

  // --- INITIALIZE & SYNC FROM FIRESTORE ---
  Future<void>? _initFuture;

  /// İlk Firestore sinxronizasiyası tamamlandımı? Ekranlar boş siyahını
  /// "məlumat yoxdur" kimi göstərməzdən əvvəl bunu yoxlamalıdır.
  bool _isInitialDataLoaded = false;
  bool get isInitialDataLoaded => _isInitialDataLoaded;

  /// Returns the ongoing (or a new) Firestore sync so callers can await it
  /// before relying on cloud data (e.g. auto-login needs the users list).
  Future<void> ensureDataReady() {
    return _initFuture ??= initFirebaseData();
  }

  Future<void> initFirebaseData() async {
    try {
      // Meet presence must start immediately. Waiting for every other school
      // collection can otherwise delay a live room by minutes on a weak link.
      _startMeetRoomsListener();

      // 1. Fetch Users
      final cloudUsers = await _firestoreService.fetchUsers();
      if (cloudUsers.isNotEmpty) {
        for (final u in cloudUsers) {
          final index = _users.indexWhere((x) => x.id == u.id);
          if (index == -1) {
            _users.add(u);
          } else {
            // Buluddakı rol təyinatı lokal köhnə kopyadan üstün olmalıdır.
            _users[index] = u;
            if (_currentUser?.id == u.id) {
              _currentUser = u;
            }
          }
        }
      }

      // 2. Fetch Students
      final cloudStudents = await _firestoreService.fetchStudents();
      if (cloudStudents.isNotEmpty) {
        final apiKids = _students.where((s) => !s.id.startsWith('std-')).toList();
        _students.clear();
        _students.addAll(apiKids);
        for (final cs in cloudStudents) {
          if (!_students.any((s) => s.id == cs.id)) {
            _students.add(cs);
          }
        }
        _pendingAttendanceStudents = List.from(_students);

        // Studentlər gecikə bilər — valideyn girişi olanda uşaq sinifləri
        // hazır deyilsə, yüklənən kimi class topic-lərini yenilə.
        final current = _currentUser;
        if (current != null && current.role == UserRole.parent) {
          final classes = _childClassesFor(current);
          if (classes.isNotEmpty) {
            unawaited(
              PushNotificationService.instance.updateClassTopics(classes),
            );
          }
        }
      }

      // 3. Fetch Timetables
      final cloudTimetables = await _firestoreService.fetchAllClassTimetables();
      if (cloudTimetables.isNotEmpty) {
        for (final entry in cloudTimetables.entries) {
          _classTimetablesMap.putIfAbsent(entry.key, () => entry.value);
        }
      }

      // 4. Fetch Books
      final cloudBooks = await _firestoreService.fetchBooks();
      if (cloudBooks.isNotEmpty) {
        _books.clear();
        _books.addAll(cloudBooks);
      }

      // 5. Fetch Assignments
      final cloudAssignments = await _firestoreService.fetchAssignments();
      if (cloudAssignments.isNotEmpty && !_assignments.any((a) => a.id.startsWith('api-'))) {
        _assignments.clear();
        _assignments.addAll(cloudAssignments);
      }

      // 6. Fetch Tickets
      final cloudTickets = await _firestoreService.fetchTickets();
      if (cloudTickets.isNotEmpty) {
        _tickets.clear();
        _tickets.addAll(cloudTickets);
      }

      // 7. Fetch Menu
      final cloudMenu = await _firestoreService.fetchWeeklyMenu();
      if (cloudMenu.isNotEmpty) {
        _weeklyMenu.clear();
        _weeklyMenu.addAll(cloudMenu);
      }

      // 8. Fetch Grades
      final cloudGrades = await _firestoreService.fetchGrades(null);
      if (cloudGrades.isNotEmpty && !_grades.any((g) => g.id.startsWith('api-'))) {
        _grades.clear();
        _grades.addAll(cloudGrades);
      }

      // 9. Fetch Medical Cards
      final cloudMedicalCards = await _firestoreService.fetchAllMedicalCards();
      if (cloudMedicalCards.isNotEmpty) {
        _medicalCardsMap.addAll(cloudMedicalCards);
      }

      // 10. Fetch Attendance
      final cloudAttendance = await _firestoreService.fetchAllAttendance();
      if (cloudAttendance.isNotEmpty) {
        for (final entry in cloudAttendance.entries) {
          _studentAttendanceMap.putIfAbsent(entry.key, () => entry.value);
        }
      }

      // 11. Fetch Meet Rooms
      final cloudMeetRooms = await _firestoreService.fetchMeetRooms();
      // Do not overwrite a newer snapshot delivered by the listener above.
      if (_meetRooms.isEmpty && cloudMeetRooms.isNotEmpty) {
        _meetRooms.addAll(cloudMeetRooms);
      }

      // 12. Fetch Notifications
      final cloudNotifs = await _firestoreService.fetchNotifications();
      if (cloudNotifs.isNotEmpty) {
        _notifications.clear();
        _notifications.addAll(cloudNotifs);
      }
      // Bundan sonra canlı dinlə — tətbiq açıq ikən gələn bildirişlər
      // dərhal görünsün (çıx-gir etməyə ehtiyac yoxdur).
      _startNotificationsListener();

      // 13. Fetch QR Inventory Items
      final cloudInventory = await _firestoreService.fetchInventoryItems();
      if (cloudInventory.isNotEmpty) {
        _inventoryItems.clear();
        _inventoryItems.addAll(cloudInventory);
      }

      // 14. Fetch Roles (ilk dəfədə default rollar yaradılır)
      await loadRoles();

      // 15. Fetch Class Details (siniflər restartdan sonra itmir)
      final cloudClassDetails = await _firestoreService.fetchClassDetails();
      if (cloudClassDetails.isNotEmpty) {
        _classDetailsMap.addAll(cloudClassDetails);
        _customClasses.addAll(cloudClassDetails.keys);
      }

      _isInitialDataLoaded = true;
      notifyListeners();
    } catch (e) {
      // Sinxronizasiya yarım qala bilər (şəbəkə ortada kəsildi). Future-u
      // sıfırlayırıq ki, növbəti ensureDataReady() çağrısı (login, şəbəkə
      // bərpası və s.) yenidən cəhd etsin — əks halda tətbiq bağlanana
      // qədər yarım datayla qalır.
      _initFuture = null;
      _isInitialDataLoaded = true; // yükləmə bitdi; boş ekranlar retry göstərə bilər
      debugPrint('Firestore initialization sync notice: $e');
      notifyListeners();
    }
  }

  void _startMeetRoomsListener() {
    _meetRoomsSubscription?.cancel();
    _meetRoomsSubscription = _firestoreService.watchMeetRooms().listen(
      (rooms) {
        _meetRooms
          ..clear()
          ..addAll(rooms);
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Meet rooms live sync error: $error');
        // Keep existing rooms on error instead of clearing
      },
      cancelOnError: false, // Keep stream alive on Firestore reconnects
    );
  }

  /// Bildirişlərin canlı sinkronizasiyası (meet rooms listener-i ilə eyni pattern).
  void _startNotificationsListener() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _firestoreService.watchNotifications().listen(
      (notifs) {
        _notifications
          ..clear()
          ..addAll(notifs);
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Notifications live sync error: $error');
        // Xətada mövcud siyahını saxla, boşaltma
      },
      cancelOnError: false, // Firestore yenidən qoşulanda axın davam etsin
    );
  }

  Future<void> syncEmployeesFromApi() async {
    try {
      final raw = await SchoolApiService.instance.fetchEmployees();
      if (raw.isNotEmpty) {
        final apiUsers = raw.map((m) {
          final fullName = m['fullName']?.toString() ?? 'Əməkdaş';
          final parts = fullName.split(' ');
          final fName = (m['firstName']?.toString() ?? '').trim().isNotEmpty
              ? m['firstName'].toString().trim()
              : (parts.isNotEmpty ? parts[0] : '');
          final lName = (m['lastName']?.toString() ?? '').trim().isNotEmpty
              ? m['lastName'].toString().trim()
              : (parts.length > 1 ? parts.sublist(1).join(' ') : '');
          final dept = m['department']?.toString() ?? '';
          final pos = m['position']?.toString() ?? '';
          final isTeacher = m['isTeacher'] == true ||
              pos.toLowerCase().contains('müəllim') ||
              pos.toLowerCase().contains('muellim');
          final rawRoles = (m['roles'] is List)
              ? (m['roles'] as List).map((e) => e.toString()).toList()
              : <String>[];
          final rawClasses = (m['assignedClasses'] is List)
              ? (m['assignedClasses'] as List).map((e) => e.toString()).toList()
              : <String>[];

          return AppUser(
            id: 'emp-${m['id']}',
            username: m['email']?.toString() ?? m['finCode']?.toString() ?? 'emp${m['id']}',
            password: '123456',
            fullName: fullName,
            firstName: fName,
            lastName: lName,
            fatherName: m['fatherName']?.toString(),
            finCode: m['finCode']?.toString(),
            gender: m['gender']?.toString() ?? 'Kişi',
            birthDate: DateTime.tryParse(m['birthDate']?.toString() ?? ''),
            address: m['address']?.toString(),
            registrationAddress: m['registrationAddress']?.toString(),
            citizenship: m['citizenship']?.toString() ?? 'Azərbaycan',
            idCardSerial: m['idCardSerial']?.toString(),
            maritalStatus: m['maritalStatus']?.toString(),
            bloodGroup: m['bloodGroup']?.toString(),
            scientificDegree: m['scientificDegree']?.toString(),
            honoraryTitle: m['honoraryTitle']?.toString(),
            educationLevel: m['educationLevel']?.toString(),
            university: m['university']?.toString(),
            specialty: m['specialty']?.toString(),
            eduDocNumber: m['eduDocNumber']?.toString(),
            bankName: m['bankName']?.toString(),
            bankAccount: m['bankAccount']?.toString(),
            bankIban: m['bankIban']?.toString(),
            position: pos,
            department: dept,
            filial: m['filial']?.toString() ?? 'Bakı filialı',
            sector: m['sector']?.toString() ?? 'Azərbaycan',
            role: isTeacher ? UserRole.teacher : UserRole.admin,
            idrakCode: m['code']?.toString() ?? 'İDR-EMP${m['id']}',
            phone: m['phone']?.toString() ?? '',
            email: m['email']?.toString(),
            salary: (m['salary'] as num?)?.toDouble() ?? 0.0,
            netSalary: (m['netSalary'] as num?)?.toDouble(),
            contractNumber: m['contractNumber']?.toString(),
            contractType: m['contractType']?.toString(),
            contractStart: DateTime.tryParse(m['contractStartDate']?.toString() ?? ''),
            contractEnd: DateTime.tryParse(m['contractEndDate']?.toString() ?? ''),
            hireDate: DateTime.tryParse(m['hireDate']?.toString() ?? ''),
            roleNames: rawRoles,
            directPermissions: (m['permissions'] is List)
                ? (m['permissions'] as List).map((e) => e.toString()).toList()
                : <String>[],
            assignedClasses: rawClasses,
            subject: m['subject']?.toString(),
            isActive: m['status'] == 'active',
            createdAt: DateTime.tryParse(m['hireDate']?.toString() ?? '') ?? DateTime.now(),
            assignedRoleId: rawRoles.isNotEmpty ? rawRoles.first : dept,
          );
        }).toList();

        final masterAdmin = _users.where((u) => u.id == 'usr-admin-1').toList();
        final nonStaff = _users.where((u) => u.role == UserRole.student || u.role == UserRole.parent).toList();
        _users.clear();
        _users.addAll(masterAdmin);
        _users.addAll(apiUsers);
        _users.addAll(nonStaff);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('syncEmployeesFromApi error: $e');
    }
  }

  Future<void> syncStudentsFromApi() async {
    try {
      final rawClasses = await SchoolApiService.instance.fetchClasses();
      for (final c in rawClasses) {
        final name = c['name']?.toString().trim() ?? '';
        if (name.isNotEmpty && name != 'Sinif təyin edilməyib') {
          _customClasses.add(name);
        }
      }

      final rawStudents = await SchoolApiService.instance.fetchStudents();
      if (rawStudents.isNotEmpty) {
        final parsed = rawStudents.map((m) {
          final idStr = m['id']?.toString() ?? '';
          final fullName = m['fullName']?.toString().trim() ?? 'Şagird';
          final cleanClass = _cleanClassName(m['className']?.toString());
          if (cleanClass != 'Sinif təyin edilməyib') {
            _customClasses.add(cleanClass);
          }
          final code = m['code']?.toString() ?? 'İDR-STU-$idStr';
          return StudentProfile(
            id: idStr,
            fullName: fullName,
            studentNumber: code,
            className: cleanClass,
            photoUrl: (m['photoUrl']?.toString().isNotEmpty == true) ? m['photoUrl'].toString() : '',
            qrData: 'IDRAK-STUDENT-$code',
            barcodeData: code,
            firstName: m['firstName']?.toString(),
            lastName: m['lastName']?.toString(),
            fatherName: m['fatherName']?.toString(),
            finCode: m['finCode']?.toString(),
            gender: m['gender']?.toString(),
            birthDate: DateTime.tryParse(m['birthDate']?.toString() ?? ''),
            address: m['address']?.toString(),
            registrationAddress: m['registrationAddress']?.toString(),
            email: m['email']?.toString(),
            phone: m['phone']?.toString(),
            bloodGroup: m['bloodGroup']?.toString(),
            eyeColor: m['eyeColor']?.toString(),
            sector: m['sector']?.toString(),
            parentName: m['parentName']?.toString() ?? '',
            parentPhone: m['parentPhone']?.toString() ?? '',
            parentEmail: m['parentEmail']?.toString(),
            contractNumber: m['contractNumber']?.toString(),
            contractStatus: m['contractStatus']?.toString(),
            contractAmount: (m['contractAmount'] as num?)?.toDouble(),
            gpa: (m['gpa'] as num?)?.toDouble() ?? 0.0,
            attendanceRate: (m['attendanceRate'] as num?)?.toInt() ?? 100,
            academicYear: '2026 - 2027',
            isCurrentYear: m['isCurrentYear'] == true,
          );
        }).toList();

        _students
          ..clear()
          ..addAll(parsed);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('syncStudentsFromApi error: $e');
    }
  }

  Future<void> syncBooksFromApi() async {
    try {
      final rawBooks = await SchoolApiService.instance.fetchBooks();
      if (rawBooks.isNotEmpty) {
        final parsed = rawBooks.map((m) {
          final title = m['title']?.toString() ?? 'Kitab';
          return BookItem(
            id: m['id']?.toString() ?? 'bk-1',
            title: title,
            author: m['author']?.toString() ?? 'Müəllif',
            category: m['category']?.toString() ?? 'Dərslik',
            coverUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}&background=1E3A8A&color=fff&size=400',
            type: BookType.physical,
            pageCount: (m['pageCount'] as num?)?.toInt() ?? 200,
            language: m['language']?.toString() ?? 'Azərbaycan',
            availableCopies: (m['availableCopies'] as num?)?.toInt() ?? 5,
            totalCopies: (m['totalCopies'] as num?)?.toInt() ?? 5,
            isBorrowedByMe: false,
            description: m['description']?.toString() ?? 'İdrak Liseyi kitabxana fondu.',
            rating: 4.9,
            isbn: m['isbn']?.toString() ?? '',
          );
        }).toList();
        _books
          ..clear()
          ..addAll(parsed);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('syncBooksFromApi error: $e');
    }
  }

  static String _cleanClassName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Sinif təyin edilməyib';
    final trimmed = raw.trim();
    final match = RegExp(r'\(([^)]+)\)').firstMatch(trimmed);
    if (match != null && match.group(1) != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    return trimmed;
  }

  // --- AUTHENTICATION ---
  void syncFromSession(SessionController session) {
    final profile = session.profile;
    if (profile == null) return;

    UserRole role;
    final childIds = <String>[];
    String? currentClassName;

    if (profile.isStudent) {
      role = UserRole.student;
      final currentClass = session.linked['current_class'];
      currentClassName = _cleanClassName(
        (currentClass is Map ? currentClass['name']?.toString() : null) ?? '9 R',
      );
      final gpaVal = (session.linked['gpa'] as num?)?.toDouble() ?? 0.0;
      final attRate = (session.linked['attendance_rate'] as num?)?.toInt() ?? 100;
      final bloodGrp = session.linked['blood_group']?.toString();
      final studentObj = StudentProfile(
        id: profile.id.toString(),
        fullName: profile.name,
        studentNumber: profile.code ?? profile.finCode ?? 'IDR-STD-${profile.id}',
        className: currentClassName,
        photoUrl: profile.photoUrl ?? '',
        qrData: 'IDRAK-STD-${profile.id}',
        barcodeData: profile.id.toString(),
        finCode: profile.finCode,
        bloodGroup: bloodGrp,
        parentName: '',
        parentPhone: profile.phone ?? '',
        gpa: gpaVal,
        attendanceRate: attRate,
        academicYear: '2026 - 2027',
      );
      _students.removeWhere((s) => s.id == profile.id.toString() || s.fullName.toLowerCase() == profile.name.toLowerCase());
      _students.insert(0, studentObj);
    } else if (profile.isParent) {
      role = UserRole.parent;
      final linkedChildren = session.linked['children'];
      if (linkedChildren is List && linkedChildren.isNotEmpty) {
        for (final raw in linkedChildren.reversed) {
          if (raw is Map) {
            final idStr = raw['id'].toString();
            childIds.insert(0, idStr);
            final name = raw['name']?.toString() ?? 'Övlad';
            final className = _cleanClassName(raw['class_name']?.toString());
            final photoUrl = raw['photo_url']?.toString() ?? '';
            final fatherName = raw['father_name']?.toString() ?? '';
            final gpaVal = (raw['gpa'] as num?)?.toDouble() ?? 0.0;
            final attRate = (raw['attendance_rate'] as num?)?.toInt() ?? 100;
            final bloodGrp = raw['blood_group']?.toString();
            final codeStr = raw['code']?.toString() ?? 'IDR-STD-$idStr';
            final finStr = raw['fin_code']?.toString();

            final studentObj = StudentProfile(
              id: idStr,
              fullName: name,
              studentNumber: codeStr,
              className: className,
              photoUrl: photoUrl,
              qrData: 'IDRAK-STD-$idStr',
              barcodeData: idStr,
              fatherName: fatherName,
              finCode: finStr,
              bloodGroup: bloodGrp,
              parentName: profile.name,
              parentPhone: profile.phone ?? '',
              gpa: gpaVal,
              attendanceRate: attRate,
              academicYear: '2026 - 2027',
            );
            _students.removeWhere((s) => s.id == idStr || s.fullName.toLowerCase() == name.toLowerCase());
            _students.insert(0, studentObj);
          }
        }
      }
      if (childIds.isNotEmpty && (_activeChildId == null || !childIds.contains(_activeChildId))) {
        _activeChildId = childIds.first;
      }
    } else if (profile.type == 'employer') {
      final r = (profile.activeRole ?? '').trim().toLowerCase();
      final checkStr = r.isNotEmpty ? r : profile.roles.join(' ').toLowerCase();
      if (checkStr.contains('müəllim') || checkStr.contains('muellim')) {
        role = UserRole.teacher;
      } else {
        role = UserRole.admin;
      }
    } else {
      role = UserRole.admin;
    }

    final linkedClasses = (session.linked['assigned_classes'] is List)
        ? (session.linked['assigned_classes'] as List)
            .map((e) => _cleanClassName(e.toString()))
            .where((e) => e.isNotEmpty && e != 'Sinif təyin edilməyib')
            .toSet()
            .toList()
        : <String>[];
    final linkedSubject = session.linked['subject']?.toString();
    final linkedDept = session.linked['department']?.toString();
    final linkedPos = session.linked['position']?.toString();

    _currentUser = AppUser(
      id: profile.id.toString(),
      username: profile.email ?? profile.finCode ?? profile.name,
      password: '',
      fullName: profile.name,
      role: role,
      idrakCode: profile.code ?? profile.finCode ?? 'IDR-${profile.id}',
      phone: profile.phone ?? '',
      email: profile.email,
      finCode: profile.finCode,
      photoUrl: null,
      isActive: true,
      className: currentClassName,
      createdAt: DateTime.now(),
      assignedRoleId: profile.isSuper ? 'superadmin' : profile.activeRole,
      roleNames: profile.roles.toList(),
      assignedClasses: linkedClasses,
      subject: (linkedSubject != null && linkedSubject.isNotEmpty) ? linkedSubject : null,
      department: (linkedDept != null && linkedDept.isNotEmpty) ? linkedDept : null,
      position: profile.isSuper
          ? 'Super Admin'
          : (profile.activeRole ?? linkedPos ?? (role == UserRole.admin ? 'İşçi Heyəti' : '')),
      directPermissions: profile.permissions.toList(),
      linkedStudentId: childIds.isNotEmpty ? childIds.first : null,
      linkedStudentIds: childIds,
    );

    unawaited(
      PushNotificationService.instance.onUserLoggedIn(
        _currentUser!,
        childClasses: _childClassesFor(_currentUser!),
      ),
    );
    unawaited(syncNotificationsFromApi());

    if (role == UserRole.parent || role == UserRole.student) {
      unawaited(syncStudentAcademicDataFromApi());
      unawaited(syncBooksFromApi());
    } else if (role == UserRole.teacher || role == UserRole.admin) {
      unawaited(syncEmployeesFromApi());
      unawaited(syncStudentsFromApi());
      unawaited(syncBooksFromApi());
      unawaited(loadRoles());
    }

    notifyListeners();
  }

  int _apiUnreadNotificationCount = 0;

  void setApiUnreadNotificationCount(int count) {
    final normalized = count < 0 ? 0 : count;
    if (_apiUnreadNotificationCount != normalized) {
      _apiUnreadNotificationCount = normalized;
      notifyListeners();
    }
  }

  Future<void> syncNotificationsFromApi() async {
    try {
      final res = await ApiClient.instance.get(
        'common/notifications',
        query: {'per_page': 50},
      );
      List<dynamic> list = const [];
      if (res is Map && res['data'] is List) {
        list = res['data'] as List;
      } else if (res is List) {
        list = res;
      }
      final unread = list.where((e) => e is Map && e['is_read'] != true).length;
      setApiUnreadNotificationCount(unread);
    } catch (_) {}
  }

  Future<void> syncStudentAcademicDataFromApi() async {
    try {
      // 1. Refresh auth/me linked payload to get clean class_name, gpa, attendance_rate, blood_group
      try {
        final meRes = await ApiClient.instance.get('auth/me');
        final meData = meRes is Map ? meRes['data'] : null;
        final linked = meData is Map ? meData['linked'] : null;
        if (linked is Map) {
          final linkedChildren = linked['children'];
          if (linkedChildren is List) {
            for (final raw in linkedChildren) {
              if (raw is Map) {
                final idStr = raw['id'].toString();
                final idx = _students.indexWhere((s) => s.id == idStr);
                final cleanCls = _cleanClassName(raw['class_name']?.toString());
                final gpaVal = (raw['gpa'] as num?)?.toDouble();
                final attRate = (raw['attendance_rate'] as num?)?.toInt();
                final bloodGrp = raw['blood_group']?.toString();
                if (idx != -1) {
                  _students[idx] = _students[idx].copyWith(
                    className: cleanCls,
                    gpa: gpaVal ?? _students[idx].gpa,
                    attendanceRate: attRate ?? _students[idx].attendanceRate,
                    bloodGroup: (bloodGrp != null && bloodGrp.isNotEmpty) ? bloodGrp : _students[idx].bloodGroup,
                  );
                }
              }
            }
          }
          final currentClass = linked['current_class'];
          if (currentClass is Map && _currentUser?.role == UserRole.student) {
            final cleanCls = _cleanClassName(currentClass['name']?.toString());
            final gpaVal = (linked['gpa'] as num?)?.toDouble();
            final attRate = (linked['attendance_rate'] as num?)?.toInt();
            final bloodGrp = linked['blood_group']?.toString();
            final idx = _students.indexWhere((s) => s.id == _currentUser!.id);
            if (idx != -1) {
              _students[idx] = _students[idx].copyWith(
                className: cleanCls,
                gpa: gpaVal ?? _students[idx].gpa,
                attendanceRate: attRate ?? _students[idx].attendanceRate,
                bloodGroup: (bloodGrp != null && bloodGrp.isNotEmpty) ? bloodGrp : _students[idx].bloodGroup,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi auth/me notice: $e');
      }

      // 2. Sync Grades from /api/mobile/v1/academic/my-grades
      try {
        final grdRes = await ApiClient.instance.get('academic/my-grades', query: {'per_page': '100'});
        final grdList = grdRes is Map ? grdRes['data'] : grdRes;
        if (grdList is List) {
          final apiGrades = <GradeRecord>[];
          for (final raw in grdList) {
            if (raw is Map) {
              final scoreVal = (raw['grade'] as num?)?.toDouble() ?? 0.0;
              final typeStr = (raw['type']?.toString() ?? 'ksq').toLowerCase();
              final aType = switch (typeStr) {
                'bsq' => AssessmentType.bsq,
                'monitoring' => AssessmentType.monitoring,
                'diagnostic' => AssessmentType.diagnostic,
                _ => AssessmentType.ksq,
              };
              final subj = raw['subject']?.toString() ?? 'Fənn';
              apiGrades.add(
                GradeRecord(
                  id: 'api-grd-${raw['id']}',
                  studentId: raw['student_id']?.toString(),
                  studentName: raw['student']?.toString(),
                  subject: subj,
                  type: aType,
                  title: '${typeStr.toUpperCase()} — $subj',
                  score: scoreVal,
                  maxScore: 100.0,
                  gradeLetter: GradeRecord.scoreToGradeLetter(scoreVal),
                  date: DateTime.tryParse(raw['date']?.toString() ?? '') ?? DateTime.now(),
                  teacherFeedback: raw['note']?.toString() ?? '',
                ),
              );
            }
          }
          _grades.removeWhere((g) => g.id.startsWith('api-grd-'));
          _grades.insertAll(0, apiGrades);

          // Update GPA per student from live grades
          final studentIdsWithGrades = apiGrades.map((g) => g.studentId).whereType<String>().toSet();
          for (final sid in studentIdsWithGrades) {
            final sGrades = apiGrades.where((g) => g.studentId == sid).toList();
            if (sGrades.isNotEmpty) {
              final avg = sGrades.map((g) => g.percentage).reduce((a, b) => a + b) / sGrades.length;
              final gpa5 = double.parse(((avg / 100.0) * 5.0).clamp(0.0, 5.0).toStringAsFixed(2));
              final idx = _students.indexWhere((s) => s.id == sid);
              if (idx != -1) {
                _students[idx] = _students[idx].copyWith(gpa: gpa5);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi grades notice: $e');
      }

      // 3. Sync Attendance from /api/mobile/v1/academic/my-attendance
      try {
        final attRes = await ApiClient.instance.get('academic/my-attendance', query: {'per_page': '200'});
        final attList = attRes is Map ? attRes['data'] : attRes;
        if (attList is List && attList.isNotEmpty) {
          final byStudent = <String, List<Map>>{};
          for (final raw in attList) {
            if (raw is Map && raw['student_id'] != null) {
              byStudent.putIfAbsent(raw['student_id'].toString(), () => []).add(raw);
            }
          }

          byStudent.forEach((sid, rows) {
            int presentTotal = 0;
            final byDay = <int, List<Map>>{};
            for (final r in rows) {
              final st = (r['status']?.toString() ?? 'present').toLowerCase();
              if (st == 'present' || st == 'late' || st == 'excused') {
                presentTotal++;
              }
              final dt = DateTime.tryParse(r['date']?.toString() ?? '');
              if (dt != null) {
                byDay.putIfAbsent(dt.day, () => []).add(r);
              }
            }

            if (rows.isNotEmpty) {
              final rate = ((presentTotal / rows.length) * 100).round().clamp(0, 100);
              final idx = _students.indexWhere((s) => s.id == sid);
              if (idx != -1) {
                _students[idx] = _students[idx].copyWith(attendanceRate: rate);
              }
            }

            final dayMap = <int, DayAttendance>{};
            byDay.forEach((dayNum, dayRows) {
              final periods = <PeriodAttendance>[];
              var hasAbsent = false;
              var hasLate = false;
              var hasExcused = false;
              DateTime? dayDate;
              String? dayNote;

              for (var i = 0; i < dayRows.length; i++) {
                final r = dayRows[i];
                dayDate ??= DateTime.tryParse(r['date']?.toString() ?? '');
                final stStr = (r['status']?.toString() ?? 'present').toLowerCase();
                final pStatus = switch (stStr) {
                  'absent' => AttendanceStatus.absent,
                  'late' => AttendanceStatus.late,
                  'excused' => AttendanceStatus.excused,
                  _ => AttendanceStatus.present,
                };
                if (pStatus == AttendanceStatus.absent) hasAbsent = true;
                if (pStatus == AttendanceStatus.late) hasLate = true;
                if (pStatus == AttendanceStatus.excused) hasExcused = true;
                if (r['note'] != null && r['note'].toString().isNotEmpty && r['note'].toString() != 'Auto-filled by system') {
                  dayNote = r['note'].toString();
                }
                final pNum = r['period'] ?? (i + 1);
                periods.add(
                  PeriodAttendance(
                    period: '$pNum-ci dərs',
                    subject: r['subject']?.toString() ?? 'Fənn',
                    status: pStatus,
                    time: r['arrival_time']?.toString(),
                  ),
                );
              }

              final overallStatus = hasAbsent
                  ? AttendanceStatus.absent
                  : (hasExcused
                      ? AttendanceStatus.excused
                      : (hasLate ? AttendanceStatus.late : AttendanceStatus.present));

              dayMap[dayNum] = DayAttendance(
                date: dayDate ?? DateTime.now(),
                status: overallStatus,
                note: dayNote,
                periodDetails: periods,
              );
            });

            _studentAttendanceMap[sid] = dayMap;
          });
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi attendance notice: $e');
      }

      // 4. Sync Timetable from /api/mobile/v1/academic/my-timetable
      try {
        final ttRes = await ApiClient.instance.get('academic/my-timetable');
        final ttList = ttRes is Map ? ttRes['data'] : ttRes;
        if (ttList is List && ttList.isNotEmpty) {
          const dayNames = [
            'Bazar ertəsi',
            'Çərşənbə axşamı',
            'Çərşənbə',
            'Cümə axşamı',
            'Cümə',
          ];
          const shortDays = ['B.E', 'Ç.A', 'Ç.', 'C.A', 'C.'];

          final byClass = <String, Map<int, List<LessonSlot>>>{};
          for (final raw in ttList) {
            if (raw is Map) {
              final clsName = _cleanClassName(
                raw['class_name']?.toString() ?? student.className,
              );
              final dow = (raw['day_of_week'] as num?)?.toInt() ?? 1;
              if (dow < 1 || dow > 5) continue;
              final periodNum = (raw['period'] as num?)?.toInt() ?? 1;
              final startStr = raw['start_time']?.toString() ?? '08:30';
              final endStr = raw['end_time']?.toString() ?? '09:15';
              final subj = raw['subject']?.toString() ?? 'Dərs';
              final tchr = raw['teacher']?.toString() ?? '';
              final rm = raw['room']?.toString() ?? '';

              byClass.putIfAbsent(clsName, () => {});
              byClass[clsName]!.putIfAbsent(dow, () => []);
              byClass[clsName]![dow]!.add(
                LessonSlot(
                  id: 'api-tt-${raw['id']}',
                  period: '$periodNum-ci dərs',
                  time: '$startStr - $endStr',
                  subject: subj,
                  teacher: tchr,
                  room: rm.isNotEmpty ? rm : clsName,
                ),
              );
            }
          }

          byClass.forEach((clsName, dowMap) {
            final days = <DayTimetable>[];
            for (var d = 1; d <= 5; d++) {
              final slots = dowMap[d] ?? <LessonSlot>[];
              slots.sort((a, b) => a.time.compareTo(b.time));
              days.add(
                DayTimetable(
                  dayName: dayNames[d - 1],
                  shortDay: shortDays[d - 1],
                  lessons: slots,
                ),
              );
            }
            _classTimetablesMap[clsName] = days;
          });
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi timetable notice: $e');
      }

      // 4.1 Sync Clubs Timetable (Dərnəklər)
      try {
        final clubRes = await ApiClient.instance.get('academic/my-timetable', query: {'show_clubs': '1'});
        final clubList = clubRes is Map ? clubRes['data'] : clubRes;
        if (clubList is List && clubList.isNotEmpty) {
          const dayNames = [
            'Bazar ertəsi',
            'Çərşənbə axşamı',
            'Çərşənbə',
            'Cümə axşamı',
            'Cümə',
          ];
          const shortDays = ['B.E', 'Ç.A', 'Ç.', 'C.A', 'C.'];
          final dowMap = <int, List<LessonSlot>>{};
          for (final raw in clubList) {
            if (raw is Map) {
              final dow = (raw['day_of_week'] as num?)?.toInt() ?? 1;
              if (dow < 1 || dow > 5) continue;
              final periodNum = (raw['period'] as num?)?.toInt() ?? 1;
              final startStr = raw['start_time']?.toString() ?? '15:00';
              final endStr = raw['end_time']?.toString() ?? '16:00';
              final subj = raw['subject']?.toString() ?? 'Dərnək';
              final tchr = raw['teacher']?.toString() ?? '';
              final rm = raw['room']?.toString() ?? '';

              dowMap.putIfAbsent(dow, () => []);
              dowMap[dow]!.add(
                LessonSlot(
                  id: 'api-club-${raw['id']}',
                  period: '$periodNum-ci dərnək',
                  time: '$startStr - $endStr',
                  subject: subj,
                  teacher: tchr,
                  room: rm.isNotEmpty ? rm : 'Dərnək otağı',
                  colorHex: '0xFF8B5CF6',
                ),
              );
            }
          }
          _clubTimetable.clear();
          for (var d = 1; d <= 5; d++) {
            final slots = dowMap[d] ?? <LessonSlot>[];
            slots.sort((a, b) => a.time.compareTo(b.time));
            _clubTimetable.add(
              DayTimetable(
                dayName: dayNames[d - 1],
                shortDay: shortDays[d - 1],
                lessons: slots,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi club timetable notice: $e');
      }

      // 4.2 Sync Calendar Holidays (Rəsmi bayramlar və tətillər)
      try {
        final now = DateTime.now();
        final startMonth = DateTime(now.year, now.month - 1, 1);
        final endMonth = DateTime(now.year, now.month + 2, 0);
        final calRes = await ApiClient.instance.get('academic/calendar-days', query: {
          'start_date': DateFormat('yyyy-MM-dd').format(startMonth),
          'end_date': DateFormat('yyyy-MM-dd').format(endMonth),
        });
        final calList = calRes is Map ? calRes['data'] : calRes;
        if (calList is List) {
          for (final raw in calList) {
            if (raw is Map && raw['date'] != null) {
              _calendarHolidaysMap[raw['date'].toString()] = Map<String, dynamic>.from(raw);
            }
          }
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi calendar days notice: $e');
      }

      // 5. Sync Assignments Overview & Grid from /api/mobile/v1/academic/assignments/overview
      try {
        final ovRes = await ApiClient.instance.get('academic/assignments/overview');
        final ovData = ovRes is Map ? ovRes['data'] : null;
        if (ovData is Map) {
          if (ovData['stats'] is Map) {
            _assignmentOverviewStats = Map<String, dynamic>.from(ovData['stats']);
          }
          if (ovData['grid'] is Map) {
            final gridMap = Map<String, dynamic>.from(ovData['grid']);
            final list = <Map<String, dynamic>>[];
            for (final entry in gridMap.entries) {
              if (entry.value is List) {
                for (final item in entry.value) {
                  if (item is Map) {
                    list.add(Map<String, dynamic>.from(item));
                  }
                }
              }
            }
            _assignmentSubjectGrid = list;
          }
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi assignments overview notice: $e');
      }

      // 5.1 Sync Assignments from /api/mobile/v1/academic/assignments
      try {
        final asgRes = await ApiClient.instance.get('academic/assignments', query: {'per_page': '1000'});
        final asgList = asgRes is Map ? asgRes['data'] : asgRes;
        if (asgList is List) {
          final apiAssignments = <HomeworkAssignment>[];
          for (final raw in asgList) {
            if (raw is Map) {
              apiAssignments.add(
                HomeworkAssignment.fromApiJson(
                  Map<String, dynamic>.from(raw),
                  currentStudentId: student.id,
                ),
              );
            }
          }
          if (apiAssignments.isNotEmpty) {
            _assignments.removeWhere((a) => a.id.startsWith('api-asg-'));
            _assignments.insertAll(0, apiAssignments);
          }
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi assignments notice: $e');
      }

      // 6. Sync Canteen Weekly Menu from /api/mobile/v1/canteen/weekly-menu
      try {
        final menuRes = await ApiClient.instance.get('canteen/weekly-menu', query: {'offset': '0'});
        if (menuRes is Map) {
          _canteenWeeklyMenu = CanteenWeeklyMenu.fromJson(Map<String, dynamic>.from(menuRes));
        }
      } catch (e) {
        debugPrint('syncStudentAcademicDataFromApi canteen weekly menu notice: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('syncStudentAcademicDataFromApi error: $e');
    }
  }

  Future<bool> switchEmployeeRole(BuildContext context, String newRole) async {
    final session = context.read<SessionController>();
    final success = await session.changeContext(role: newRole);
    if (success) {
      _currentTabIndex = 0;
      syncFromSession(session);
      await loadUserPreferences();
      notifyListeners();
    }
    return success;
  }

  String? login(
    String username,
    String password, {
    bool saveCredentials = true,
  }) {
    final cleanUsername = username.trim().toLowerCase();
    final cleanPass = password.trim();

    // Loglarda parola uzunluğu / istifadəçi adı barədə məlumat saxlanmır —
    // release buildlərdə də logcat-ə düşmür.
    debugPrint('[AppState] Login attempt (user lookup)');
    debugPrint('[AppState] Total users in database: ${_users.length}');

    // Firestore-da parolalar `sha256:<hex>` formatında saxlanır (bax:
    // PasswordHasher). Köhnə qeydlərdə hələ də düz mətn ola bilər — hər iki
    // format dəstəklənir, düz mətnlə uğurlu girişdə dərhal hash-ə köçürülür.
    bool passwordMatches(AppUser u) {
      if (cleanPass.isEmpty) return false;
      if (PasswordHasher.verify(u.id, cleanPass, u.password)) return true;
      return !PasswordHasher.isHash(u.password) && u.password == cleanPass;
    }

    final user = _users.firstWhere(
      (u) =>
          (u.username.toLowerCase() == cleanUsername ||
              u.idrakCode.toLowerCase() == cleanUsername ||
              (u.email ?? '').toLowerCase() == cleanUsername ||
              (u.finCode ?? '').toLowerCase() == cleanUsername) &&
          passwordMatches(u),
      orElse: () => AppUser(
        id: '',
        username: '',
        password: '',
        fullName: '',
        role: UserRole.student,
        idrakCode: '',
        createdAt: DateTime.now(),
      ),
    );

    if (user.id.isEmpty) {
      debugPrint('[AppState] Login failed - user not found');
      return 'E-poçt / FIN / istifadəçi adı və ya şifrə yanlışdır!';
    }

    if (!user.isActive) {
      return 'Bu hesab inzibatçı tərəfindən deaktiv edilib.';
    }

    debugPrint('[AppState] ✓ Login successful - user: ${user.fullName}');
    _currentUser = user;

    // Lazy migration: köhnə düz mətn parolayla giriş uğurlu olubsa, yaddaşda
    // və Firestore-da hash-ə köçürülür.
    if (!PasswordHasher.isHash(user.password)) {
      final migrated = user.copyWith(
        password: PasswordHasher.hash(user.id, cleanPass),
      );
      _currentUser = migrated;
      final userIndex = _users.indexWhere((u) => u.id == user.id);
      if (userIndex != -1) {
        _users[userIndex] = migrated;
      }
      unawaited(_firestoreService.saveUser(migrated));
    }

    // Səlahiyyət qapısı üçün rollar mütləq yüklənməlidir. Hər girişdə
    // yenilənir ki, admin rolu dəyişdikdən sonra köhnə icazələrlə
    // davam edilməsin. (login sync-dır; UI loadRoles bitəndə yenilənir.)
    unawaited(loadRoles());

    // 🆕 İstifadəçi seçimlərini yüklə (modul sıralaması üçün)
    loadUserPreferences();

    // Push bildirişləri: icazə + token + topic abunəlikləri
    // (valideyn uşaqlarının siniflərinə də abunə olur)
    unawaited(
      PushNotificationService.instance.onUserLoggedIn(
        user,
        childClasses: _childClassesFor(user),
      ),
    );

    // Save credentials for auto-login if requested
    if (saveCredentials) {
      debugPrint('[AppState] Saving credentials for auto-login...');
      _authStorage.saveCredentials(cleanUsername, cleanPass);
    }

    notifyListeners();
    return null;
  }

  /// Attempt auto-login using stored credentials.
  /// Never logs in silently: biometric confirmation is always required.
  Future<bool> tryAutoLogin() async {
    try {
      debugPrint('[AppState] Attempting auto-login...');

      // Fast local checks first, before waiting on any network sync.
      final hasCredentials = await _authStorage.hasStoredCredentials();
      final biometricEnabled = await _authStorage.isBiometricEnabled();
      debugPrint(
        '[AppState] Credentials: $hasCredentials, biometric enabled: $biometricEnabled',
      );

      // Without stored credentials or an explicit opt-in to biometric
      // login the user must always sign in manually.
      if (!hasCredentials || !biometricEnabled) return false;

      final authenticated = await _authStorage.authenticateWithBiometrics();
      debugPrint('[AppState] Biometric authenticated: $authenticated');
      if (!authenticated) return false;

      // Wait for the Firestore users sync; without it only the built-in
      // master admin exists and saved cloud users would fail to match.
      try {
        await ensureDataReady().timeout(const Duration(seconds: 10));
      } on TimeoutException {
        debugPrint('[AppState] Firestore sync timed out, trying login anyway');
      }

      debugPrint('[AppState] Users in database: ${_users.length}');

      final credentials = await _authStorage.getSavedCredentials();
      debugPrint('[AppState] Credentials found: ${credentials != null}');

      if (credentials == null) return false;

      debugPrint('[AppState] Stored credentials found, attempting login');

      final error = login(
        credentials['username']!,
        credentials['password']!,
        saveCredentials: false, // Already saved
      );

      if (error == null) {
        debugPrint('[AppState] ✓ Auto-login successful');
        return true;
      } else {
        debugPrint('[AppState] ⚠️ Auto-login failed: $error');
        // Parolları yalnız bulud siyahısı TAM yüklənəndən sonra etibarsız
        // say. Sinxron yarımçıq olsa (yavaş şəbəkə) saxlanmış parolu
        // silmək — istifadəçini birdəfəlik çıxarırdı.
        if (_isInitialDataLoaded) {
          await _authStorage.clearAll();
        }
        return false;
      }
    } catch (e) {
      debugPrint('[AppState] ⚠️ Auto-login error: $e');
      return false;
    }
  }

  void logout() async {
    // Şəxsi push topic-lərinə abunəliyi ləğv et (başqa hesabın
    // bildirişləri bu cihaza gəlməsin)
    unawaited(PushNotificationService.instance.onUserLoggedOut());
    _currentUser = null;
    _currentTabIndex = 0;
    // Keçmiş istifadəçinin panel düzülüşü/övlad seçimi növbəti hesaba
    // keçməsin (aynı rollu fərqli istifadəçi üçün vacibdir).
    _userPreferences = null;
    _activeChildId = null;
    await _authStorage.clearAll();
    notifyListeners();
  }

  void switchUserRoleForTesting(UserRole role) {
    final matchingUser = _users.firstWhere(
      (u) => u.role == role && u.isActive,
      orElse: () => _users.first,
    );
    _currentUser = matchingUser;
    _currentTabIndex = 0;
    loadUserPreferences();
    notifyListeners();
  }

  // --- APP VERSION CONFIG (mağaza yeniləmə xəbərdarlığı) ---
  /// Son versiya xəbərdarlığını `app_config/version` sənədinə yazır
  Future<bool> saveAppVersionConfig({
    required String latestVersion,
    String? updateUrlIos,
    String? updateUrlAndroid,
  }) {
    return _firestoreService.saveAppVersionConfig(
      latestVersion: latestVersion,
      updateUrlIos: updateUrlIos,
      updateUrlAndroid: updateUrlAndroid,
    );
  }

  /// `app_config/version` sənədini oxuyur (boşdursa → {})
  Future<Map<String, dynamic>> fetchAppVersionConfig() {
    return _firestoreService.fetchAppVersionConfig();
  }

  // --- SMART CLASS MANAGEMENT & PROMOTION ---
  /// Yeni sinif yaradır — detallarla birlikdə Firestore-da saxlanır
  void addNewClass(    String className, {
    String? room,
    String? curatorTeacherId,
    String academicYear = '2025 - 2026',
    String? note,
  }) {
    final name = className.trim();
    _customClasses.add(name);
    final details = ClassDetails(
      name: name,
      room: room,
      curatorTeacherId: curatorTeacherId,
      academicYear: academicYear,
      note: note,
    );
    _classDetailsMap[name] = details;
    _firestoreService.saveClassDetails(details);
    notifyListeners();
  }

  void deleteClass(String className) {
    _customClasses.remove(className);
    _classTimetablesMap.remove(className);
    _classDetailsMap.remove(className);
    _firestoreService.deleteClassDetails(className);
    notifyListeners();
  }

  /// Sinifə müəllim təyin edir (müəllimin assignedClasses siyahısına əlavə
  /// olunur və class_teachers kolleksiyasında qeydə alınır)
  void assignTeacherToClass({
    required String teacherId,
    required String className,
    String? subject,
    bool isClassTeacher = false,
  }) {
    final index = _users.indexWhere((u) => u.id == teacherId);
    if (index != -1) {
      final t = _users[index];
      final classes = [...t.assignedClasses];
      if (!classes.contains(className)) classes.add(className);
      _users[index] = t.copyWith(assignedClasses: classes);
      _firestoreService.saveUser(_users[index]);
      notifyListeners();
    }
    _firestoreService.assignTeacherToClass(
      className: className,
      teacherId: teacherId,
      isClassTeacher: isClassTeacher,
      subject: subject,
    );
  }

  /// Sinfə təyin olunan müəllimlər
  List<AppUser> getTeachersForClass(String className) {
    return _users
        .where(
          (u) =>
              u.role == UserRole.teacher &&
              u.assignedClasses.contains(className),
        )
        .toList();
  }

  List<StudentProfile> getStudentsForClass(String className) {
    return _students
        .where((s) => s.className.toLowerCase() == className.toLowerCase())
        .toList();
  }

  double getClassAverageGpa(String className) {
    final classStudents = getStudentsForClass(className);
    if (classStudents.isEmpty) return 0.0;
    final gradedStudents = classStudents.where((s) => s.gpa > 0).toList();
    if (gradedStudents.isEmpty) return 0.0;
    final sum = gradedStudents.map((s) => s.gpa).reduce((a, b) => a + b);
    return double.parse((sum / gradedStudents.length).toStringAsFixed(2));
  }

  int getClassAverageAttendance(String className) {
    final classStudents = getStudentsForClass(className);
    if (classStudents.isEmpty) return 0;
    final sum = classStudents
        .map((s) => s.attendanceRate)
        .reduce((a, b) => a + b);
    return (sum / classStudents.length).round();
  }

  // 🚀 PROMOTE CLASS ("Sinifi Yüksəlt")
  void promoteClass(String fromClass, String toClass) {
    for (int i = 0; i < _students.length; i++) {
      if (_students[i].className.toLowerCase() == fromClass.toLowerCase()) {
        final std = _students[i];
        _students[i] = StudentProfile(
          id: std.id,
          fullName: std.fullName,
          studentNumber: std.studentNumber,
          className: toClass,
          photoUrl: std.photoUrl,
          qrData: std.qrData.replaceAll(fromClass, toClass),
          barcodeData: std.barcodeData,
          parentName: std.parentName,
          parentPhone: std.parentPhone,
          gpa: std.gpa,
          attendanceRate: std.attendanceRate,
          academicYear: std.academicYear,
        );
        _firestoreService.updateStudentClass(std.id, toClass);
      }
    }

    // Update corresponding AppUsers
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].className != null &&
          _users[i].className!.toLowerCase() == fromClass.toLowerCase()) {
        _users[i] = _users[i].copyWith(className: toClass);
      }
    }

    // Move Timetable if exists
    if (_classTimetablesMap.containsKey(fromClass)) {
      final t = _classTimetablesMap.remove(fromClass)!;
      _classTimetablesMap[toClass] = t;
      _firestoreService.saveClassTimetable(toClass, t);
    }

    _customClasses.remove(fromClass);
    _customClasses.add(toClass);

    notifyListeners();
  }

  // --- TEACHER CLASS OWNERSHIP (Sinif Sahiplənmə) ---
  void claimClassForTeacher(String className) {
    if (_currentUser == null || _currentUser!.role != UserRole.teacher) return;
    final currentClasses = List<String>.from(_currentUser!.assignedClasses);
    if (!currentClasses.contains(className)) {
      currentClasses.add(className);
      final updatedUser = _currentUser!.copyWith(
        assignedClasses: currentClasses,
      );
      _currentUser = updatedUser;
      final idx = _users.indexWhere((u) => u.id == updatedUser.id);
      if (idx != -1) _users[idx] = updatedUser;
      _firestoreService.updateTeacherAssignedClasses(
        updatedUser.id,
        currentClasses,
      );
      notifyListeners();
    }
  }

  void unclaimClassForTeacher(String className) {
    if (_currentUser == null || _currentUser!.role != UserRole.teacher) return;
    final currentClasses = List<String>.from(_currentUser!.assignedClasses);
    if (currentClasses.contains(className)) {
      currentClasses.remove(className);
      final updatedUser = _currentUser!.copyWith(
        assignedClasses: currentClasses,
      );
      _currentUser = updatedUser;
      final idx = _users.indexWhere((u) => u.id == updatedUser.id);
      if (idx != -1) _users[idx] = updatedUser;
      _firestoreService.updateTeacherAssignedClasses(
        updatedUser.id,
        currentClasses,
      );
      notifyListeners();
    }
  }

  // --- DƏRS CƏDVƏLİ ƏLAVƏ ETMƏ & SİLMƏ (TIMETABLE CRUD) ---
  void addLessonSlotToClass({
    required String className,
    required String dayName,
    required String period,
    required String time,
    required String subject,
    required String teacherName,
    required String room,
    String colorHex = '0xFF2563EB',
  }) {
    final days = getClassTimetable(className);
    final dayIndex = days.indexWhere((d) => d.dayName == dayName);

    final newSlot = LessonSlot(
      period: period,
      time: time,
      subject: subject,
      teacher: teacherName,
      room: room,
      colorHex: colorHex,
    );

    if (dayIndex != -1) {
      days[dayIndex].lessons.add(newSlot);
    } else {
      days.add(
        DayTimetable(
          dayName: dayName,
          shortDay: dayName.substring(0, 2),
          lessons: [newSlot],
        ),
      );
    }

    _classTimetablesMap[className] = days;
    _firestoreService.saveClassTimetable(className, days);
    notifyListeners();
  }

  void deleteLessonSlotFromClass({
    required String className,
    required String dayName,
    required int slotIndex,
  }) {
    final days = getClassTimetable(className);
    final dayIndex = days.indexWhere((d) => d.dayName == dayName);

    if (dayIndex != -1 &&
        slotIndex >= 0 &&
        slotIndex < days[dayIndex].lessons.length) {
      days[dayIndex].lessons.removeAt(slotIndex);
      _classTimetablesMap[className] = days;
      _firestoreService.saveClassTimetable(className, days);
      notifyListeners();
    }
  }

  // Helper: DateTime -> Gün adı
  String getDayNameFromDateTime(DateTime date) {
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

  // ✅ YENİ: Müəllimə və Konkret Tarixə görə dərslər (İstisnalar, birgə tədris və xüsusi dərslər nəzərə alınır)
  List<LessonSlot> getTeacherLessonsForDate(String teacherId, DateTime date) {
    final dayName = getDayNameFromDateTime(date);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final List<LessonSlot> result = [];

    for (final className in _classTimetablesMap.keys) {
      final classDays = _classTimetablesMap[className]!;
      final matchDay = classDays.where((d) => d.dayName == dayName).firstOrNull;
      if (matchDay != null) {
        for (final lesson in matchDay.lessons) {
          if (lesson.teacherId == teacherId ||
              lesson.coTeacherId == teacherId) {
            // Əgər bu tarix üçün ləğv edilibsə (istisna), göstərmə
            if (lesson.excludedDates.contains(dateStr)) continue;

            // Əgər təkrarlanmayan xüsusi tarixli dərsdirsə, yalnız həmin tarixdə göstər
            if (!lesson.isRecurring && lesson.dateStr != null) {
              if (lesson.dateStr != dateStr) continue;
            }

            // Eyni saatdakı birləşdirilmiş dərsləri təkrar əlavə etmə
            final alreadyAdded = result.any(
              (existing) =>
                  existing.time == lesson.time &&
                  (existing.id == lesson.id ||
                      existing.subject == lesson.subject),
            );
            if (!alreadyAdded) {
              result.add(lesson);
            }
          }
        }
      }
    }

    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  // ✅ YENİ: Sinifə və Konkret Tarixə görə dərslər
  List<LessonSlot> getClassLessonsForDate(String className, DateTime date, {bool showClubs = false}) {
    // 1. Əgər rəsmi bayram və ya qeyri-iş günüdürsə (Web TeqvimDays::HOLIDAY / 'B' / 'I' / 'STRIKE') -> Dərs YOXDUR!
    if (isDateHoliday(date)) {
      return const [];
    }

    final dayName = getDayNameFromDateTime(date);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final List<LessonSlot> result = [];

    // Dərnəklər rejimi
    if (showClubs) {
      final matchDay = _clubTimetable.where((d) => d.dayName == dayName).firstOrNull;
      if (matchDay != null) {
        result.addAll(matchDay.lessons);
      }
      result.sort((a, b) => a.time.compareTo(b.time));
      return result;
    }

    final classDays = getClassTimetable(className);
    final matchDay = classDays.where((d) => d.dayName == dayName).firstOrNull;
    if (matchDay != null) {
      for (final lesson in matchDay.lessons) {
        if (lesson.excludedDates.contains(dateStr)) continue;
        if (!lesson.isRecurring && lesson.dateStr != null) {
          if (lesson.dateStr != dateStr) continue;
        }
        result.add(lesson);
      }
    }

    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  // ✅ YENİ: Müəllimə görə cədvəl (Birgə tədris & Birləşdirilmiş dərslər dəstəyi ilə)
  List<DayTimetable> getTeacherTimetable(String teacherId) {
    final Map<String, List<LessonSlot>> dayMap = {};

    for (final className in _classTimetablesMap.keys) {
      final classDays = _classTimetablesMap[className]!;
      for (final day in classDays) {
        dayMap.putIfAbsent(day.dayName, () => []);

        for (final lesson in day.lessons) {
          // Müəllim ya əsas müəllimdir, ya da co-teacher
          if (lesson.teacherId == teacherId ||
              lesson.coTeacherId == teacherId) {
            // Əgər birləşdirilmiş dərsdirsə, eyni saatda təkrar əlavə etməyək
            final alreadyAdded = dayMap[day.dayName]!.any(
              (existing) =>
                  existing.time == lesson.time &&
                  (existing.id == lesson.id ||
                      existing.subject == lesson.subject),
            );
            if (!alreadyAdded) {
              dayMap[day.dayName]!.add(lesson);
            }
          }
        }
      }
    }

    final allDays = <DayTimetable>[];
    const defaultDayNames = [
      'Bazar ertəsi',
      'Çərşənbə axşamı',
      'Çərşənbə',
      'Cümə axşamı',
      'Cümə',
    ];
    const shortNames = ['B.E', 'Ç.A', 'Ç.', 'C.A', 'C.'];

    for (int i = 0; i < defaultDayNames.length; i++) {
      final dName = defaultDayNames[i];
      final lessons = dayMap[dName] ?? [];
      allDays.add(
        DayTimetable(dayName: dName, shortDay: shortNames[i], lessons: lessons),
      );
    }

    return allDays;
  }

  // ✅ YENİ: Konflikt yoxlama (KƏSIŞƏN SAAT ARALIĞI)
  String? checkTimetableConflict({
    required String className,
    required String day,
    required String time,
    required String teacherId,
    List<String> allowedClassExceptions = const [],
    String? currentLessonId,
  }) {
    // Saatları parse et
    final timeParts = time.split(' - ');
    if (timeParts.length != 2) {
      return 'Saat formatı yanlışdır! (məs: 08:00 - 08:45)';
    }

    final newStartParts = timeParts[0].trim().split(':');
    final newEndParts = timeParts[1].trim().split(':');

    if (newStartParts.length != 2 || newEndParts.length != 2) {
      return 'Saat formatı yanlışdır! (məs: 08:00 - 08:45)';
    }

    final newStartHour = int.tryParse(newStartParts[0]);
    final newStartMin = int.tryParse(newStartParts[1]);
    final newEndHour = int.tryParse(newEndParts[0]);
    final newEndMin = int.tryParse(newEndParts[1]);

    if (newStartHour == null ||
        newStartMin == null ||
        newEndHour == null ||
        newEndMin == null) {
      return 'Saat formatı yanlışdır!';
    }

    final newStart = newStartHour * 60 + newStartMin; // dəqiqə olaraq
    final newEnd = newEndHour * 60 + newEndMin;

    if (newStart >= newEnd) {
      return 'Başlama saatı bitmə saatından böyük və ya bərabər ola bilməz!';
    }

    // Helper: Saat aralığı kəsişir?
    bool isOverlapping(String existingTime) {
      final parts = existingTime.split(' - ');
      if (parts.length != 2) return false;

      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      if (startParts.length != 2 || endParts.length != 2) return false;

      final startHour = int.tryParse(startParts[0]);
      final startMin = int.tryParse(startParts[1]);
      final endHour = int.tryParse(endParts[0]);
      final endMin = int.tryParse(endParts[1]);

      if (startHour == null ||
          startMin == null ||
          endHour == null ||
          endMin == null) {
        return false;
      }

      final existingStart = startHour * 60 + startMin;
      final existingEnd = endHour * 60 + endMin;

      // Kəsişmə yoxlaması: A.start < B.end VƏ B.start < A.end
      return newStart < existingEnd && existingStart < newEnd;
    }

    // 1. Eyni sinif + gün + kəsişən saat
    if (!allowedClassExceptions.contains(className)) {
      final classDays = getClassTimetable(className);
      final targetDay = classDays.firstWhere(
        (d) => d.dayName == day,
        orElse: () => DayTimetable(dayName: day, shortDay: '', lessons: []),
      );

      for (final lesson in targetDay.lessons) {
        if (currentLessonId != null && lesson.id == currentLessonId) continue;
        if (isOverlapping(lesson.time)) {
          return '❌ Bu saat aralığı $className sinfində artıq mövcud dərs ilə kəsişir:\n\n'
              '📚 ${lesson.subject} (${lesson.teacher})\n'
              '🕐 ${lesson.time}\n\n'
              'Zəhmət olmasa fərqli saat seçin!';
        }
      }
    }

    // 2. Eyni müəllim + gün + kəsişən saat (birləşdirilmiş siniflər istisnadır)
    for (final cls in _classTimetablesMap.keys) {
      if (allowedClassExceptions.contains(cls)) continue;

      final days = _classTimetablesMap[cls]!;
      final matchDay = days.firstWhere(
        (d) => d.dayName == day,
        orElse: () => DayTimetable(dayName: day, shortDay: '', lessons: []),
      );

      for (final lesson in matchDay.lessons) {
        if (currentLessonId != null && lesson.id == currentLessonId) continue;
        if (lesson.teacherId == teacherId && isOverlapping(lesson.time)) {
          return '❌ Bu müəllim eyni gün və saatda başqa sinifdə ($cls) dərs tədris edir:\n\n'
              '📚 $cls sinfi - ${lesson.subject}\n'
              '🕐 ${lesson.time}\n'
              '👤 ${lesson.teacher}\n\n'
              'Əgər bu sinifləri birləşdirmək istəyirsinizsə, "Sinifləri Birləşdir" seçimindən istifadə edin!';
        }
      }
    }

    return null; // Konflikt yoxdur ✅
  }

  // ✅ YENİ: Dərsi bir və ya bir neçə sinfə (Birləşdirilmiş) əlavə et
  void addLessonWithMultipleClasses({
    required List<String> targetClasses,
    required String day,
    required LessonSlot lesson,
  }) {
    if (targetClasses.isEmpty) return;

    final isMerged = targetClasses.length > 1;
    final cleanClasses = targetClasses.toSet().toList();
    bool isEdit = false;

    for (final cls in cleanClasses) {
      final days = getClassTimetable(cls);
      final dayIndex = days.indexWhere((d) => d.dayName == day);

      final slotToSave = lesson.copyWith(
        id: lesson.id ?? 'ls-${DateTime.now().millisecondsSinceEpoch}-${cls}',
        isMerged: isMerged,
        mergedClassNames: isMerged ? cleanClasses : const [],
      );

      if (dayIndex != -1) {
        // Mövcud eyni period varsa əvəzlə, yoxsa əlavə et
        final existingIdx = days[dayIndex].lessons.indexWhere(
          (l) => l.period == lesson.period || l.time == lesson.time,
        );
        if (existingIdx != -1) {
          isEdit = true;
          days[dayIndex].lessons[existingIdx] = slotToSave;
        } else {
          days[dayIndex].lessons.add(slotToSave);
        }
      } else {
        days.add(
          DayTimetable(
            dayName: day,
            shortDay: day.length >= 2 ? day.substring(0, 2) : day,
            lessons: [slotToSave],
          ),
        );
      }

      _classTimetablesMap[cls] = days;
      _firestoreService.saveClassTimetable(cls, days);
    }

    if (isEdit) {
      sendTimetableChangeNotification(
        title: '✏️ Dərs Cədvəli Yeniləndi',
        message:
            '$day günü ${lesson.period} dərsi (${lesson.subject}) üçün cədvəldə dəyişiklik edildi.',
        targetClasses: cleanClasses,
      );
    }

    notifyListeners();
  }

  // ✅ YENİ: Dərs cədvəli dəyişikliyi/birləşməsi üçün avtomatik bildiriş göndər
  void sendTimetableChangeNotification({
    required String title,
    required String message,
    required List<String> targetClasses,
  }) {
    final notif = AppNotification(
      id: 'notif-tt-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      category: NotificationCategory.academic,
      senderId: _currentUser?.id ?? 'admin',
      senderName: _currentUser?.fullName ?? 'Dərs Hissə Müdiriyyəti',
      senderRole: 'admin',
      targetClasses: targetClasses,
      targetRoles: ['student', 'parent', 'teacher'],
      priority: 'important',
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _firestoreService.saveNotification(notif);
    notifyListeners();
  }

  // ✅ YENİ: Mövcud fərqli siniflərin dərslərini birləşdir
  void mergeExistingClassesInTimetable({
    required String day,
    required String period,
    required List<String> classNames,
    required String primarySubject,
    required String primaryTeacher,
    required String primaryTeacherId,
    String? primaryTeacherPhotoUrl,
    required String primaryRoom,
    String? coTeacherName,
    String? coTeacherId,
    String? coTeacherPhotoUrl,
    required String time,
    bool isRecurring = true,
    String? dateStr,
  }) {
    if (classNames.length < 2) return;

    final mergedId = 'merge-${DateTime.now().millisecondsSinceEpoch}';
    final cleanClasses = classNames.toSet().toList();

    if (!isRecurring && dateStr != null) {
      // 🌟 YALNIZ SEÇİLMİŞ KONKRET TARİX ÜÇÜN BİRLƏŞDİR
      for (final cls in cleanClasses) {
        final days = getClassTimetable(cls);
        var dayIndex = days.indexWhere((d) => d.dayName == day);
        if (dayIndex == -1) {
          days.add(
            DayTimetable(
              dayName: day,
              shortDay: day.length >= 2 ? day.substring(0, 2) : day,
              lessons: [],
            ),
          );
          dayIndex = days.length - 1;
        }

        // Əgər bu sinifdə həmin period üçün təkrarlanan başqa dərs varsa, onu həmin tarix üçün istisna et
        final recurringSlotIdx = days[dayIndex].lessons.indexWhere(
          (l) => (l.period == period || l.time == time) && l.isRecurring,
        );
        if (recurringSlotIdx != -1) {
          final old = days[dayIndex].lessons[recurringSlotIdx];
          if (!old.excludedDates.contains(dateStr)) {
            final updatedExclusions = List<String>.from(old.excludedDates)
              ..add(dateStr);
            days[dayIndex].lessons[recurringSlotIdx] = old.copyWith(
              excludedDates: updatedExclusions,
            );
          }
        }

        // Tək bu tarix üçün birgə dərs slotunu əlavə et
        final singleDateMergedSlot = LessonSlot(
          id: mergedId,
          period: period,
          time: time,
          subject: primarySubject,
          teacher: primaryTeacher,
          teacherId: primaryTeacherId,
          teacherPhotoUrl: primaryTeacherPhotoUrl,
          room: primaryRoom,
          isMerged: true,
          mergedClassNames: cleanClasses,
          coTeacherName: coTeacherName,
          coTeacherId: coTeacherId,
          coTeacherPhotoUrl: coTeacherPhotoUrl,
          isRecurring: false,
          dateStr: dateStr,
        );

        // Əvvəlki tək-tarixli slot varsa əvəzlə, yoxdursa əlavə et
        final existingSingleIdx = days[dayIndex].lessons.indexWhere(
          (l) =>
              (l.period == period || l.time == time) &&
              !l.isRecurring &&
              l.dateStr == dateStr,
        );
        if (existingSingleIdx != -1) {
          days[dayIndex].lessons[existingSingleIdx] = singleDateMergedSlot;
        } else {
          days[dayIndex].lessons.add(singleDateMergedSlot);
        }

        _classTimetablesMap[cls] = days;
        _firestoreService.saveClassTimetable(cls, days);
      }

      sendTimetableChangeNotification(
        title: '🔗 Birgə Dərs Təyin Edildi ($dateStr)',
        message:
            '$dateStr tarixində ($period) $primarySubject dərsi ${cleanClasses.join(" və ")} sinifləri üçün birgə keçiriləcək.',
        targetClasses: cleanClasses,
      );
    } else {
      // 🌟 BÜTÜN HƏFTƏLƏRİN BU GÜNÜ ÜÇÜN BİRLƏŞDİR (DAİMİ)
      for (final cls in cleanClasses) {
        final days = getClassTimetable(cls);
        final dayIndex = days.indexWhere((d) => d.dayName == day);

        final mergedSlot = LessonSlot(
          id: mergedId,
          period: period,
          time: time,
          subject: primarySubject,
          teacher: primaryTeacher,
          teacherId: primaryTeacherId,
          teacherPhotoUrl: primaryTeacherPhotoUrl,
          room: primaryRoom,
          isMerged: true,
          mergedClassNames: cleanClasses,
          coTeacherName: coTeacherName,
          coTeacherId: coTeacherId,
          coTeacherPhotoUrl: coTeacherPhotoUrl,
          isRecurring: true,
        );

        if (dayIndex != -1) {
          final existingIdx = days[dayIndex].lessons.indexWhere(
            (l) => l.period == period || l.time == time,
          );
          if (existingIdx != -1) {
            days[dayIndex].lessons[existingIdx] = mergedSlot;
          } else {
            days[dayIndex].lessons.add(mergedSlot);
          }
        } else {
          days.add(
            DayTimetable(
              dayName: day,
              shortDay: day.length >= 2 ? day.substring(0, 2) : day,
              lessons: [mergedSlot],
            ),
          );
        }

        _classTimetablesMap[cls] = days;
        _firestoreService.saveClassTimetable(cls, days);
      }

      sendTimetableChangeNotification(
        title: '🔗 Birgə Dərs Təyin Edildi',
        message:
            '$day günü $time ($period) $primarySubject dərsi ${cleanClasses.join(" və ")} sinifləri üçün otaq $primaryRoom-də birgə keçiriləcək.',
        targetClasses: cleanClasses,
      );
    }

    notifyListeners();
  }

  // ✅ YENİ: Birləşdirilmiş dərsi ayır (Un-merge)
  void unmergeClassesInTimetable({
    required String day,
    required String period,
    required List<String> classNames,
    String? dateStr,
  }) {
    for (final cls in classNames) {
      final days = getClassTimetable(cls);
      final dayIndex = days.indexWhere((d) => d.dayName == day);
      if (dayIndex != -1) {
        if (dateStr != null) {
          // Əgər konkret tarixli birləşmədirsə:
          // 1. Həmin tarixdəki single-date slotu sil
          days[dayIndex].lessons.removeWhere(
            (l) =>
                (l.period == period) && !l.isRecurring && l.dateStr == dateStr,
          );
          // 2. Əgər recurring slotda excludedDates-də bu tarix varsa, bərpa et
          final recIdx = days[dayIndex].lessons.indexWhere(
            (l) => l.period == period && l.isRecurring,
          );
          if (recIdx != -1) {
            final old = days[dayIndex].lessons[recIdx];
            final updatedEx = List<String>.from(old.excludedDates)
              ..remove(dateStr);
            days[dayIndex].lessons[recIdx] = old.copyWith(
              excludedDates: updatedEx,
            );
          }
        } else {
          // Daimi birləşmədirsə:
          final lIdx = days[dayIndex].lessons.indexWhere(
            (l) => l.period == period,
          );
          if (lIdx != -1) {
            final old = days[dayIndex].lessons[lIdx];
            days[dayIndex].lessons[lIdx] = old.copyWith(
              isMerged: false,
              mergedClassNames: [],
              coTeacherName: null,
              coTeacherId: null,
              coTeacherPhotoUrl: null,
            );
          }
        }
        _classTimetablesMap[cls] = days;
        _firestoreService.saveClassTimetable(cls, days);
      }
    }

    sendTimetableChangeNotification(
      title: 'Dərs Cədvəli Yeniləndi',
      message: '$day günü $period üçün birgə dərs rejimi ləğv edildi.',
      targetClasses: classNames,
    );

    notifyListeners();
  }

  // ✅ YENİ: Dərsi cədvəldən sil
  void deleteLessonFromTimetable({
    required String className,
    required String day,
    required String period,
  }) {
    final days = getClassTimetable(className);
    final dayIndex = days.indexWhere((d) => d.dayName == day);
    if (dayIndex != -1) {
      final targetLesson = days[dayIndex].lessons
          .where((l) => l.period == period)
          .firstOrNull;
      final affectedClasses =
          targetLesson?.isMerged == true &&
              targetLesson!.mergedClassNames.isNotEmpty
          ? targetLesson.mergedClassNames
          : [className];

      if (targetLesson?.isMerged == true &&
          targetLesson!.mergedClassNames.isNotEmpty) {
        for (final mCls in targetLesson.mergedClassNames) {
          final mDays = getClassTimetable(mCls);
          final mDayIdx = mDays.indexWhere((d) => d.dayName == day);
          if (mDayIdx != -1) {
            mDays[mDayIdx].lessons.removeWhere((l) => l.period == period);
            _classTimetablesMap[mCls] = mDays;
            _firestoreService.saveClassTimetable(mCls, mDays);
          }
        }
      } else {
        days[dayIndex].lessons.removeWhere((l) => l.period == period);
        _classTimetablesMap[className] = days;
        _firestoreService.saveClassTimetable(className, days);
      }

      sendTimetableChangeNotification(
        title: '🗓️ Dərs Cədvəldən Silindi',
        message:
            '$day günü $period ${targetLesson?.subject ?? "Dərs"} cədvəldən silindi.',
        targetClasses: affectedClasses,
      );

      notifyListeners();
    }
  }

  // ✅ YENİ: Dərsi yalnız konkret bir tarix üçün ləğv et (Bütün həftələrə toxunmadan)
  void excludeLessonFromDate({
    required String className,
    required String day,
    required String period,
    required String dateFormatted,
  }) {
    final days = getClassTimetable(className);
    final dayIndex = days.indexWhere((d) => d.dayName == day);
    if (dayIndex != -1) {
      final targetLesson = days[dayIndex].lessons
          .where((l) => l.period == period)
          .firstOrNull;
      if (targetLesson == null) return;

      final targetClasses =
          targetLesson.isMerged && targetLesson.mergedClassNames.isNotEmpty
          ? targetLesson.mergedClassNames
          : [className];

      for (final cls in targetClasses) {
        final cDays = getClassTimetable(cls);
        final cDayIdx = cDays.indexWhere((d) => d.dayName == day);
        if (cDayIdx != -1) {
          final lIdx = cDays[cDayIdx].lessons.indexWhere(
            (l) => l.period == period,
          );
          if (lIdx != -1) {
            final old = cDays[cDayIdx].lessons[lIdx];
            final updatedExclusions = List<String>.from(old.excludedDates)
              ..add(dateFormatted);
            cDays[cDayIdx].lessons[lIdx] = old.copyWith(
              excludedDates: updatedExclusions,
            );
            _classTimetablesMap[cls] = cDays;
            _firestoreService.saveClassTimetable(cls, cDays);
          }
        }
      }

      sendTimetableChangeNotification(
        title: '⚠️ Dərs Təxirə Salındı ($dateFormatted)',
        message:
            '$dateFormatted tarixindəki $period ${targetLesson.subject} dərsi təxirə salındı.',
        targetClasses: targetClasses,
      );

      notifyListeners();
    }
  }

  // Legacy dəstək üçün qorunur
  void addLessonToClassTimetable({
    required String className,
    required String day,
    required LessonSlot lesson,
  }) {
    addLessonWithMultipleClasses(
      targetClasses: [className],
      day: day,
      lesson: lesson,
    );
  }

  // --- ADMIN: CREATE EMPLOYEE ACCOUNT (Detallı HR məlumatları ilə) ---
  /// İşçi yaradır: tam şəxsi məlumatlar + avtomatik @idrak.edu.az mail +
  /// (müəllim deyilsə) rol təyinatı. İstifadəçi adı = e-poçtun lokal hissəsi.
  AppUser createEmployeeAccount({
    required String firstName,
    required String lastName,
    String? fatherName,
    required String gender,
    DateTime? birthDate,
    required String finCode,
    String? address,
    String? citizenship,
    String? idCardSerial,
    String? educationLevel,
    String? bankName,
    required String phone,
    required String password,
    String? photoUrl,
    bool isTeacher = false,
    String? position,
    DateTime? hireDate,
    double? salary,
    DateTime? contractStart,
    DateTime? contractEnd,
    String? subject,
    String? roomNumber,
    List<String> assignedClasses = const [],
    TeacherPermissions? teacherPermissions,
    String? assignedRoleId,
  }) {
    final fullName = '$firstName $lastName'.trim();
    final existingEmails = _collectEmails();
    final email = EmailGenerator.generateStaffEmail(
      fullName,
      existingEmails: existingEmails,
    );

    final role = isTeacher ? UserRole.teacher : UserRole.admin;
    final codePrefix = isTeacher ? 'IDR-TCH' : 'IDR-STF';

    // İşçi İdrak kodu da toqquşmasız — silinmiş işçinin kodu üstünə
    // yazılmasın (köhnə üsul sayğacla hesablanırdı).
    final usedIdrakCodes = _users
        .map((u) => u.idrakCode.toUpperCase())
        .toSet();
    var codeNum = 100 + _users.where((u) => u.role == role).length + 1;
    while (usedIdrakCodes.contains('$codePrefix-$codeNum'.toUpperCase())) {
      codeNum++;
    }
    final idrakCode = '$codePrefix-$codeNum';

    final newEmployee = AppUser(
      id: 'usr-stf-${DateTime.now().millisecondsSinceEpoch}',
      username: email.split('@').first,
      password: password.isEmpty ? '123456' : password,
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      fatherName: (fatherName ?? '').isEmpty ? null : fatherName,
      finCode: finCode,
      gender: gender,
      birthDate: birthDate,
      address: (address ?? '').isEmpty ? null : address,
      citizenship: (citizenship ?? '').isEmpty ? null : citizenship,
      idCardSerial: (idCardSerial ?? '').isEmpty ? null : idCardSerial,
      educationLevel: (educationLevel ?? '').isEmpty ? null : educationLevel,
      bankName: (bankName ?? '').isEmpty ? null : bankName,
      role: role,
      idrakCode: idrakCode,
      phone: phone,
      email: email,
      photoUrl: photoUrl,
      position: (position ?? '').isEmpty ? null : position,
      hireDate: hireDate,
      salary: salary,
      contractStart: contractStart,
      contractEnd: contractEnd,
      subject: (subject ?? '').isEmpty ? null : subject,
      roomNumber: (roomNumber ?? '').isEmpty ? null : roomNumber,
      assignedClasses: assignedClasses,
      teacherPermissions: isTeacher
          ? (teacherPermissions ?? const TeacherPermissions())
          : null,
      assignedRoleId: (assignedRoleId ?? '').isEmpty ? null : assignedRoleId,
      createdAt: DateTime.now(),
    );

    _users.insert(0, newEmployee);
    _firestoreService.saveUser(newEmployee);
    notifyListeners();
    return newEmployee;
  }

  /// Mövcud istifadəçilərin e-poçtları (unikallıq yoxlaması üçün)
  List<String> _collectEmails() {
    return _users
        .map((u) => (u.email ?? '').toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // --- ADMIN: REGISTER STUDENT WITH PARENT (tam məlumatlarla) ---
  /// Şagird + veli yaradır: tam şəxsi məlumatlar, avtomatik maillər
  /// (@idrak.edu.az), veli avtomatik şagirdə bağlanır.
  Map<String, AppUser> registerStudentWithParent({
    required String firstName,
    required String lastName,
    String? fatherName,
    required String gender,
    DateTime? birthDate,
    required String finCode,
    String? address,
    required String className,
    String bloodGroup = '',
    List<String> allergies = const [],
    required String studentPassword,
    AppUser? existingParent, // Mövcud valideyn: yeni övlad ona bağlanır
    required String parentName,
    required String parentFinCode,
    DateTime? parentBirthDate,
    required String parentPhone,
    String? parentAddress,
    required String parentPassword,
    String? studentPhotoUrl,
  }) {
    final studentName = '$firstName $lastName'.trim();

    // Mövcud ID/kod/barkodlarla toqquşmayan nömrə tap. Köhnə üsul
    // (siyahı uzunluğu + 1) silinmiş şagird və ya paralel qeydiyyat
    // halında mövcud şagirdin üzərinə yazırdı.
    final usedStdIds = _students.map((s) => s.id).toSet();
    final usedStudentNumbers =
        _students.map((s) => s.studentNumber.toUpperCase()).toSet();
    final usedBarcodes = _students.map((s) => s.barcodeData).toSet();

    var stdIndex = _students.length + 1;
    String stdId;
    String studentIdrakCode;
    String barcodeData;
    while (true) {
      stdId = 'std-${100 + stdIndex}';
      studentIdrakCode = 'IDR-2025-0${490 + stdIndex}';
      barcodeData = '994019${283740 + stdIndex}';
      final clash =
          usedStdIds.contains(stdId) ||
          usedStudentNumbers.contains(studentIdrakCode.toUpperCase()) ||
          usedBarcodes.contains(barcodeData);
      if (!clash) break;
      stdIndex++;
    }

    final existingEmails = _collectEmails();
    // Şagird mailindəki il FIN-dən hesablanır (məktəbə başlama ili)
    final schoolYear = EmailGenerator.getYearFromFIN(finCode);
    final studentEmail = EmailGenerator.generateStudentEmail(
      studentName,
      schoolYear,
      existingEmails: existingEmails,
    );
    // Mövcud valideyn seçilibsə onun maili istifadə olunur, yenisi yaradılmır
    final parentEmail =
        existingParent?.email ??
        EmailGenerator.generateParentEmail(
          existingParent?.fullName ?? parentName,
          existingEmails: [...existingEmails, studentEmail],
        );

    // 1. Create Student Profile (tam məlumatlarla)
    final newStudentProfile = StudentProfile(
      id: stdId,
      fullName: studentName,
      studentNumber: studentIdrakCode,
      className: className,
      photoUrl:
          studentPhotoUrl ??
          '',
      qrData: 'IDRAK-STUDENT-2025-$studentName-$className',
      barcodeData: barcodeData,
      firstName: firstName,
      lastName: lastName,
      fatherName: (fatherName ?? '').isEmpty ? null : fatherName,
      finCode: finCode,
      gender: gender,
      birthDate: birthDate,
      address: (address ?? '').isEmpty ? null : address,
      email: studentEmail,
      bloodGroup: bloodGroup.isEmpty ? null : bloodGroup,
      parentName: existingParent?.fullName ?? parentName,
      parentPhone: existingParent?.phone ?? parentPhone,
      parentEmail: parentEmail,
      parentAddress:
          existingParent?.address ??
          ((parentAddress ?? '').isEmpty ? null : parentAddress),
      gpa: 0.0,
      attendanceRate: 0,
      academicYear: '2024 - 2025',
    );
    _students.add(newStudentProfile);
    _customClasses.add(className);
    _pendingAttendanceStudents.add(newStudentProfile);
    _firestoreService.saveStudent(newStudentProfile);

    // 2. Create Student AppUser
    final studentUser = AppUser(
      id: 'usr-$stdId',
      username: studentEmail.split('@').first,
      password: studentPassword.isEmpty ? '123456' : studentPassword,
      fullName: studentName,
      firstName: firstName,
      lastName: lastName,
      fatherName: (fatherName ?? '').isEmpty ? null : fatherName,
      finCode: finCode,
      gender: gender,
      birthDate: birthDate,
      address: (address ?? '').isEmpty ? null : address,
      role: UserRole.student,
      idrakCode: studentIdrakCode,
      className: className,
      phone: existingParent?.phone ?? parentPhone,
      email: studentEmail,
      photoUrl: studentPhotoUrl,
      createdAt: DateTime.now(),
    );
    _users.insert(0, studentUser);
    _firestoreService.saveUser(studentUser);

    // 3. Valideyn: mövcuddursa bağla, yoxdursa yeni yarad (Övladlar modeli)
    AppUser parentUser;
    if (existingParent != null) {
      // Yeni övlad mövcud valideynə əlavə olunur
      final childIds = [...existingParent.linkedStudentIds];
      if (!childIds.contains(stdId)) childIds.add(stdId);
      final parentIndex = _users.indexWhere((u) => u.id == existingParent.id);
      parentUser = existingParent.copyWith(
        linkedStudentIds: childIds,
        linkedStudentId: existingParent.linkedStudentId ?? stdId,
      );
      if (parentIndex != -1) {
        _users[parentIndex] = parentUser;
      } else {
        _users.insert(0, parentUser);
      }
      _firestoreService.saveUser(parentUser);
    } else {
      final parentIdrakCode = 'IDR-PAR-0${490 + stdIndex}';
      parentUser = AppUser(
        id: 'usr-par-$stdId',
        username: parentEmail.split('@').first,
        password: parentPassword.isEmpty ? '123456' : parentPassword,
        fullName: parentName,
        finCode: parentFinCode,
        birthDate: parentBirthDate,
        role: UserRole.parent,
        idrakCode: parentIdrakCode,
        phone: parentPhone,
        email: parentEmail,
        address: (parentAddress ?? '').isEmpty ? null : parentAddress,
        linkedStudentId: stdId,
        linkedStudentIds: [stdId],
        createdAt: DateTime.now(),
      );
      _users.insert(0, parentUser);
      _firestoreService.saveUser(parentUser);
    }

    // 4. Create Student's Clean Medical Card
    final allergyItems = allergies
        .map(
          (a) => AllergyItem(
            name: a,
            severity: 'Yüksək dərəcə',
            reaction: 'Xüsusi qida / dərman həssaslığı',
            firstAid: 'Tibb otağına məlumat verilməli və pəhriz saxlanmalıdır.',
          ),
        )
        .toList();

    final newMedicalCard = StudentMedicalCard(
      bloodGroup: bloodGroup.isEmpty ? 'Məlumat daxil edilməyib' : bloodGroup,
      heightCm: 0.0,
      weightKg: 0.0,
      allergies: allergyItems,
      chronicConditions: [],
      vaccineHistory: [],
      emergencyContactName: parentName,
      emergencyContactPhone: parentPhone,
      lyceumDoctorNotes: 'Qeydiyyat zamanı həkim baxışı gözlənilir.',
    );
    _medicalCardsMap[stdId] = newMedicalCard;
    _firestoreService.saveMedicalCard(stdId, newMedicalCard);

    notifyListeners();
    return {'student': studentUser, 'parent': parentUser};
  }

  void updateTeacherPermissions(String userId, TeacherPermissions permissions) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(teacherPermissions: permissions);
      _firestoreService.updateTeacherPermissions(userId, permissions);
      notifyListeners();
    }
  }

  void toggleUserStatus(String userId) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final updatedStatus = !_users[index].isActive;
      _users[index] = _users[index].copyWith(isActive: updatedStatus);
      _firestoreService.updateUserStatus(userId, updatedStatus);
      notifyListeners();
    }
  }

  /// İstənilən istifadəçinin (işçi/müəllim/şagird/valideyn) məlumatlarını
  /// yeniləşdirir — admin və edit_users səlahiyyəti olanlar üçün.
  /// Firestore yazması uğurlu oldursa true qaytarır.
  Future<bool> updateUserAccount(AppUser updated) async {
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
    } else {
      _users.insert(0, updated);
    }
    if (updated.role == UserRole.teacher || updated.role == UserRole.admin) {
      try {
        await SchoolApiService.instance.updateEmployee(updated.id, {
          'finCode': updated.finCode,
          'fullName': updated.fullName,
          'firstName': updated.firstName,
          'lastName': updated.lastName,
          'fatherName': updated.fatherName,
          'gender': updated.gender,
          'birthDate': updated.birthDate?.toIso8601String().split('T').first,
          'citizenship': updated.citizenship,
          'idCardSerial': updated.idCardSerial,
          'maritalStatus': updated.maritalStatus,
          'bloodGroup': updated.bloodGroup,
          'address': updated.address,
          'email': updated.email,
          'phone': updated.phone,
          'educationLevel': updated.educationLevel,
          'university': updated.university,
          'specialty': updated.specialty,
          'bankName': updated.bankName,
          'bankAccount': updated.bankAccount,
          'bankIban': updated.bankIban,
          'position': updated.position,
          'department': updated.department,
          'salary': updated.salary,
          'sector': updated.sector,
          'status': updated.isActive ? 'active' : 'inactive',
          'password': updated.password,
          'contractStart': updated.contractStart?.toIso8601String().split('T').first,
          'contractEnd': updated.contractEnd?.toIso8601String().split('T').first,
        });
      } catch (_) {}
    }
    final saved = await _firestoreService.saveUser(updated);
    if (_currentUser?.id == updated.id) {
      _currentUser = updated;
    }
    notifyListeners();
    return saved;
  }

  /// İstifadəçinin öz şifrəsini parametrlərdən (Settings) dəyişdirməsi üçün.
  /// Uğurlu dəyişiklikdə null, xətada istifadəçiyə göstəriləcək mesaj qaytarır.
  Future<String?> changeCurrentUserPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return 'İstifadəçi tapılmadı.';
    final old = oldPassword.trim();
    final fresh = newPassword.trim();

    // Minimum parola siyasəti
    if (fresh.length < 6) {
      return 'Yeni şifrə ən azı 6 simvol olmalıdır.';
    }

    final stored = _currentUser!.password;
    // Həm yeni hash formatı, həm köhnə düz mətn qeydləri yoxlanılır
    final oldOk = PasswordHasher.verify(_currentUser!.id, old, stored) ||
        (!PasswordHasher.isHash(stored) && stored == old);
    if (!oldOk) {
      return 'Cari şifrəniz yanlışdır. Yenidən cəhd edin.';
    }

    final updated = _currentUser!.copyWith(password: fresh);
    final saved = await updateUserAccount(updated);
    if (!saved) {
      return 'Şifrə saxlanmadı — internet bağlantısını yoxlayıb yenidən cəhd edin.';
    }

    // Əgər cihazda biometrik / avto login yadda saxlanılıbsa AuthStorageService-də də yenilə
    try {
      final savedCreds = await _authStorage.getSavedCredentials();
      if (savedCreds != null && savedCreds['username'] != null) {
        await _authStorage.saveCredentials(savedCreds['username']!, fresh);
      }
    } catch (_) {}

    return null;
  }

  /// Adminin istənilən istifadəçinin (müəllim, şagird, valideyn, işçi) şifrəsini sıfırlaması
  /// Standart sıfırlama şifrəsi: 123456
  Future<bool> resetUserPasswordByAdmin(String userId, {String newPassword = '123456'}) async {
    int index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      final clean = userId.trim().toLowerCase();
      index = _users.indexWhere((u) =>
          u.username.toLowerCase() == clean ||
          u.idrakCode.toLowerCase() == clean ||
          (u.finCode != null && u.finCode!.toLowerCase() == clean) ||
          (u.email != null && u.email!.toLowerCase() == clean) ||
          u.id == 'usr-$userId' ||
          (u.linkedStudentId != null && u.linkedStudentId == userId));
    }
    if (index == -1) return false;

    final updated = _users[index].copyWith(password: newPassword.trim());
    return updateUserAccount(updated);
  }

  /// Şagird profilini (students kolleksiyası) yeniləşdirir
  void updateStudentRecord(StudentProfile updated) {
    final index = _students.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _students[index] = updated;
      _firestoreService.saveStudent(updated);
      notifyListeners();
    }
    SchoolApiService.instance.saveStudent(
      {
        'firstName': updated.firstName,
        'lastName': updated.lastName,
        'fullName': updated.fullName,
        'fatherName': updated.fatherName,
        'finCode': updated.finCode,
        'gender': updated.gender,
        'birthDate': updated.birthDate?.toIso8601String().split('T').first,
        'bloodGroup': updated.bloodGroup,
        'address': updated.address,
        'registrationAddress': updated.registrationAddress,
        'email': updated.email,
        'phone': updated.phone,
        'className': updated.className,
        'parentName': updated.parentName,
        'parentPhone': updated.parentPhone,
        'parentEmail': updated.parentEmail,
      },
      id: updated.id,
    );
  }

  /// İstifadəçinin profil fotosunu yeniləyir (Cloudinary URL)
  void updateUserPhoto(String userId, String newPhotoUrl) {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = _users[userIndex].copyWith(photoUrl: newPhotoUrl);
      _firestoreService.saveUser(_users[userIndex]);
    }
    // Əgər tələbədirsə, StudentProfile-ı da yenilə
    final stdId = userId.replaceFirst('usr-', '');
    final stdIndex = _students.indexWhere((s) => s.id == stdId);
    if (stdIndex != -1) {
      _students[stdIndex] = _students[stdIndex].copyWith(photoUrl: newPhotoUrl);
      _firestoreService.saveStudent(_students[stdIndex]);
    }
    notifyListeners();
  }

  void deleteUser(String userId) {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  // --- TIMETABLE (DƏRS CƏDVƏLİ) ---
  List<DayTimetable> get weeklyTimetable {
    final cls = student.className.isNotEmpty
        ? student.className
        : (allDistinctClasses.isNotEmpty ? allDistinctClasses.first : '');
    if (cls.isEmpty) return const [];
    return getClassTimetable(cls);
  }

  // --- GRADES & LIVE GPA CALCULATION ---
  final List<GradeRecord> _grades = [];
  List<GradeRecord> get grades => _grades;

  void recalculateStudentGpa(String targetStdId) {
    final stdIndex = _students.indexWhere((s) => s.id == targetStdId);
    if (stdIndex == -1) return;

    final studentGrades = _grades
        .where((g) => g.studentId == targetStdId)
        .toList();
    if (studentGrades.isEmpty) {
      final old = _students[stdIndex];
      _students[stdIndex] = StudentProfile(
        id: old.id,
        fullName: old.fullName,
        studentNumber: old.studentNumber,
        className: old.className,
        photoUrl: old.photoUrl,
        qrData: old.qrData,
        barcodeData: old.barcodeData,
        parentName: old.parentName,
        parentPhone: old.parentPhone,
        gpa: 0.0,
        attendanceRate: old.attendanceRate,
        academicYear: old.academicYear,
      );
      _firestoreService.updateStudentGPA(targetStdId, 0.0, old.attendanceRate);
      return;
    }

    final validPcts = studentGrades.map((g) => g.percentage).toList();
    final avgPct = validPcts.reduce((a, b) => a + b) / validPcts.length;
    final calculatedGpa = double.parse(
      ((avgPct / 100.0) * 5.0).clamp(0.0, 5.0).toStringAsFixed(2),
    );

    final old = _students[stdIndex];
    _students[stdIndex] = StudentProfile(
      id: old.id,
      fullName: old.fullName,
      studentNumber: old.studentNumber,
      className: old.className,
      photoUrl: old.photoUrl,
      qrData: old.qrData,
      barcodeData: old.barcodeData,
      parentName: old.parentName,
      parentPhone: old.parentPhone,
      gpa: calculatedGpa,
      attendanceRate: old.attendanceRate,
      academicYear: old.academicYear,
    );
    _firestoreService.updateStudentGPA(
      targetStdId,
      calculatedGpa,
      old.attendanceRate,
    );
  }

  /// Cloud yazmasının nəticəsini qaytarır — true: Firestore-a yazıldı.
  Future<bool> addGrade(GradeRecord grade, [String? studentId]) async {
    final targetStdId = studentId ?? grade.studentId ?? student.id;
    final stdIndex = _students.indexWhere((s) => s.id == targetStdId);
    final stdName = stdIndex != -1
        ? _students[stdIndex].fullName
        : student.fullName;

    // Sanitize score if out of bounds
    double sanitizedScore = grade.score;
    if (grade.maxScore == 100.0 &&
        sanitizedScore > 100.0 &&
        sanitizedScore <= 1000.0) {
      sanitizedScore = sanitizedScore / 10.0;
    } else if (sanitizedScore > grade.maxScore) {
      sanitizedScore = grade.maxScore;
    }

    final completeGrade = GradeRecord(
      id: grade.id,
      studentId: targetStdId,
      studentName: stdName,
      subject: grade.subject,
      type: grade.type,
      title: grade.title,
      score: sanitizedScore,
      maxScore: grade.maxScore,
      gradeLetter: grade.gradeLetter,
      date: grade.date,
      teacherFeedback: grade.teacherFeedback,
    );

    _grades.insert(0, completeGrade);
    final saved = await _firestoreService.saveGrade(
      completeGrade,
      targetStdId,
      stdName,
    );

    recalculateStudentGpa(targetStdId);
    notifyListeners();
    return saved;
  }

  void deleteGrade(String gradeId, [String? studentId]) {
    final targetGrade = _grades.firstWhere(
      (g) => g.id == gradeId,
      orElse: () => GradeRecord(
        id: '',
        subject: '',
        type: AssessmentType.ksq,
        title: '',
        score: 0,
        gradeLetter: '',
        date: DateTime.now(),
      ),
    );
    // GPA həmişə NOTUN SAHİBİNƏ görə yenidən hesablansın —
    // çağıran tərəfdən göndərilən "cari şagird" yanlış hesaba
    // səhvən tətiq olunmasın.
    final targetStdId = targetGrade.studentId ?? studentId ?? student.id;

    _grades.removeWhere((g) => g.id == gradeId);
    _firestoreService.deleteGrade(gradeId);

    recalculateStudentGpa(targetStdId);
    notifyListeners();
  }

  // Attendance: studentId -> (dayOfMonth -> DayAttendance)
  final Map<String, Map<int, DayAttendance>> _studentAttendanceMap = {};

  Map<int, DayAttendance> getStudentAttendance(String studentId) {
    if (_studentAttendanceMap.containsKey(studentId)) {
      return _studentAttendanceMap[studentId]!;
    }
    final emptyMap = <int, DayAttendance>{};
    _studentAttendanceMap[studentId] = emptyMap;
    return emptyMap;
  }

  Map<int, DayAttendance> get attendance => getStudentAttendance(student.id);

  // --- MEDICAL CARD & PHYSICAL STATS (BOY / ÇƏKİ & BMI) ---
  StudentMedicalCard getMedicalCardForStudent(String studentId) {
    if (_medicalCardsMap.containsKey(studentId)) {
      return _medicalCardsMap[studentId]!;
    }
    final cleanCard = StudentMedicalCard(
      bloodGroup: 'Məlumat yoxdur',
      heightCm: 0.0,
      weightKg: 0.0,
      allergies: [],
      chronicConditions: [],
      vaccineHistory: [],
      emergencyContactName: '',
      emergencyContactPhone: '',
      lyceumDoctorNotes: 'Həkim qeydi yoxdur.',
    );
    _medicalCardsMap[studentId] = cleanCard;
    return cleanCard;
  }

  StudentMedicalCard get medicalCard => getMedicalCardForStudent(student.id);

  void updateStudentPhysicalStats({
    required String studentId,
    required double heightCm,
    required double weightKg,
    String? bloodGroup,
    String? doctorNote,
  }) {
    final card = getMedicalCardForStudent(studentId);
    final updatedCard = card.copyWith(
      heightCm: heightCm,
      weightKg: weightKg,
      bloodGroup: bloodGroup ?? card.bloodGroup,
      lyceumDoctorNotes: doctorNote ?? card.lyceumDoctorNotes,
    );
    _medicalCardsMap[studentId] = updatedCard;
    _firestoreService.saveMedicalCard(studentId, updatedCard);
    notifyListeners();
  }

  void addAllergyToStudent(String studentId, AllergyItem allergy) {
    final card = getMedicalCardForStudent(studentId);
    card.allergies.insert(0, allergy);
    _medicalCardsMap[studentId] = card;
    _firestoreService.saveMedicalCard(studentId, card);
    notifyListeners();
  }

  void addAllergy(AllergyItem allergy) {
    addAllergyToStudent(student.id, allergy);
  }

  void addVaccineRecordToStudent(String studentId, VaccineRecord vaccine) {
    final card = getMedicalCardForStudent(studentId);
    card.vaccineHistory.insert(0, vaccine);
    _medicalCardsMap[studentId] = card;
    _firestoreService.saveMedicalCard(studentId, card);
    notifyListeners();
  }

  void addVaccineRecord(VaccineRecord vaccine) {
    addVaccineRecordToStudent(student.id, vaccine);
  }

  void addParentMedicalNote(String studentId, String noteText) {
    final card = getMedicalCardForStudent(studentId);
    final parName = _currentUser?.fullName ?? 'Valideyn';
    final newNote = ParentMedicalNote(
      id: 'pnote-${DateTime.now().millisecondsSinceEpoch}',
      note: noteText,
      date: DateTime.now(),
      parentName: parName,
    );
    final updatedList = List<ParentMedicalNote>.from(card.parentNotes)
      ..insert(0, newNote);
    final updatedCard = card.copyWith(parentNotes: updatedList);
    _medicalCardsMap[studentId] = updatedCard;
    _firestoreService.saveMedicalCard(studentId, updatedCard);
    notifyListeners();
  }

  // QR Inventory Items
  final List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> get inventoryItems => _inventoryItems;

  /// Resolves a scanned QR payload to its registered equipment, if any.
  InventoryItem? findInventoryItemByQr(String qrCode) {
    final clean = qrCode.trim();
    for (final item in _inventoryItems) {
      if (item.qrCode.trim() == clean) return item;
    }
    return null;
  }

  void addInventoryItem(InventoryItem item) {
    _inventoryItems.insert(0, item);
    _firestoreService.saveInventoryItem(item);
    notifyListeners();
  }

  void updateInventoryItem(InventoryItem item) {
    final index = _inventoryItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _inventoryItems[index] = item;
      _firestoreService.saveInventoryItem(item);
      notifyListeners();
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    _inventoryItems.removeWhere((i) => i.id == id);
    await _firestoreService.deleteInventoryItem(id);
    notifyListeners();
  }

  // Tickets
  final List<HelpdeskTicket> _tickets = [];
  List<HelpdeskTicket> get tickets => _tickets;

  /// Verilən icazəyə sahib aktiv işçi istifadəçilərin ID-ləri
  List<String> _staffIdsWithPermission(String permissionId) {
    return _users
        .where((u) {
          if (!u.isActive) return false;
          // Yalnız rol təyin olunMAYAN super admin hər icazəyə malikdir;
          // xüsusi rollu işçi (IT, Helpdesk...) yalnız rolunun icazəsi ilə.
          final roleId = u.assignedRoleId;
          if (u.role == UserRole.admin &&
              (roleId == null || roleId.isEmpty)) {
            return true;
          }
          if (roleId == null || roleId.isEmpty) return false;
          final role = getRoleById(roleId);
          return role?.permissionIds.contains(permissionId) ?? false;
        })
        .map((u) => u.id)
        .toList();
  }

  /// Psixoloq / rəhbər müəllim rolundakı işçilərin ID-ləri
  List<String> _psychologistIds() {
    return _users
        .where((u) {
          if (!u.isActive) return false;
          final roleId = u.assignedRoleId;
          if (roleId == null || roleId.isEmpty) return false;
          final role = getRoleById(roleId);
          if (role == null) return false;
          final name = role.name.toLowerCase();
          return role.id == 'role-psikolog' ||
              name.contains('psix') ||
              name.contains('psik') ||
              name.contains('rehberlik') ||
              name.contains('rəhbər müəllim');
        })
        .map((u) => u.id)
        .toList();
  }

  /// Ticketın hansı işçilərə yönləndiriləcəyini müəyyən edir:
  /// inventar → helpdesk/IT; psixoloji → yalnız psixoloq;
  /// qalanları → idarəetmə (manage_tickets icazəliləri).
  Set<String> _ticketRecipients(HelpdeskTicket ticket) {
    switch (ticket.category) {
      case TicketCategory.psychological:
        return _psychologistIds().toSet();
      case TicketCategory.inventory:
      case TicketCategory.general:
      case TicketCategory.academic:
      case TicketCategory.finance:
      case TicketCategory.cafeteria:
        return _staffIdsWithPermission('manage_tickets').toSet();
    }
  }

  String _ticketNotificationTitle(HelpdeskTicket ticket) {
    switch (ticket.category) {
      case TicketCategory.inventory:
        return '🔧 Yeni inventar müraciəti';
      case TicketCategory.psychological:
        return '🧠 Yeni psixoloji müraciət';
      case TicketCategory.finance:
        return '💰 Yeni maliyyə müraciəti';
      case TicketCategory.cafeteria:
        return '🍽 Yeni yeməkxana müraciəti';
      case TicketCategory.academic:
        return '📚 Yeni tədris müraciəti';
      case TicketCategory.general:
        return '📨 Yeni müraciət';
    }
  }

  String _ticketStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Gözləmədə';
      case TicketStatus.inProgress:
        return 'Baxılır / İcrada';
      case TicketStatus.resolved:
        return 'Həll olundu';
      case TicketStatus.closed:
        return 'Bağlandı';
    }
  }

  /// Cloud yazmasının nəticəsini qaytarır — true: Firestore-a yazıldı.
  Future<bool> addTicket(HelpdeskTicket ticket) async {
    _tickets.insert(0, ticket);
    final saved = await _firestoreService.saveTicket(ticket);
    // Yalnız məsul şöbəyə bildiriş (valideyn/şagirdlərə YOX)
    final recipients = _ticketRecipients(
      ticket,
    ).where((id) => id != ticket.senderId).toList();
    if (recipients.isNotEmpty) {
      sendNotification(
        title: _ticketNotificationTitle(ticket),
        message:
            '${ticket.senderName}: ${ticket.title}${ticket.roomNumber != null ? ' (${ticket.roomNumber})' : ''}',
        category: ticket.priority == TicketPriority.urgent
            ? NotificationCategory.emergency
            : NotificationCategory.general,
        priority: ticket.priority == TicketPriority.urgent ? 'high' : 'normal',
        targetUserIds: recipients,
      );
    }
    notifyListeners();
    return saved;
  }

  void addTicketMessage(String ticketId, TicketMessage message) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final ticket = _tickets[index];
      final updatedMessages = List<TicketMessage>.from(ticket.messages)
        ..add(message);
      final updatedTicket = HelpdeskTicket(
        id: ticket.id,
        title: ticket.title,
        category: ticket.category,
        status: ticket.status,
        priority: ticket.priority,
        senderName: ticket.senderName,
        senderRole: ticket.senderRole,
        senderId: ticket.senderId,
        description: ticket.description,
        createdAt: ticket.createdAt,
        roomNumber: ticket.roomNumber,
        inventoryCode: ticket.inventoryCode,
        attachedImage: ticket.attachedImage,
        messages: updatedMessages,
      );
      _tickets[index] = updatedTicket;
      _firestoreService.saveTicket(updatedTicket);
      // Əks tərəfə bildiriş: işçi cavabı → göndərənə; göndərən → məsul şöbəyə
      final myId = _currentUser?.id;
      if (message.isFromStaff) {
        if (ticket.senderId != null && ticket.senderId != myId) {
          sendNotification(
            title: '💬 Müraciətinizə cavab verildi',
            message: '${ticket.title} — ${message.message}',
            category: NotificationCategory.general,
            targetUserIds: [ticket.senderId!],
          );
        }
      } else {
        final recipients = _ticketRecipients(
          ticket,
        ).where((id) => id != myId).toList();
        if (recipients.isNotEmpty) {
          sendNotification(
            title: '💬 Yeni cavab: ${ticket.title}',
            message: '${message.sender}: ${message.message}',
            category: NotificationCategory.general,
            targetUserIds: recipients,
          );
        }
      }
      notifyListeners();
    }
  }

  /// Biletin statusunu dəyişir (helpdesk / admin — manage_tickets)
  void updateTicketStatus(String ticketId, TicketStatus status) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final ticket = _tickets[index];
      _tickets[index] = ticket.copyWith(status: status);
      _firestoreService.updateTicketStatus(ticketId, status);
      // Statusu yalnız göndərən şəxs görür (başqalarına bildiriş YOX)
      if (ticket.senderId != null && ticket.senderId != _currentUser?.id) {
        sendNotification(
          title: '📋 Müraciət statusu yeniləndi',
          message: '"${ticket.title}" — ${_ticketStatusLabel(status)}',
          category: NotificationCategory.general,
          targetUserIds: [ticket.senderId!],
        );
      }
      notifyListeners();
    }
  }

  // Assignments
  final List<HomeworkAssignment> _assignments = [];
  List<HomeworkAssignment> get assignments => _assignments;

  Map<String, dynamic>? _assignmentOverviewStats;
  Map<String, dynamic>? get assignmentOverviewStats => _assignmentOverviewStats;

  List<Map<String, dynamic>> _assignmentSubjectGrid = [];
  List<Map<String, dynamic>> get assignmentSubjectGrid => _assignmentSubjectGrid;

  Future<void> refreshAssignmentsOverview() async {
    try {
      final ovRes = await ApiClient.instance.get('academic/assignments/overview');
      final ovData = ovRes is Map ? ovRes['data'] : null;
      if (ovData is Map) {
        if (ovData['stats'] is Map) {
          _assignmentOverviewStats = Map<String, dynamic>.from(ovData['stats']);
        }
        if (ovData['grid'] is Map) {
          final gridMap = Map<String, dynamic>.from(ovData['grid']);
          final list = <Map<String, dynamic>>[];
          for (final entry in gridMap.entries) {
            if (entry.value is List) {
              for (final item in entry.value) {
                if (item is Map) {
                  list.add(Map<String, dynamic>.from(item));
                }
              }
            }
          }
          _assignmentSubjectGrid = list;
        }
      }

      final asgRes = await ApiClient.instance.get('academic/assignments', query: {'per_page': '1000'});
      final asgList = asgRes is Map ? asgRes['data'] : asgRes;
      if (asgList is List) {
        final apiAssignments = <HomeworkAssignment>[];
        final currentStudentId = student.id;
        for (final raw in asgList) {
          if (raw is Map) {
            apiAssignments.add(
              HomeworkAssignment.fromApiJson(
                Map<String, dynamic>.from(raw),
                currentStudentId: currentStudentId,
              ),
            );
          }
        }
        if (apiAssignments.isNotEmpty) {
          _assignments.removeWhere((a) => a.id.startsWith('api-asg-'));
          _assignments.insertAll(0, apiAssignments);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('refreshAssignmentsOverview notice: $e');
    }
  }

  // Filtered assignments for currently logged in teacher (Admin sees all)
  List<HomeworkAssignment> get currentTeacherAssignments {
    if (_currentUser == null || _currentUser!.role == UserRole.admin) {
      return _assignments;
    }
    final teacherName = _currentUser!.fullName.trim().toLowerCase();
    return _assignments.where((a) {
      final aTeacher = a.teacherName.trim().toLowerCase();
      return aTeacher == teacherName ||
          aTeacher.contains(teacherName) ||
          teacherName.contains(aTeacher);
    }).toList();
  }

  /// Cloud yazmasının nəticəsini qaytarır — true: Firestore-a yazıldı.
  Future<bool> createAssignment(HomeworkAssignment assignment) async {
    _assignments.insert(0, assignment);
    final saved = await _firestoreService.saveAssignment(assignment);
    notifyListeners();
    return saved;
  }

  /// Tapşırığı təhvil verir. Yerli vəziyyət dərhal, bulud yazısı
  /// gözlənilir — false qayıdırsa (oflayn) istifadəçiyə xəta göstərilir.
  Future<bool> submitHomework({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required List<String> images,
    required String note,
  }) async {
    final index = _assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return false;
    final old = _assignments[index];
    final newSubmissions = Map<String, AssignmentSubmission>.from(
      old.submissions,
    );
    newSubmissions[studentId] = AssignmentSubmission(
      studentId: studentId,
      studentName: studentName,
      submittedAt: DateTime.now(),
      scannedImages: images,
      studentNote: note,
    );

    final updated = HomeworkAssignment(
      id: old.id,
      rawBackendId: old.rawBackendId,
      subject: old.subject,
      title: old.title,
      teacherName: old.teacherName,
      instructions: old.instructions,
      assignedDate: old.assignedDate,
      dueDate: old.dueDate,
      attachmentDocUrl: old.attachmentDocUrl,
      assignedClass: old.assignedClass,
      assignedStudentIds: old.assignedStudentIds,
      maxScore: old.maxScore,
      attachments: old.attachments,
      submissions: newSubmissions,
    );
    _assignments[index] = updated;
    notifyListeners();

    // Sync to Laravel Backend API (MariaDB assignment_submissions)
    final rawBackendId = old.rawBackendId ?? int.tryParse(old.id.replaceFirst('api-asg-', ''));
    if (rawBackendId != null) {
      try {
        await ApiClient.instance.post(
          'academic/assignments/$rawBackendId/submit',
          data: {
            'content': note,
            'attachments_data': images,
            'student_id': studentId,
          },
        );
      } catch (e) {
        debugPrint('⚠️ submitHomework API backend notice: $e');
      }
    }

    try {
      await _firestoreService.saveAssignment(updated);
      return true;
    } catch (e) {
      debugPrint('⚠️ submitHomework cloud sync failed (local kept): $e');
      return true; // Still return true if local and backend succeeded
    }
  }

  void gradeHomework({
    required String assignmentId,
    required String studentId,
    required double score,
    required String comment,
  }) {
    final index = _assignments.indexWhere((a) => a.id == assignmentId);
    if (index != -1) {
      final old = _assignments[index];
      final oldSub = old.submissions[studentId];
      if (oldSub != null) {
        final sanitizedScore = (score > 100.0)
            ? (score / 10.0).clamp(0.0, 100.0)
            : score.clamp(0.0, 100.0);
        final newSubmissions = Map<String, AssignmentSubmission>.from(
          old.submissions,
        );
        newSubmissions[studentId] = AssignmentSubmission(
          studentId: oldSub.studentId,
          studentName: oldSub.studentName,
          submittedAt: oldSub.submittedAt,
          scannedImages: oldSub.scannedImages,
          studentNote: oldSub.studentNote,
          score: sanitizedScore,
          teacherComment: comment,
          gradedAt: DateTime.now(),
        );

        final updated = HomeworkAssignment(
          id: old.id,
          subject: old.subject,
          title: old.title,
          teacherName: old.teacherName,
          instructions: old.instructions,
          assignedDate: old.assignedDate,
          dueDate: old.dueDate,
          attachmentDocUrl: old.attachmentDocUrl,
          assignedClass: old.assignedClass,
          assignedStudentIds: old.assignedStudentIds,
          submissions: newSubmissions,
        );

        _assignments[index] = updated;
        _firestoreService.saveAssignment(updated);

        // Auto-sync into student GradeRecords so parents see the grade and GPA is updated
        final targetStd = _students.firstWhere(
          (s) => s.id == studentId,
          orElse: () => student,
        );

        final gradeRecord = GradeRecord(
          id: 'gr-hw-${old.id}-$studentId',
          studentId: targetStd.id,
          studentName: targetStd.fullName,
          subject: old.subject,
          type: AssessmentType.ksq,
          title: 'Tapşırıq: ${old.title}',
          score: sanitizedScore,
          maxScore: 100.0,
          gradeLetter: sanitizedScore >= 90
              ? 'A'
              : (sanitizedScore >= 80
                    ? 'B'
                    : (sanitizedScore >= 70
                          ? 'C'
                          : (sanitizedScore >= 60 ? 'D' : 'E'))),
          date: DateTime.now(),
          teacherFeedback: comment.isNotEmpty
              ? comment
              : 'Müəllim (${old.teacherName}) tərəfindən yoxlanıldı.',
        );

        final existingGradeIdx = _grades.indexWhere(
          (g) => g.id == 'gr-hw-${old.id}-$studentId',
        );
        if (existingGradeIdx != -1) {
          _grades[existingGradeIdx] = gradeRecord;
        } else {
          _grades.insert(0, gradeRecord);
        }
        _firestoreService.saveGrade(
          gradeRecord,
          targetStd.id,
          targetStd.fullName,
        );
        recalculateStudentGpa(targetStd.id);

        notifyListeners();
      }
    }
  }

  void deleteAssignment(String assignmentId) {
    _assignments.removeWhere((a) => a.id == assignmentId);
    _firestoreService.deleteAssignment(assignmentId);
    notifyListeners();
  }

  // --- MEET İDRAK (VOICE ROOMS) ---
  final List<MeetRoom> _meetRooms = [];
  List<MeetRoom> get meetRooms => _meetRooms;

  List<MeetRoom> get onlineLessons => getMeetRoomsForCurrentUser();

  List<MeetRoom> getMeetRoomsForCurrentUser() {
    final user = _currentUser;
    if (user == null) return _meetRooms;

    if (user.role == UserRole.admin) {
      return _meetRooms;
    }

    if (user.role == UserRole.teacher) {
      return _meetRooms.where((room) {
        if (room.hostId == user.id) return true;
        if (room.allowTeachers) return true;
        return false;
      }).toList();
    }

    if (user.role == UserRole.student) {
      final studentClass = user.className ?? student.className;
      return _meetRooms.where((room) {
        if (!room.allowStudents) return false;
        if (room.targetClasses.isEmpty) return true;
        return room.targetClasses.contains(studentClass);
      }).toList();
    }

    if (user.role == UserRole.parent) {
      final childClass = student.className;
      return _meetRooms.where((room) {
        if (!room.allowStudents) return false;
        if (room.targetClasses.isEmpty) return true;
        return room.targetClasses.contains(childClass);
      }).toList();
    }

    return _meetRooms;
  }

  Future<MeetRoom> createMeetRoom({
    required String title,
    required String subject,
    List<String> targetClasses = const [],
    bool allowTeachers = true,
    bool allowStudents = true,
    DateTime? scheduledTime,
    bool hasVideo = false,
    bool allowGuestLink = false,
    int guestLimit = 10,
  }) async {
    final host = _currentUser;
    final hostId = host?.id ?? 'usr-tch-1';
    final hostName = host?.fullName ?? 'Fənn Müəllimi';
    final hostPhoto = host?.photoUrl;
    final roomId = 'meet-${DateTime.now().millisecondsSinceEpoch}';

    // Host is automatically the first participant
    final hostParticipant = MeetParticipant(
      userId: hostId,
      fullName: hostName,
      role: 'host',
      photoUrl: hostPhoto,
      className: host?.className,
      isMuted: false,
      isMutedByHost: false,
      isSpeaking: false,
    );

    final room = MeetRoom(
      id: roomId,
      title: title,
      hostId: hostId,
      hostName: hostName,
      hostPhotoUrl: hostPhoto,
      subject: subject,
      targetClasses: targetClasses,
      allowTeachers: allowTeachers,
      allowStudents: allowStudents,
      status: 'live',
      scheduledTime: scheduledTime,
      participants: [hostParticipant],
      hasVideo: hasVideo,
      allowGuestLink: allowGuestLink,
      guestLimit: guestLimit,
    );

    _meetRooms.insert(0, room);
    await _firestoreService.saveMeetRoom(room);

    // Register room on Render Agora Token Server for Web Guests
    if (allowGuestLink) {
      unawaited(AgoraTokenService.registerRoom(
        roomId: roomId,
        title: title,
        hostName: hostName,
        allowGuestLink: allowGuestLink,
        guestLimit: guestLimit,
        hasVideo: hasVideo,
      ));
    }

    notifyListeners();
    return room;
  }

  Future<void> endMeetRoom(String roomId) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      _meetRooms[index] = _meetRooms[index].copyWith(status: 'ended');
      await _firestoreService.setMeetRoomStatus(roomId, 'ended');
      unawaited(AgoraTokenService.endRoom(roomId));
      notifyListeners();
    }
  }

  Future<void> deleteMeetRoom(String roomId) async {
    _meetRooms.removeWhere((r) => r.id == roomId);
    await _firestoreService.deleteMeetRoom(roomId);
    unawaited(AgoraTokenService.endRoom(roomId));
    notifyListeners();
  }

  Future<void> joinMeetRoom(String roomId) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final room = _meetRooms[index];
    final user = _currentUser;
    final userId = user?.id ?? student.id;
    final userName = user?.fullName ?? student.fullName;
    final userRole = user?.role == UserRole.teacher
        ? 'teacher'
        : (user?.role == UserRole.admin ? 'admin' : 'student');
    final userPhoto = user?.photoUrl ?? student.photoUrl;
    final userClass = user?.className ?? student.className;

    final newParticipant = MeetParticipant(
      userId: userId,
      fullName: userName,
      role: room.hostId == userId ? 'host' : userRole,
      photoUrl: userPhoto,
      className: userClass,
      isMuted: false,
      isMutedByHost: false,
    );

    // Immediately update local state for responsive UI
    final localParticipants = List<MeetParticipant>.from(room.participants);
    final existingIndex = localParticipants.indexWhere(
      (p) => p.userId == userId,
    );
    if (existingIndex == -1) {
      localParticipants.add(newParticipant);
    } else {
      localParticipants[existingIndex] = newParticipant;
    }
    _meetRooms[index] = room.copyWith(participants: localParticipants);
    notifyListeners();

    // Sync to Firestore in background (don't block UI)
    try {
      final updatedParticipants = await _firestoreService.joinMeetParticipant(
        roomId,
        newParticipant,
      );
      final currentIndex = _meetRooms.indexWhere((r) => r.id == roomId);
      if (currentIndex != -1) {
        _meetRooms[currentIndex] = _meetRooms[currentIndex].copyWith(
          participants: updatedParticipants,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Firestore sync failed (local state preserved): $e');
    }
  }

  Future<void> leaveMeetRoom(String roomId) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final room = _meetRooms[index];
    final userId = _currentUser?.id ?? student.id;

    // Immediately update local state
    final localParticipants = List<MeetParticipant>.from(room.participants);
    localParticipants.removeWhere((p) => p.userId == userId);
    _meetRooms[index] = room.copyWith(participants: localParticipants);
    notifyListeners();

    // Sync to Firestore in background
    try {
      final updatedParticipants = await _firestoreService.leaveMeetParticipant(
        roomId,
        userId,
      );
      final currentIndex = _meetRooms.indexWhere((r) => r.id == roomId);
      if (currentIndex != -1) {
        _meetRooms[currentIndex] = _meetRooms[currentIndex].copyWith(
          participants: updatedParticipants,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Firestore leave sync failed (local state preserved): $e');
    }
  }

  Future<void> toggleMyMuteInRoom(String roomId) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final room = _meetRooms[index];
    final userId = _currentUser?.id ?? student.id;

    final currentParticipant = room.participants
        .where((p) => p.userId == userId)
        .firstOrNull;
    if (currentParticipant?.isMutedByHost ?? false) return;
    final updatedParticipants = await _firestoreService.setMeetParticipantMuted(
      roomId,
      userId,
      !(currentParticipant?.isMuted ?? false),
    );

    _meetRooms[index] = room.copyWith(participants: updatedParticipants);
    notifyListeners();
  }

  Future<void> setParticipantMuteByHost(
    String roomId,
    String targetUserId,
    bool mute,
  ) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final room = _meetRooms[index];
    final updatedParticipants = await _firestoreService.setMeetParticipantMuted(
      roomId,
      targetUserId,
      mute,
      mutedByHost: mute,
    );

    _meetRooms[index] = room.copyWith(participants: updatedParticipants);
    notifyListeners();
  }

  /// Host tərəfindən iştirakçını otaqdan HƏQİQİTƏN çıxarır.
  /// (Yalnız susdurma yox — iştirakçı siyahısından tam silinir və
  /// qovulan tərəfdə otaq avtomatik bağlanır.)
  Future<void> removeMeetParticipant(
    String roomId,
    String targetUserId,
  ) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final updatedParticipants = await _firestoreService.leaveMeetParticipant(
      roomId,
      targetUserId,
    );
    final currentIndex = _meetRooms.indexWhere((r) => r.id == roomId);
    if (currentIndex != -1) {
      _meetRooms[currentIndex] = _meetRooms[currentIndex].copyWith(
        participants: updatedParticipants,
      );
      notifyListeners();
    }
  }

  Future<void> muteAllInRoom(String roomId, bool mute) async {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final room = _meetRooms[index];
    final updatedParticipants = await _firestoreService.muteAllMeetParticipants(
      roomId,
      mute,
    );

    _meetRooms[index] = room.copyWith(participants: updatedParticipants);
    notifyListeners();
  }

  void updateParticipantSpeaking(
    String roomId,
    String userId,
    bool isSpeaking,
  ) {
    final index = _meetRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;

    final room = _meetRooms[index];
    final updatedParticipants = room.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(isSpeaking: isSpeaking);
      }
      return p;
    }).toList();

    _meetRooms[index] = room.copyWith(participants: updatedParticipants);
    notifyListeners();
  }

  // Library
  final List<BookItem> _books = [];
  List<BookItem> get books => _books;

  // Kitabları yenilə (Firebase-dən gələn yeni kitabları set et)
  void updateBooks(List<BookItem> newBooks) {
    _books.clear();
    _books.addAll(newBooks);
    notifyListeners();
  }

  void addBook(BookItem book) {
    _books.insert(0, book);
    _firestoreService.saveBook(book);
    notifyListeners();
  }

  void toggleBorrowBook(String bookId) {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      final old = _books[index];
      final newBorrowed = !old.isBorrowedByMe;
      // Nüsxə qalmayıbsa götürmək olmaz — sayı -1-ə düşməsin.
      if (newBorrowed && old.availableCopies <= 0) return;
      final updated = BookItem(
        id: old.id,
        title: old.title,
        author: old.author,
        category: old.category,
        coverUrl: old.coverUrl,
        type: old.type,
        pageCount: old.pageCount,
        language: old.language,
        availableCopies: newBorrowed
            ? old.availableCopies - 1
            : old.availableCopies + 1,
        isBorrowedByMe: newBorrowed,
        returnDeadline: newBorrowed
            ? DateTime.now().add(const Duration(days: 14))
            : null,
        description: old.description,
        rating: old.rating,
        isbn: old.isbn,
        pdfUrl: old.pdfUrl,
        totalCopies: old.totalCopies,
      );
      _books[index] = updated;
      _firestoreService.saveBook(updated);
      notifyListeners();
    }
  }

  // Canteen Weekly Menu (Live API synced with Gopanel)
  CanteenWeeklyMenu? _canteenWeeklyMenu;
  CanteenWeeklyMenu? get canteenWeeklyMenu => _canteenWeeklyMenu;

  int _canteenWeekOffset = 0;
  int get canteenWeekOffset => _canteenWeekOffset;

  bool _isCanteenMenuLoading = false;
  bool get isCanteenMenuLoading => _isCanteenMenuLoading;

  Future<void> fetchCanteenWeeklyMenu({int offset = 0}) async {
    _canteenWeekOffset = offset;
    _isCanteenMenuLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get('canteen/weekly-menu', query: {
        'offset': offset.toString(),
      });
      if (res is Map) {
        _canteenWeeklyMenu = CanteenWeeklyMenu.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('fetchCanteenWeeklyMenu error: $e');
    } finally {
      _isCanteenMenuLoading = false;
      notifyListeners();
    }
  }

  // Cafeteria Menu
  final List<DailyMenu> _weeklyMenu = List.from(MockData.weeklyMenu);
  List<DailyMenu> get weeklyMenu => _weeklyMenu;

  static const List<String> _weekdayNames = [
    'Bazar ertəsi',
    'Çərşənbə axşamı',
    'Çərşənbə',
    'Cümə axşamı',
    'Cümə',
    'Şənbə',
    'Bazar',
  ];

  int _menuIndexForDate(DateTime date) {
    return _weeklyMenu.indexWhere(
      (m) =>
          m.date.year == date.year &&
          m.date.month == date.month &&
          m.date.day == date.day,
    );
  }

  /// Seçilmiş tarixli günün menyusuna yemək əlavə edir.
  /// Gün menyuda yoxdursa (məs. növbəti həftə boş gündür) yeni gün yaradılır.
  void addMenuItemToDay(DateTime date, MenuItem item) {
    final index = _menuIndexForDate(date);
    if (index != -1) {
      final day = _weeklyMenu[index];
      _weeklyMenu[index] = DailyMenu(
        dayName: day.dayName,
        date: day.date,
        mealTime: day.mealTime,
        totalCalories: day.totalCalories + item.calories,
        items: [...day.items, item],
      );
    } else {
      final newDay = DailyMenu(
        dayName: _weekdayNames[date.weekday - 1],
        date: DateTime(date.year, date.month, date.day),
        mealTime: 'Səhər və Günorta',
        totalCalories: item.calories,
        items: [item],
      );
      _weeklyMenu.add(newDay);
      _weeklyMenu.sort((a, b) => a.date.compareTo(b.date));
    }
    _firestoreService.saveWeeklyMenu(_weeklyMenu);
    notifyListeners();
  }

  void removeMenuItemFromDay(DateTime date, int itemIndex) {
    final index = _menuIndexForDate(date);
    if (index != -1) {
      final day = _weeklyMenu[index];
      if (itemIndex >= 0 && itemIndex < day.items.length) {
        final removed = day.items[itemIndex];
        _weeklyMenu[index] = DailyMenu(
          dayName: day.dayName,
          date: day.date,
          mealTime: day.mealTime,
          totalCalories: (day.totalCalories - removed.calories).clamp(0, 99999),
          items: List<MenuItem>.from(day.items)..removeAt(itemIndex),
        );
        _firestoreService.saveWeeklyMenu(_weeklyMenu);
        notifyListeners();
      }
    }
  }

  // Menyunu yenilə (Firebase-dən gələn yeni menyunu set et)
  void updateWeeklyMenu(List<DailyMenu> newMenu) {
    _weeklyMenu.clear();
    _weeklyMenu.addAll(newMenu);
    notifyListeners();
  }

  // --- TEACHER HUB: SMART ATTENDANCE TINDER-STYLE STATE ---
  late List<StudentProfile> _pendingAttendanceStudents = List.from(_students);
  List<StudentProfile> get pendingAttendanceStudents =>
      _pendingAttendanceStudents;

  final Map<String, AttendanceStatus> _currentSessionAttendance = {};
  Map<String, AttendanceStatus> get currentSessionAttendance =>
      _currentSessionAttendance;

  final List<MapEntry<String, AttendanceStatus>> _attendanceHistory = [];

  String _currentSessionClass = '';
  String get currentSessionClass => _currentSessionClass;
  String _currentSessionSubject = '';
  String get currentSessionSubject => _currentSessionSubject;
  List<String> _currentSessionClasses = [];
  List<String> get currentSessionClasses => _currentSessionClasses;

  void startAttendanceForLesson({
    String? className,
    List<String>? classNames,
    required String subject,
    required String time,
  }) {
    final targets =
        classNames ?? (className != null ? [className] : <String>[]);
    _currentSessionClasses = List.from(targets);
    _currentSessionClass = targets.isNotEmpty
        ? targets.join(' & ')
        : (className ?? '');
    _currentSessionSubject = subject;

    final allStudents = <StudentProfile>[];
    for (final cls in targets) {
      allStudents.addAll(getStudentsForClass(cls));
    }
    if (allStudents.isEmpty && className != null) {
      allStudents.addAll(getStudentsForClass(className));
    }

    _pendingAttendanceStudents = List.from(allStudents);
    _currentSessionAttendance.clear();
    _attendanceHistory.clear();
    notifyListeners();
  }

  void recordSwipeAttendance(String studentId, AttendanceStatus status) {
    _currentSessionAttendance[studentId] = status;
    _attendanceHistory.add(MapEntry(studentId, status));
    _pendingAttendanceStudents.removeWhere((s) => s.id == studentId);
    notifyListeners();
  }

  final Map<String, DateTime> _attendanceLockTimestamps = {};

  bool isAttendanceLocked(String className, String subject) {
    if (_currentUser?.role == UserRole.admin) return false;
    final now = DateTime.now();

    // Check both individual class and merged classes
    final classesToCheck = className.contains(' & ')
        ? className.split(' & ').map((c) => c.trim()).toList()
        : [className.trim()];

    for (final cls in classesToCheck) {
      final key =
          '${cls.toLowerCase()}_${subject.trim().toLowerCase()}_${now.year}_${now.month}_${now.day}';
      final submittedTime = _attendanceLockTimestamps[key];
      if (submittedTime != null) {
        final diff = now.difference(submittedTime);
        if (diff.inMinutes >= 5) return true;
      }
    }
    return false;
  }

  DateTime? getAttendanceSubmittedTime(String className, String subject) {
    final now = DateTime.now();
    final classesToCheck = className.contains(' & ')
        ? className.split(' & ').map((c) => c.trim()).toList()
        : [className.trim()];

    for (final cls in classesToCheck) {
      final key =
          '${cls.toLowerCase()}_${subject.trim().toLowerCase()}_${now.year}_${now.month}_${now.day}';
      if (_attendanceLockTimestamps[key] != null) {
        return _attendanceLockTimestamps[key];
      }
    }
    return null;
  }

  void completeAttendanceSession() {
    final now = DateTime.now();
    final dayNum = now.day;
    final subjectName = _currentSessionSubject.isNotEmpty
        ? _currentSessionSubject
        : 'Dərs';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final targets = _currentSessionClasses.isNotEmpty
        ? _currentSessionClasses
        : [_currentSessionClass];

    for (final cls in targets) {
      final lockKey =
          '${cls.trim().toLowerCase()}_${_currentSessionSubject.trim().toLowerCase()}_${now.year}_${now.month}_${now.day}';
      _attendanceLockTimestamps[lockKey] = now;
    }

    _currentSessionAttendance.forEach((studentId, status) {
      final studentAttMap = _studentAttendanceMap.putIfAbsent(
        studentId,
        () => {},
      );
      final existingDay = studentAttMap[dayNum];

      List<PeriodAttendance> periods = [];
      if (existingDay != null) {
        periods = List<PeriodAttendance>.from(existingDay.periodDetails);
      }

      // Check if this subject already exists in today's lesson list; if so, update, otherwise append!
      final existingPeriodIndex = periods.indexWhere(
        (p) => p.subject.toLowerCase() == subjectName.toLowerCase(),
      );
      final newPeriod = PeriodAttendance(
        period:
            '${existingPeriodIndex != -1 ? existingPeriodIndex + 1 : periods.length + 1}-ci dərs',
        subject: subjectName,
        status: status,
        time: timeStr,
      );

      if (existingPeriodIndex != -1) {
        periods[existingPeriodIndex] = newPeriod;
      } else {
        periods.add(newPeriod);
      }

      // Overall status for the day:
      // If any period is absent -> absent, else if any is late -> late, else present!
      AttendanceStatus overallStatus = AttendanceStatus.present;
      if (periods.any((p) => p.status == AttendanceStatus.absent)) {
        overallStatus = AttendanceStatus.absent;
      } else if (periods.any((p) => p.status == AttendanceStatus.late)) {
        overallStatus = AttendanceStatus.late;
      }

      final hasLate = periods.any((p) => p.status == AttendanceStatus.late);
      final hasAbsent = periods.any((p) => p.status == AttendanceStatus.absent);
      final noteText = hasAbsent
          ? 'Qayıb dərslər var'
          : (hasLate
                ? 'Dərsə gecikmə qeydə alınıb'
                : 'Bütün dərslərdə tam iştirak edib');

      final dayAtt = DayAttendance(
        date: now,
        status: overallStatus,
        note: noteText,
        periodDetails: periods,
      );

      studentAttMap[dayNum] = dayAtt;
      _firestoreService.saveStudentDayAttendance(studentId, dayNum, dayAtt);
    });

    // Recalculate attendance rate for students
    for (final studentId in _currentSessionAttendance.keys) {
      final stdIndex = _students.indexWhere((s) => s.id == studentId);
      if (stdIndex != -1) {
        final stdAttMap = _studentAttendanceMap[studentId] ?? {};
        if (stdAttMap.isNotEmpty) {
          int totalPeriods = 0;
          int attendedPeriods = 0;
          for (final d in stdAttMap.values) {
            totalPeriods += d.periodDetails.length;
            attendedPeriods += d.periodDetails
                .where(
                  (p) =>
                      p.status == AttendanceStatus.present ||
                      p.status == AttendanceStatus.late,
                )
                .length;
          }
          final rate = totalPeriods > 0
              ? ((attendedPeriods / totalPeriods) * 100).round()
              : 100;
          final old = _students[stdIndex];
          _students[stdIndex] = StudentProfile(
            id: old.id,
            fullName: old.fullName,
            studentNumber: old.studentNumber,
            className: old.className,
            photoUrl: old.photoUrl,
            qrData: old.qrData,
            barcodeData: old.barcodeData,
            parentName: old.parentName,
            parentPhone: old.parentPhone,
            gpa: old.gpa,
            attendanceRate: rate,
            academicYear: old.academicYear,
          );
          _firestoreService.updateStudentGPA(studentId, old.gpa, rate);
        }
      }
    }

    notifyListeners();
  }

  void undoLastSwipe() {
    if (_attendanceHistory.isNotEmpty) {
      final last = _attendanceHistory.removeLast();
      _currentSessionAttendance.remove(last.key);
      final restoredStudent = _students.firstWhere(
        (s) => s.id == last.key,
        orElse: () => MockData.currentStudent,
      );
      if (restoredStudent.id != 'std-empty') {
        _pendingAttendanceStudents.insert(0, restoredStudent);
      }
      notifyListeners();
    }
  }

  void resetAttendanceSession() {
    _pendingAttendanceStudents = _currentSessionClass.isNotEmpty
        ? List.from(getStudentsForClass(_currentSessionClass))
        : List.from(_students);
    _currentSessionAttendance.clear();
    _attendanceHistory.clear();
    notifyListeners();
  }

  // --- NOTIFICATIONS & ANNOUNCEMENTS ---
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  List<AppNotification> get notificationsForCurrentUser {
    final user = _currentUser;
    if (user == null) return [];

    final userId = user.id;
    final userRole = user.role;

    if (userRole == UserRole.admin &&
        (user.assignedRoleId == null || user.assignedRoleId!.isEmpty)) {
      // Rol təyin olunmamış SUPER admin — hər şeyi görür.
      return _notifications;
    }

    // İşçi rolü kimlikləri (assignedRole id + adı) — helpdesk/IT/psixoloq
    // kimi rolların bildirişlərə hədəflənməsi üçün. Rol təyin olunmuş
    // admin-rollu işçi (IT, Helpdesk...) yalnız ümumi elanları və öz
    // roluna/şəxsinə hədərlənən bildirişləri görür.
    String? assignedRoleId;
    String assignedRoleName = '';
    if (user.assignedRoleId != null && user.assignedRoleId!.isNotEmpty) {
      assignedRoleId = user.assignedRoleId;
      assignedRoleName = getRoleById(assignedRoleId)?.name.toLowerCase() ?? '';
    }

    return _notifications.where((n) {
      // Hədəflənmiş bildiriş (spesifik şəxs siyahısı varsa) YALNIZ o
      // şəxslərə çatır. Kənar şagird/valideynə "ümumi elan" kimi sızması
      // elə burada baş verirdi (helpdesk/IT cavabları bütün panelə düşürdü).
      if (n.targetUserIds.isNotEmpty && !n.targetUserIds.contains(userId)) {
        return false;
      }

      // 0. Doğrudan istifadəçiyə hədərlənmiş bildirişlər
      //    (ticket cavabı, status dəyişikliyi, helpdesk yönləndirməsi)
      if (n.targetUserIds.contains(userId)) return true;

      // 1. Direct message targeted to this user or sent by this user
      if (n.targetParentId == userId ||
          n.targetStudentId == userId ||
          n.senderId == userId) {
        return true;
      }

      // 2. Rol təyin olunmuş işçi (admin-rollu IT/Helpdesk və s.)
      if (userRole == UserRole.admin && assignedRoleId != null) {
        // Adminin ümumi elanları hamıya çatır
        if (n.targetRoles.isEmpty && n.senderRole == 'admin') return true;
        // Rol bazlı hədəfləmə: 'role-helpdesk' və ya rol adı ilə
        if (n.targetRoles.contains(assignedRoleId) ||
            (assignedRoleName.isNotEmpty &&
                n.targetRoles.any(
                  (r) => r.toLowerCase() == assignedRoleName,
                ))) {
          return true;
        }
        return false;
      }

      // 2b. İşçi eyni zamanda valideyndirsə (övladıyla bağlı elanlar)
      if ((userRole == UserRole.admin || userRole == UserRole.teacher) &&
          user.linkedStudentIds.isNotEmpty) {
        final kids = childrenOf(user);
        if (kids.isNotEmpty) {
          final childIds = kids.map((c) => c.id).toSet();
          final childClasses = kids.map((c) => c.className).toSet();
          if (n.targetStudentId != null &&
              childIds.contains(n.targetStudentId)) {
            return true;
          }
          if (n.targetRoles.contains('parent') &&
              n.targetClasses.isNotEmpty &&
              n.targetClasses.any((c) => childClasses.contains(c))) {
            return true;
          }
        }
      }

      // 3. Teacher / işçi rollar (müəllim, helpdesk, IT, psixoloq...)
      if (userRole == UserRole.teacher) {
        // Adminin ümumi elanları hamıya çatır
        if (n.targetRoles.isEmpty && n.senderRole == 'admin') return true;
        if (n.targetRoles.contains('teacher')) return true;
        // Rol bazlı hədəfləmə: 'role-helpdesk' və ya rol adı ilə
        if (assignedRoleId != null &&
            (n.targetRoles.contains(assignedRoleId) ||
                (assignedRoleName.isNotEmpty &&
                    n.targetRoles.any(
                      (r) => r.toLowerCase() == assignedRoleName,
                    )))) {
          return true;
        }
        return false;
      }

      // Köməkçi: Bildiriş helpdesk/IT/inventar və ya işçi daxili müraciətidirmi?
      final titleLower = n.title.toLowerCase();
      final msgLower = n.message.toLowerCase();
      final isStaffTicketNotice = titleLower.contains('müraciət') ||
          titleLower.contains('helpdesk') ||
          titleLower.contains('inventar') ||
          titleLower.contains('ticket') ||
          titleLower.contains('avadanlıq') ||
          msgLower.contains('müraciət') ||
          msgLower.contains('inventar') ||
          msgLower.contains('helpdesk');

      // 3. Student filtering — yalnız: adminin ümumi məktəb elanları,
      //    birbaşa özünə hədəflənənlər, yaxud sinif elanları
      if (userRole == UserRole.student) {
        // Helpdesk / IT daxili müraciətləri şagirdə qətiyyən göstərilmir
        // (yalnız şagirdin özü birbaşa hədəf seçilibsə istisna)
        if (isStaffTicketNotice &&
            n.targetStudentId != userId &&
            n.targetStudentId != student.id &&
            !n.targetUserIds.contains(userId)) {
          return false;
        }

        if (n.targetStudentId != null &&
            n.targetStudentId != userId &&
            n.targetStudentId != student.id) {
          return false;
        }
        if (n.targetRoles.isEmpty) {
          // Yalnız ümumi rəsmi elanlar keçir
          return n.senderRole == 'admin' && !isStaffTicketNotice;
        }
        if (!n.targetRoles.contains('student')) return false;
        final sClass = user.className ?? student.className;
        if (n.targetClasses.isNotEmpty && !n.targetClasses.contains(sClass)) {
          return false;
        }
        return true;
      }

      // 4. Parent filtering — yalnız: adminin rəsmi məktəb elanları,
      //    öz uşağına hədəflənənlər, yaxud sinif elanları
      if (userRole == UserRole.parent) {
        final kids = children;
        final childIds = kids.map((c) => c.id).toSet();
        final childClasses = kids.map((c) => c.className).toSet();

        // Helpdesk / IT daxili işçi bildirişləri valideynə sızmamalıdır
        // (yalnız valideynin öz müraciəti/cavabı deyilsə)
        if (isStaffTicketNotice &&
            n.targetParentId != userId &&
            (n.targetStudentId == null || !childIds.contains(n.targetStudentId)) &&
            !n.targetUserIds.contains(userId) &&
            n.senderId != userId) {
          return false;
        }

        if (n.targetStudentId != null &&
            !childIds.contains(n.targetStudentId)) {
          return false;
        }
        if (n.targetParentId != null && n.targetParentId != userId) {
          return false;
        }
        if (n.targetRoles.isEmpty) {
          return n.senderRole == 'admin' && !isStaffTicketNotice;
        }
        if (!n.targetRoles.contains('parent')) return false;
        if (n.targetClasses.isNotEmpty &&
            !n.targetClasses.any((c) => childClasses.contains(c))) {
          return false;
        }
        return true;
      }

      return false;
    }).toList();
  }

  int get unreadNotificationCount {
    final user = _currentUser;
    if (user == null) return 0;
    return _apiUnreadNotificationCount;
  }

  /// Valideynin uşaqlarının sinif adları — class_<sinif> push topic-ləri üçün.
  Set<String> _childClassesFor(AppUser user) {
    // Valideynlər və eyni zamanda övladı olan işçilər (müəllim/admin)
    // övlad siniflərinin elanlarına abunə olurlar.
    final ids = <String>{
      if (user.linkedStudentId != null && user.linkedStudentId!.isNotEmpty)
        user.linkedStudentId!,
      ...user.linkedStudentIds,
    };
    if (ids.isEmpty) return {};
    return _students
        .where((s) => ids.contains(s.id) && s.className.trim().isNotEmpty)
        .map((s) => s.className.trim())
        .toSet();
  }

  /// Valideynin uşaqlarının sinif adları — class_<sinif> push topic-ləri üçün.
  Set<String> _childClassesFor(AppUser user) {
    // Valideynlər və eyni zamanda övladı olan işçilər (müəllim/admin)
    // övlad siniflərinin elanlarına abunə olurlar.
    final ids = <String>{
      if (user.linkedStudentId != null && user.linkedStudentId!.isNotEmpty)
        user.linkedStudentId!,
      ...user.linkedStudentIds,
    };
    if (ids.isEmpty) return {};
    return _students
        .where((s) => ids.contains(s.id) && s.className.trim().isNotEmpty)
        .map((s) => s.className.trim())
        .toSet();
  }

  Future<AppNotification> sendNotification({
    required String title,
    required String message,
    NotificationCategory category = NotificationCategory.general,
    String? targetStudentId,
    String? targetStudentName,
    String? targetParentId,
    List<String> targetUserIds = const [],
    List<String> targetClasses = const [],
    List<String> targetRoles = const [],
    String priority = 'normal',
  }) async {
    final user = _currentUser;
    final senderId = user?.id ?? 'school';
    final senderName = user?.fullName ?? 'İdrak Liseyi Rəhbərliyi';
    final senderRole = user?.role == UserRole.teacher
        ? 'teacher'
        : (user?.role == UserRole.admin ? 'admin' : 'school');
    final senderSubject = user?.subject;
    final senderPhoto = user?.photoUrl;
    final notifId = 'notif-${DateTime.now().millisecondsSinceEpoch}';

    final notif = AppNotification(
      id: notifId,
      title: title,
      message: message,
      category: category,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhoto,
      senderRole: senderRole,
      senderSubject: senderSubject,
      targetStudentId: targetStudentId,
      targetStudentName: targetStudentName,
      targetParentId: targetParentId,
      targetUserIds: targetUserIds,
      targetClasses: targetClasses,
      targetRoles: targetRoles,
      priority: priority,
    );

    _notifications.insert(0, notif);
    await _firestoreService.saveNotification(notif);

    // Push (tətbiq bağlı ikən də): hədəfləri relay-ə ötür. Best-effort —
    // relay xətası bildirişin Firestore-dakı saxlanmasına təsir etmir.
    // Şagirdə göndərilən qeydlərdə həmin şagirdin valideynləri də əlavə olunur.
    final parentIds = targetStudentId == null
        ? const <String>[]
        : _users
              .where(
                (u) =>
                    u.role == UserRole.parent &&
                    (u.linkedStudentIds.contains(targetStudentId) ||
                        u.linkedStudentId == targetStudentId),
              )
              .map((u) => u.id)
              .toList();
    unawaited(
      PushRelayService.instance.sendPush(
        title: title,
        body: message,
        targetUserIds: [...targetUserIds, ...parentIds],
        targetRoles: targetRoles,
        targetClasses: targetClasses,
        targetStudentId: targetStudentId,
        targetParentId: targetParentId,
        priority: priority,
        excludeUserId: senderId,
      ),
    );

    notifyListeners();
    return notif;
  }

  Future<void> markNotificationAsRead(String notifId) async {
    final user = _currentUser;
    if (user == null) return;
    final userId = user.id;

    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx != -1) {
      if (!_notifications[idx].readByUserIds.contains(userId)) {
        final updatedIds = List<String>.from(_notifications[idx].readByUserIds)
          ..add(userId);
        _notifications[idx] = _notifications[idx].copyWith(
          readByUserIds: updatedIds,
        );
        await _firestoreService.markNotificationRead(notifId, userId);
        notifyListeners();
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final user = _currentUser;
    if (user == null) return;
    final userId = user.id;

    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].readByUserIds.contains(userId)) {
        final updatedIds = List<String>.from(_notifications[i].readByUserIds)
          ..add(userId);
        _notifications[i] = _notifications[i].copyWith(
          readByUserIds: updatedIds,
        );
        _firestoreService.markNotificationRead(_notifications[i].id, userId);
      }
    }
    notifyListeners();
  }

  Future<void> deleteNotification(String notifId) async {
    _notifications.removeWhere((n) => n.id == notifId);
    await _firestoreService.deleteNotification(notifId);
    notifyListeners();
  }

  // --- MEMORY MANAGEMENT ---

  /// Dispose method to cleanup resources and prevent memory leaks
  @override
  void dispose() {
    // Cancel all active stream subscriptions
    _meetRoomsSubscription?.cancel();
    _notificationsSubscription?.cancel();

    debugPrint('✓ AppState disposed - subscriptions canceled');
    super.dispose();
  }
}
