/// Models for school examinations, grading rubrics, and new student admission exams.
class ExamItem {
  final String id;
  final String title;
  final String examType; // 'KSQ', 'BSQ', 'Sınaq', 'Qəbul', 'Beynəlxalq'
  final String subject;
  final String className;
  final DateTime examDate;
  final String startTime;
  final int durationMinutes;
  final String room;
  final double maxScore;
  final String status; // 'upcoming', 'in_progress', 'completed'
  final String instructions;

  const ExamItem({
    required this.id,
    required this.title,
    required this.examType,
    required this.subject,
    required this.className,
    required this.examDate,
    required this.startTime,
    this.durationMinutes = 45,
    required this.room,
    this.maxScore = 100.0,
    this.status = 'upcoming',
    this.instructions = '',
  });

  bool get isUpcoming => status == 'upcoming';
  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'exam_type': examType,
        'subject': subject,
        'class_name': className,
        'exam_date': examDate.toIso8601String(),
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        'room': room,
        'max_score': maxScore,
        'status': status,
        'instructions': instructions,
      };

  factory ExamItem.fromJson(Map<String, dynamic> json) => ExamItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        examType: json['exam_type']?.toString() ?? 'KSQ',
        subject: json['subject']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        examDate: json['exam_date'] != null
            ? DateTime.tryParse(json['exam_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        startTime: json['start_time']?.toString() ?? '09:00',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 45,
        room: json['room']?.toString() ?? '',
        maxScore: (json['max_score'] as num?)?.toDouble() ?? 100.0,
        status: json['status']?.toString() ?? 'upcoming',
        instructions: json['instructions']?.toString() ?? '',
      );
}

/// Student performance result for an exam.
class ExamResult {
  final String id;
  final String examId;
  final String examTitle;
  final String studentId;
  final String studentName;
  final String className;
  final String subject;
  final double score;
  final double maxScore;
  final DateTime examDate;
  final String notes;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.score,
    this.maxScore = 100.0,
    required this.examDate,
    this.notes = '',
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get gradeLetter {
    if (percentage >= 90) return 'A (Əla)';
    if (percentage >= 80) return 'B (Çox yaxşı)';
    if (percentage >= 70) return 'C (Yaxşı)';
    if (percentage >= 60) return 'D (Kafi)';
    return 'E (Qeyri-kafi)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'exam_title': examTitle,
        'student_id': studentId,
        'student_name': studentName,
        'class_name': className,
        'subject': subject,
        'score': score,
        'max_score': maxScore,
        'exam_date': examDate.toIso8601String(),
        'notes': notes,
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        id: json['id']?.toString() ?? '',
        examId: json['exam_id']?.toString() ?? '',
        examTitle: json['exam_title']?.toString() ?? '',
        studentId: json['student_id']?.toString() ?? '',
        studentName: json['student_name']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        maxScore: (json['max_score'] as num?)?.toDouble() ?? 100.0,
        examDate: json['exam_date'] != null
            ? DateTime.tryParse(json['exam_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        notes: json['notes']?.toString() ?? '',
      );
}

/// New applicant admission inquiry / application.
class StudentApplication {
  final String id;
  final String applicantName;
  final String parentName;
  final String phone;
  final String email;
  final String appliedGrade;
  final DateTime birthDate;
  final DateTime applicationDate;
  final String status; // 'gözləmədə', 'imtahan_təyin_edilib', 'qəbul', 'rədd'
  final double? examScore;
  final String notes;

  const StudentApplication({
    required this.id,
    required this.applicantName,
    required this.parentName,
    required this.phone,
    required this.email,
    required this.appliedGrade,
    required this.birthDate,
    required this.applicationDate,
    this.status = 'gözləmədə',
    this.examScore,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicant_name': applicantName,
        'parent_name': parentName,
        'phone': phone,
        'email': email,
        'applied_grade': appliedGrade,
        'birth_date': birthDate.toIso8601String(),
        'application_date': applicationDate.toIso8601String(),
        'status': status,
        'exam_score': examScore,
        'notes': notes,
      };

  factory StudentApplication.fromJson(Map<String, dynamic> json) => StudentApplication(
        id: json['id']?.toString() ?? '',
        applicantName: json['applicant_name']?.toString() ?? '',
        parentName: json['parent_name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        appliedGrade: json['applied_grade']?.toString() ?? '1-ci sinif',
        birthDate: json['birth_date'] != null
            ? DateTime.tryParse(json['birth_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        applicationDate: json['application_date'] != null
            ? DateTime.tryParse(json['application_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: json['status']?.toString() ?? 'gözləmədə',
        examScore: (json['exam_score'] as num?)?.toDouble(),
        notes: json['notes']?.toString() ?? '',
      );
}
