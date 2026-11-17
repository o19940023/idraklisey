
/// Employee model representing school staff and pedagogical personnel.
class Employee {
  final String id;
  final String uid;
  final String code;
  final String finCode;
  final String fullName;
  final String firstName;
  final String lastName;
  final String fatherName;
  final String position;
  final String department;
  final String email;
  final String phone;
  final String? corporatePhone;
  final String? photoUrl;
  final String status; // 'active', 'onLeave', 'inactive'
  final DateTime hireDate;
  final DateTime? birthDate;
  final double salary;
  final double netSalary;
  final String? filial;
  final String? sector; // 'Azərbaycan', 'Rus', 'İngilis'
  final String gender;
  final String idCardSerial;
  final String maritalStatus;
  final String bloodGroup;
  final String address;
  final String educationLevel;
  final String university;
  final String specialty;
  final String bankName;
  final String bankAccount;
  final String bankIban;
  final String? contractId;
  final String contractNumber;
  final String contractType;
  final String? contractStartDate;
  final String? contractEndDate;
  final String citizenship;
  final String scientificDegree;
  final String honoraryTitle;
  final String militaryDuty;
  final String driverLicense;
  final String registrationAddress;
  final List<String> roles;
  final bool isTeacher;
  final String subject;
  final List<String> assignedClasses;
  final List<Map<String, dynamic>> contracts;

  const Employee({
    required this.id,
    this.uid = '',
    required this.code,
    required this.finCode,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.position,
    required this.department,
    required this.email,
    required this.phone,
    this.corporatePhone,
    this.photoUrl,
    this.status = 'active',
    required this.hireDate,
    this.birthDate,
    this.salary = 0.0,
    this.netSalary = 0.0,
    this.filial,
    this.sector,
    this.gender = 'Kişi',
    this.idCardSerial = '',
    this.maritalStatus = '',
    this.bloodGroup = '',
    this.address = '',
    this.educationLevel = '',
    this.university = '',
    this.specialty = '',
    this.bankName = '',
    this.bankAccount = '',
    this.bankIban = '',
    this.contractId,
    this.contractNumber = '',
    this.contractType = '',
    this.contractStartDate,
    this.contractEndDate,
    this.citizenship = 'Azərbaycan',
    this.scientificDegree = 'Yoxdur',
    this.honoraryTitle = 'Yoxdur',
    this.militaryDuty = 'Xeyr',
    this.driverLicense = 'Xeyr',
    this.registrationAddress = '',
    this.roles = const [],
    this.isTeacher = false,
    this.subject = '',
    this.assignedClasses = const [],
    this.contracts = const [],
  });

  bool get isActive => status == 'active';

  Employee copyWith({
    String? id,
    String? uid,
    String? code,
    String? finCode,
    String? fullName,
    String? firstName,
    String? lastName,
    String? fatherName,
    String? position,
    String? department,
    String? email,
    String? phone,
    String? corporatePhone,
    String? photoUrl,
    String? status,
    DateTime? hireDate,
    DateTime? birthDate,
    double? salary,
    double? netSalary,
    String? filial,
    String? sector,
    String? gender,
    String? idCardSerial,
    String? maritalStatus,
    String? bloodGroup,
    String? address,
    String? educationLevel,
    String? university,
    String? specialty,
    String? bankName,
    String? bankAccount,
    String? bankIban,
    String? contractId,
    String? contractNumber,
    String? contractType,
    String? contractStartDate,
    String? contractEndDate,
    String? citizenship,
    String? scientificDegree,
    String? honoraryTitle,
    String? militaryDuty,
    String? driverLicense,
    String? registrationAddress,
    List<String>? roles,
    bool? isTeacher,
    String? subject,
    List<String>? assignedClasses,
    List<Map<String, dynamic>>? contracts,
  }) {
    return Employee(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      code: code ?? this.code,
      finCode: finCode ?? this.finCode,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      position: position ?? this.position,
      department: department ?? this.department,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      corporatePhone: corporatePhone ?? this.corporatePhone,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      hireDate: hireDate ?? this.hireDate,
      birthDate: birthDate ?? this.birthDate,
      salary: salary ?? this.salary,
      netSalary: netSalary ?? this.netSalary,
      filial: filial ?? this.filial,
      sector: sector ?? this.sector,
      gender: gender ?? this.gender,
      idCardSerial: idCardSerial ?? this.idCardSerial,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      educationLevel: educationLevel ?? this.educationLevel,
      university: university ?? this.university,
      specialty: specialty ?? this.specialty,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankIban: bankIban ?? this.bankIban,
      contractId: contractId ?? this.contractId,
      contractNumber: contractNumber ?? this.contractNumber,
      contractType: contractType ?? this.contractType,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      citizenship: citizenship ?? this.citizenship,
      scientificDegree: scientificDegree ?? this.scientificDegree,
      honoraryTitle: honoraryTitle ?? this.honoraryTitle,
      militaryDuty: militaryDuty ?? this.militaryDuty,
      driverLicense: driverLicense ?? this.driverLicense,
      registrationAddress: registrationAddress ?? this.registrationAddress,
      roles: roles ?? this.roles,
      isTeacher: isTeacher ?? this.isTeacher,
      subject: subject ?? this.subject,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      contracts: contracts ?? this.contracts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'code': code,
        'fin_code': finCode,
        'full_name': fullName,
        'first_name': firstName,
        'last_name': lastName,
        'father_name': fatherName,
        'position': position,
        'department': department,
        'email': email,
        'phone': phone,
        'corporate_phone': corporatePhone,
        'photo_url': photoUrl,
        'status': status,
        'hire_date': hireDate.toIso8601String(),
        'birth_date': birthDate?.toIso8601String(),
        'salary': salary,
        'net_salary': netSalary,
        'filial': filial,
        'sector': sector,
        'gender': gender,
        'id_card_serial': idCardSerial,
        'marital_status': maritalStatus,
        'blood_group': bloodGroup,
        'address': address,
        'registration_address': registrationAddress,
        'citizenship': citizenship,
        'scientific_degree': scientificDegree,
        'honorary_title': honoraryTitle,
        'military_duty': militaryDuty,
        'driver_license': driverLicense,
        'education_level': educationLevel,
        'university': university,
        'specialty': specialty,
        'bank_name': bankName,
        'bank_account': bankAccount,
        'bank_iban': bankIban,
        'contract_id': contractId,
        'contract_number': contractNumber,
        'contract_type': contractType,
        'contract_start_date': contractStartDate,
        'contract_end_date': contractEndDate,
        'roles': roles,
        'is_teacher': isTeacher,
        'subject': subject,
        'assigned_classes': assignedClasses,
        'contracts': contracts,
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawFullName = json['fullName']?.toString() ?? json['full_name']?.toString() ?? '';
    final rawFirstName = json['firstName']?.toString() ?? json['first_name']?.toString() ?? '';
    final rawLastName = json['lastName']?.toString() ?? json['last_name']?.toString() ?? '';
    final rawFatherName = json['fatherName']?.toString() ?? json['father_name']?.toString() ?? '';

    String fullName = rawFullName;
    String firstName = rawFirstName;
    String lastName = rawLastName;
    if (fullName.isEmpty) {
      fullName = '$firstName $lastName'.trim();
      if (fullName.isEmpty) {
        fullName = json['code']?.toString() ?? 'Əməkdaş';
      }
    }
    if (firstName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      firstName = parts.first;
      if (lastName.isEmpty && parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    return Employee(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      finCode: json['finCode']?.toString() ?? json['fin_code']?.toString() ?? '',
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      fatherName: rawFatherName,
      position: json['position']?.toString() ?? 'Müəllim',
      department: json['department']?.toString() ?? 'Pedaqoji heyət',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      corporatePhone: json['corporatePhone']?.toString() ?? json['corporate_phone']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
      status: json['status']?.toString() ?? 'active',
      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'].toString()) ?? DateTime.now()
          : (json['hire_date'] != null
              ? DateTime.tryParse(json['hire_date'].toString()) ?? DateTime.now()
              : DateTime.now()),
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : (json['birth_date'] != null
              ? DateTime.tryParse(json['birth_date'].toString())
              : null),
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? (json['net_salary'] as num?)?.toDouble() ?? 0.0,
      filial: json['filial']?.toString() ?? 'Bakı filialı',
      sector: json['sector']?.toString() ?? 'Azərbaycan',
      gender: json['gender']?.toString() ?? 'Kişi',
      idCardSerial: json['idCardSerial']?.toString() ?? json['id_card_serial']?.toString() ?? '',
      maritalStatus: json['maritalStatus']?.toString() ?? json['marital_status']?.toString() ?? '',
      bloodGroup: json['bloodGroup']?.toString() ?? json['blood_group']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      registrationAddress: json['registrationAddress']?.toString() ?? json['registration_address']?.toString() ?? '',
      citizenship: json['citizenship']?.toString() ?? 'Azərbaycan',
      scientificDegree: json['scientificDegree']?.toString() ?? json['scientific_degree']?.toString() ?? 'Yoxdur',
      honoraryTitle: json['honoraryTitle']?.toString() ?? json['honorary_title']?.toString() ?? 'Yoxdur',
      militaryDuty: json['militaryDuty']?.toString() ?? json['military_duty']?.toString() ?? 'Xeyr',
      driverLicense: json['driverLicense']?.toString() ?? json['driver_license']?.toString() ?? 'Xeyr',
      educationLevel: json['educationLevel']?.toString() ?? json['education_level']?.toString() ?? '',
      university: json['university']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? json['bank_name']?.toString() ?? '',
      bankAccount: json['bankAccount']?.toString() ?? json['bank_account']?.toString() ?? '',
      bankIban: json['bankIban']?.toString() ?? json['bank_iban']?.toString() ?? '',
      contractId: json['contractId']?.toString() ?? json['contract_id']?.toString(),
      contractNumber: json['contractNumber']?.toString() ?? json['contract_number']?.toString() ?? '',
      contractType: json['contractType']?.toString() ?? json['contract_type']?.toString() ?? '',
      contractStartDate: json['contractStartDate']?.toString() ?? json['contract_start_date']?.toString(),
      contractEndDate: json['contractEndDate']?.toString() ?? json['contract_end_date']?.toString(),
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isTeacher: json['isTeacher'] == true || json['is_teacher'] == true,
      subject: json['subject']?.toString() ?? '',
      assignedClasses: (json['assignedClasses'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contracts: (json['contracts'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }
}

/// Official employment contract model.
class EmployeeContract {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String employeeFin;
  final String contractNumber;
  final String contractType; // 'indefinite' (Müddətsiz), 'fixed' (Müddətli)
  final DateTime startDate;
  final DateTime? endDate;
  final double grossSalary;
  final double netSalary;
  final double salarySupplement;
  final double foodAllowance;
  final double workConditionSupplement;
  final String status; // 'active', 'expired', 'terminated'
  final bool isActive;
  final String positionTitle;
  final String department;
  final String filial;
  final String company;
  final double workHours;
  final String notes;

  // Web GoPanel 1:1 attributes
  final String costCenter;
  final String teqvim;
  final String workSchedule;
  final String workRegime;
  final String jobDescription;
  final int? trialPeriodValue;
  final String? trialPeriodUnit;
  final DateTime? probationEndDate;
  final int? baseVacationDays;
  final int? positionId;
  final int? structureId;
  final int? filialId;
  final int? companyId;
  final int? teqvimId;

  const EmployeeContract({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeeCode = '',
    this.employeeFin = '',
    required this.contractNumber,
    this.contractType = 'indefinite',
    required this.startDate,
    this.endDate,
    required this.grossSalary,
    required this.netSalary,
    this.salarySupplement = 0.0,
    this.foodAllowance = 0.0,
    this.workConditionSupplement = 0.0,
    this.status = 'active',
    this.isActive = true,
    required this.positionTitle,
    this.department = '',
    this.filial = '',
    this.company = '',
    this.workHours = 40.0,
    this.notes = '',
    this.costCenter = '',
    this.teqvim = '',
    this.workSchedule = '',
    this.workRegime = '',
    this.jobDescription = '',
    this.trialPeriodValue,
    this.trialPeriodUnit,
    this.probationEndDate,
    this.baseVacationDays = 21,
    this.positionId,
    this.structureId,
    this.filialId,
    this.companyId,
    this.teqvimId,
  });

  bool get isIndefinite => contractType == 'indefinite' || endDate == null;

  String get remainingText {
    if (isIndefinite) return 'Müddətsiz müqavilə';
    if (endDate == null) return 'Müddətsiz';
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 'Müddəti bitib';
    final diff = endDate!.difference(now);
    final days = diff.inDays;
    if (days > 365) {
      final years = (days / 365).floor();
      return '$years il qalıb';
    } else if (days > 30) {
      final months = (days / 30).floor();
      return '$months ay qalıb';
    } else {
      return '$days gün qalıb';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'contract_number': contractNumber,
        'contract_type': contractType,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'gross_salary': grossSalary,
        'net_salary': netSalary,
        'salary_supplement': salarySupplement,
        'food_allowance': foodAllowance,
        'work_condition_supplement': workConditionSupplement,
        'status': status,
        'position_title': positionTitle,
        'notes': notes,
        'cost_center': costCenter,
        'teqvim': teqvim,
        'work_schedule': workSchedule,
        'work_regime': workRegime,
        'job_description': jobDescription,
        'trial_period_value': trialPeriodValue,
        'trial_period_unit': trialPeriodUnit,
        'base_vacation_days': baseVacationDays,
        'position_id': positionId,
        'structure_id': structureId,
        'filial_id': filialId,
        'company_id': companyId,
        'teqvim_id': teqvimId,
      };

  factory EmployeeContract.fromJson(Map<String, dynamic> json) => EmployeeContract(
        id: json['id']?.toString() ?? '',
        employeeId: json['employee_id']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? '',
        employeeCode: json['employee_code']?.toString() ?? '',
        employeeFin: json['employee_fin']?.toString() ?? '',
        contractNumber: json['contract_number']?.toString() ?? '',
        contractType: json['contract_type']?.toString() ?? 'indefinite',
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        endDate: json['end_date'] != null
            ? DateTime.tryParse(json['end_date'].toString())
            : null,
        grossSalary: (json['gross_salary'] as num?)?.toDouble() ?? 0.0,
        netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0.0,
        salarySupplement: (json['salary_supplement'] as num?)?.toDouble() ?? 0.0,
        foodAllowance: (json['food_allowance'] as num?)?.toDouble() ?? 0.0,
        workConditionSupplement: (json['work_condition_supplement'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? 'active',
        isActive: json['is_active'] == true || json['status'] == 'active',
        positionTitle: json['position_title']?.toString() ?? '',
        department: json['department']?.toString() ?? '',
        filial: json['filial']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
        workHours: (json['work_hours'] as num?)?.toDouble() ?? 40.0,
        notes: json['notes']?.toString() ?? '',
        costCenter: json['cost_center']?.toString() ?? '',
        teqvim: json['teqvim']?.toString() ?? '',
        workSchedule: json['work_schedule']?.toString() ?? '',
        workRegime: json['work_regime']?.toString() ?? '',
        jobDescription: json['job_description']?.toString() ?? '',
        trialPeriodValue: json['trial_period_value'] != null ? int.tryParse(json['trial_period_value'].toString()) : null,
        trialPeriodUnit: json['trial_period_unit']?.toString(),
        probationEndDate: json['probation_end_date'] != null ? DateTime.tryParse(json['probation_end_date'].toString()) : null,
        baseVacationDays: json['base_vacation_days'] != null ? int.tryParse(json['base_vacation_days'].toString()) : 21,
        positionId: json['position_id'] != null ? int.tryParse(json['position_id'].toString()) : null,
        structureId: json['structure_id'] != null ? int.tryParse(json['structure_id'].toString()) : null,
        filialId: json['filial_id'] != null ? int.tryParse(json['filial_id'].toString()) : null,
        companyId: json['company_id'] != null ? int.tryParse(json['company_id'].toString()) : null,
        teqvimId: json['teqvim_id'] != null ? int.tryParse(json['teqvim_id'].toString()) : null,
      );
}

/// Official employee document record.
class EmployeeDocument {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String employeeFin;
  final String employeePosition;
  final int documentTypeId;
  final String documentType; // e.g. 'Əmək Müqaviləsi (İşə Qəbul)', 'İşdən azad etmə', 'Əmək məzuniyyəti'
  final String documentTypeCode;
  final String documentNumber;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String creatorName;
  final String status; // 'active', 'completed', 'cancelled', 'draft'
  final String statusLabel;
  final String fileUrl;
  final String notes;
  final List<Map<String, dynamic>> templates;
  final String previewUrl;

  const EmployeeDocument({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeeCode = '',
    this.employeeFin = '',
    this.employeePosition = '',
    this.documentTypeId = 0,
    required this.documentType,
    this.documentTypeCode = '',
    required this.documentNumber,
    required this.issueDate,
    this.expiryDate,
    this.creatorName = 'Admin',
    this.status = 'active',
    this.statusLabel = 'Aktiv',
    this.fileUrl = '',
    this.notes = '',
    this.templates = const [],
    this.previewUrl = '',
  });

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'employee_code': employeeCode,
        'employee_fin': employeeFin,
        'document_type_id': documentTypeId,
        'document_type': documentType,
        'document_type_code': documentTypeCode,
        'document_number': documentNumber,
        'issue_date': issueDate.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'creator_name': creatorName,
        'status': status,
        'status_label': statusLabel,
        'file_url': fileUrl,
        'notes': notes,
        'templates': templates,
        'preview_url': previewUrl,
      };

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) => EmployeeDocument(
        id: json['id']?.toString() ?? '',
        employeeId: json['employeeId']?.toString() ?? json['employee_id']?.toString() ?? '',
        employeeName: json['employeeName']?.toString() ?? json['employee_name']?.toString() ?? 'Əməkdaş',
        employeeCode: json['employeeCode']?.toString() ?? json['employee_code']?.toString() ?? '',
        employeeFin: json['employeeFin']?.toString() ?? json['employee_fin']?.toString() ?? '',
        employeePosition: json['employeePosition']?.toString() ?? json['position']?.toString() ?? '',
        documentTypeId: int.tryParse((json['documentTypeId'] ?? json['document_type_id'] ?? 0).toString()) ?? 0,
        documentType: json['documentTypeName']?.toString() ?? json['document_type']?.toString() ?? 'Sənəd',
        documentTypeCode: json['documentTypeCode']?.toString() ?? json['document_type_code']?.toString() ?? '',
        documentNumber: json['documentNumber']?.toString() ?? json['document_number']?.toString() ?? ('DOC-' + (json['id']?.toString() ?? '')),
        issueDate: json['startDate'] != null || json['issue_date'] != null
            ? DateTime.tryParse((json['startDate'] ?? json['issue_date']).toString()) ?? DateTime.now()
            : DateTime.now(),
        expiryDate: json['endDate'] != null || json['expiry_date'] != null
            ? DateTime.tryParse((json['endDate'] ?? json['expiry_date']).toString())
            : null,
        creatorName: json['creatorName']?.toString() ?? json['creator_name']?.toString() ?? 'Admin',
        status: json['status']?.toString() ?? 'active',
        statusLabel: json['statusLabel']?.toString() ?? json['status_label']?.toString() ?? 'Aktiv',
        fileUrl: json['file_url']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        templates: (json['templates'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
        previewUrl: json['previewUrl']?.toString() ?? json['preview_url']?.toString() ?? '',
      );
}

/// Employee attendance record.
class EmployeeAttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String? checkInTime;
  final String? checkOutTime;
  final String status; // 'present' (Gəldi), 'absent' (Qayıb), 'late' (Gecikdi), 'excused' (Məzuniyyət)
  final String notes;

  const EmployeeAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.status = 'present',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'date': date.toIso8601String(),
        'check_in': checkInTime,
        'check_out': checkOutTime,
        'status': status,
        'notes': notes,
      };

  factory EmployeeAttendanceRecord.fromJson(Map<String, dynamic> json) =>
      EmployeeAttendanceRecord(
        id: json['id']?.toString() ?? '',
        employeeId: json['employee_id']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        checkInTime: json['check_in']?.toString(),
        checkOutTime: json['check_out']?.toString(),
        status: json['status']?.toString() ?? 'present',
        notes: json['notes']?.toString() ?? '',
      );
}
