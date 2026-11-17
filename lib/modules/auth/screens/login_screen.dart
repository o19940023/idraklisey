import '../../../providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../core/widgets/motion.dart';
import '../../../services/auth_storage_service.dart';
import '../../../services/network/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final AuthStorageService _authStorage = AuthStorageService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isCheckingAutoLogin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    setState(() => _isCheckingAutoLogin = true);

    // StartupGate artıq API sessiyasını bərpa edib; burada yalnız
    // biometrik sürətli giriş təklif olunur (qeydiyyatdan keçən istifadəçi üçün).
    final biometricEnabled = await _authStorage.isBiometricEnabled();

    if (biometricEnabled) {
      final authenticated = await _authStorage.authenticateWithBiometrics();
      if (authenticated && mounted) {
        final credentials = await _authStorage.getSavedCredentials();
        final username = credentials?['username'];
        final password = credentials?['password'];

        if (username != null &&
            username.isNotEmpty &&
            password != null &&
            password.isNotEmpty &&
            mounted) {
          final session = context.read<SessionController>();
          final ok = await session.login(
            loginType: username.contains('@') ? 'email' : 'fin',
            loginValue: username,
            password: password,
            deviceName: 'flutter-mobile',
          );
          if (ok && mounted) {
            context.read<AppState>().syncFromSession(session);
          }
        }
      }
    }

    if (mounted) {
      setState(() => _isCheckingAutoLogin = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final credentials = await _authStorage.getSavedCredentials();
    final username = credentials?['username'];
    final password = credentials?['password'];

    if (username == null || password == null || username.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saxlanmış biometrik məlumat yoxdur. Əvvəlcə istifadəçi adı və şifrə ilə daxil olun.'),
          ),
        );
      }
      return;
    }

    final authenticated = await _authStorage.authenticateWithBiometrics();
    if (authenticated && mounted) {
      setState(() => _isLoading = true);
      final session = context.read<SessionController>();
      final ok = await session.login(
        loginType: username.contains('@') ? 'email' : 'fin',
        loginValue: username,
        password: password,
        deviceName: 'flutter-mobile',
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          context.read<AppState>().syncFromSession(session);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(session.error ?? 'Giriş uğursuz oldu.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final loc = AppLocalizations.of(context);
    final userToLogin = _usernameCtrl.text.trim();
    final passToLogin = _passwordCtrl.text;

    if (userToLogin.isEmpty || passToLogin.isEmpty) {
      setState(() {
        _errorMessage = loc.loginError;
      });
      return;
    }

    // Tək sahə: e-poçt və ya FİN (avtomatik tanınır).
    // Mövcud hesablarda FİN uzunluğu dəyişə bilər (məs. TEST12) — login-də
    // sərt uzunluq yoxlaması YOXDUR; bu yalnız yeni qeydiyyatda tələb olunur.
    final loginType = userToLogin.contains('@') ? 'email' : 'fin';

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!mounted) return;

    final session = context.read<SessionController>();
    final ok = await session.login(
      loginType: loginType,
      loginValue: userToLogin,
      password: passToLogin,
      deviceName: 'flutter-mobile',
    );

    if (!mounted) return;

    if (ok) {
      // Uğurlu giriş — biometrik quraşdırma təklifi (köhnə UX qorunur).
      final biometricAvailable = await _authStorage.isBiometricAvailable();
      final biometricEnabled = await _authStorage.isBiometricEnabled();

      if (biometricAvailable && !biometricEnabled) {
        final types = await _authStorage.getAvailableBiometrics();
        if (mounted && types.isNotEmpty) {
          await _showBiometricSetupDialog(
            context,
            userToLogin,
            passToLogin,
            types,
          );
        }
      }

      if (mounted) {
        final profile = session.profile;
        if (profile != null && profile.branches.length > 1 && profile.filialId == null) {
          await _pickBranch(session);
        }
      }

      if (mounted) {
        context.read<AppState>().syncFromSession(session);
        context.read<AppState>().resetToDashboard();
        setState(() => _isLoading = false);
      }
      // Naviqasiya lazım deyil — StartupGate sessiyanı izləyib shell-ə keçir.
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = session.error ?? loc.loginError;
        });

        final message = _errorMessage ?? '';
        final isConnectionIssue = message.contains('Serverə qoşulmaq') ||
            message.contains('Server cavab vermədi') ||
            message.contains('Mobil API ünvanı');

        if (isConnectionIssue) {
          await _showConnectionHelp(message);
        }
      }
    }
  }

  Future<void> _showConnectionHelp(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 36),
        title: const Text('Serverə qoşulmaq mümkün deyil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İstifadə olunan ünvan:', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              ApiClient.instance.baseUrl,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'Hansı cihazda işlədirsiniz?\n'
              '• Android emulyator → http://10.0.2.2:8000/api/mobile/v1\n'
              '• Fiziki telefon → http://<PC IP-si>:8000/api/mobile/v1 '
              '(telefon və kompüter eyni şəbəkədə olmalıdır)',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bağla'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openServerSettings();
            },
            icon: const Icon(Icons.dns_rounded, size: 17),
            label: const Text('Ünvanı dəyiş'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBranch(SessionController session) async {
    if (!mounted) return;
    final profile = session.profile;
    if (profile == null) return;

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filial seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hesabınız bir neçə filiala bağlıdır. Davam etmək üçün birini seçin.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ...profile.branches.map(
                (branch) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.apartment_rounded, color: AppColors.primaryAccent),
                  title: Text(branch.name),
                  subtitle: branch.code != null ? Text(branch.code!) : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(branch.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await session.changeContext(filialId: selected);
    }
  }

  Future<void> _openServerSettings() async {
    final client = ApiClient.instance;
    final controller = TextEditingController(text: client.baseUrl);
    bool testing = false;
    String? status;

    void runProbe(StateSetter setDialogState, String url) async {
      setDialogState(() => testing = true);
      final ok = await client.probe(url.trim());
      setDialogState(() {
        testing = false;
        status = ok ? '✓ Server cavab verir — giriş yoxlaya bilərsiniz.' : '✗ Serverə çatmaq mümkün deyil.';
      });
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Server ünvanı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Emulyator', style: TextStyle(fontSize: 11.5)),
                    onPressed: () {
                      controller.text = 'http://10.0.2.2:8000/api/mobile/v1';
                      setDialogState(() => status = null);
                      runProbe(setDialogState, controller.text);
                    },
                  ),
                  ActionChip(
                    label: const Text('Bu kompüter', style: TextStyle(fontSize: 11.5)),
                    onPressed: () {
                      controller.text = 'http://127.0.0.1:8000/api/mobile/v1';
                      setDialogState(() => status = null);
                      runProbe(setDialogState, controller.text);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API base URL',
                  hintText: 'http://10.0.2.2:8000/api/mobile/v1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Fiziki telefon üçün kompüterin IP-sini yazın, məs: '
                'http://10.10.15.253:8000/api/mobile/v1 — telefon və kompüter '
                'eyni Wi-Fi şəbəkəsində olmalıdır.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              if (status != null) ...[
                const SizedBox(height: 10),
                Text(
                  status!,
                  style: TextStyle(
                    fontSize: 12,
                    color: status!.startsWith('✓') ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bağla'),
            ),
            TextButton(
              onPressed: testing ? null : () => runProbe(setDialogState, controller.text),
              child: Text(testing ? 'Yoxlanılır...' : 'Yoxla'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await client.setBaseUrl(controller.text.trim());
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) setState(() {});
                } on StateError catch (e) {
                  setDialogState(() => status = '✗ ${e.message}');
                } catch (_) {
                  setDialogState(() => status = '✗ Ünvan düzgün deyil.');
                }
              },
              child: const Text('Yadda saxla'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBiometricSetupDialog(
    BuildContext dialogContext,
    String username,
    String password,
    List<BiometricType> types,
  ) async {
    final loc = AppLocalizations.of(dialogContext);
    final biometricName = _authStorage.getBiometricName(types);

    await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                types.contains(BiometricType.face)
                    ? Icons.face_rounded
                    : Icons.fingerprint_rounded,
                color: AppColors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.biometricLogin,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          loc.biometricSetupMessage(biometricName),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              loc.notNow,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authStorage.setBiometricEnabled(true);
              await _authStorage.saveCredentials(username, password);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loc.enableBiometric,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IdrakLogo(size: 80, showText: false, isLightText: true),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: AppColors.primaryAccent,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              Text(
                loc.loading,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // ── Dekorativ işıq qatları: kral mavisi + qızıl radial glowlar ──
          Positioned(
            top: -140,
            left: -120,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withAlpha(120),
                    const Color(0xFF2563EB).withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -140,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF5B301).withAlpha(60),
                    const Color(0xFFF5B301).withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withAlpha(70),
                    const Color(0xFF38BDF8).withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          // Zərif diaqonal şüa
          Positioned.fill(
            child: CustomPaint(painter: _LightBeamPainter()),
          ),

          // ── Məzmun ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand Header
                  const SizedBox(height: 12),
                  FadeIn(
                    child: Column(
                      children: [
                        const IdrakLogo(size: 84, showText: true, isLightText: true),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF5B301).withAlpha(90),
                            ),
                          ),
                          child: const Text(
                            'BEYNƏLXALQ TƏHSİL PORTALI',
                            style: TextStyle(
                              color: Color(0xFFF5B301),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Form Card — qaranlıq üzərində incə "shatter" ağ kart
                  FadeIn(
                    delay: const Duration(milliseconds: 130),
                    child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withAlpha(120),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withAlpha(60),
                          blurRadius: 40,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(120),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistemə Giriş',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Şəxsi istifadəçi məlumatlarınızla portala daxil olun.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.danger.withAlpha(40),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email / FIN / Username / Idrak Code Input
                        Text(
                          'E-poçt, FIN, İstifadəçi Adı və ya İdrak Kodu',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText:
                                'Məs: ayse.memmedova@idrak.edu.az və ya 1234567',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primaryAccent,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primaryAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Input
                        Text(
                          'Şifrə',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: 'Şifrənizi daxil edin',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primaryAccent,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.textMuted,
                                size: 19,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primaryAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login Action Button (Gradient Modern Button)
                        PressableScale(
                          pressedScale: 0.98,
                          enabled: !_isLoading,
                          child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.sm,
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Daxil Ol',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        ),

                        // Face ID / Touch ID Button
                        FutureBuilder<bool>(
                          future: _authStorage.isBiometricAvailable(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  foregroundColor: AppColors.primaryAccent,
                                  side: BorderSide(color: AppColors.primaryAccent.withAlpha(70)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.fingerprint_rounded, size: 20),
                                label: const Text(
                                  'Face ID / Barmaq izi ilə daxil ol',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: _isLoading ? null : _handleBiometricLogin,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Badge — tünd şüşə + qızıl qalxan
                  FadeIn(
                    delay: const Duration(milliseconds: 280),
                    child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFFF5B301),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '256-Bit SSL Təhlükəsiz Şifrələmə • İdrak Liseyi',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}

class _LightBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(14),
          Colors.white.withAlpha(0),
        ],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    final path = Path()
      ..moveTo(size.width * 0.85, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.35, size.height)
      ..lineTo(size.width * 0.15, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
