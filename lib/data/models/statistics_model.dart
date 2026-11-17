/// Models for pedagogical quality control and teacher workload reports.
class QualityControlAudit {
  final String id;
  final String teacherName;
  final String subject;
  final String className;
  final String observerName;
  final DateTime observationDate;
  final double overallScore; // 1.0 to 5.0
  final Map<String, double> criteriaScores;
  final String strengths;
  final String recommendations;

  const QualityControlAudit({
    required this.id,
    required this.teacherName,
    required this.subject,
    required this.className,
    required this.observerName,
    required this.observationDate,
    required this.overallScore,
    this.criteriaScores = const {},
    this.strengths = '',
    this.recommendations = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_name': teacherName,
        'subject': subject,
        'class_name': className,
        'observer_name': observerName,
        'observation_date': observationDate.toIso8601String(),
        'overall_score': overallScore,
        'criteria_scores': criteriaScores,
        'strengths': strengths,
        'recommendations': recommendations,
      };

  factory QualityControlAudit.fromJson(Map<String, dynamic> json) =>
      QualityControlAudit(
        id: json['id']?.toString() ?? '',
        teacherName: json['teacher_name']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        className: json['class_name']?.toString() ?? '',
        observerName: json['observer_name']?.toString() ?? '',
        observationDate: json['observation_date'] != null
            ? DateTime.tryParse(json['observation_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        overallScore: (json['overall_score'] as num?)?.toDouble() ?? 5.0,
        criteriaScores: (json['criteria_scores'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
        strengths: json['strengths']?.toString() ?? '',
        recommendations: json['recommendations']?.toString() ?? '',
      );
}

/// Teacher weekly workload allocation report item.
class TeacherWorkload {
  final String id;
  final String teacherName;
  final String department;
  final int weeklyHours;
  final int classCount;
  final int subjectCount;
  final int overloadHours;
  final int maxLoadHours;

  const TeacherWorkload({
    required this.id,
    required this.teacherName,
    required this.department,
    required this.weeklyHours,
    required this.classCount,
    required this.subjectCount,
    this.overloadHours = 0,
    this.maxLoadHours = 24,
  });

  bool get isOverloaded => weeklyHours > maxLoadHours;
  double get loadPercentage => maxLoadHours > 0 ? (weeklyHours / maxLoadHours) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_name': teacherName,
        'department': department,
        'weekly_hours': weeklyHours,
        'class_count': classCount,
        'subject_count': subjectCount,
        'overload_hours': overloadHours,
        'max_load_hours': maxLoadHours,
      };

  factory TeacherWorkload.fromJson(Map<String, dynamic> json) => TeacherWorkload(
        id: json['id']?.toString() ?? '',
        teacherName: json['teacher_name']?.toString() ?? '',
        department: json['department']?.toString() ?? 'Pedaqoji',
        weeklyHours: (json['weekly_hours'] as num?)?.toInt() ?? 18,
        classCount: (json['class_count'] as num?)?.toInt() ?? 4,
        subjectCount: (json['subject_count'] as num?)?.toInt() ?? 2,
        overloadHours: (json['overload_hours'] as num?)?.toInt() ?? 0,
        maxLoadHours: (json['max_load_hours'] as num?)?.toInt() ?? 24,
      );
}
