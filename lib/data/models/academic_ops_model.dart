/// Models for academic operations, curricula, clubs, excuses, rooms, and bell schedules.
class CurriculumItem {
  final String id;
  final String gradeLevel;
  final String subject;
  final String academicYear;
  final int weeklyHours;
  final int totalHours;
  final String syllabusTitle;
  final int topicsCount;
  final String department;

  const CurriculumItem({
    required this.id,
    required this.gradeLevel,
    required this.subject,
    required this.academicYear,
    required this.weeklyHours,
    required this.totalHours,
    required this.syllabusTitle,
    this.topicsCount = 0,
    this.department = 'Pedaqoji',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade_level': gradeLevel,
        'subject': subject,
        'academic_year': academicYear,
        'weekly_hours': weeklyHours,
        'total_hours': totalHours,
        'syllabus_title': syllabusTitle,
        'topics_count': topicsCount,
        'department': department,
      };

  factory CurriculumItem.fromJson(Map<String, dynamic> json) => CurriculumItem(
        id: json['id']?.toString() ?? '',
        gradeLevel: json['grade_level']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        academicYear: json['academic_year']?.toString() ?? '2026-2027',
        weeklyHours: (json['weekly_hours'] as num?)?.toInt() ?? 2,
        totalHours: (json['total_hours'] as num?)?.toInt() ?? 68,
        syllabusTitle: json['syllabus_title']?.toString() ?? '',
        topicsCount: (json['topics_count'] as num?)?.toInt() ?? 0,
        department: json['department']?.toString() ?? 'Pedaqoji',
      );
}

/// School extracurricular club.
class SchoolClub {
  final String id;
  final String name;
  final String category; // 'İntellektual', 'STEAM', 'İncəsənət', 'İdman'
  final String supervisorTeacher;
  final String schedule;
  final String room;
  final int maxCapacity;
  final int memberCount;
  final String description;
  final bool isActive;

  const SchoolClub({
    required this.id,
    required this.name,
    required this.category,
    required this.supervisorTeacher,
    required this.schedule,
    required this.room,
    this.maxCapacity = 20,
    this.memberCount = 0,
    this.description = '',
    this.isActive = true,
  });

  bool get isFull => memberCount >= maxCapacity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'supervisor_teacher': supervisorTeacher,
        'schedule': schedule,
        'room': room,
        'max_capacity': maxCapacity,
        'member_count': memberCount,
        'description': description,
        'is_active': isActive,
      };

  factory SchoolClub.fromJson(Map<String, dynamic> json) => SchoolClub(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? 'İntellektual',
        supervisorTeacher: json['supervisor_teacher']?.toString() ?? '',
        schedule: json['schedule']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 20,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        description: json['description']?.toString() ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Excused student absence (medical excuse, parent letter).
class ExcusedAbsence {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final String reasonType; // 'Xəstəlik', 'Ailə vəziyyəti', 'İdman yarışı', 'Digər'
  final String documentNumber;
  final String status; // 'təsdiqlənib', 'gözləmədə', 'rədd_edilib'
  final String notes;

  const ExcusedAbsence({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.reasonType,
    this.documentNumber = '',
    this.status = 'təsdiqlənib',
    this.notes = '',
  });

  bool get isApproved => status == 'təsdiqlənib';

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'student_name': studentName,
        'class_name': className,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'days_count': daysCount,
        'reason_type': reasonType,
        'document_number': documentNumber,
        'status': status,
        'notes': notes,
      };

  factory ExcusedAbsence.fromJson(Map<String, dynamic> json) => ExcusedAbsence(
        id: json['id']?.toString() ?? '',
        studentId: json['student_id']?.toString() ?? '',
        studentName: json['student_name']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        endDate: json['end_date'] != null
            ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        daysCount: (json['days_count'] as num?)?.toInt() ?? 1,
        reasonType: json['reason_type']?.toString() ?? 'Xəstəlik',
        documentNumber: json['document_number']?.toString() ?? '',
        status: json['status']?.toString() ?? 'təsdiqlənib',
        notes: json['notes']?.toString() ?? '',
      );
}

/// School alumni / graduation record.
class GraduationItem {
  final String id;
  final String studentName;
  final String graduationYear;
  final String completedGrade;
  final String diplomaNumber;
  final bool hasHonors;
  final String universityAdmission;

  const GraduationItem({
    required this.id,
    required this.studentName,
    required this.graduationYear,
    required this.completedGrade,
    required this.diplomaNumber,
    this.hasHonors = false,
    this.universityAdmission = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_name': studentName,
        'graduation_year': graduationYear,
        'completed_grade': completedGrade,
        'diploma_number': diplomaNumber,
        'has_honors': hasHonors,
        'university_admission': universityAdmission,
      };

  factory GraduationItem.fromJson(Map<String, dynamic> json) => GraduationItem(
        id: json['id']?.toString() ?? '',
        studentName: json['student_name']?.toString() ?? '',
        graduationYear: json['graduation_year']?.toString() ?? '2026',
        completedGrade: json['completed_grade']?.toString() ?? '11-A',
        diplomaNumber: json['diploma_number']?.toString() ?? '',
        hasHonors: json['has_honors'] as bool? ?? false,
        universityAdmission: json['university_admission']?.toString() ?? '',
      );
}

/// Academic year setting.
class AcademicYearItem {
  final String id;
  final String name; // e.g. "2026-2027"
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final int semesterCount;

  const AcademicYearItem({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    this.semesterCount = 2,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_current': isCurrent,
        'semester_count': semesterCount,
      };

  factory AcademicYearItem.fromJson(Map<String, dynamic> json) => AcademicYearItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        endDate: json['end_date'] != null
            ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isCurrent: json['is_current'] as bool? ?? false,
        semesterCount: (json['semester_count'] as num?)?.toInt() ?? 2,
      );
}

/// Campus room / laboratory.
class SchoolRoom {
  final String id;
  final String roomNumber;
  final String name;
  final int floor;
  final String wing;
  final int capacity;
  final String roomType; // 'Sinif otağı', 'Laboratoriya', 'Kompüter zalı', 'İdman zalı'
  final bool hasSmartBoard;
  final bool hasProjector;

  const SchoolRoom({
    required this.id,
    required this.roomNumber,
    required this.name,
    required this.floor,
    this.wing = 'A korpusu',
    this.capacity = 24,
    this.roomType = 'Sinif otağı',
    this.hasSmartBoard = true,
    this.hasProjector = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_number': roomNumber,
        'name': name,
        'floor': floor,
        'wing': wing,
        'capacity': capacity,
        'room_type': roomType,
        'has_smart_board': hasSmartBoard,
        'has_projector': hasProjector,
      };

  factory SchoolRoom.fromJson(Map<String, dynamic> json) => SchoolRoom(
        id: json['id']?.toString() ?? '',
        roomNumber: json['room_number']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        floor: (json['floor'] as num?)?.toInt() ?? 1,
        wing: json['wing']?.toString() ?? 'A korpusu',
        capacity: (json['capacity'] as num?)?.toInt() ?? 24,
        roomType: json['room_type']?.toString() ?? 'Sinif otağı',
        hasSmartBoard: json['has_smart_board'] as bool? ?? true,
        hasProjector: json['has_projector'] as bool? ?? true,
      );
}

/// Bell schedule period slot.
class TimeSlotItem {
  final String id;
  final int periodNumber;
  final String periodName; // '1-ci dərs', 'Böyük Nahar Tənəffüsü'
  final String startTime;
  final String endTime;
  final bool isBreak;
  final int durationMinutes;

  const TimeSlotItem({
    required this.id,
    required this.periodNumber,
    required this.periodName,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'period_number': periodNumber,
        'period_name': periodName,
        'start_time': startTime,
        'end_time': endTime,
        'is_break': isBreak,
        'duration_minutes': durationMinutes,
      };

  factory TimeSlotItem.fromJson(Map<String, dynamic> json) => TimeSlotItem(
        id: json['id']?.toString() ?? '',
        periodNumber: (json['period_number'] as num?)?.toInt() ?? 1,
        periodName: json['period_name']?.toString() ?? '',
        startTime: json['start_time']?.toString() ?? '',
        endTime: json['end_time']?.toString() ?? '',
        isBreak: json['is_break'] as bool? ?? false,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 45,
      );
}
