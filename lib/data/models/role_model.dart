// Rol və Səlahiyyət Modeli (GoPanel Web 1:1 Spatie İcazə Kataloqu ilə)

class Permission {
  final String id;
  final String name;
  final String description;
  final String category;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
  };

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    category: json['category']?.toString() ?? 'Sistem İdarəetməsi',
  );
}

class Role {
  final String id;
  final String name;
  final String description;
  final List<String> permissionIds;
  final bool isDefault;
  final bool isDeletable;
  final DateTime createdAt;

  Role({
    required this.id,
    required this.name,
    required this.description,
    this.permissionIds = const [],
    this.isDefault = false,
    this.isDeletable = true,
    required this.createdAt,
  });

  Role copyWith({
    String? name,
    String? description,
    List<String>? permissionIds,
    bool? isDefault,
    bool? isDeletable,
  }) {
    return Role(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissionIds: permissionIds ?? this.permissionIds,
      isDefault: isDefault ?? this.isDefault,
      isDeletable: isDeletable ?? this.isDeletable,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'permissionIds': permissionIds,
    'isDefault': isDefault,
    'isDeletable': isDeletable,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    permissionIds: List<String>.from(json['permissionIds'] ?? []),
    isDefault: json['isDefault'] ?? false,
    isDeletable: json['isDeletable'] ?? true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

class DefaultPermissions {
  static List<Permission> _dynamicCatalog = [];

  static void setDynamicCatalog(List<Permission> catalog) {
    if (catalog.isNotEmpty) {
      _dynamicCatalog = catalog;
    }
  }

  static List<Permission> get all =>
      _dynamicCatalog.isNotEmpty ? _dynamicCatalog : _builtInWebCatalog;

  static const List<Permission> _builtInWebCatalog = [
    // Şagird və Valideyn (Şagird Əməliyyatları)
    Permission(id: 'gopanel.academic.students.view', name: 'Şagirdlər — Siyahı və 360 Profil', description: 'gopanel.academic.students.view', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.create', name: 'Şagirdlər — Yeni şagird yaratmaq', description: 'gopanel.academic.students.create', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.update', name: 'Şagirdlər — Məlumatları redaktə etmək', description: 'gopanel.academic.students.update', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.delete', name: 'Şagirdlər — Şagirdi silmək', description: 'gopanel.academic.students.delete', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.view_password', name: 'Şagirdlər — Giriş və şifrə məlumatlarını görmək', description: 'gopanel.academic.students.view_password', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.more_info', name: 'Şagirdlər — Daxili qeydlər və tarixçə', description: 'gopanel.academic.students.more_info', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.manage_relations', name: 'Şagirdlər — Valideyn və qohumluq əlaqələri', description: 'gopanel.academic.students.manage_relations', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.finance.student_contracts.view', name: 'Şagird müqavilələri — Müqavilə və təhsil haqqına baxış', description: 'gopanel.finance.student_contracts.view', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.finance.student_contracts.create', name: 'Şagird müqavilələri — Yeni müqavilə bağlamaq', description: 'gopanel.finance.student_contracts.create', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.transitions.exceptions.view', name: 'Bölmə dəyişiklikləri — Keçid istisnalarına baxış', description: 'gopanel.academic.transitions.exceptions.view', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.students.admissions', name: 'Şagird qəbulu — Müraciətlər və qəbul prosesi', description: 'gopanel.academic.students.admissions', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),
    Permission(id: 'gopanel.academic.graduations.view', name: 'Məzunlar — Məzuniyyət siyahısına baxış', description: 'gopanel.academic.graduations.view', category: 'Şagird və Valideyn (Şagird Əməliyyatları)'),

    // E-məktəb (Akademik)
    Permission(id: 'gopanel.academic.students.admissions', name: 'Şagird qəbulu — Baxış və İdarə', description: 'gopanel.academic.students.admissions', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.students.view', name: 'Şagirdlər — Baxış', description: 'gopanel.academic.students.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.students.create', name: 'Şagirdlər — Yaratmaq', description: 'gopanel.academic.students.create', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.students.update', name: 'Şagirdlər — Redaktə', description: 'gopanel.academic.students.update', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.students.delete', name: 'Şagirdlər — Silmək', description: 'gopanel.academic.students.delete', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.graduations.view', name: 'Məzunlar — Baxış', description: 'gopanel.academic.graduations.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.classes.view', name: 'Siniflər — Baxış', description: 'gopanel.academic.classes.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.classes.create', name: 'Siniflər — Yaratmaq', description: 'gopanel.academic.classes.create', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.classes.update', name: 'Siniflər — Redaktə', description: 'gopanel.academic.classes.update', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.schedules.view', name: 'Cədvəl — Baxış', description: 'gopanel.academic.schedules.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.schedules.manage', name: 'Cədvəl — İdarəetmə', description: 'gopanel.academic.schedules.manage', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.ejournal.view', name: 'E-Jurnal — Baxış', description: 'gopanel.academic.ejournal.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.homeroom.excuses.view', name: 'Üzürlü qayıb sorğuları — Baxış', description: 'gopanel.academic.homeroom.excuses.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.homeroom.excuses.approve', name: 'Üzürlü qayıb sorğuları — Təsdiqləmək', description: 'gopanel.academic.homeroom.excuses.approve', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.ejournal.curriculums.view', name: 'Kurikulum — Baxış', description: 'gopanel.academic.ejournal.curriculums.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.subjects.view', name: 'Fənlər — Baxış', description: 'gopanel.academic.foundations.subjects.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.clubs.view', name: 'Dərnəklər — Baxış', description: 'gopanel.academic.clubs.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.clubs.create', name: 'Dərnəklər — Yaratmaq', description: 'gopanel.academic.clubs.create', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.clubs.update', name: 'Dərnəklər — Redaktə', description: 'gopanel.academic.clubs.update', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.clubs.delete', name: 'Dərnəklər — Silmək', description: 'gopanel.academic.clubs.delete', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.clubs.journal.view', name: 'Dərnək Jurnalı — Baxış', description: 'gopanel.academic.clubs.journal.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.years.view', name: 'Akademik illər — Baxış', description: 'gopanel.academic.foundations.years.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.rooms.view', name: 'Otaqlar — Baxış', description: 'gopanel.academic.foundations.rooms.view', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.rooms.create', name: 'Otaqlar — Yaratmaq', description: 'gopanel.academic.foundations.rooms.create', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.rooms.update', name: 'Otaqlar — Redaktə', description: 'gopanel.academic.foundations.rooms.update', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.rooms.delete', name: 'Otaqlar — Silmək', description: 'gopanel.academic.foundations.rooms.delete', category: 'E-məktəb (Akademik)'),
    Permission(id: 'gopanel.academic.foundations.time_slots.view', name: 'Zəng cədvəli — Baxış', description: 'gopanel.academic.foundations.time_slots.view', category: 'E-məktəb (Akademik)'),

    // İnsan Resursları (HR)
    Permission(id: 'gopanel.structure.structures.view', name: 'Təşkilati struktur — Baxış', description: 'gopanel.structure.structures.view', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.structure.positions.view', name: 'Vəzifələr — Baxış', description: 'gopanel.structure.positions.view', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.employees.view', name: 'Əməkdaşlar — Baxış', description: 'gopanel.hr.employees.view', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.employees.create', name: 'Əməkdaşlar — Yaratmaq', description: 'gopanel.hr.employees.create', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.employees.update', name: 'Əməkdaşlar — Redaktə', description: 'gopanel.hr.employees.update', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.employees.delete', name: 'Əməkdaşlar — Silmək', description: 'gopanel.hr.employees.delete', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.contracts.view', name: 'Müqavilələr — Baxış', description: 'gopanel.hr.contracts.view', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.contracts.create', name: 'Müqavilələr — Yaratmaq', description: 'gopanel.hr.contracts.create', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.documents.view', name: 'İşçi sənədləri — Baxış', description: 'gopanel.hr.documents.view', category: 'İnsan Resursları (HR)'),
    Permission(id: 'gopanel.hr.attendances.view', name: 'Davamiyyət — Baxış', description: 'gopanel.hr.attendances.view', category: 'İnsan Resursları (HR)'),

    // Maliyyə və Mühasibatlıq
    Permission(id: 'gopanel.finance.student_contracts.view', name: 'Şagird müqavilələri — Baxış', description: 'gopanel.finance.student_contracts.view', category: 'Maliyyə və Mühasibatlıq'),
    Permission(id: 'gopanel.finance.payments.view', name: 'Ödənişlər — Baxış', description: 'gopanel.finance.payments.view', category: 'Maliyyə və Mühasibatlıq'),
    Permission(id: 'gopanel.finance.payroll.view', name: 'Əmək haqqı hesablanması — Baxış', description: 'gopanel.finance.payroll.view', category: 'Maliyyə və Mühasibatlıq'),
    Permission(id: 'gopanel.finance.ledger.view', name: 'Gəlir/xərc — Baxış', description: 'gopanel.finance.ledger.view', category: 'Maliyyə və Mühasibatlıq'),
    Permission(id: 'gopanel.finance.dictionary.view', name: 'Maliyyə tənzimləmələri — Baxış', description: 'gopanel.finance.dictionary.view', category: 'Maliyyə və Mühasibatlıq'),

    // Təsərrüfat və İnventar
    Permission(id: 'gopanel.warehouse.items.view', name: 'Anbar inventarı — Baxış', description: 'gopanel.warehouse.items.view', category: 'Anbar və İnventar'),
    Permission(id: 'gopanel.warehouse_actions.inventorizations.view', name: 'İnventarizasiya — Baxış', description: 'gopanel.warehouse_actions.inventorizations.view', category: 'Anbar və İnventar'),
    Permission(id: 'gopanel.canteen.canteens.view', name: 'Yeməkxana — Baxış', description: 'gopanel.canteen.canteens.view', category: 'Yeməkxana'),
    Permission(id: 'gopanel.canteen.menu.view', name: 'Həftəlik Menyu — Baxış', description: 'gopanel.canteen.menu.view', category: 'Yeməkxana'),

    // Tibb və Psixologiya
    Permission(id: 'gopanel.medical.medical_results.view', name: 'Tibbi müayinə nəticələri — Baxış', description: 'gopanel.medical.medical_results.view', category: 'Tibbi Əməliyyatlar'),
    Permission(id: 'gopanel.medical.reference_journals.view', name: 'Tibbi arayış jurnalı — Baxış', description: 'gopanel.medical.reference_journals.view', category: 'Tibbi Əməliyyatlar'),
    Permission(id: 'gopanel.medical.excuses.view', name: 'Tibbi üzürlü qayıblar — Baxış', description: 'gopanel.medical.excuses.view', category: 'Tibbi Əməliyyatlar'),
    Permission(id: 'gopanel.psicology.psicology_results.view', name: 'Psixologiya nəticələri — Baxış', description: 'gopanel.psicology.psicology_results.view', category: 'Psixologiya'),

    // İmtahanlar
    Permission(id: 'gopanel.exams.exam_categories.view', name: 'İmtahan kateqoriyaları — Baxış', description: 'gopanel.exams.exam_categories.view', category: 'İmtahanlar'),
    Permission(id: 'gopanel.exams.exams.view', name: 'İmtahanlar — Baxış', description: 'gopanel.exams.exams.view', category: 'İmtahanlar'),
    Permission(id: 'gopanel.exams.results.view', name: 'İmtahan nəticələri — Baxış', description: 'gopanel.exams.results.view', category: 'İmtahanlar'),

    // Dəstək Biletləri
    Permission(id: 'gopanel.tickets.view', name: 'Dəstək biletləri — Baxış', description: 'gopanel.tickets.view', category: 'Dəstək Biletləri (Helpdesk)'),
    Permission(id: 'gopanel.tickets.create', name: 'Dəstək bileti — Yaratmaq', description: 'gopanel.tickets.create', category: 'Dəstək Biletləri (Helpdesk)'),
    Permission(id: 'gopanel.tickets.respond', name: 'Dəstək biletinə — Cavab yazmaq', description: 'gopanel.tickets.respond', category: 'Dəstək Biletləri (Helpdesk)'),

    // Kitabxana
    Permission(id: 'gopanel.library.books.view', name: 'Kitablar — Baxış', description: 'gopanel.library.books.view', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.books.create', name: 'Kitablar — Əlavə etmək', description: 'gopanel.library.books.create', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.books.update', name: 'Kitablar — Redaktə', description: 'gopanel.library.books.update', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.books.delete', name: 'Kitablar — Silmək', description: 'gopanel.library.books.delete', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.loans.view', name: 'Kitab icarələri — Baxış', description: 'gopanel.library.loans.view', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.loans.create', name: 'Kitab icarələri — Yaratmaq', description: 'gopanel.library.loans.create', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.reservations.view', name: 'Kitab reservasiyaları — Baxış', description: 'gopanel.library.reservations.view', category: 'Kitabxana'),
    Permission(id: 'gopanel.library.reservations.approve', name: 'Kitab reservasiyaları — Təsdiqləmək', description: 'gopanel.library.reservations.approve', category: 'Kitabxana'),

    // Statistika və Hesabatlar
    Permission(id: 'gopanel.statistics.quality_control.view', name: 'Keyfiyyətə nəzarət — Baxış', description: 'gopanel.statistics.quality_control.view', category: 'Statistika və Hesabatlar'),
    Permission(id: 'gopanel.statistics.attendance.view', name: 'Davamiyyət statistikası — Baxış', description: 'gopanel.statistics.attendance.view', category: 'Statistika və Hesabatlar'),
    Permission(id: 'gopanel.academic.statistics.performance', name: 'Şagird performans statistikası — Baxış', description: 'gopanel.academic.statistics.performance', category: 'Statistika və Hesabatlar'),
    Permission(id: 'gopanel.academic.teachers.report.view', name: 'İş yükü hesabatı — Baxış', description: 'gopanel.academic.teachers.report.view', category: 'Statistika və Hesabatlar'),

    // Sistem və Loqlar
    Permission(id: 'gopanel.notifications.view', name: 'Bildirişlər — Baxış', description: 'gopanel.notifications.view', category: 'Bildirişlər'),
    Permission(id: 'gopanel.notifications.create', name: 'Bildirişlər — Göndərmək', description: 'gopanel.notifications.create', category: 'Bildirişlər'),
    Permission(id: 'gopanel.admins.view', name: 'Adminlər — Baxış', description: 'gopanel.admins.view', category: 'Sistem İdarəetməsi'),
    Permission(id: 'gopanel.roles.view', name: 'Vəzifələr (Rollar) — Baxış', description: 'gopanel.roles.view', category: 'Sistem İdarəetməsi'),
    Permission(id: 'gopanel.roles.create', name: 'Vəzifələr (Rollar) — Yaratmaq', description: 'gopanel.roles.create', category: 'Sistem İdarəetməsi'),
    Permission(id: 'gopanel.roles.update', name: 'Vəzifələr (Rollar) — Redaktə', description: 'gopanel.roles.update', category: 'Sistem İdarəetməsi'),
    Permission(id: 'gopanel.roles.delete', name: 'Vəzifələr (Rollar) — Silmək', description: 'gopanel.roles.delete', category: 'Sistem İdarəetməsi'),
    Permission(id: 'gopanel.activity.logs.view', name: 'Sistem loqları — Baxış', description: 'gopanel.activity.logs.view', category: 'Sistem Loqları'),
  ];

  static Map<String, List<Permission>> get byCategory {
    final Map<String, List<Permission>> grouped = {};
    for (final permission in all) {
      grouped.putIfAbsent(permission.category, () => []).add(permission);
    }
    return grouped;
  }
}

class DefaultRoles {
  static List<Role> createAll() {
    final now = DateTime.now();
    return [
      Role(
        id: 'SuperAdmin',
        name: 'SuperAdmin',
        description: 'Sistem inzibatçısı — Bütün səlahiyyətlər',
        permissionIds: DefaultPermissions.all.map((p) => p.id).toList(),
        isDefault: true,
        isDeletable: false,
        createdAt: now,
      ),
    ];
  }
}
