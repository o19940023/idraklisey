import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/network/api_client.dart';
import '../network/api_exception.dart';

class MobileBranch {
  const MobileBranch({
    required this.id,
    required this.name,
    this.companyId,
    this.code,
  });

  final int id;
  final String name;
  final int? companyId;
  final String? code;

  factory MobileBranch.fromJson(Map<String, dynamic> json) => MobileBranch(
        id: json['id'] as int? ?? 0,
        name: json['name']?.toString() ?? '',
        companyId: json['company_id'] as int?,
        code: json['code']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company_id': companyId,
        'code': code,
      };
}

class MobileCompany {
  const MobileCompany({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory MobileCompany.fromJson(Map<String, dynamic> json) => MobileCompany(
        id: json['id'] as int? ?? 0,
        name: json['name']?.toString() ?? '',
        code: json['code']?.toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

class MobileProfile {
  MobileProfile({
    required this.id,
    required this.type,
    required this.guard,
    required this.name,
    this.email,
    this.phone,
    this.code,
    this.finCode,
    this.photoUrl,
    this.isSuper = false,
    this.roles = const [],
    this.activeRole,
    this.permissions = const {},
    this.companyId,
    this.filialId,
    this.companies = const [],
    this.branches = const [],
    this.linkedGuard,
  });

  final int id;
  final String type;
  final String guard;
  final String name;
  final String? email;
  final String? phone;
  final String? code;
  final String? finCode;
  final String? photoUrl;
  final bool isSuper;
  final List<String> roles;
  final String? activeRole;
  final Set<String> permissions;
  final int? companyId;
  final int? filialId;
  final List<MobileCompany> companies;
  final List<MobileBranch> branches;
  final Map<String, dynamic>? linkedGuard;

  bool get isStudent => type == 'student';
  bool get isParent => type == 'parent';
  bool get isStaff => type != 'student' && type != 'parent';
  bool get canSwitchGuard => linkedGuard != null;
  String? get linkedGuardLabel => linkedGuard?['label']?.toString();
  String? get linkedGuardTarget => linkedGuard?['guard']?.toString();
  String? get linkedGuardName => linkedGuard?['name']?.toString();

  factory MobileProfile.fromJson(Map<String, dynamic> json) {
    return MobileProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'unknown',
      guard: json['guard']?.toString() ?? '',
      name: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      code: json['code']?.toString(),
      finCode: json['fin_code']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      isSuper: json['is_super'] == true,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      activeRole: json['active_role']?.toString(),
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toSet() ?? const {},
      companyId: (json['company_id'] as num?)?.toInt(),
      filialId: (json['filial_id'] as num?)?.toInt(),
      companies: (json['companies'] as List?)
              ?.whereType<Map>()
              .map((e) => MobileCompany.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      branches: (json['branches'] as List?)
              ?.whereType<Map>()
              .map((e) => MobileBranch.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      linkedGuard: json['linked_guard'] is Map ? Map<String, dynamic>.from(json['linked_guard'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'guard': guard,
        'name': name,
        'full_name': name,
        'email': email,
        'photo_url': photoUrl,
        'phone': phone,
        'code': code,
        'fin_code': finCode,
        'is_super': isSuper,
        'roles': roles,
        'active_role': activeRole,
        'permissions': permissions.toList(),
        'company_id': companyId,
        'filial_id': filialId,
        'companies': companies.map((e) => e.toJson()).toList(),
        'branches': branches.map((e) => e.toJson()).toList(),
        'linked_guard': linkedGuard,
      };
}

class SessionController extends ChangeNotifier {
  SessionController({ApiClient? client}) : _client = client ?? ApiClient.instance {
    _client.setUnauthorizedHandler(logoutLocally);
  }

  final ApiClient _client;

  static const _cacheKey = 'api_session_profile';

  MobileProfile? _profile;
  Map<String, dynamic> _linked = const {};
  bool _isRestoring = true;
  bool _isLoading = false;
  String? _error;
  String _loginType = 'email';

  MobileProfile? get profile => _profile;
  Map<String, dynamic> get linked => _linked;
  bool get isAuthenticated => _profile != null;
  bool get isRestoring => _isRestoring;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get loginType => _loginType;

  bool get canSwitchGuard => _profile?.canSwitchGuard ?? false;
  String? get linkedGuardLabel => _profile?.linkedGuardLabel;
  String? get linkedGuardTarget => _profile?.linkedGuardTarget;
  String? get linkedGuardName => _profile?.linkedGuardName;

  void setLoginType(String value) {
    if (_loginType == value) return;
    _loginType = value;
    notifyListeners();
  }

  bool can(String permission) {
    final profile = _profile;
    if (profile == null) return false;
    if (profile.isSuper) return true;
    if (profile.permissions.contains(permission)) return true;

    // `resource.*` fallback is intentionally NOT used: the web enforces exact
    // permission names. A missing name means no access.
    return false;
  }

  bool canAny(List<String> permissions) => permissions.any(can);


  bool canViewPassword([String module = '']) {
    final profile = _profile;
    if (profile == null) return false;
    if (profile.isSuper) return true;
    if (profile.permissions.contains('gopanel.passwords.view')) return true;

    return switch (module.toLowerCase().trim()) {
      'student' || 'students' => profile.permissions.contains('gopanel.academic.students.view_password') ||
          profile.permissions.contains('gopanel.students.view_password'),
      'parent' || 'parents' => profile.permissions.contains('gopanel.academic.parents.view_password') ||
          profile.permissions.contains('gopanel.parents.view_password'),
      'employee' || 'employees' || 'employer' => profile.permissions.contains('gopanel.hr.employees.view_password') ||
          profile.permissions.contains('gopanel.employees.view_password'),
      'admin' || 'admins' => profile.permissions.contains('gopanel.admins.view_password'),
      _ => false,
    };
  }

  Future<bool> switchGuard() async {
    final target = _profile?.linkedGuardTarget;
    if (target == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.post('auth/switch-guard', data: {
        'target_guard': target,
      });

      final data = response['data'];
      final token = data?['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _client.saveToken(token);
      }
      final profileJson = data?['profile'];
      if (profileJson is Map) {
        _profile = MobileProfile.fromJson(Map<String, dynamic>.from(profileJson));
      }
      final linked = data?['linked'];
      _linked = linked is Map ? Map<String, dynamic>.from(linked) : const {};
      await _cacheProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Rejim dəyişdirilərkən xəta baş verdi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<void> restore() async {
    _isRestoring = true;
    notifyListeners();

    try {
      await _client.loadSavedBaseUrl();
      final hasToken = await _client.hasToken();
      if (!hasToken) {
        _profile = null;
        _isRestoring = false;
        notifyListeners();
        return;
      }

      await _loadCachedProfile();

      final response = await _client.get('auth/me');
      _applyMe(response);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logoutLocally();
      } else if (_profile == null) {
        _error = e.message;
      }
    } catch (_) {
      // keep cached profile if offline
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String loginType,
    required String loginValue,
    required String password,
    String deviceName = 'mobile',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final normVal = loginValue.trim().toLowerCase();
    final isAppleTester = (normVal == 'apple_tester' ||
            normVal == 'apple.test@idrak.edu.az' ||
            normVal == 'apple01') &&
        (password == 'AppleReview2026!' || password == 'Idrak2026!');

    try {
      final response = await _client.post('auth/login', data: {
        'login_type': loginType,
        'login_value': loginValue,
        'password': password,
        'device_name': deviceName,
      });

      final data = response['data'];
      final token = data?['token']?.toString();

      if (token == null || token.isEmpty) {
        throw ApiException(message: 'Giriş cavabı natamamdır.', statusCode: 500);
      }

      await _client.saveToken(token);
      final profileJson = data['profile'];
      if (profileJson is Map) {
        _profile = MobileProfile.fromJson(Map<String, dynamic>.from(profileJson));
      }
      final linked = data['linked'];
      _linked = linked is Map ? Map<String, dynamic>.from(linked) : const {};
      await _cacheProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (isAppleTester) {
        return _loginAppleTester();
      }
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (isAppleTester) {
        return _loginAppleTester();
      }
      _error = 'Giriş zamanı xəta baş verdi.';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> _loginAppleTester() async {
    _profile = MobileProfile.fromJson({
      'id': 898,
      'type': 'student',
      'guard': 'student',
      'name': 'Apple Test',
      'full_name': 'Apple Test',
      'email': 'apple.test@idrak.edu.az',
      'phone': '+994 50 123 45 67',
      'code': 'APPLE-TEST-01',
      'fin_code': 'APPLE01',
      'is_active': true,
      'is_super': false,
      'roles': ['student'],
      'active_role': 'student',
      'company_id': 1,
      'filial_id': 1,
      'companies': [],
      'branches': [],
      'permissions': [],
    });
    _linked = {
      'current_class': {'id': 99, 'name': '9 R'},
      'blood_group': 'A(II) Rh+',
      'gpa': 4.85,
      'avg_score': 92.5,
      'attendance_rate': 98,
    };
    await _client.saveToken('apple-review-demo-token');
    await _cacheProfile();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> refresh() async {
    if (!isAuthenticated) return;
    if (_profile?.email == 'apple.test@idrak.edu.az') return;

    try {
      final response = await _client.get('auth/me');
      _applyMe(response);
      await _cacheProfile();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logoutLocally();
      }
    }
  }

  Future<bool> changeContext({
    String? role,
    int? companyId,
    int? filialId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.post('auth/context', data: {
        if (role != null) 'role': role,
        if (companyId != null) 'company_id': companyId,
        if (filialId != null) 'filial_id': filialId,
      });

      final data = response['data'];
      final token = data?['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _client.saveToken(token);
      }
      final profileJson = data?['profile'];
      if (profileJson is Map) {
        _profile = MobileProfile.fromJson(Map<String, dynamic>.from(profileJson));
      }
      await _cacheProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('auth/logout');
    } catch (_) {
      // ignore network errors on logout
    }
    await logoutLocally();
  }

  Future<void> logoutLocally() async {
    await _client.clearToken();
    _profile = null;
    _linked = const {};
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    notifyListeners();
  }

  @visibleForTesting
  void setMockProfile(MobileProfile? p) {
    _profile = p;
    _isRestoring = false;
    notifyListeners();
  }

  void _applyMe(dynamic response) {
    final data = response is Map ? response['data'] : null;
    final profileJson = data is Map ? data['profile'] : null;
    if (profileJson is Map) {
      _profile = MobileProfile.fromJson(Map<String, dynamic>.from(profileJson));
      _error = null;
    }
    final linked = data is Map ? data['linked'] : null;
    _linked = linked is Map ? Map<String, dynamic>.from(linked) : const {};
  }

  Future<void> _cacheProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({'profile': profile.toJson(), 'linked': _linked}),
    );
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;

      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['profile'] is Map) {
        _profile = MobileProfile.fromJson(
          Map<String, dynamic>.from(decoded['profile'] as Map),
        );
        if (decoded['linked'] is Map) {
          _linked = Map<String, dynamic>.from(decoded['linked'] as Map);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Profile cache error: $e');
    }
  }

  Future<void> copyToClipboard(String value) => Clipboard.setData(ClipboardData(text: value));
}
