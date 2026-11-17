import '../../providers/app_state.dart';

class TeacherPermissions {
  final bool canManageCafeteria; // Kantin / Yeməkxana menyusunu dəyişə bilsin
  final bool canManageMedical;   // Şagirdin xəstəlik və tibbi qeydlərinə əlavə edə bilsin
  final bool canManageInventory; // İnventar QR ticketlərini idarə edə bilsin

  const TeacherPermissions({
    this.canManageCafeteria = false,
    this.canManageMedical = false,
    this.canManageInventory = true,
  });

  TeacherPermissions copyWith({
    bool? canManageCafeteria,
    bool? canManageMedical,
    bool? canManageInventory,
  }) {
    return TeacherPermissions(
      canManageCafeteria: canManageCafeteria ?? this.canManageCafeteria,
      canManageMedical: canManageMedical ?? this.canManageMedical,
      canManageInventory: canManageInventory ?? this.canManageInventory,
    );
  }

  Map<String, dynamic> toJson() => {
    'canManageCafeteria': canManageCafeteria,
    'canManageMedical': canManageMedical,
    'canManageInventory': canManageInventory,
  };
}

class AppUser {
  final String id;
  final String username;
  final String password;
  final String fullName;
  
  // HR & Dynamic Fields (GoPanel 1:1)
  final String? firstName;     // Ad (ayrıca)
  final String? lastName;      // Soyad (ayrıca)
  final String? fatherName;    // Ata adı
  final String? finCode;       // FIN kod (7 rəqəm)
  final String? gender;        // Cins: "Kişi" / "Qadın"
  final DateTime? birthDate;   // Doğum tarixi
  final String? address;       // Yaşadığı ünvan
  final String? registrationAddress; // Qeydiyyat ünvanı
  final String? citizenship;   // Vətəndaşlıq (sayt modeli: vetendasligi)
  final String? idCardSerial;  // ŞV seriyası və nömrəsi
  final String? idCardNumber;  // ŞV nömrəsi
  final String? corporatePhone;// Korporativ telefon nömrəsi
  final String? maritalStatus; // Ailə vəziyyəti (Evli / Subay)
  final String? bloodGroup;    // Qan qrupu
  final String? scientificDegree; // Elmi dərəcə
  final String? honoraryTitle; // Fəxri ad
  final String? educationLevel;// Təhsil dərəcəsi (sayt modeli: tehsil_derecesi)
  final String? university;    // Təhsil müəssisəsi adı
  final String? specialty;     // İxtisas
  final String? eduDocNumber;  // Diplom / Sənəd nömrəsi
  final String? diplomaNumber; // Diplom nömrəsi alias
  final String? bankName;      // Bank adı (sayt modeli: bank_adi)
  final String? bankAccount;   // Hesab nömrəsi
  final String? bankIban;      // Bank IBAN

  // İş & Müqavilə məlumatları (HR)
  final String? position;      // Vəzifə adı (məs: "İT üzrə mütəxəssis")
  final String? department;    // Struktur / Departament
  final String? filial;        // Filial (məs: "Bakı filialı")
  final String? sector;        // Bölmə ("Azərbaycan", "Rus", "İngilis")
  final DateTime? hireDate;    // İşə qəbul tarixi
  final double? salary;        // Əmək haqqı (AZN, gross)
  final double? netSalary;     // Xalis (net) əmək haqqı
  final String? contractNumber;// Müqavilə nömrəsi
  final String? contractType;  // 'indefinite' / 'fixed'
  final DateTime? contractStart; // Müqavilə başlanğıc tarixi
  final DateTime? contractEnd;   // Müqavilə bitmə tarixi
  final List<String> roleNames;  // Bütün Spatie rolları
  
  final UserRole role; // admin, teacher, student, parent
  final String idrakCode; // e.g. "IDR-2025-0492" or "IDR-TCH-102"
  final String phone;
  final String? email;
  final String? photoUrl;
  final String? className; // for student
  final List<String> assignedClasses; // for teacher (e.g. ['9B', '10A'])
  final String? subject;   // for teacher
  final String? roomNumber;// for teacher
  final String? linkedStudentId; // For parent to link to their child
  final List<String> linkedStudentIds; // Övladlar: valideynin bütün uşaqları (sayt modeli)
  final TeacherPermissions? teacherPermissions; // For teacher
  final String? assignedRoleId; // Atanan özel rol ID'si
  final List<String> directPermissions; // Birbaşa istifadəçiyə verilmiş xüsusi icazələr
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.fatherName,
    this.finCode,
    this.gender,
    this.birthDate,
    this.address,
    this.registrationAddress,
    this.citizenship,
    this.idCardSerial,
    this.idCardNumber,
    this.corporatePhone,
    this.maritalStatus,
    this.bloodGroup,
    this.scientificDegree,
    this.honoraryTitle,
    this.educationLevel,
    this.university,
    this.specialty,
    this.eduDocNumber,
    this.diplomaNumber,
    this.bankName,
    this.bankAccount,
    this.bankIban,
    this.position,
    this.department,
    this.filial,
    this.sector,
    this.hireDate,
    this.salary,
    this.netSalary,
    this.contractNumber,
    this.contractType,
    this.contractStart,
    this.contractEnd,
    this.roleNames = const [],
    required this.role,
    required this.idrakCode,
    this.phone = '',
    this.email,
    this.photoUrl,
    this.className,
    this.assignedClasses = const [],
    this.subject,
    this.roomNumber,
    this.linkedStudentId,
    this.linkedStudentIds = const [],
    this.teacherPermissions,
    this.assignedRoleId,
    this.directPermissions = const [],
    this.isActive = true,
    required this.createdAt,
  });

  AppUser copyWith({
    String? username,
    String? password,
    String? fullName,
    String? firstName,
    String? lastName,
    String? fatherName,
    String? finCode,
    String? gender,
    DateTime? birthDate,
    String? address,
    String? registrationAddress,
    String? citizenship,
    String? idCardSerial,
    String? idCardNumber,
    String? corporatePhone,
    String? maritalStatus,
    String? bloodGroup,
    String? scientificDegree,
    String? honoraryTitle,
    String? educationLevel,
    String? university,
    String? specialty,
    String? eduDocNumber,
    String? diplomaNumber,
    String? bankName,
    String? bankAccount,
    String? bankIban,
    String? position,
    String? department,
    String? filial,
    String? sector,
    DateTime? hireDate,
    double? salary,
    double? netSalary,
    String? contractNumber,
    String? contractType,
    DateTime? contractStart,
    DateTime? contractEnd,
    List<String>? roleNames,
    UserRole? role,
    String? idrakCode,
    String? phone,
    String? email,
    String? photoUrl,
    String? className,
    List<String>? assignedClasses,
    String? subject,
    String? roomNumber,
    String? linkedStudentId,
    List<String>? linkedStudentIds,
    TeacherPermissions? teacherPermissions,
    String? assignedRoleId,
    List<String>? directPermissions,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      finCode: finCode ?? this.finCode,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      registrationAddress: registrationAddress ?? this.registrationAddress,
      citizenship: citizenship ?? this.citizenship,
      idCardSerial: idCardSerial ?? this.idCardSerial,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      corporatePhone: corporatePhone ?? this.corporatePhone,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      scientificDegree: scientificDegree ?? this.scientificDegree,
      honoraryTitle: honoraryTitle ?? this.honoraryTitle,
      educationLevel: educationLevel ?? this.educationLevel,
      university: university ?? this.university,
      specialty: specialty ?? this.specialty,
      eduDocNumber: eduDocNumber ?? diplomaNumber ?? this.eduDocNumber,
      diplomaNumber: diplomaNumber ?? eduDocNumber ?? this.diplomaNumber,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankIban: bankIban ?? this.bankIban,
      position: position ?? this.position,
      department: department ?? this.department,
      filial: filial ?? this.filial,
      sector: sector ?? this.sector,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      netSalary: netSalary ?? this.netSalary,
      contractNumber: contractNumber ?? this.contractNumber,
      contractType: contractType ?? this.contractType,
      contractStart: contractStart ?? this.contractStart,
      contractEnd: contractEnd ?? this.contractEnd,
      roleNames: roleNames ?? this.roleNames,
      role: role ?? this.role,
      idrakCode: idrakCode ?? this.idrakCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      className: className ?? this.className,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      subject: subject ?? this.subject,
      roomNumber: roomNumber ?? this.roomNumber,
      linkedStudentId: linkedStudentId ?? this.linkedStudentId,
      linkedStudentIds: linkedStudentIds ?? this.linkedStudentIds,
      teacherPermissions: teacherPermissions ?? this.teacherPermissions,
      assignedRoleId: assignedRoleId ?? this.assignedRoleId,
      directPermissions: directPermissions ?? this.directPermissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
