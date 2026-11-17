class StudentProfile {
  final String id;
  final String fullName;
  final String studentNumber; // e.g. "İDR-BAK-STD-0000714"
  final String className;     // e.g. "4 R2"
  final String photoUrl;
  final String qrData;
  final String barcodeData;
  
  // Genişləndirilmiş şagird məlumatları (GoPanel 1:1)
  final String? firstName;
  final String? lastName;
  final String? fatherName;    // Ata adı
  final String? finCode;       // 7 rəqəm
  final String? gender;        // Kişi / Qadın
  final DateTime? birthDate;
  final String? address;
  final String? registrationAddress;
  final String? email;
  final String? phone;
  final String? bloodGroup;    // Qan qrupu
  final String? eyeColor;      // Göz rəngi
  final String? sector;        // Bölmə ("Azərbaycan", "Rus", "İngilis")
  final List<String>? allergies; // Alergiyalar
  
  // Veli məlumatları
  final String parentName;
  final String parentPhone;
  final String? parentEmail;
  final String? parentAddress;
  final String? parentRelation;
  
  // Müqavilə və Akademik məlumatlar
  final String? contractNumber;
  final String? contractStatus;
  final double? contractAmount;
  final double gpa;           // e.g. 4.8 / 5.0
  final int attendanceRate;   // e.g. 96%
  final String academicYear;  // "2025 - 2026"
  final bool isCurrentYear;   // Cari tədris ilində aktiv oxuyur

  StudentProfile({
    required this.id,
    required this.fullName,
    required this.studentNumber,
    required this.className,
    required this.photoUrl,
    required this.qrData,
    required this.barcodeData,
    this.firstName,
    this.lastName,
    this.fatherName,
    this.finCode,
    this.gender,
    this.birthDate,
    this.address,
    this.registrationAddress,
    this.email,
    this.phone,
    this.bloodGroup,
    this.eyeColor,
    this.sector,
    this.allergies,
    required this.parentName,
    required this.parentPhone,
    this.parentEmail,
    this.parentAddress,
    this.parentRelation,
    this.contractNumber,
    this.contractStatus,
    this.contractAmount,
    required this.gpa,
    required this.attendanceRate,
    required this.academicYear,
    this.isCurrentYear = false,
  });

  StudentProfile copyWith({
    String? fullName,
    String? studentNumber,
    String? className,
    String? photoUrl,
    String? qrData,
    String? barcodeData,
    String? firstName,
    String? lastName,
    String? fatherName,
    String? finCode,
    String? gender,
    DateTime? birthDate,
    String? address,
    String? registrationAddress,
    String? email,
    String? phone,
    String? bloodGroup,
    String? eyeColor,
    String? sector,
    List<String>? allergies,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? parentAddress,
    String? parentRelation,
    String? contractNumber,
    String? contractStatus,
    double? contractAmount,
    double? gpa,
    int? attendanceRate,
    String? academicYear,
    bool? isCurrentYear,
  }) {
    return StudentProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      studentNumber: studentNumber ?? this.studentNumber,
      className: className ?? this.className,
      photoUrl: photoUrl ?? this.photoUrl,
      qrData: qrData ?? this.qrData,
      barcodeData: barcodeData ?? this.barcodeData,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      finCode: finCode ?? this.finCode,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      registrationAddress: registrationAddress ?? this.registrationAddress,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      eyeColor: eyeColor ?? this.eyeColor,
      sector: sector ?? this.sector,
      allergies: allergies ?? this.allergies,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      parentAddress: parentAddress ?? this.parentAddress,
      parentRelation: parentRelation ?? this.parentRelation,
      contractNumber: contractNumber ?? this.contractNumber,
      contractStatus: contractStatus ?? this.contractStatus,
      contractAmount: contractAmount ?? this.contractAmount,
      gpa: gpa ?? this.gpa,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      academicYear: academicYear ?? this.academicYear,
      isCurrentYear: isCurrentYear ?? this.isCurrentYear,
    );
  }
}
