import '../../../services/network/api_client.dart';

/// Cached academic dictionaries sourced from the web GoPanel foundations.
class AcademicMeta {
  AcademicMeta._();

  static final AcademicMeta instance = AcademicMeta._();

  bool _loaded = false;
  List<Map<String, dynamic>> academicYears = [];
  List<Map<String, dynamic>> statuses = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> sectors = [];
  List<Map<String, dynamic>> parentTypes = [];
  List<Map<String, dynamic>> exclusiveTypes = [];
  List<Map<String, dynamic>> gradeLevels = [];
  List<Map<String, dynamic>> gradeSuffixes = [];
  List<Map<String, dynamic>> filials = [];

  bool get isLoaded => _loaded;

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;

    final response = await ApiClient.instance.get('academic/foundations');
    final data = response is Map ? response['data'] : null;
    if (data is! Map) return;

    List<Map<String, dynamic>> list(dynamic value) =>
        value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

    academicYears = list(data['academic_years']);
    statuses = list(data['statuses']);
    subjects = list(data['subjects']);
    classes = list(data['classes']);
    sectors = list(data['sectors']);
    parentTypes = list(data['parent_types']);
    exclusiveTypes = list(data['exclusive_types']);
    gradeLevels = list(data['grade_levels']);
    gradeSuffixes = list(data['grade_suffixes']);
    filials = list(data['filials']);
    _loaded = true;
  }

  Map<String, dynamic>? get currentYear {
    for (final year in academicYears) {
      if (year['is_current'] == true) return year;
    }
    return academicYears.isNotEmpty ? academicYears.first : null;
  }

  List<Map<String, dynamic>> get studentStatuses => statuses
      .where((s) => (s['key'] ?? '').toString().startsWith('student_'))
      .toList();

  String statusLabel(String? key) {
    if (key == null) return '—';
    for (final status in statuses) {
      if (status['key'] == key) return status['name']?.toString() ?? key;
    }
    return key;
  }
}
