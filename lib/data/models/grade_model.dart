enum AssessmentType {
  diagnostic,  // İlkin Diaqnostik
  monitoring,  // Monitorinq
  ksq,         // KSQ (Kiçik Summativ Qiymətləndirmə)
  bsq,         // BSQ (Böyük Summativ Qiymətləndirmə)
  international, // Beynəlxalq (STR, Midterm, Result)
}

extension AssessmentTypeExt on AssessmentType {
  String get displayName {
    switch (this) {
      case AssessmentType.diagnostic:
        return 'İlkin Diaqnostik';
      case AssessmentType.monitoring:
        return 'Monitorinq';
      case AssessmentType.ksq:
        return 'KSQ';
      case AssessmentType.bsq:
        return 'BSQ';
      case AssessmentType.international:
        return 'Beynəlxalq (IB/STR)';
    }
  }
}

class GradeRecord {
  final String id;
  final String? studentId;
  final String? studentName;
  final String subject;
  final AssessmentType type;
  final String title; // e.g. "KSQ-2: Cəbr və Funksiyalar", "STR Term 1"
  final double score; // e.g. 88.5
  final double maxScore; // 100 or 7 for IB
  final String gradeLetter; // "A", "B", "5", "7"
  final DateTime date;
  final String teacherFeedback;

  GradeRecord({
    required this.id,
    this.studentId,
    this.studentName,
    required this.subject,
    required this.type,
    required this.title,
    required this.score,
    this.maxScore = 100.0,
    required this.gradeLetter,
    required this.date,
    this.teacherFeedback = '',
  });

  double get percentage {
    if (maxScore <= 0) return 0.0;
    double raw = (score / maxScore) * 100;
    if (raw > 100 && score > 100 && score <= 1000) {
      raw = ((score / 10.0) / maxScore) * 100;
    }
    return raw.clamp(0.0, 100.0);
  }

  double get displayScore {
    if (maxScore == 100.0 && score > 100 && score <= 1000) {
      return score / 10.0;
    }
    if (score > maxScore) {
      return maxScore;
    }
    return score;
  }

  /// AR Elm və Təhsil Nazirliyinin rəsmi KSQ / BSQ qiymətləndirmə şkalası
  /// 0  - 30  -> 2 (Qeyri-kafi / F)
  /// 31 - 60  -> 3 (Qənaətbəxş / D)
  /// 61 - 80  -> 4 (Yaxşı / C)
  /// 81 - 100 -> 5 (Əla / A)
  static int scoreTo5Scale(double scorePercent) {
    if (scorePercent >= 81) return 5;
    if (scorePercent >= 61) return 4;
    if (scorePercent >= 31) return 3;
    return 2;
  }

  static String scoreToOfficialGrade(double scorePercent) {
    if (scorePercent >= 81) return '5 (Əla / A)';
    if (scorePercent >= 61) return '4 (Yaxşı / C)';
    if (scorePercent >= 31) return '3 (Qənaətbəxş / D)';
    return '2 (Qeyri-kafi / F)';
  }

  static String scoreToGradeLetter(double scorePercent) {
    if (scorePercent >= 81) return 'A';
    if (scorePercent >= 61) return 'C';
    if (scorePercent >= 31) return 'D';
    return 'F';
  }
}

class SubjectProgress {
  final String subject;
  final double averageScore;
  final List<double> monthlyScores;
  final List<String> months;

  SubjectProgress({
    required this.subject,
    required this.averageScore,
    required this.monthlyScores,
    required this.months,
  });
}
