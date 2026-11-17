import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SchoolApiService {
  SchoolApiService._();
  static final SchoolApiService instance = SchoolApiService._();

  static String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    return 'https://new.idrak.edu.az/api/mobile';
  }

  static const Duration _timeout = Duration(seconds: 25);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ----------------------------------------------------
  // Generic HTTP helpers
  // ----------------------------------------------------
  Future<dynamic> _get(String path, [Map<String, dynamic>? queryParams]) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        final cleanParams = <String, String>{};
        queryParams.forEach((k, v) {
          if (v != null) cleanParams[k] = v.toString();
        });
        uri = uri.replace(queryParameters: cleanParams);
      }
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('SchoolApiService GET $path error: $e');
    }
    return null;
  }

  Future<dynamic> _post(String path, dynamic data) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(data))
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('SchoolApiService POST $path error: $e');
    }
    return null;
  }

  Future<dynamic> _put(String path, dynamic data) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .put(uri, headers: _headers, body: jsonEncode(data))
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('SchoolApiService PUT $path error: $e');
    }
    return null;
  }

  Future<bool> _delete(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http.delete(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['success'] == true;
      }
    } catch (e) {
      debugPrint('SchoolApiService DELETE $path error: $e');
    }
    return false;
  }

  // ----------------------------------------------------
  // Employees & Staff
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployees({String? query}) async {
    final res = await _get('/employees', query != null ? {'q': query} : null);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> createEmployee(Map<String, dynamic> data) async {
    final res = await _post('/employees', data);
    if (res != null && res['success'] == true) {
      return res['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> updateEmployee(String id, Map<String, dynamic> data) async {
    final res = await _put('/employees/$id', data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteEmployee(String id) async {
    return await _delete('/employees/$id');
  }

  Future<Map<String, dynamic>?> fetchEmployeePermissions(String id) async {
    final res = await _get('/employees/$id/permissions');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> updateEmployeePermissions(
    String id, {
    List<String>? permissions,
    List<String>? roles,
    List<String>? directPermissions,
  }) async {
    final payload = <String, dynamic>{
      if (permissions != null) 'permissions': permissions,
      if (roles != null) 'roles': roles,
      if (directPermissions != null) 'direct_permissions': directPermissions,
    };
    final res = await _post('/employees/$id/permissions', payload);
    return res != null && res['success'] == true;
  }

  // ----------------------------------------------------
  // Students & Registration
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchStudents({String? query}) async {
    final res = await _get('/students', query != null ? {'q': query} : null);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchStudentFormMeta() async {
    final res = await _get('/academic/students/meta');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchStudentForm(String studentId) async {
    final res = await _get('/academic/students/$studentId/form');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchStudentAddress(String studentId) async {
    final res = await _get('/academic/contracts/student-address/$studentId');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> saveStudentFull(Map<String, dynamic> payload, {String? id}) async {
    final path = id != null && id.isNotEmpty ? '/academic/students/$id' : '/academic/students';
    final res = await _post(path, payload);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveStudent(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/students/$recordId' : '/students';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteStudent(String studentId) async {
    return await _delete('/academic/students/$studentId');
  }

  // ----------------------------------------------------
  // Student Operations: Login, Parents, Cancel, Notes, Grad
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchStudentLoginDetails(String studentId) async {
    final res = await _get('/academic/students/$studentId/login-details');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveStudentLoginDetails(String studentId, Map<String, dynamic> data) async {
    final res = await _post('/academic/students/$studentId/login-details', data);
    return res != null && res['success'] == true;
  }

  Future<Map<String, dynamic>?> fetchStudentRelations(String studentId) async {
    final res = await _get('/academic/students/$studentId/relations');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveStudentRelations(String studentId, Map<String, dynamic> data) async {
    final res = await _post('/academic/students/$studentId/relations', data);
    return res != null && res['success'] == true;
  }

  Future<Map<String, dynamic>?> fetchStudentCancellation(String studentId) async {
    final res = await _get('/academic/students/$studentId/cancellation');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> storeStudentCancellation(String studentId, Map<String, dynamic> data) async {
    final res = await _post('/academic/students/$studentId/cancellation', data);
    return res != null && res['success'] == true;
  }

  Future<List<Map<String, dynamic>>> fetchStudentNotes(String studentId, {String? yearId}) async {
    final res = await _get('/academic/students/$studentId/notes', yearId != null ? {'year_id': yearId} : null);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> storeStudentNote(String studentId, Map<String, dynamic> data) async {
    final res = await _post('/academic/students/$studentId/notes', data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteStudentNote(String noteId) async {
    return await _delete('/academic/students/notes/$noteId');
  }

  Future<Map<String, dynamic>?> fetchStudentGraduation(String studentId) async {
    final res = await _get('/academic/students/$studentId/graduation');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveStudentGraduation(String studentId, Map<String, dynamic> data) async {
    final res = await _post('/academic/students/$studentId/graduation', data);
    return res != null && res['success'] == true;
  }

  // ----------------------------------------------------
  // Admissions (Şagird qəbulu)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchAdmissionsData({String? tab}) async {
    final res = await _get('/academic/admissions', tab != null ? {'tab': tab} : null);
    return res != null && res['success'] == true ? (res as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchAdmissionDetail(String admissionId) async {
    final res = await _get('/academic/admissions/$admissionId');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> updateAdmissionStage(String id, dynamic stageOrData) async {
    final body = stageOrData is Map ? stageOrData : {'stage': stageOrData};
    final res = await _post('/academic/admissions/$id/stage', body);
    return res != null && res['success'] == true;
  }

  Future<bool> rejectAdmission(String id, String reason) async {
    final res = await _post('/academic/admissions/$id/reject', {'reason': reason});
    return res != null && res['success'] == true;
  }

  Future<bool> deleteAdmission(String id) async {
    return await _delete('/academic/admissions/$id');
  }

  // ----------------------------------------------------
  // Contracts & Pricing
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> getContractFormData(String studentId) async {
    final res = await _get('/academic/contracts/form/$studentId');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchTuitionFee({
    String? userId,
    required String academicYearId,
    String? classId,
    String? contractType,
  }) async {
    final query = <String, dynamic>{
      'academic_year_id': academicYearId,
      if (userId != null) 'user_id': userId,
      if (classId != null) 'class_id': classId,
      if (contractType != null) 'contract_type': contractType,
    };
    final res = await _get('/academic/pricing/tuition', query);
    return res != null && res['success'] == true ? (res as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> calculateTransportPrice({
    String? studentId,
    required String academicYearId,
    String? startDate,
    required String pickupAddress,
    required String dropoffAddress,
  }) async {
    final res = await _post('/academic/pricing/transport', {
      if (studentId != null) 'student_id': studentId,
      'academic_year_id': academicYearId,
      if (startDate != null) 'start_date': startDate,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> saveContract(Map<String, dynamic> payload) async {
    final res = await _post('/academic/contracts', payload);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<List<Map<String, dynamic>>> fetchContracts({
    String? studentId,
    String? employeeId,
    String? employeeCode,
    String? status,
    String? type,
    String? search,
    bool? expiring,
  }) async {
    final query = <String, dynamic>{
      if (studentId != null) 'student_id': studentId,
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeCode != null) 'employee_code': employeeCode,
      if (status != null && status != 'all' && status != 'Hamısı') 'status': status,
      if (type != null && type != 'all' && type != 'Hamısı') 'type': type,
      if (search != null && search.isNotEmpty) 'q': search,
      if (expiring == true) 'expiring': '1',
    };
    final res = await _get('/contracts', query);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchContractsDetailedData({
    String? employeeId,
    String? employeeCode,
    String? status,
    String? type,
    String? search,
    bool? expiring,
  }) async {
    final query = <String, dynamic>{
      if (employeeId != null) 'employee_id': employeeId,
      if (employeeCode != null) 'employee_code': employeeCode,
      if (status != null && status != 'all' && status != 'Hamısı') 'status': status,
      if (type != null && type != 'all' && type != 'Hamısı') 'type': type,
      if (search != null && search.isNotEmpty) 'q': search,
      if (expiring == true) 'expiring': '1',
    };
    final res = await _get('/contracts', query);
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<bool> terminateHrContract(String contractId, {String? endDate, String? reason}) async {
    final res = await _post('/contracts/$contractId/terminate', {
      'end_date': endDate,
      'reason': reason,
    });
    return res != null && res['success'] == true;
  }

  Future<Map<String, dynamic>?> saveHrContract(Map<String, dynamic> data, {String? contractId}) async {
    final endpoint = (contractId != null && contractId.isNotEmpty)
        ? '/contracts/$contractId'
        : '/contracts';
    final res = await _post(endpoint, data);
    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  // ----------------------------------------------------
  // HR Sənədlər (Employee Documents)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchEmployeeDocumentsData({
    int? documentTypeId,
    String? employeeId,
    String? status,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (documentTypeId != null && documentTypeId > 0) 'document_type_id': documentTypeId,
      if (employeeId != null) 'employee_id': employeeId,
      if (status != null && status != 'all' && status != 'Hamısı') 'status': status,
      if (search != null && search.isNotEmpty) 'q': search,
    };
    final res = await _get('/employee-documents', query);
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> createEmployeeDocument({
    required int employeeId,
    required int documentTypeId,
    required String startDate,
    String? endDate,
    String? notes,
    Map<String, dynamic>? content,
  }) async {
    final res = await _post('/employee-documents', {
      'employee_id': employeeId,
      'document_type_id': documentTypeId,
      'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (notes != null) 'notes': notes,
      if (content != null) 'content': content,
    });
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<bool> deleteEmployeeDocument(String id) async {
    return _delete('/employee-documents/$id');
  }

  // ----------------------------------------------------
  // Ambulatory (Ambulator Sorğular)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchAmbulatoryData({
    String? date,
    String? status,
    String? tab,
    String? search,
    String? finalStatus,
    String? dateFrom,
    String? dateTo,
  }) async {
    final query = <String, dynamic>{};
    if (date != null) query['date'] = date;
    if (status != null) query['status'] = status;
    if (tab != null) query['tab'] = tab;
    if (search != null) query['search'] = search;
    if (finalStatus != null) query['final_status'] = finalStatus;
    if (dateFrom != null) query['date_from'] = dateFrom;
    if (dateTo != null) query['date_to'] = dateTo;
    final res = await _get('/medical/ambulatory', query);
    return res != null && res['success'] == true ? (res as Map<String, dynamic>?) : null;
  }

  Future<bool> approveAmbulatory(String id, {String? note}) async {
    final data = <String, dynamic>{};
    if (note != null) data['note'] = note;
    final res = await _post('/medical/ambulatory/$id/approve', data);
    return res != null && res['success'] == true;
  }

  Future<bool> rejectAmbulatory(String id, String? reason, {String? note}) async {
    final data = <String, dynamic>{};
    if (reason != null) data['reason'] = reason;
    if (note != null) data['note'] = note;
    final res = await _post('/medical/ambulatory/$id/reject', data);
    return res != null && res['success'] == true;
  }

  // ----------------------------------------------------
  // Graduations (Məzunlar)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchGraduationsData({String? academicYearId, String? search}) async {
    final query = <String, dynamic>{};
    if (academicYearId != null) query['academic_year_id'] = academicYearId;
    if (search != null) query['q'] = search;
    final res = await _get('/academic/graduations', query);
    return res != null && res['success'] == true ? (res as Map<String, dynamic>?) : null;
  }

  Future<bool> updateGraduation(String id, Map<String, dynamic> data) async {
    final res = await _put('/academic/graduations/$id', data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteGraduation(String id) async {
    return await _delete('/academic/graduations/$id');
  }

  // ----------------------------------------------------
  // Academic Classes, Subjects, Rooms, Slots, Years, Curriculums
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final res = await _get('/classes');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchClassesFull() async {
    final res = await _get('/academic/classes/full');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchClassesPayload({
    String? academicYearId,
    String? gradeLevel,
    String? gradeLanguage,
    String? studentSearch,
  }) async {
    final query = <String, dynamic>{
      if (academicYearId != null && academicYearId.isNotEmpty) 'academic_year_id': academicYearId,
      if (gradeLevel != null && gradeLevel.isNotEmpty) 'grade_level': gradeLevel,
      if (gradeLanguage != null && gradeLanguage.isNotEmpty) 'grade_language': gradeLanguage,
      if (studentSearch != null && studentSearch.isNotEmpty) 'student_search': studentSearch,
    };
    final res = await _get('/academic/classes/full', query.isEmpty ? null : query);
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchClassManageDetails(String classId) async {
    final res = await _get('/academic/classes/$classId/manage');
    if (res != null && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    return null;
  }

  Future<bool> saveClass(Map<String, dynamic> data, {String? id}) async {
    final path = id != null && id.isNotEmpty ? '/academic/classes/$id' : '/academic/classes';
    final res = id != null ? await _put(path, data) : await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteClass(String id) async {
    return await _delete('/academic/classes/$id');
  }

  Future<bool> assignClassHomeroomTeacher(String classId, List<String> teacherIds) async {
    final res = await _post('/academic/classes/$classId/homeroom-teacher', {'teacherIds': teacherIds});
    return res != null && res['success'] == true;
  }

  Future<bool> saveClassSubjectTeacher(String classId, Map<String, dynamic> data) async {
    final res = await _post('/academic/classes/$classId/subject-teachers', data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteClassSubjectTeacher(String classId, String assignmentId) async {
    return await _delete('/academic/classes/$classId/subject-teachers/$assignmentId');
  }

  Future<bool> updateClassStudentStartDate(String classId, String classStudentId, String startDate) async {
    final res = await _post('/academic/classes/$classId/student-start-date', {
      'classStudentId': classStudentId,
      'startDate': startDate,
    });
    return res != null && res['success'] == true;
  }

  Future<bool> assignStudentToClass(String classId, String studentId) async {
    final res = await _post('/academic/classes/assign-student', {
      'classId': classId,
      'studentId': studentId,
    });
    return res != null && res['success'] == true;
  }

  Future<bool> removeStudentFromClass(String classId, String studentId) async {
    return await _delete('/academic/classes/$classId/students/$studentId');
  }

  Future<bool> dissolveClass(String classId, {String? dissolveDate, Map<String, dynamic>? transfers}) async {
    final res = await _post('/academic/classes/$classId/dissolve', {
      if (dissolveDate != null && dissolveDate.isNotEmpty) 'dissolveDate': dissolveDate,
      if (transfers != null && transfers.isNotEmpty) 'transfers': transfers,
    });
    return res != null && res['success'] == true;
  }

  Future<bool> saveClassSubjectTeachersBulk(String classId, Map<String, dynamic> data) async {
    final res = await _post('/academic/classes/$classId/subject-teachers/bulk', data);
    return res != null && res['success'] == true;
  }

  Future<List<Map<String, dynamic>>> fetchStudentsForAssignment(String classId) async {
    final res = await _get('/academic/classes/$classId/students-for-assignment');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> assignStudentsToClass(String classId, List<String> studentIds) async {
    final res = await _post('/academic/classes/$classId/assign-students', {
      'students': studentIds,
      'studentIds': studentIds,
    });
    return res != null && res['success'] == true;
  }

  Future<Map<String, dynamic>> fetchRoomAssignments({String? academicYearId, String? classId}) async {
    final res = await _get('/academic/classes/room-assignments', {
      if (academicYearId != null && academicYearId.isNotEmpty) 'academic_year_id': academicYearId,
      if (classId != null && classId.isNotEmpty) 'class_id': classId,
    });
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return {};
  }

  Future<String?> saveClassGroupForClass(String classId, Map<String, dynamic> data, {String? groupId}) async {
    final res = groupId != null && groupId.isNotEmpty
        ? await _post('/academic/classes/$classId/groups/$groupId', data)
        : await _post('/academic/classes/$classId/groups', data);
    if (res != null && res['success'] == true) {
      final payload = res['data'];
      if (payload is Map && payload['id'] != null) {
        return payload['id'].toString();
      }
      return '';
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchGroupStudentsForAssignment(String classId, String groupId) async {
    final res = await _get('/academic/classes/$classId/groups/$groupId/students-for-assignment');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> assignGroupStudentsToGroup(String classId, String groupId, List<String> studentIds) async {
    final res = await _post('/academic/classes/$classId/groups/$groupId/students', {
      'group_students': studentIds,
      'studentIds': studentIds,
    });
    return res != null && res['success'] == true;
  }

  Future<String?> mergeClassGroups(String classId, Map<String, dynamic> data) async {
    final res = await _post('/academic/classes/$classId/groups/merge', data);
    if (res != null && res['success'] == true) {
      final payload = res['data'];
      if (payload is Map && payload['id'] != null) {
        return payload['id'].toString();
      }
      return '';
    }
    return null;
  }

  Future<bool> saveClassCurriculum(String classId, List<Map<String, dynamic>> items) async {
    final res = await _post('/academic/classes/$classId/curriculum', {'curriculum': items});
    return res != null && res['success'] == true;
  }

  Future<bool> cancelClassSubject(String classId, {required String subjectId, required String cancelDate}) async {
    final res = await _post('/academic/classes/$classId/cancel-subject', {
      'subjectId': subjectId,
      'cancelDate': cancelDate,
    });
    return res != null && res['success'] == true;
  }

  Future<bool> splitClass(
    String classId, {
    required String newClassName,
    required String splitDate,
    required List<String> movedStudents,
    bool copySchedules = false,
  }) async {
    final res = await _post('/academic/classes/$classId/split', {
      'newClassName': newClassName,
      'splitDate': splitDate,
      'movedStudents': movedStudents,
      'copySchedules': copySchedules,
    });
    return res != null && res['success'] == true;
  }

  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    final res = await _get('/academic/subjects');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveSubject(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/subjects/$recordId' : '/academic/subjects';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteSubject(String id) async {
    return await _delete('/academic/subjects/$id');
  }

  Future<List<Map<String, dynamic>>> fetchAcademicYears() async {
    final res = await _get('/academic/years');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveAcademicYear(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/years/$recordId' : '/academic/years';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteAcademicYear(String id) async {
    return await _delete('/academic/years/$id');
  }

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final res = await _get('/academic/rooms');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveRoom(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/rooms/$recordId' : '/academic/rooms';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteRoom(String id) async {
    return await _delete('/academic/rooms/$id');
  }

  Future<List<Map<String, dynamic>>> fetchTimeSlots() async {
    final res = await _get('/academic/time-slots');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveTimeSlot(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/time-slots/$recordId' : '/academic/time-slots';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteTimeSlot(String id) async {
    return await _delete('/academic/time-slots/$id');
  }

  Future<List<Map<String, dynamic>>> fetchCurriculums() async {
    final res = await _get('/academic/curriculums');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveCurriculum(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/curriculums/$recordId' : '/academic/curriculums';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteCurriculum(String id) async {
    return await _delete('/academic/curriculums/$id');
  }

  // ----------------------------------------------------
  // Transitions (Sinifdən-sinfə keçid)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchTransitionsPayload({String? tab, String? department}) async {
    final params = <String, String>{};
    if (tab != null && tab.isNotEmpty) params['tab'] = tab;
    if (department != null && department.isNotEmpty) params['department'] = department;
    final res = await _get('/academic/transitions', params.isNotEmpty ? params : null);
    return res != null && res['success'] == true ? (res as Map<String, dynamic>?) : null;
  }

  Future<bool> updateTransitionStage(String id, Map<String, dynamic> data) async {
    final res = await _post('/academic/transitions/$id/stage', data);
    return res != null && res['success'] == true;
  }

  Future<bool> updateTransitionDecision(String id, {required bool approved, String? note, String? reason}) async {
    final data = <String, dynamic>{'approved': approved};
    if (note != null) data['note'] = note;
    if (reason != null) data['reason'] = reason;
    final res = await _post('/academic/transitions/$id/decision', data);
    return res != null && res['success'] == true;
  }

  Future<bool> saveTransition(Map<String, dynamic> data, {String? id}) async {
    final path = id != null && id.isNotEmpty ? '/academic/transitions/$id' : '/academic/transitions';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteTransition(String id) async {
    return await _delete('/academic/transitions/$id');
  }

  // ----------------------------------------------------
  // Parents
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchParents({String? query}) async {
    final res = await _get('/academic/parents', query != null ? {'q': query} : null);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchParentsPayload({String? query}) async {
    final res = await _get('/academic/parents', query != null && query.isNotEmpty ? {'q': query} : null);
    if (res != null && res is Map<String, dynamic>) {
      return res;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchParentForm(String parentId) async {
    final res = await _get('/academic/parents/$parentId/form');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> saveParent(Map<String, dynamic> data, {String? id}) async {
    final path = id != null && id.isNotEmpty ? '/academic/parents/$id' : '/academic/parents';
    final res = id != null && id.isNotEmpty ? await _put(path, data) : await _post(path, data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> deleteParent(String id) async {
    return await _delete('/academic/parents/$id');
  }

  Future<Map<String, dynamic>?> fetchParentLoginDetails(String parentId) async {
    final res = await _get('/academic/parents/$parentId/login-details');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveParentLoginDetails(String parentId, Map<String, dynamic> data) async {
    final res = await _post('/academic/parents/$parentId/login-details', data);
    return res != null && res['success'] == true;
  }

  Future<bool> addParentChild(String parentId, {required String studentId, required String parentType}) async {
    final res = await _post('/academic/parents/$parentId/add-child', {
      'student_id': studentId,
      'parent_type': parentType,
    });
    return res != null && res['success'] == true;
  }

  Future<bool> transferParentChild(String parentId, {required String studentId, String? targetParentId, String? parentType, bool detachOnly = false}) async {
    final res = await _post('/academic/parents/$parentId/transfer-child', {
      'student_id': studentId,
      'target_parent_id': targetParentId,
      'parent_type': parentType,
      'detach_only': detachOnly,
    });
    return res != null && res['success'] == true;
  }

  Future<bool> detachParentChild(String parentId, String studentId) async {
    return await _delete('/academic/parents/$parentId/children/$studentId');
  }

  Future<Map<String, dynamic>?> parentMergePreview({required String targetId, required String sourceId}) async {
    final res = await _post('/academic/parents/merge-preview', {
      'target_id': targetId,
      'source_id': sourceId,
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> executeParentMerge({required String targetId, required String sourceId}) async {
    final res = await _post('/academic/parents/merge', {
      'target_id': targetId,
      'source_id': sourceId,
    });
    return res != null && res['success'] == true;
  }

  // ----------------------------------------------------
  // Schedules / Lessons
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchSchedules({
    String? classId,
    String? teacherId,
    int? dayOfWeek,
    String? weekStart,
    bool isTemplate = false,
  }) async {
    final params = <String, dynamic>{'per_page': 300};
    if (classId != null && classId.isNotEmpty) params['class_id'] = classId;
    if (teacherId != null && teacherId.isNotEmpty) params['teacher_id'] = teacherId;
    if (dayOfWeek != null) params['day_of_week'] = dayOfWeek;
    if (weekStart != null && weekStart.isNotEmpty) params['week_start'] = weekStart;
    if (isTemplate) params['is_template'] = 1;

    final res = await _get('/academic/schedules', params);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      final data = res['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      if (data is Map && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }
    // Fallback to legacy
    final legacy = await _get('/schedules', classId != null ? {'class_id': classId} : null);
    if (legacy != null && legacy['success'] == true && legacy['data'] is List) {
      return List<Map<String, dynamic>>.from(legacy['data']);
    }
    return [];
  }

  Future<bool> saveSchedule(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/schedules/$recordId' : '/academic/schedules';
    final res = await _post(path, data);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) return true;
    final fallbackPath = recordId != null && recordId.isNotEmpty ? '/schedules/$recordId' : '/schedules';
    final fallbackRes = await _post(fallbackPath, data);
    return fallbackRes != null && fallbackRes['success'] == true;
  }

  Future<bool> deleteSchedule(String id) async {
    final res = await _delete('/academic/schedules/$id');
    if (res) return true;
    return await _delete('/schedules/$id');
  }

  // ----------------------------------------------------
  // Clubs & Club Journals (100% Web GoPanel Parity)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> _postWithMessage(String path, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(data))
          .timeout(_timeout);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final ok = decoded['success'] == true || (response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] != false);
        return {
          ...decoded,
          'success': ok,
          'message': decoded['message']?.toString() ?? (ok ? 'Əməliyyat uğurla tamamlandı' : 'Əməliyyat alınmadı'),
        };
      }
    } catch (e) {
      debugPrint('SchoolApiService _postWithMessage $path error: $e');
    }
    return {'success': false, 'message': 'Serverlə əlaqə zamanı xəta baş verdi'};
  }

  Future<Map<String, dynamic>?> fetchClubsPayload({
    String? studentId,
    String? parentId,
    String? gradeCategory,
    bool onlyActive = false,
  }) async {
    final params = <String, dynamic>{
      if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
      if (parentId != null && parentId.isNotEmpty) 'parent_id': parentId,
      if (gradeCategory != null && gradeCategory.isNotEmpty) 'grade_category': gradeCategory,
      if (onlyActive) 'only_active': '1',
    };
    final res = await _get('/clubs', params.isNotEmpty ? params : null);
    if (res is Map<String, dynamic> && res['success'] == true) {
      return res;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchClubs({String? studentId, String? parentId}) async {
    final res = await fetchClubsPayload(studentId: studentId, parentId: parentId);
    if (res != null && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveClub(Map<String, dynamic> data, {String? id}) async {
    final res = await saveClubWithResult(data, id: id);
    return res['success'] == true;
  }

  Future<Map<String, dynamic>> saveClubWithResult(Map<String, dynamic> data, {String? id}) async {
    try {
      final hasId = id != null && id.isNotEmpty;
      final uri = Uri.parse('$baseUrl${hasId ? '/clubs/$id' : '/clubs'}');
      final response = hasId
          ? await http.put(uri, headers: _headers, body: jsonEncode(data)).timeout(_timeout)
          : await http.post(uri, headers: _headers, body: jsonEncode(data)).timeout(_timeout);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return {
          'success': decoded['success'] == true,
          'message': decoded['message']?.toString() ?? 'Yadda saxlanıldı',
          'data': decoded['data'],
        };
      }
    } catch (e) {
      debugPrint('saveClubWithResult error: $e');
    }
    return {'success': false, 'message': 'Əməliyyat alınmadı'};
  }

  Future<bool> deleteClub(String id) async {
    return await _delete('/clubs/$id');
  }

  Future<Map<String, dynamic>> saveClubSchedule(
    String clubId, {
    required List<Map<String, dynamic>> schedules,
    bool generateLessons = false,
    String? startDate,
  }) async {
    return await _postWithMessage('/clubs/$clubId/schedule', {
      'schedules': schedules,
      'generate_lessons': generateLessons,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
    });
  }

  Future<Map<String, dynamic>> enrollClubStudents(String clubId, List<String> studentIds) async {
    return await _postWithMessage('/clubs/$clubId/enroll', {
      'student_ids': studentIds,
    });
  }

  Future<bool> removeClubStudent(String clubId, String studentId) async {
    return await _delete('/clubs/$clubId/students/$studentId');
  }

  Future<Map<String, dynamic>> joinClubRequest(String clubId, String studentId, {bool asParent = true}) async {
    return await _postWithMessage('/clubs/$clubId/join', {
      'student_id': studentId,
      'as_parent': asParent,
    });
  }

  Future<Map<String, dynamic>> cancelClubJoinRequest(String clubId, String studentId) async {
    return await _postWithMessage('/clubs/$clubId/cancel-request', {
      'student_id': studentId,
    });
  }

  Future<Map<String, dynamic>> approveClubJoinRequest(int clubStudentId) async {
    return await _postWithMessage('/clubs/requests/$clubStudentId/approve', {});
  }

  Future<Map<String, dynamic>> rejectClubJoinRequest(int clubStudentId, {String? reason}) async {
    return await _postWithMessage('/clubs/requests/$clubStudentId/reject', {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchClubJournal() async {
    final res = await _get('/academic/club-journal');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchClubJournalData(String clubId, {String? date}) async {
    final res = await _get('/academic/club-journal/$clubId', date != null ? {'date': date} : null);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveClubJournalData(Map<String, dynamic> payload) async {
    final res = await _post('/academic/club-journal/save', payload);
    return res != null && res['success'] == true;
  }

  // ----------------------------------------------------
  // Excused Absences (Üzrlü Səbəblər)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchExcuses({String? studentId, String? status, String? parentId}) async {
    final query = <String, dynamic>{};
    if (studentId != null) query['student_id'] = studentId;
    if (status != null) query['status'] = status;
    if (parentId != null) query['parent_id'] = parentId;
    final res = await _get('/excuses', query);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveExcuse(Map<String, dynamic> data) async {
    final res = await _post('/excuses', data);
    return res != null && res['success'] == true;
  }

  Future<bool> updateExcuseStatus(String id, String status, {String? reason, Map<String, dynamic>? extra}) async {
    final body = <String, dynamic>{'status': status};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    if (extra != null) body.addAll(extra);
    final res = await _post('/excuses/$id/status', body);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteExcuse(String id) async {
    return await _delete('/excuses/$id');
  }

  // ----------------------------------------------------
  // Final Grading (Yekun Qiymətləndirmə)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchFinalGrading() async {
    final res = await _get('/grading/final');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveGrade(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/grading/final/$recordId' : '/grading/final';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteGrade(String id) async {
    return await _delete('/grading/final/$id');
  }

  // ----------------------------------------------------
  // Parallel Lessons / Groups V1 (100% Web Parity)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchParallelLessonsPage({
    int? academicYearId,
    int? filialId,
    String? parallelType,
    int? classId,
    int? subjectId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (academicYearId != null) queryParams['academic_year_id'] = academicYearId;
    if (filialId != null) queryParams['filial_id'] = filialId;
    if (parallelType != null && parallelType != 'all') queryParams['parallel_type'] = parallelType;
    if (classId != null) queryParams['class_id'] = classId;
    if (subjectId != null) queryParams['subject_id'] = subjectId;

    final res = await _get('/academic/parallel-lessons', queryParams);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      return (res['data'] as Map<String, dynamic>?) ?? res;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchParallelLessonForm({
    int? id,
    int? academicYearId,
    int? filialId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (academicYearId != null) queryParams['academic_year_id'] = academicYearId;
    if (filialId != null) queryParams['filial_id'] = filialId;

    final path = id != null ? '/academic/parallel-lessons/form/$id' : '/academic/parallel-lessons/form';
    final res = await _get(path, queryParams);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      return (res['data'] as Map<String, dynamic>?) ?? res;
    }
    return null;
  }

  Future<Map<String, dynamic>> saveParallelLessonBundle(Map<String, dynamic> payload, {int? id}) async {
    final path = id != null ? '/academic/parallel-lessons/save/$id' : '/academic/parallel-lessons/save';
    final res = await _post(path, payload);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      return {'success': true, 'message': res['message']?.toString() ?? 'Uğurla saxlanıldı'};
    }
    return {'success': false, 'message': res?['message']?.toString() ?? 'Xəta baş verdi'};
  }

  Future<bool> deleteParallelLessonBundle(int id) async {
    final res = await _delete('/academic/parallel-lessons/$id');
    return res;
  }

  Future<List<Map<String, dynamic>>> fetchGroupAssignmentStudents(int classId, int groupId) async {
    final res = await _get('/academic/classes/$classId/groups/$groupId/students');
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      final data = res['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return [];
  }

  Future<bool> saveGroupAssignmentStudents(int classId, int groupId, List<int> studentIds) async {
    final res = await _post('/academic/classes/$classId/groups/$groupId/students', {
      'group_students': studentIds,
    });
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<List<Map<String, dynamic>>> fetchParallelLessons() async {
    final page = await fetchParallelLessonsPage();
    if (page != null && page['groups'] is List) {
      return List<Map<String, dynamic>>.from(page['groups']);
    }
    final res = await _get('/parallel-lessons');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveClassGroup(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/parallel-lessons/$recordId' : '/parallel-lessons';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteClassGroup(String id) async {
    return await _delete('/parallel-lessons/$id');
  }

  // ----------------------------------------------------
  // Assignments
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAssignments() async {
    final res = await _get('/assignments');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveAssignment(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/assignments/$recordId' : '/assignments';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteAssignment(String id) async {
    return await _delete('/assignments/$id');
  }

  // ----------------------------------------------------
  // Academic Notes & Statuses
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAcademicNotes({
    String? studentId,
    String? type,
    String? search,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, String>{};
    if (studentId != null && studentId.isNotEmpty) queryParams['student_id'] = studentId;
    if (type != null && type.isNotEmpty && type != 'all') queryParams['type'] = type;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final res = await _get('/academic/notes$queryString');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveAcademicNote(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/notes/$recordId' : '/academic/notes';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteAcademicNote(String id) async {
    return await _delete('/academic/notes/$id');
  }

  Future<List<Map<String, dynamic>>> fetchStatuses() async {
    final res = await _get('/academic/statuses');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<bool> saveStatus(Map<String, dynamic> data, {String? id}) async {
    final recordId = id ?? data['id']?.toString();
    final path = recordId != null && recordId.isNotEmpty ? '/academic/statuses/$recordId' : '/academic/statuses';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteStatus(String id) async {
    return await _delete('/academic/statuses/$id');
  }

  // ----------------------------------------------------
  // Roles & Permissions
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchRolesWithCatalog() async {
    final res = await _get('/roles');
    return res != null && res['success'] == true ? res : null;
  }

  Future<bool> saveRole(Map<String, dynamic> data, {String? id}) async {
    final path = id != null && id.isNotEmpty ? '/roles/$id' : '/roles';
    final res = await _post(path, data);
    return res != null && res['success'] == true;
  }

  Future<bool> deleteRole(String id) async {
    return await _delete('/roles/$id');
  }

  // ----------------------------------------------------
  // Miscellaneous helpers (Books, Journal, Finance, Logs, etc.)
  // ----------------------------------------------------
  Future<Map<String, dynamic>> fetchTeachersPage({
    int? filialId,
    int? academicYearId,
    String? status,
    String? query,
    int page = 1,
    int perPage = 300,
  }) async {
    final params = <String, dynamic>{'per_page': perPage, 'page': page};
    if (filialId != null) params['filial_id'] = filialId;
    if (academicYearId != null) params['academic_year_id'] = academicYearId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

    final res = await _get('/academic/teachers', params);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      final data = res['data'];
      final meta = (res['meta'] as Map<String, dynamic>?) ?? {};
      List<Map<String, dynamic>> items = [];
      if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        items = List<Map<String, dynamic>>.from(data['data']);
      }
      return {
        'items': items,
        'kpi': (meta['kpi'] as Map<String, dynamic>?) ?? {},
        'filters': (meta['filters'] as Map<String, dynamic>?) ?? {},
        'permissions': (meta['permissions'] as Map<String, dynamic>?) ?? {},
        'total': meta['total'] ?? items.length,
      };
    }
    return {'items': <Map<String, dynamic>>[], 'kpi': <String, dynamic>{}, 'filters': <String, dynamic>{}, 'permissions': <String, dynamic>{}, 'total': 0};
  }

  Future<List<Map<String, dynamic>>> fetchTeachers({int? filialId, int? academicYearId, String? query, int perPage = 300}) async {
    final params = <String, dynamic>{'per_page': perPage};
    if (filialId != null) params['filial_id'] = filialId;
    if (academicYearId != null) params['academic_year_id'] = academicYearId;
    if (query != null && query.isNotEmpty) params['q'] = query;

    final res = await _get('/academic/teachers', params);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      final data = res['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      if (data is Map && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }
    // Fallback to legacy
    final legacy = await _get('/teachers');
    if (legacy != null && legacy['success'] == true && legacy['data'] is List) {
      return List<Map<String, dynamic>>.from(legacy['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchTeacherProfile(int id, {int? academicYearId}) async {
    final params = <String, dynamic>{};
    if (academicYearId != null) params['academic_year_id'] = academicYearId;
    final res = await _get('/academic/teachers/$id/profile', params);
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      return (res['data'] as Map<String, dynamic>?) ?? res;
    }
    return null;
  }

  Future<bool> saveTeacherHomeroom(int teacherId, List<int> classIds) async {
    final res = await _post('/academic/teachers/$teacherId/homeroom', {'classes': classIds});
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<bool> saveTeacherSubjects(int teacherId, List<int> subjectIds) async {
    final res = await _post('/academic/teachers/$teacherId/subjects', {'subjects': subjectIds});
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<bool> saveTeacherColor(int teacherId, String colorCode) async {
    final res = await _post('/academic/teachers/$teacherId/color', {'color_code': colorCode});
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<bool> saveTeacherUnavailability(int teacherId, List<String> unavailableSlots) async {
    final res = await _post('/academic/teachers/$teacherId/unavailability', {'unavailable_slots': unavailableSlots});
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<bool> createTeacherClassSubject(
    int teacherId, {
    required int subjectId,
    required double weeklyHours,
    int hoursPerDay = 1,
    required String assignmentType,
    List<int>? classes,
    int? classGroupId,
  }) async {
    final payload = <String, dynamic>{
      'subject_id': subjectId,
      'weekly_hours': weeklyHours.toInt(),
      'hours_per_day': hoursPerDay,
      'assignment_type': assignmentType,
    };
    if (classes != null && classes.isNotEmpty) {
      payload['classes'] = classes;
    }
    if (classGroupId != null) {
      payload['target_group_id'] = classGroupId;
      payload['class_group_id'] = classGroupId;
    }
    final res = await _post('/academic/teachers/$teacherId/class-subjects', payload);
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<bool> deleteTeacherClassSubject(int teacherId, int assignmentId) async {
    return await _delete('/academic/teachers/$teacherId/class-subjects/$assignmentId');
  }

  Future<bool> splitTransferTeacherClassSubject(int teacherId, int assignmentId, int newTeacherId, double hours) async {
    final res = await _post('/academic/teachers/$teacherId/class-subjects/$assignmentId/split-transfer', {
      'new_teacher_id': newTeacherId,
      'hours': hours,
    });
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<Map<String, dynamic>?> fetchTeacherSubstitution(int teacherId) async {
    final res = await _get('/academic/teachers/$teacherId/substitution');
    if (res != null && (res['status'] == 'success' || res['success'] == true)) {
      return (res['data'] as Map<String, dynamic>?) ?? res;
    }
    return null;
  }

  Future<bool> saveTeacherSubstitution({
    required int teacherId,
    required int documentTypeId,
    required String startDate,
    String? endDate,
    String? documentNumber,
    String? reason,
    required Map<String, int> substitutions,
  }) async {
    final res = await _post('/academic/teachers/$teacherId/substitution', {
      'document_type_id': documentTypeId,
      'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (documentNumber != null && documentNumber.isNotEmpty) 'document_number': documentNumber,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      'substitutions': substitutions,
    });
    return res != null && (res['status'] == 'success' || res['success'] == true);
  }

  Future<List<Map<String, dynamic>>> fetchBooks() async {
    final res = await _get('/library/books');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchJournalLesson(String lessonId, {String? date}) async {
    final res = await _get('/journal/lessons/$lessonId', date != null ? {'date': date} : null);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> saveJournalLesson(String lessonId, Map<String, dynamic> data) async {
    final res = await _post('/journal/lessons/$lessonId', data);
    return res != null && res['success'] == true;
  }

  Future<Map<String, dynamic>?> fetchParentFinance({String? parentId, String? studentId}) async {
    final query = <String, dynamic>{
      if (parentId != null) 'parent_id': parentId,
      if (studentId != null) 'student_id': studentId,
    };
    final res = await _get('/parent/finance', query);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchStructure() async {
    final res = await _get('/structure');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  // =================================================================
  // HR STRUKTURLAR (Organizational Structures 1:1 GoPanel Web Parity)
  // =================================================================

  Future<List<Map<String, dynamic>>> fetchHrStructures({
    String? q,
    String? type,
    int? companyId,
    bool? isActive,
    bool all = true,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.isNotEmpty) 'q': q,
      if (type != null && type.isNotEmpty) 'type_of_structure': type,
      if (companyId != null) 'company_id': companyId,
      if (isActive != null) 'is_active': isActive,
      if (all) 'all': 'true',
    };
    final res = await _get('/hr/structures', query);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchHrStructureTree({int? companyId}) async {
    final query = <String, dynamic>{
      if (companyId != null) 'company_id': companyId,
    };
    final res = await _get('/hr/structures/tree', query);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchHrStructureDiagram({int? companyId}) async {
    final query = <String, dynamic>{
      if (companyId != null) 'company_id': companyId,
    };
    final res = await _get('/hr/structures/diagram', query);
    if (res != null && res['success'] == true && res['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(res['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchHrStructureDetail(int id) async {
    final res = await _get('/hr/structures/$id');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchHrStructureEmployees(int id, {bool includeInactive = false}) async {
    final res = await _get('/hr/structures/$id/employees', {
      if (includeInactive) 'include_inactive': 'true',
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> createHrStructure(Map<String, dynamic> data) async {
    final res = await _post('/hr/structures', data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> updateHrStructure(int id, Map<String, dynamic> data) async {
    final res = await _put('/hr/structures/$id', data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> deleteHrStructure(int id) async {
    return await _delete('/hr/structures/$id');
  }

  Future<Map<String, dynamic>?> toggleHrStructureStatus(int id) async {
    final res = await _post('/hr/structures/$id/status', {});
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchHrStructureConnections(int id) async {
    final res = await _get('/hr/structures/$id/connections');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> attachHrStructureParent(int id, {int? parentId, String mode = 'replace'}) async {
    final res = await _post('/hr/structures/$id/attach-parent', {
      'parent_id': parentId,
      'mode': mode,
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> detachHrStructureParent(int id, int parentId) async {
    final res = await _post('/hr/structures/$id/detach-parent', {
      'parent_id': parentId,
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  // =================================================================
  // HR POSITIONS (VƏZİFƏLƏR - Web Parity)
  // =================================================================

  Future<List<Map<String, dynamic>>> fetchHrPositions({
    String? q,
    String? workerType,
    bool? isActive,
    bool? isTeachingStaff,
    bool all = true,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (workerType != null && workerType.isNotEmpty && workerType != 'ALL') 'worker_type': workerType,
      if (isActive != null) 'is_active': isActive.toString(),
      if (isTeachingStaff != null) 'is_teaching_staff': isTeachingStaff.toString(),
      if (all) 'all': 'true',
    };
    final res = await _get('/hr/positions', query);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchHrPositionDetail(int id) async {
    final res = await _get('/hr/positions/$id');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchHrPositionEmployees(int id, {bool includeInactive = false}) async {
    final res = await _get('/hr/positions/$id/employees', {
      if (includeInactive) 'include_inactive': 'true',
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> createHrPosition(Map<String, dynamic> data) async {
    final res = await _post('/hr/positions', data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> updateHrPosition(int id, Map<String, dynamic> data) async {
    final res = await _put('/hr/positions/$id', data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> deleteHrPosition(int id) async {
    return await _delete('/hr/positions/$id');
  }

  Future<Map<String, dynamic>?> toggleHrPositionStatus(int id) async {
    final res = await _post('/hr/positions/$id/status', {});
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  // =================================================================
  // HR STAFFING TABLES (ŞTAT CƏDVƏLİ - Web Parity)
  // =================================================================

  Future<List<Map<String, dynamic>>> fetchHrStaffingTables({
    String? q,
    int? filialId,
    int? structureId,
    int? positionId,
    bool? isVacant,
    bool all = true,
  }) async {
    final query = <String, dynamic>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (filialId != null) 'filial_id': filialId,
      if (structureId != null) 'structure_id': structureId,
      if (positionId != null) 'position_id': positionId,
      if (isVacant != null) 'is_vacant': isVacant.toString(),
      if (all) 'all': 'true',
    };
    final res = await _get('/hr/staffing-tables', query);
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchHrStaffingTablesSummary() async {
    final res = await _get('/hr/staffing-tables/summary');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchHrStaffingTableDetail(int id) async {
    final res = await _get('/hr/staffing-tables/$id');
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> fetchHrStaffingTableEmployees(int id, {bool includeInactive = false}) async {
    final res = await _get('/hr/staffing-tables/$id/employees', {
      if (includeInactive) 'include_inactive': 'true',
    });
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> createHrStaffingTable(Map<String, dynamic> data) async {
    final res = await _post('/hr/staffing-tables', data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<Map<String, dynamic>?> updateHrStaffingTable(int id, Map<String, dynamic> data) async {
    final res = await _put('/hr/staffing-tables/$id', data);
    return res != null && res['success'] == true ? (res['data'] as Map<String, dynamic>?) : null;
  }

  Future<bool> deleteHrStaffingTable(int id) async {
    return await _delete('/hr/staffing-tables/$id');
  }

  Future<List<Map<String, dynamic>>> fetchFilials() async {
    final res = await _get('/filials');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchActivityLogs() async {
    final res = await _get('/logs');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchExamResults() async {
    final res = await _get('/exams/results');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchExams() async {
    final res = await _get('/exams');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchInvoices() async {
    final res = await _get('/invoices');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchContractsDetailed({
    String? search,
    String? contractType,
    String? status,
    String? directorApprovalStatus,
    int? studentId,
    int? academicYearId,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (contractType != null && contractType != 'all') params['contract_type'] = contractType;
    if (status != null && status != 'all') params['status'] = status;
    if (directorApprovalStatus != null && directorApprovalStatus != 'all') {
      params['director_approval_status'] = directorApprovalStatus;
    }
    if (studentId != null) params['student_id'] = studentId;
    if (academicYearId != null) params['academic_year_id'] = academicYearId;

    final res = await _get('/invoices', params);
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> directorApproveContract(int contractId) async {
    final res = await _post('/academic/contracts/' + contractId.toString() + '/director-approve', {});
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> directorRejectContract(int contractId, String reason) async {
    final res = await _post('/academic/contracts/' + contractId.toString() + '/director-reject', {'reason': reason});
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> terminateStudentContract(int contractId, {String? reason, String? cancellationDate}) async {
    final res = await _post('/academic/contracts/' + contractId.toString() + '/terminate', {
      if (reason != null) 'reason': reason,
      if (cancellationDate != null) 'cancellation_date': cancellationDate,
    });
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchContractInstallments(int contractId) async {
    final res = await _get('/academic/contracts/' + contractId.toString() + '/installments');
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> recordContractPayment(
    int contractId, {
    required double amount,
    String? paymentDate,
    String? paymentMethod,
    String? notes,
  }) async {
    final res = await _post('/academic/contracts/' + contractId.toString() + '/record-payment', {
      'amount': amount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    });
    if (res != null && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchLedger() async {
    final res = await _get('/ledger');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchMedicalRecords() async {
    final res = await _get('/medical/records');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchPsychologyRecords() async {
    final res = await _get('/psychology/records');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchWarehouseItems() async {
    final res = await _get('/warehouse/items');
    if (res != null && res['success'] == true && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  // --- Student Contract Advanced Operations (Full Web Parity) ---

  Future<Map<String, dynamic>?> fetchContractEditForm({int? contractId, int? studentId}) async {
    final endpoint = contractId != null
        ? '/finance/contracts/form/$contractId'
        : (studentId != null ? '/finance/contracts/form?student_id=$studentId' : '/finance/contracts/form');
    final res = await _get(endpoint);
    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> saveContractFull(Map<String, dynamic> payload, {int? contractId}) async {
    final endpoint = contractId != null
        ? '/finance/contracts/save/$contractId'
        : '/finance/contracts/save';
    final res = await _post(endpoint, payload);
    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      return Map<String, dynamic>.from(res);
    }
    return res != null ? Map<String, dynamic>.from(res) : null;
  }

  Future<Map<String, dynamic>?> applyContractDiscount(
    int contractId, {
    required String discountType,
    required double discountValue,
  }) async {
    final res = await _post('/finance/contracts/$contractId/apply-discount', {
      'discount_type': discountType,
      'discount_value': discountValue,
    });
    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      return Map<String, dynamic>.from(res);
    }
    return res != null ? Map<String, dynamic>.from(res) : null;
  }

  Future<Map<String, dynamic>?> updateContractAmount(
    int contractId, {
    required double totalAmount,
    String? reason,
  }) async {
    final res = await _post('/finance/contracts/$contractId/update-amount', {
      'total_amount': totalAmount,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      return Map<String, dynamic>.from(res);
    }
    return res != null ? Map<String, dynamic>.from(res) : null;
  }

  Future<Map<String, dynamic>?> saveContractInstallments(
    int contractId, {
    int? numberOfInstallments,
    double? initialPayment,
    required List<Map<String, dynamic>> schedule,
    String? reason,
  }) async {
    final res = await _post('/finance/contracts/$contractId/save-installments', {
      'number_of_installments': numberOfInstallments ?? schedule.length,
      if (initialPayment != null) 'initial_payment': initialPayment,
      'schedule': schedule,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    if (res != null && (res['success'] == true || res['status'] == 'success')) {
      return Map<String, dynamic>.from(res);
    }
    return res != null ? Map<String, dynamic>.from(res) : null;
  }

  Future<Map<String, dynamic>?> fetchContractHistory(int contractId) async {
    final res = await _get('/finance/contracts/$contractId/history');
    if (res != null && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    return null;
  }

  Future<String?> fetchContractPrintUrl(int contractId) async {
    final res = await _get('/finance/contracts/$contractId/print-url');
    if (res != null && res['success'] == true && res['data'] is Map) {
      return res['data']['print_url']?.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchStudentFinanceModal(int contractId) async {
    final res = await _get('/finance/contracts/$contractId/student-modal');
    if (res != null && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    return null;
  }

  // --- Student Payments Operations (100% Web Parity) ---

  Future<Map<String, dynamic>?> fetchStudentPaymentsPage({
    int? academicYearId,
    int? classId,
    String? contractType,
    String? gradeLanguage,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (academicYearId != null) queryParams['academic_year_id'] = academicYearId.toString();
    if (classId != null) queryParams['class_id'] = classId.toString();
    if (contractType != null && contractType.isNotEmpty) queryParams['contract_type'] = contractType;
    if (gradeLanguage != null && gradeLanguage.isNotEmpty) queryParams['filter_grade_language'] = gradeLanguage;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri(
      path: '/finance/student-payments',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final res = await _get(uri.toString());
    if (res != null && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchPaymentPendingInvoices({
    int? studentId,
    int? parentId,
    String? contractType,
  }) async {
    final payload = <String, dynamic>{
      if (studentId != null) 'student_id': studentId,
      if (parentId != null) 'parent_id': parentId,
      if (contractType != null && contractType.isNotEmpty) 'contract_type': contractType,
    };

    final res = await _post('/finance/student-payments/pending-invoices', payload);
    if (res != null) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> storeStudentPayment(Map<String, dynamic> payload) async {
    final res = await _post('/finance/student-payments/store', payload);
    if (res != null) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> approvePendingPayment(int pendingId, {
    required double amount,
    required String paymentMethod,
    int? bankAccountId,
    String? notes,
  }) async {
    final res = await _post('/finance/student-payments/pending/$pendingId/approve', {
      'amount': amount,
      'payment_method': paymentMethod,
      if (bankAccountId != null) 'bank_account_id': bankAccountId,
      if (notes != null) 'notes': notes,
    });
    if (res != null) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> rejectPendingPayment(int pendingId, {String? reason}) async {
    final res = await _post('/finance/student-payments/pending/$pendingId/reject', {
      if (reason != null) 'reason': reason,
    });
    if (res != null) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  Future<Map<String, dynamic>?> cancelStudentPayment(int paymentId, {String? reason}) async {
    final res = await _post('/finance/student-payments/$paymentId/cancel', {
      if (reason != null) 'reason': reason,
    });
    if (res != null) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }
}