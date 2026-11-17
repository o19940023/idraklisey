enum AssignmentStatus {
  pending,   // Yeni / Gözləmədə
  inProgress,// İcrada
  submitted, // Təhvil verildi
  graded,    // Yoxlanıldı / Qiymətləndirildi
}

class AssignmentSubmission {
  final String studentId;
  final String studentName;
  final DateTime submittedAt;
  final List<String> scannedImages; // Photos taken via camera
  final String? studentNote;
  final double? score;
  final String? teacherComment;
  final DateTime? gradedAt;

  AssignmentSubmission({
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    required this.scannedImages,
    this.studentNote,
    this.score,
    this.teacherComment,
    this.gradedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'submittedAt': submittedAt.toIso8601String(),
      'scannedImages': scannedImages,
      'studentNote': studentNote,
      'score': score,
      'teacherComment': teacherComment,
      'gradedAt': gradedAt?.toIso8601String(),
    };
  }

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      submittedAt: DateTime.tryParse(map['submittedAt'] ?? '') ?? DateTime.now(),
      scannedImages: List<String>.from(map['scannedImages'] ?? []),
      studentNote: map['studentNote'],
      score: (map['score'] as num?)?.toDouble(),
      teacherComment: map['teacherComment'],
      gradedAt: map['gradedAt'] != null ? DateTime.tryParse(map['gradedAt']) : null,
    );
  }
}

class HomeworkAssignment {
  final String id;
  final int? rawBackendId;
  final String subject;
  final String title;
  final String teacherName;
  final String instructions;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String? attachmentDocUrl;
  final String? assignedClass;
  final List<String> assignedStudentIds;
  final double maxScore;
  final List<Map<String, dynamic>> attachments;
  final Map<String, AssignmentSubmission> submissions; // studentId -> AssignmentSubmission

  HomeworkAssignment({
    required this.id,
    this.rawBackendId,
    required this.subject,
    required this.title,
    required this.teacherName,
    required this.instructions,
    required this.assignedDate,
    required this.dueDate,
    this.attachmentDocUrl,
    this.assignedClass,
    this.assignedStudentIds = const [],
    this.maxScore = 100.0,
    this.attachments = const [],
    this.submissions = const {},
  });

  factory HomeworkAssignment.fromApiJson(
    Map<String, dynamic> json, {
    String? currentStudentId,
  }) {
    final rawId = json['id'];
    final id = 'api-asg-$rawId';
    final subject = json['subject']?.toString() ?? 'Fənn';
    final title = json['title']?.toString() ?? 'Tapşırıq';
    final teacherName = json['teacher']?.toString() ?? 'Müəllim';
    final instructions = json['description']?.toString() ?? '';
    final assignedDate = DateTime.tryParse(json['start_at']?.toString() ?? '') ?? DateTime.now();
    final dueDate = DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1));
    final assignedClass = json['class']?.toString();
    final maxScore = (json['max_score'] as num?)?.toDouble() ?? 100.0;

    final rawAtts = json['attachments'];
    final List<Map<String, dynamic>> attachmentsList = [];
    if (rawAtts is List) {
      for (final a in rawAtts) {
        if (a is Map) {
          attachmentsList.add(Map<String, dynamic>.from(a));
        }
      }
    }

    final submissions = <String, AssignmentSubmission>{};
    final rawSub = json['submission'];
    if (rawSub is Map && currentStudentId != null) {
      final subImages = <String>[];
      final rawSubAtts = rawSub['attachments'];
      if (rawSubAtts is List) {
        for (final a in rawSubAtts) {
          if (a is Map && a['url'] != null) {
            subImages.add(a['url'].toString());
          }
        }
      }
      submissions[currentStudentId] = AssignmentSubmission(
        studentId: currentStudentId,
        studentName: '',
        submittedAt: DateTime.tryParse(rawSub['submitted_at']?.toString() ?? '') ?? DateTime.now(),
        scannedImages: subImages,
        studentNote: rawSub['content']?.toString(),
        score: (rawSub['grade'] as num?)?.toDouble(),
        teacherComment: rawSub['feedback']?.toString(),
        gradedAt: rawSub['grade'] != null ? DateTime.now() : null,
      );
    }

    return HomeworkAssignment(
      id: id,
      rawBackendId: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      subject: subject,
      title: title,
      teacherName: teacherName,
      instructions: instructions,
      assignedDate: assignedDate,
      dueDate: dueDate,
      assignedClass: assignedClass,
      maxScore: maxScore,
      attachments: attachmentsList,
      attachmentDocUrl: attachmentsList.isNotEmpty ? attachmentsList.first['url']?.toString() : null,
      submissions: submissions,
    );
  }

  AssignmentSubmission? getSubmissionForStudent(String studentId) => submissions[studentId];

  AssignmentStatus getStatusForStudent(String studentId) {
    final sub = submissions[studentId];
    if (sub == null) return AssignmentStatus.pending;
    if (sub.score != null) return AssignmentStatus.graded;
    return AssignmentStatus.submitted;
  }

  bool isOverdueForStudent(String studentId) {
    final status = getStatusForStudent(studentId);
    return DateTime.now().isAfter(dueDate) &&
        status != AssignmentStatus.submitted &&
        status != AssignmentStatus.graded;
  }

  int get submittedCount => submissions.values.where((s) => s.score == null).length;
  int get gradedCount => submissions.values.where((s) => s.score != null).length;
  int get totalSubmissionsCount => submissions.length;
}
